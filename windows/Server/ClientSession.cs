using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;
using AeroPointAgent.Input;
using AeroPointAgent.Protocol;
using AeroPointAgent.Storage;

namespace AeroPointAgent.Server
{
    public class ClientSessionResponse
    {
        public string Type { get; }
        public Dictionary<string, object> Payload { get; }

        public ClientSessionResponse(string type, Dictionary<string, object> payload)
        {
            Type = type;
            Payload = payload;
        }

        public string ToJson()
        {
            var dict = new Dictionary<string, object>(Payload)
            {
                ["type"] = Type
            };
            return JsonSerializer.Serialize(dict);
        }
    }

    public sealed class ClientSession
    {
        private readonly IPairingTokenStore _tokenStore;
        private readonly IInputInjector _inputInjector;
        private readonly MessageValidator _messageValidator = new();
        private readonly string _serverName;

        public bool IsAuthenticated { get; private set; }

        public ClientSession(
            IPairingTokenStore tokenStore,
            IInputInjector inputInjector,
            string serverName = "AeroPoint Agent")
        {
            _tokenStore = tokenStore;
            _inputInjector = inputInjector;
            _serverName = serverName;
        }

        public string Receive(string rawMessage)
        {
            Console.WriteLine($"[Session] receive {rawMessage.Length} characters, authenticated={IsAuthenticated}");

            string type = GetMessageType(rawMessage);
            if (type == "hello")
            {
                return Authenticate(rawMessage).ToJson();
            }

            if (!IsAuthenticated)
            {
                Console.WriteLine("[Session] ⚠️ not authenticated — dropping command");
                return JsonSerializer.Serialize(new Dictionary<string, string>
                {
                    ["type"] = "error",
                    ["code"] = "not_authenticated"
                });
            }

            try
            {
                var message = _messageValidator.Validate(rawMessage);
                Console.WriteLine($"[Session] routing message sequence {message.Sequence}");
                Route(message);
                
                return JsonSerializer.Serialize(new Dictionary<string, object>
                {
                    ["type"] = "ack",
                    ["seq"] = message.Sequence
                });
            }
            catch (MessageValidationError ex)
            {
                return JsonSerializer.Serialize(new Dictionary<string, string>
                {
                    ["type"] = "error",
                    ["code"] = ex.Code
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Session] Input injection error: {ex.Message}");
                return JsonSerializer.Serialize(new Dictionary<string, string>
                {
                    ["type"] = "error",
                    ["code"] = "input_injection_failed"
                });
            }
        }

        private ClientSessionResponse Authenticate(string rawMessage)
        {
            HelloMessage hello;
            try
            {
                hello = JsonSerializer.Deserialize<HelloMessage>(rawMessage) ?? throw new Exception();
            }
            catch (Exception)
            {
                Console.WriteLine("[Session] ⚠️ hello decode failed");
                throw new MessageValidationError("invalid_json", "Invalid hello payload");
            }

            if (hello.ClientId == null || hello.Token == null)
            {
                throw new MessageValidationError("missing_field", "Missing clientId or token");
            }

            // Check token match
            string? storedToken = _tokenStore.GetToken(hello.ClientId) 
                                 ?? _tokenStore.GetToken("__pairing__");

            Console.WriteLine($"[Session] hello clientId={hello.ClientId} tokenMatch={storedToken == hello.Token}");
            if (storedToken == null || storedToken != hello.Token)
            {
                throw new MessageValidationError("invalid_token", "Invalid client token");
            }

            // Persist the token under the real clientId so future reconnects
            // (after PC restarts) don't require re-scanning the QR code.
            _tokenStore.Save(hello.Token, hello.ClientId);
            IsAuthenticated = true;
            Console.WriteLine($"[Session] ✓ authenticated as {_serverName}, saved token for {hello.ClientId}");

            return new ClientSessionResponse("hello_ok", new Dictionary<string, object>
            {
                ["serverName"] = _serverName,
                ["protocolVersion"] = 1
            });
        }

        private void Route(AeroPointMessage message)
        {
            switch (message)
            {
                case MouseMoveMessage move:
                    _inputInjector.MoveMouse(move.Dx, move.Dy);
                    break;
                case MouseClickMessage click:
                    _inputInjector.ClickMouse(click.Button);
                    break;
                case MouseDownMessage down:
                    _inputInjector.SetMouseButton(down.Button, true);
                    break;
                case MouseUpMessage up:
                    _inputInjector.SetMouseButton(up.Button, false);
                    break;
                case MouseScrollMessage scroll:
                    _inputInjector.ScrollMouse(scroll.Dx, scroll.Dy);
                    break;
                case KeyboardTextMessage text:
                    _inputInjector.TypeText(text.Text);
                    break;
                case KeyboardKeyMessage key:
                    _inputInjector.PressKey(key.Key, key.Modifiers);
                    break;
            }
        }

        private string GetMessageType(string rawMessage)
        {
            try
            {
                var envelope = JsonSerializer.Deserialize<TypeEnvelope>(rawMessage);
                return envelope?.Type ?? "";
            }
            catch
            {
                return "";
            }
        }

        private class TypeEnvelope
        {
            [JsonPropertyName("type")]
            public string? Type { get; set; }
        }

        private class HelloMessage
        {
            [JsonPropertyName("type")]
            public string? Type { get; set; }

            [JsonPropertyName("clientId")]
            public string? ClientId { get; set; }

            [JsonPropertyName("token")]
            public string? Token { get; set; }
        }
    }
}
