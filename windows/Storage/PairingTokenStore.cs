using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace AeroPointAgent.Storage
{
    public interface IPairingTokenStore
    {
        void Save(string token, string clientId);
        string? GetToken(string clientId);
    }

    public final class FilePairingTokenStore : IPairingTokenStore
    {
        private readonly string _filePath;

        public FilePairingTokenStore(string fileName = "tokens.json")
        {
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            string directoryPath = Path.Combine(appData, "AeroPointAgent");
            
            // Ensure the directory exists
            Directory.CreateDirectory(directoryPath);
            _filePath = Path.Combine(directoryPath, fileName);
            Console.WriteLine($"[Storage] FilePairingTokenStore path: {_filePath}");
        }

        private Dictionary<string, string> LoadTokens()
        {
            if (!File.Exists(_filePath))
            {
                return new Dictionary<string, string>();
            }

            try
            {
                string json = File.ReadAllText(_filePath);
                return JsonSerializer.Deserialize<Dictionary<string, string>>(json) ?? new Dictionary<string, string>();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Storage] Error loading tokens: {ex.Message}");
                return new Dictionary<string, string>();
            }
        }

        private void SaveTokens(Dictionary<string, string> tokens)
        {
            try
            {
                string json = JsonSerializer.Serialize(tokens, new JsonSerializerOptions { WriteIndented = true });
                File.WriteAllText(_filePath, json);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Storage] Error saving tokens: {ex.Message}");
            }
        }

        public void Save(string token, string clientId)
        {
            var tokens = LoadTokens();
            tokens[clientId] = token;
            SaveTokens(tokens);
        }

        public string? GetToken(string clientId)
        {
            var tokens = LoadTokens();
            return tokens.TryGetValue(clientId, out string? token) ? token : null;
        }
    }
}
