using System.IO;
using System.Text.Json;
using ScriptLauncher.Models;

namespace ScriptLauncher.Services
{
    /// <summary>
    /// Creates a service bound to a specific config path, defaulting to the user config when null or empty.
    /// </summary>
    /// <param name="configPath">Preferred config path; defaults to user path when null/empty.</param>
    /// <param name="allowFallbackToGlobal">When true and the preferred path does not exist, attempts to load from the global fallback path. For user configs, this should be false to avoid cross-scope contamination.</param>
    public class ConfigService(string? configPath = null, bool allowFallbackToGlobal = false)
    {
        private const string ConfigFileName = "scripts.json";
        private readonly bool _allowFallbackToGlobal = allowFallbackToGlobal;
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            WriteIndented = true
        };

        public string ConfigPath { get; } = string.IsNullOrWhiteSpace(configPath)
                ? GetDefaultUserConfigPath()
                : configPath;

        /// <summary>
        /// Gets the default per-user configuration file path.
        /// </summary>
        /// <returns>Absolute path to the user config file.</returns>
        public static string GetDefaultUserConfigPath()
        {
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            return Path.Combine(appData, "ScriptLauncher", ConfigFileName);
        }

        /// <summary>
        /// Gets the fallback global configuration file path under the application base directory.
        /// </summary>
        /// <returns>Absolute path to the global config file.</returns>
        public static string GetFallbackAppConfigPath()
        {
            // Hardened global config path under ProgramData to persist across builds and deployments
            string programData = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
            return Path.Combine(programData, "ScriptLauncher", "global.json");
        }

        /// <summary>
        /// Loads the configuration from the bound path, falling back to defaults if not present or invalid.
        /// When no file exists, writes and returns a default configuration.
        /// </summary>
        /// <returns>Loaded configuration.</returns>
        public AppConfig Load()
        {
            try
            {
                string? pathToUse = ResolveExistingPath();
                if (pathToUse == null)
                {
                    var defaultConfig = GetDefaultConfig();
                    Save(defaultConfig);
                    return defaultConfig;
                }

                string json = File.ReadAllText(pathToUse);
                var cfg = JsonSerializer.Deserialize<AppConfig>(json) ?? new AppConfig();
                return cfg;
            }
            catch
            {
                return GetDefaultConfig();
            }
        }

        /// <summary>
        /// Saves the configuration to the bound path, creating the directory if needed.
        /// </summary>
        /// <param name="config">Configuration to persist.</param>
        public void Save(AppConfig config)
        {
            string dir = Path.GetDirectoryName(ConfigPath)!;
            Directory.CreateDirectory(dir);
            string json = JsonSerializer.Serialize(config, JsonOptions);
            File.WriteAllText(ConfigPath, json);
        }

        private string? ResolveExistingPath()
        {
            if (File.Exists(ConfigPath))
            {
                return ConfigPath;
            }

            if (_allowFallbackToGlobal)
            {
                string fallback = GetFallbackAppConfigPath();
                return File.Exists(fallback) ? fallback : null;
            }
            return null;
        }

        private static AppConfig GetDefaultConfig()
        {
            return new AppConfig
            {
                Categories =
                {
                    new Category{ Name = "General", DefaultSort = SortOrder.AtoZ },
                    new Category{ Name = "AD", DefaultSort = SortOrder.AtoZ },
                    new Category{ Name = "E365", DefaultSort = SortOrder.AtoZ },
                    new Category{ Name = "Intune", DefaultSort = SortOrder.AtoZ }
                },
                Scripts = []
            };
        }
    }
}
