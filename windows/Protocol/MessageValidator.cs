using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;
using AeroPointAgent.Input;

namespace AeroPointAgent.Protocol
{
    public sealed class MessageValidator
    {
        private readonly HashSet<int> _seenSequences = new();

        public MessageValidator() {}

        public AeroPointMessage Validate(string json)
        {
            RawMessage raw;
            try
            {
                raw = JsonSerializer.Deserialize<RawMessage>(json) ?? throw new MessageValidationError("invalid_json", "Failed to deserialize JSON");
            }
            catch (Exception)
            {
                throw new MessageValidationError("invalid_json", "Invalid JSON format");
            }

            if (raw.Type == null)
            {
                throw new MessageValidationError("missing_field", "Missing 'type' field");
            }

            if (!raw.Seq.HasValue)
            {
                throw new MessageValidationError("missing_field", "Missing 'seq' field");
            }

            int seq = raw.Seq.Value;
            lock (_seenSequences)
            {
                if (!_seenSequences.Add(seq))
                {
                    throw new MessageValidationError("duplicate_sequence", $"Duplicate sequence number: {seq}");
                }
            }

            switch (raw.Type)
            {
                case "mouse.move":
                    if (!raw.Dx.HasValue) throw new MessageValidationError("missing_field", "Missing 'dx' field");
                    if (!raw.Dy.HasValue) throw new MessageValidationError("missing_field", "Missing 'dy' field");
                    return new MouseMoveMessage(seq, raw.Dx.Value, raw.Dy.Value);

                case "mouse.click":
                    if (raw.Button == null) throw new MessageValidationError("missing_field", "Missing 'button' field");
                    if (!Enum.TryParse<MouseButton>(raw.Button, true, out var button))
                    {
                        throw new MessageValidationError("unsupported_button", $"Unsupported button: {raw.Button}");
                    }
                    return new MouseClickMessage(seq, button);

                case "mouse.scroll":
                    if (!raw.Dx.HasValue) throw new MessageValidationError("missing_field", "Missing 'dx' field");
                    if (!raw.Dy.HasValue) throw new MessageValidationError("missing_field", "Missing 'dy' field");
                    return new MouseScrollMessage(seq, raw.Dx.Value, raw.Dy.Value);

                case "keyboard.text":
                    if (raw.Text == null) throw new MessageValidationError("missing_field", "Missing 'text' field");
                    return new KeyboardTextMessage(seq, raw.Text);

                case "keyboard.key":
                    if (raw.Key == null) throw new MessageValidationError("missing_field", "Missing 'key' field");
                    if (!Enum.TryParse<KeyboardKey>(raw.Key, true, out var key))
                    {
                        throw new MessageValidationError("unsupported_key", $"Unsupported key: {raw.Key}");
                    }

                    var modifiers = new List<KeyboardModifier>();
                    if (raw.Modifiers != null)
                    {
                        foreach (var modStr in raw.Modifiers)
                        {
                            if (!Enum.TryParse<KeyboardModifier>(modStr, true, out var modifier))
                            {
                                throw new MessageValidationError("unsupported_modifier", $"Unsupported modifier: {modStr}");
                            }
                            modifiers.Add(modifier);
                        }
                    }
                    return new KeyboardKeyMessage(seq, key, modifiers);

                default:
                    throw new MessageValidationError("unsupported_type", $"Unsupported message type: {raw.Type}");
            }
        }

        private class RawMessage
        {
            [JsonPropertyName("seq")]
            public int? Seq { get; set; }

            [JsonPropertyName("type")]
            public string? Type { get; set; }

            [JsonPropertyName("dx")]
            public double? Dx { get; set; }

            [JsonPropertyName("dy")]
            public double? Dy { get; set; }

            [JsonPropertyName("button")]
            public string? Button { get; set; }

            [JsonPropertyName("text")]
            public string? Text { get; set; }

            [JsonPropertyName("key")]
            public string? Key { get; set; }

            [JsonPropertyName("modifiers")]
            public List<string>? Modifiers { get; set; }
        }
    }
}
