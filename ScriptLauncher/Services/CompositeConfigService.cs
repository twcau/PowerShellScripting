using ScriptLauncher.Models;

namespace ScriptLauncher.Services
{
    /// <summary>
    /// Initializes a composite service for user and global configurations.
    /// </summary>
    /// <param name="userPath">Explicit user config path; defaults inside ConfigService if null/empty.</param>
    /// <param name="globalPath">Explicit global config path; falls back to app base path if null.</param>
    public class CompositeConfigService(string userPath, string? globalPath)
    {
        private readonly ConfigService _userService = new(userPath, allowFallbackToGlobal: false);
        private readonly ConfigService _globalService = new(globalPath ?? ConfigService.GetFallbackAppConfigPath(), allowFallbackToGlobal: true);

        /// <summary>
        /// Loads and merges user and global configurations, annotating each entity with its scope.
        /// </summary>
        /// <returns>Merged configuration containing categories and scripts from both scopes.</returns>
        public AppConfig LoadMerged()
        {
            var user = _userService.Load();
            foreach (var c in user.Categories)
            {
                c.Scope = ConfigScope.User;
            }

            foreach (var s in user.Scripts)
            {
                s.Scope = ConfigScope.User;
            }

            var glob = _globalService.Load();
            foreach (var c in glob.Categories)
            {
                c.Scope = ConfigScope.Global;
            }

            foreach (var s in glob.Scripts)
            {
                s.Scope = ConfigScope.Global;
            }

            return new AppConfig
            {
                Categories = [.. user.Categories, .. glob.Categories],
                Scripts = [.. user.Scripts, .. glob.Scripts]
            };
        }

        /// <summary>
        /// Saves the merged configuration to both user and global scopes, with snapshot retention.
        /// </summary>
        /// <param name="merged">Merged configuration to persist.</param>
        public void Save(AppConfig merged)
        {
            Save(merged, saveUser: true, saveGlobal: true);
        }

        /// <summary>
        /// Saves the merged configuration selectively to user and/or global scopes, taking snapshots before save.
        /// </summary>
        /// <param name="merged">Merged configuration to persist.</param>
        /// <param name="saveUser">Whether to save to the user scope.</param>
        /// <param name="saveGlobal">Whether to save to the global scope.</param>
        public void Save(AppConfig merged, bool saveUser, bool saveGlobal)
        {
            // Project-wide invariant: no duplicate categories within the same scope, sorted alphabetically.
            // Likewise, scripts are de-duplicated by (Scope, Category, DisplayName) and sorted.

            AppConfig user = new()
            {
                Categories = [.. merged.Categories
                    .Where(c => c.Scope == ConfigScope.User)
                    .GroupBy(c => c.Name)
                    .Select(g => new Category { Name = g.Key, DefaultSort = g.Last().DefaultSort, Scope = ConfigScope.User })
                    .OrderBy(c => c.Name)],
                Scripts = [.. merged.Scripts
                    .Where(s => s.Scope == ConfigScope.User)
                    .GroupBy(s => new { s.Category, s.DisplayName })
                    .Select(g =>
                    {
                        var last = g.Last();
                        return new ScriptItem
                        {
                            DisplayName = last.DisplayName,
                            Category = last.Category,
                            FilePath = last.FilePath,
                            RequiresAdmin = last.RequiresAdmin,
                            Scope = ConfigScope.User,
                            PowerShellVersion = last.PowerShellVersion
                        };
                    })
                    .OrderBy(s => s.Category)
                    .ThenBy(s => s.DisplayName)]
            };

            AppConfig glob = new()
            {
                Categories = [.. merged.Categories
                    .Where(c => c.Scope == ConfigScope.Global)
                    .GroupBy(c => c.Name)
                    .Select(g => new Category { Name = g.Key, DefaultSort = g.Last().DefaultSort, Scope = ConfigScope.Global })
                    .OrderBy(c => c.Name)],
                Scripts = [.. merged.Scripts
                    .Where(s => s.Scope == ConfigScope.Global)
                    .GroupBy(s => new { s.Category, s.DisplayName })
                    .Select(g =>
                    {
                        var last = g.Last();
                        return new ScriptItem
                        {
                            DisplayName = last.DisplayName,
                            Category = last.Category,
                            FilePath = last.FilePath,
                            RequiresAdmin = last.RequiresAdmin,
                            Scope = ConfigScope.Global,
                            PowerShellVersion = last.PowerShellVersion
                        };
                    })
                    .OrderBy(s => s.Category)
                    .ThenBy(s => s.DisplayName)]
            };

            // Snapshot before saving with configurable retention for selected scopes only
            int retention = SettingsService.Load().HistoryRetention;
            if (saveUser)
            {
                HistoryService.Snapshot(_userService.ConfigPath, user, ConfigScope.User, retention);
                _userService.Save(user);
            }
            if (saveGlobal)
            {
                HistoryService.Snapshot(_globalService.ConfigPath, glob, ConfigScope.Global, retention);
                _globalService.Save(glob);
            }
        }
    }
}