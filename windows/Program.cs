using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Windows.Forms;
using AeroPointAgent.Pairing;
using AeroPointAgent.Server;
using AeroPointAgent.Storage;
using AeroPointAgent.UI;

namespace AeroPointAgent
{
    internal static class Program
    {
        private static NotifyIcon _notifyIcon = null!;
        private static ContextMenuStrip _contextMenu = null!;
        private static ToolStripMenuItem _statusMenuItem = null!;
        private static ToolStripMenuItem _addressMenuItem = null!;
        private static WebSocketServer _server = null!;
        private static PairingService _pairingService = null!;
        private static FilePairingTokenStore _tokenStore = null!;
        private static PairingForm? _activePairingForm;
        private static Icon _appIcon = null!;

        [STAThread]
        private static void Main()
        {
            ApplicationConfiguration.Initialize();

            // Create program icon dynamically
            _appIcon = CreateProgramIcon();

            // Set up token store
            _tokenStore = new FilePairingTokenStore();

            // Set up tray icon and menu
            InitializeTrayIcon();

            // Initialize pairing service with local IP or fallback
            ushort port = 41074;
            string serverName = System.Net.Dns.GetHostName();
            string initialIp = WebSocketServer.GetLocalIPAddress() ?? "127.0.0.1";
            _pairingService = new PairingService(initialIp, port, serverName, _tokenStore);

            // Start WebSocket server on default port 41074
            _server = new WebSocketServer(port, _tokenStore);
            _server.Delegate = new ServerDelegate();
            _server.Start();

            Application.Run();

            // Cleanup on exit
            _server.Stop();
            _notifyIcon.Dispose();
            _appIcon.Dispose();
        }

        private static void InitializeTrayIcon()
        {
            _contextMenu = new ContextMenuStrip();

            _statusMenuItem = new ToolStripMenuItem("Status: Starting...") { Enabled = false };
            _addressMenuItem = new ToolStripMenuItem("Address: Detecting...") { Enabled = false };
            
            var pairItem = new ToolStripMenuItem("Pair iPhone...", null, OnPairClick);
            var unpairItem = new ToolStripMenuItem("Forget Devices", null, OnUnpairClick);
            var exitItem = new ToolStripMenuItem("Exit", null, OnExitClick);

            _contextMenu.Items.Add(_statusMenuItem);
            _contextMenu.Items.Add(_addressMenuItem);
            _contextMenu.Items.Add(new ToolStripSeparator());
            _contextMenu.Items.Add(pairItem);
            _contextMenu.Items.Add(unpairItem);
            _contextMenu.Items.Add(new ToolStripSeparator());
            _contextMenu.Items.Add(exitItem);

            _notifyIcon = new NotifyIcon
            {
                Icon = _appIcon,
                ContextMenuStrip = _contextMenu,
                Text = "AeroPoint Agent",
                Visible = true
            };

            // Double click opens the pairing window
            _notifyIcon.DoubleClick += OnPairClick;
        }

        private static void OnPairClick(object? sender, EventArgs e)
        {
            if (_activePairingForm == null || _activePairingForm.IsDisposed)
            {
                _activePairingForm = new PairingForm(_pairingService, _tokenStore, UnpairAll);
            }

            _activePairingForm.Show();
            _activePairingForm.BringToFront();
        }

        private static void OnUnpairClick(object? sender, EventArgs e)
        {
            var result = MessageBox.Show(
                "Are you sure you want to unpair and clear all stored iPhone access tokens?",
                "Forget Devices",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );

            if (result == DialogResult.Yes)
            {
                UnpairAll();
                _notifyIcon.ShowBalloonTip(3000, "AeroPoint", "All paired devices have been forgotten.", ToolTipIcon.Info);
            }
        }

        private static void UnpairAll()
        {
            // Clear standard local tokens
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            string tokensPath = Path.Combine(appData, "AeroPointAgent", "tokens.json");
            if (File.Exists(tokensPath))
            {
                try
                {
                    File.Delete(tokensPath);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Program] Error deleting tokens: {ex.Message}");
                }
            }

            // Also clear pairing nonce from active memory store in PairingService by recreating it
            ushort port = 41074;
            string serverName = System.Net.Dns.GetHostName();
            string address = WebSocketServer.GetLocalIPAddress() ?? "127.0.0.1";
            _pairingService = new PairingService(address, port, serverName, _tokenStore);
            
            _activePairingForm?.UpdateStatus("Disconnected (Cleared)", false);
        }

        private static void OnExitClick(object? sender, EventArgs e)
        {
            Application.Exit();
        }

        private static Icon CreateProgramIcon()
        {
            using (Bitmap bmp = new Bitmap(16, 16))
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);

                // Premium Indigo Circle
                using (Brush brush = new SolidBrush(Color.FromArgb(99, 102, 241)))
                {
                    g.FillEllipse(brush, 0, 0, 15, 15);
                }

                // White paper plane / cursor shape
                Point[] points = {
                    new Point(3, 4),
                    new Point(12, 7),
                    new Point(3, 11),
                    new Point(6, 7)
                };
                g.FillPolygon(Brushes.White, points);

                return Icon.FromHandle(bmp.GetHicon());
            }
        }

        private class ServerDelegate : IWebSocketServerDelegate
        {
            public void ServerDidStart(string address, ushort port)
            {
                _statusMenuItem.Text = "Status: Running";
                _addressMenuItem.Text = $"Address: {address}:{port}";
                _notifyIcon.Text = $"AeroPoint Agent ({address}:{port})";

                // Update the pairing service with the real IP address
                string serverName = System.Net.Dns.GetHostName();
                _pairingService = new PairingService(address, port, serverName, _tokenStore);

                _notifyIcon.ShowBalloonTip(3000, "AeroPoint Agent", $"Server started on {address}:{port}", ToolTipIcon.Info);
            }

            public void ServerDidFailToStart(Exception error)
            {
                _statusMenuItem.Text = $"Status: Error";
                _addressMenuItem.Text = $"Error: {error.Message}";
                _notifyIcon.ShowBalloonTip(3000, "AeroPoint Agent", $"Server failed to start: {error.Message}", ToolTipIcon.Error);
            }

            public void ClientDidConnect()
            {
                _statusMenuItem.Text = "Status: iPhone connected";
                _activePairingForm?.UpdateStatus("iPhone connected ✓", true);
                _notifyIcon.ShowBalloonTip(3000, "AeroPoint Connected", "An iPhone has connected to the agent.", ToolTipIcon.Info);
            }

            public void ClientDidAuthenticate()
            {
                _statusMenuItem.Text = "Status: iPhone authenticated";
                _activePairingForm?.UpdateStatus("iPhone authenticated ✓", true);
            }

            public void ClientDidDisconnect()
            {
                _statusMenuItem.Text = "Status: Running";
                _activePairingForm?.UpdateStatus("Disconnected", false);
                _notifyIcon.ShowBalloonTip(3000, "AeroPoint Disconnected", "The iPhone disconnected.", ToolTipIcon.Info);
            }
        }
    }
}
