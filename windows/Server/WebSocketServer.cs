using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using AeroPointAgent.Input;
using AeroPointAgent.Storage;

namespace AeroPointAgent.Server
{
    public interface IWebSocketServerDelegate
    {
        void ServerDidStart(string address, ushort port);
        void ServerDidFailToStart(Exception error);
        void ClientDidConnect();
        void ClientDidAuthenticate();
        void ClientDidDisconnect();
    }

    public final class WebSocketServer
    {
        private readonly ushort _port;
        private readonly IPairingTokenStore _tokenStore;
        private TcpListener? _listener;
        private CancellationTokenSource? _cts;
        private TcpClient? _activeClient;
        private WebSocket? _activeSocket;
        private ClientSession? _activeSession;

        public IWebSocketServerDelegate? Delegate { get; set; }

        public WebSocketServer(ushort port, IPairingTokenStore tokenStore)
        {
            _port = port;
            _tokenStore = tokenStore;
        }

        public void Start()
        {
            if (_listener != null) return;

            try
            {
                // Bind to 0.0.0.0 (all interfaces) to allow local network connections
                _listener = new TcpListener(IPAddress.Any, _port);
                _listener.Start();

                _cts = new CancellationTokenSource();
                string address = GetLocalIPAddress() ?? "127.0.0.1";
                Delegate?.ServerDidStart(address, _port);

                // Run connection loop in background
                Task.Run(() => AcceptConnectionsAsync(_cts.Token));
            }
            catch (Exception ex)
            {
                Delegate?.ServerDidFailToStart(ex);
            }
        }

        public void Stop()
        {
            _cts?.Cancel();
            _listener?.Stop();
            _listener = null;

            CloseActiveConnection();
        }

        private async Task AcceptConnectionsAsync(CancellationToken token)
        {
            while (!token.IsCancellationRequested)
            {
                try
                {
                    var client = await _listener!.AcceptTcpClientAsync(token);
                    
                    // One client at a time: disconnect any existing client
                    CloseActiveConnection();

                    _activeClient = client;
                    
                    // Run client loop in background
                    _ = Task.Run(() => ProcessClientAsync(client, token));
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Server] Error accepting client: {ex.Message}");
                }
            }
        }

        private async Task ProcessClientAsync(TcpClient client, CancellationToken token)
        {
            WebSocket? socket = null;
            try
            {
                Delegate?.ClientDidConnect();

                socket = await PerformHandshakeAsync(client);
                if (socket == null)
                {
                    CloseActiveConnection();
                    return;
                }

                _activeSocket = socket;
                
                string hostName = Dns.GetHostName();
                _activeSession = new ClientSession(_tokenStore, new SendInputInjector(), hostName);

                byte[] buffer = new byte[4096];
                using var ms = new MemoryStream();

                while (socket.State == WebSocketState.Open && !token.IsCancellationRequested)
                {
                    WebSocketReceiveResult result;
                    do
                    {
                        result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), token);
                        if (result.MessageType == WebSocketMessageType.Close)
                        {
                            break;
                        }
                        ms.Write(buffer, 0, result.Count);
                    } while (!result.EndOfMessage);

                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed by client", token);
                        break;
                    }

                    string rawMessage = Encoding.UTF8.GetString(ms.ToArray());
                    ms.SetLength(0); // Reset stream length for next frame

                    // Pass request to session state machine
                    string responseJson = _activeSession.Receive(rawMessage);

                    // Send response frame
                    byte[] responseBytes = Encoding.UTF8.GetBytes(responseJson);
                    await socket.SendAsync(
                        new ArraySegment<byte>(responseBytes),
                        WebSocketMessageType.Text,
                        true,
                        token
                    );

                    // Notify delegate on authentication
                    if (_activeSession.IsAuthenticated && responseJson.Contains("\"hello_ok\""))
                    {
                        Delegate?.ClientDidAuthenticate();
                    }

                    // If token authentication failed, send error and terminate connection
                    if (responseJson.Contains("\"invalid_token\""))
                    {
                        Console.WriteLine("[Server] Invalid token — terminating client connection");
                        await Task.Delay(500, token); // Allow response to flush
                        break;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Server] Error processing client: {ex.Message}");
            }
            finally
            {
                if (client == _activeClient)
                {
                    CloseActiveConnection();
                }
            }
        }

        private async Task<WebSocket?> PerformHandshakeAsync(TcpClient client)
        {
            try
            {
                var stream = client.GetStream();
                var reader = new StreamReader(stream, Encoding.UTF8);
                var writer = new StreamWriter(stream, Encoding.UTF8) { AutoFlush = true };

                string? line;
                string? webSocketKey = null;

                while ((line = await reader.ReadLineAsync()) != null)
                {
                    if (line == "") break; // Blank line marks end of headers
                    if (line.StartsWith("Sec-WebSocket-Key:", StringComparison.OrdinalIgnoreCase))
                    {
                        webSocketKey = line.Substring("Sec-WebSocket-Key:".Length).Trim();
                    }
                }

                if (string.IsNullOrEmpty(webSocketKey))
                {
                    Console.WriteLine("[Server] Handshake failed: Sec-WebSocket-Key is missing");
                    return null;
                }

                // Compute accept key matching the standard
                string magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
                byte[] sha1Bytes = System.Security.Cryptography.SHA1.HashData(
                    Encoding.UTF8.GetBytes(webSocketKey + magic)
                );
                string acceptKey = Convert.ToBase64String(sha1Bytes);

                // Write the upgrade HTTP response
                await writer.WriteAsync(
                    "HTTP/1.1 101 Switching Protocols\r\n" +
                    "Upgrade: websocket\r\n" +
                    "Connection: Upgrade\r\n" +
                    "Sec-WebSocket-Accept: " + acceptKey + "\r\n\r\n"
                );

                return WebSocket.CreateFromStream(stream, isServer: true, subProtocol: null, keepAliveInterval: TimeSpan.FromSeconds(30));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Server] Handshake error: {ex.Message}");
                return null;
            }
        }

        private void CloseActiveConnection()
        {
            if (_activeSocket != null)
            {
                try
                {
                    _activeSocket.Dispose();
                }
                catch {}
                _activeSocket = null;
            }

            if (_activeClient != null)
            {
                try
                {
                    _activeClient.Dispose();
                }
                catch {}
                _activeClient = null;
                
                Delegate?.ClientDidDisconnect();
            }

            _activeSession = null;
        }

        public static string? GetLocalIPAddress()
        {
            try
            {
                foreach (var ni in System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces())
                {
                    if (ni.OperationalStatus == System.Net.NetworkInformation.OperationalStatus.Up &&
                        (ni.NetworkInterfaceType == System.Net.NetworkInformation.NetworkInterfaceType.Wireless80211 ||
                         ni.NetworkInterfaceType == System.Net.NetworkInformation.NetworkInterfaceType.Ethernet))
                    {
                        foreach (var ip in ni.GetIPProperties().UnicastAddresses)
                        {
                            if (ip.Address.AddressFamily == AddressFamily.InterNetwork)
                            {
                                return ip.Address.ToString();
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Server] Error getting local IP: {ex.Message}");
            }
            return null;
        }
    }
}
