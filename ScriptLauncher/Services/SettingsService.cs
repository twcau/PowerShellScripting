using System.IO;
using System.Text.Json;

namespace ScriptLauncher.Services
{
    public class AppSettings
    {
        public string? ConfigPath { get; set; }
        public string? GlobalConfigPath { get; set; }
        public int HistoryRetention { get; set; } = 20;
        public int AutoRefreshMinutes { get; set; } = 15;
        public bool ShowBadgeNotification { get; set; } = true;
        public bool ShowToastNotification { get; set; } = true;
    }

    public class SettingsService
    {
        private static readonly string SettingsDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "ScriptLauncher");
        private static readonly string SettingsPath = Path.Combine(SettingsDir, "settings.json");
        private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };

        /// <summary>
        /// Loads application settings from the per-user settings file, returning defaults if unavailable or invalid.
        /// </summary>
        /// <returns>Loaded settings object with sensible defaults.</returns>
        public static AppSettings Load()
        {
            try
            {
                if (!File.Exists(SettingsPath))
                {
                    return new AppSettings();
                }

                string json = File.ReadAllText(SettingsPath);
                return JsonSerializer.Deserialize<AppSettings>(json) ?? new AppSettings();
            }
            catch
            {
                return new AppSettings();
            }
        }

        /// <summary>
        /// Saves application settings to the per-user settings file.
        /// </summary>
        /// <param name="settings">Settings to persist.</param>
        public static void Save(AppSettings settings)
        {
            Directory.CreateDirectory(SettingsDir);
            string json = JsonSerializer.Serialize(settings, JsonOptions);
            File.WriteAllText(SettingsPath, json);
        }
    }
}
