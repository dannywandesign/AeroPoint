using System;
using AeroPointAgent.Storage;

namespace AeroPointAgent.Pairing
{
    public struct PairingSession
    {
        public string Nonce { get; }
        public string Payload { get; }

        public PairingSession(string nonce, string payload)
        {
            Nonce = nonce;
            Payload = payload;
        }
    }

    public sealed class PairingService
    {
        private readonly string _host;
        private readonly int _port;
        private readonly string _serverName;
        private readonly IPairingTokenStore _tokenStore;
        private readonly Func<string> _nonceGenerator;
        private readonly Func<string> _tokenGenerator;
        private string? _activeNonce;

        public const string PairingClientId = "__pairing__";

        public PairingService(
            string host,
            int port,
            string serverName,
            IPairingTokenStore tokenStore,
            Func<string>? nonceGenerator = null,
            Func<string>? tokenGenerator = null)
        {
            _host = host;
            _port = port;
            _serverName = serverName;
            _tokenStore = tokenStore;
            _nonceGenerator = nonceGenerator ?? (() => Guid.NewGuid().ToString());
            _tokenGenerator = tokenGenerator ?? (() => Guid.NewGuid().ToString());
        }

        public PairingSession StartPairing()
        {
            string nonce = _nonceGenerator();
            _activeNonce = nonce;
            // Save the nonce as a valid token immediately under the pairing sentinel key.
            // The iPhone sends the nonce as its token in the hello message, so the server
            // can authenticate it before completePairing() is called.
            _tokenStore.Save(nonce, PairingClientId);

            string payload = $"aeropoint://pair?host={_host}&port={_port}&nonce={nonce}&name={Uri.EscapeDataString(_serverName)}&v=1";
            return new PairingSession(nonce, payload);
        }

        public string CompletePairing(string nonce, string clientId)
        {
            if (nonce != _activeNonce)
            {
                throw new InvalidOperationException("Invalid pairing nonce");
            }

            string token = _tokenGenerator();
            _tokenStore.Save(token, clientId);
            _activeNonce = null;
            return token;
        }
    }
}
