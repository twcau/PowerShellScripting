using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using ScriptLauncher.Models;
using ScriptLauncher.Services;

namespace ScriptLauncher.ViewModels
{
    public class MainViewModel : INotifyPropertyChanged
    {
        private static readonly System.Text.Json.JsonSerializerOptions JsonOptions = new() { WriteIndented = true };
        private readonly CompositeConfigService _configService;
        private AppConfig _config = new();

        public ObservableCollection<CategoryDisplay> Categories { get; } = [];
        public ObservableCollection<ScriptItem> Scripts { get; } = [];

        public CategoryDisplay? SelectedCategory
        {
            get;
            set
            {
                field = value;
                TraceService.SafeLog("SelectedCategoryChanged", field == null ? "null" : $"{field.Name} ({field.Availability})");
                OnPropertyChanged();
                UpdateScopeVisibilityForSelectedCategory();
                RefreshScripts();
            }
        }

        public int SortIndex
        {
            get;
            set { field = value; OnPropertyChanged(); RefreshScripts(); }
        }

        public int ScopeFilterIndex
        {
            get;
            set { field = value; OnPropertyChanged(); RefreshScripts(); }
        }

        public bool SelectedCategoryHasBothScopes
        {
            get;
            set { field = value; OnPropertyChanged(); }
        } = true;

        public ScriptItem? SelectedScriptItem
        {
            get;
            set { field = value; OnPropertyChanged(); }
        }

        public RelayCommand RunSelectedCommand { get; }
        public RelayCommand SetDefaultSortCommand { get; }

        public int ScopeCategoryFilterIndex
        {
            get;
            set { field = value; OnPropertyChanged(); RefreshCategories(); }
        }

        public string StatusText { get; private set { field = value; OnPropertyChanged(); } } = string.Empty;

        public bool ReloadHadChanges { get; private set { field = value; OnPropertyChanged(); } }

        public MainViewModel(string userConfigPath, string? globalConfigPath)
        {
            _configService = new CompositeConfigService(userConfigPath, globalConfigPath);
            RunSelectedCommand = new RelayCommand(() =>
            {
                if (SelectedScriptItem == null)
                {
                    MessageBox.Show("Please select a script.", "No Selection", MessageBoxButton.OK, MessageBoxImage.Information);
                    return;
                }
                var result = ProcessRunner.Run(SelectedScriptItem);
                if (result == RunResult.FailedToStart)
                {
                    MessageBox.Show("Failed to start the script.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            });

            SetDefaultSortCommand = new RelayCommand(() =>
            {
                if (SelectedCategory == null)
                {
                    return;
                }

                var pickScope = SelectedCategory.Availability == ScopeAvailability.Both ? ConfigScope.User : (SelectedCategory.Availability == ScopeAvailability.Global ? ConfigScope.Global : ConfigScope.User);
                var cat = _config.Categories.FirstOrDefault(c => c.Name == SelectedCategory.Name && c.Scope == pickScope);
                if (cat == null)
                {
                    return;
                }

                cat.DefaultSort = SortIndex == 0 ? SortOrder.AtoZ : SortOrder.ZtoA;
                LoadConfigAndDetectChanges(false);
            });
            // Initial load
            LoadConfig();
        }

        private static bool HasDiff(AppConfig? a, AppConfig b)
        {
            if (a == null)
            {
                return true;
            }

            var aCats = a.Categories.Select(c => $"{c.Scope}:{c.Name}:{c.DefaultSort}").OrderBy(x => x);
            var bCats = b.Categories.Select(c => $"{c.Scope}:{c.Name}:{c.DefaultSort}").OrderBy(x => x);
            if (!aCats.SequenceEqual(bCats))
            {
                return true;
            }

            static string Key(ScriptItem s)
            {
                return $"{s.Scope}:{s.Category}|{s.DisplayName}|{s.FilePath}|{s.RequiresAdmin}|{s.PowerShellVersion}";
            }

            var aScr = a.Scripts.Select(Key).OrderBy(x => x);
            var bScr = b.Scripts.Select(Key).OrderBy(x => x);
            return !aScr.SequenceEqual(bScr);
        }

        public bool LoadConfigAndDetectChanges(bool userInitiated)
        {
            var previous = _config;
            var merged = _configService.LoadMerged();
            bool changed = HasDiff(previous, merged);
            _config = merged;
            RefreshCategories();
            StatusText = $"Config reloaded at {DateTime.Now:HH:mm:ss}{(changed ? " — changes detected" : " — no changes")}";
            ReloadHadChanges = changed;
            return changed;
        }

        public void LoadConfig()
        {
            _config = _configService.LoadMerged();
            RefreshCategories();
            StatusText = $"Config loaded at {DateTime.Now:HH:mm:ss}";
            ReloadHadChanges = false;
        }

        public void SaveConfig()
        {
            _configService.Save(_config);
        }

        public AppConfig GetCurrentConfig()
        {
            return _config;
        }

        public void ReplaceAndSave(AppConfig newConfig)
        {
            _config = newConfig;
            SaveConfig();
        }

        private void RefreshScripts()
        {
            Scripts.Clear();
            if (SelectedCategory == null)
            {
                return;
            }

            IEnumerable<ScriptItem> items = SelectedCategory.Name == "Unassigned"
                ? _config.Scripts.Where(s => string.IsNullOrWhiteSpace(s.Category))
                : _config.Scripts.Where(s => s.Category == SelectedCategory.Name);
            // Apply scope filter
            if (ScopeFilterIndex == 1) // User
            {
                items = items.Where(s => s.Scope == ConfigScope.User);
            }
            else if (ScopeFilterIndex == 2) // Global
            {
                items = items.Where(s => s.Scope == ConfigScope.Global);
            }

            items = SortIndex == 0 ? items.OrderBy(s => s.DisplayName) : items.OrderByDescending(s => s.DisplayName);

            foreach (var s in items)
            {
                Scripts.Add(s);
            }

            TraceService.SafeLog("RefreshScripts",
                $"Category={SelectedCategory.Name}; ScopeFilterIndex={ScopeFilterIndex}; Total={Scripts.Count}; Users={Scripts.Count(x => x.Scope == ConfigScope.User)}; Globals={Scripts.Count(x => x.Scope == ConfigScope.Global)}");
        }

        private void RefreshCategories()
        {
            Categories.Clear();
            // Build category availability from both defined categories and actual scripts,
            // strictly based on actual scripts. Categories with zero scripts assigned are hidden.
            List<string> categoryNames = _config.Scripts
                .Where(s => !string.IsNullOrWhiteSpace(s.Category))
                .Select(s => s.Category)
                .Distinct()
                .OrderBy(n => n)
                .ToList();

            foreach (string? name in categoryNames)
            {
                // Determine availability only from scripts to avoid showing empty categories
                bool hasUser = _config.Scripts.Any(s => s.Category == name && s.Scope == ConfigScope.User);
                bool hasGlobal = _config.Scripts.Any(s => s.Category == name && s.Scope == ConfigScope.Global);

                // Apply category scope filter
                if (ScopeCategoryFilterIndex == 1 && !hasUser)
                {
                    continue; // User only filter
                }

                if (ScopeCategoryFilterIndex == 2 && !hasGlobal)
                {
                    continue; // Global only filter
                }

                var availability = (hasUser && hasGlobal)
                    ? ScopeAvailability.Both
                    : (hasGlobal ? ScopeAvailability.Global : ScopeAvailability.User);

                Categories.Add(new CategoryDisplay { Name = name, Availability = availability });
            }

            // Add synthetic Unassigned category if any scripts lack a category
            bool hasUnassigned = _config.Scripts.Any(s => string.IsNullOrWhiteSpace(s.Category));
            if (hasUnassigned)
            {
                Categories.Add(new CategoryDisplay { Name = "Unassigned", Availability = ScopeAvailability.Both });
            }

            if (Categories.Count > 0)
            {
                // Ensure selection is valid within filtered set
                if (SelectedCategory == null || !Categories.Any(c => c.Name == SelectedCategory.Name))
                {
                    SelectedCategory = Categories.First();
                }
                // Set sort index from selected category default
                var pickScope = SelectedCategory.Availability == ScopeAvailability.Both ? ConfigScope.User : (SelectedCategory.Availability == ScopeAvailability.Global ? ConfigScope.Global : ConfigScope.User);
                var cat = _config.Categories.FirstOrDefault(c => c.Name == SelectedCategory.Name && c.Scope == pickScope);
                var def = cat?.DefaultSort ?? SortOrder.AtoZ;
                SortIndex = def == SortOrder.AtoZ ? 0 : 1;
            }
            else
            {
                SelectedCategory = null;
            }
            TraceService.SafeLog("RefreshCategories",
                $"Count={Categories.Count}; Selected={(SelectedCategory == null ? "null" : SelectedCategory.Name)}; FilterIndex={ScopeCategoryFilterIndex}");
        }

        private void UpdateScopeVisibilityForSelectedCategory()
        {
            if (SelectedCategory == null)
            {
                SelectedCategoryHasBothScopes = true;
                return;
            }
            SelectedCategoryHasBothScopes = SelectedCategory.Availability == ScopeAvailability.Both;
            if (!SelectedCategoryHasBothScopes)
            {
                // force scope filter to the available scope
                ScopeFilterIndex = SelectedCategory.Availability == ScopeAvailability.Global ? 2 : 1;
                TraceService.SafeLog("ScopeFilterForced", $"Index={ScopeFilterIndex}; Reason={SelectedCategory.Availability}");
            }
            else
            {
                // Reset to show both when category supports both scopes
                ScopeFilterIndex = 0;
                TraceService.SafeLog("ScopeFilterReset", "Index=0 for Both-scope category");
            }
        }

        public void ImportConfig(string path)
        {
            try
            {
                string json = System.IO.File.ReadAllText(path);
                var cfg = System.Text.Json.JsonSerializer.Deserialize<AppConfig>(json);
                if (cfg == null)
                {
                    return;
                }

                _config = cfg;
                TraceService.SafeLog("ImportConfig", new Dictionary<string, object?>
                {
                    ["Path"] = path,
                    ["Categories"] = _config?.Categories?.Count ?? 0,
                    ["Scripts"] = _config?.Scripts?.Count ?? 0
                });
                SaveConfig();
                LoadConfigAndDetectChanges(true);
            }
            catch { }
        }

        public void ImportConfigWithScope(string path, int scopeOption)
        {
            try
            {
                string json = System.IO.File.ReadAllText(path);
                var incoming = System.Text.Json.JsonSerializer.Deserialize<AppConfig>(json);
                if (incoming == null)
                {
                    return;
                }

                var targetScope = scopeOption == 2 ? ConfigScope.Global : ConfigScope.User;
                foreach (var c in incoming.Categories)
                {
                    var existing = _config.Categories.FirstOrDefault(x => x.Name == c.Name && x.Scope == targetScope);
                    if (existing == null)
                    {
                        _config.Categories.Add(new Category { Name = c.Name, DefaultSort = c.DefaultSort, Scope = targetScope });
                    }
                    else
                    {
                        existing.DefaultSort = c.DefaultSort;
                    }
                }
                foreach (var s in incoming.Scripts)
                {
                    var existing = _config.Scripts.FirstOrDefault(x => x.DisplayName == s.DisplayName && x.Category == s.Category && x.Scope == targetScope);
                    if (existing == null)
                    {
                        _config.Scripts.Add(new ScriptItem { DisplayName = s.DisplayName, Category = s.Category, FilePath = s.FilePath, RequiresAdmin = s.RequiresAdmin, Scope = targetScope });
                    }
                    else
                    {
                        existing.FilePath = s.FilePath;
                        existing.RequiresAdmin = s.RequiresAdmin;
                    }
                }
                // Save and snapshot only the chosen scope
                _configService.Save(_config, saveUser: targetScope == ConfigScope.User, saveGlobal: targetScope == ConfigScope.Global);
                LoadConfig();
            }
            catch { }
        }

        public void ExportConfig(string path)
        {
            try
            {
                string? dir = System.IO.Path.GetDirectoryName(path);
                if (!string.IsNullOrEmpty(dir))
                {
                    System.IO.Directory.CreateDirectory(dir);
                }

                string json = System.Text.Json.JsonSerializer.Serialize(_config, JsonOptions);
                System.IO.File.WriteAllText(path, json);
            }
            catch { }
        }

        public void ExportByScope(string path, int scopeOption)
        {
            try
            {
                string? dir = System.IO.Path.GetDirectoryName(path);
                if (!string.IsNullOrEmpty(dir))
                {
                    System.IO.Directory.CreateDirectory(dir);
                }

                AppConfig toWrite = scopeOption == 1
                    ? new AppConfig
                    {
                        Categories = [.. _config.Categories.Where(c => c.Scope == ConfigScope.User).Select(c => new Category { Name = c.Name, DefaultSort = c.DefaultSort, Scope = ConfigScope.User })],
                        Scripts = [.. _config.Scripts.Where(s => s.Scope == ConfigScope.User).Select(s => new ScriptItem { DisplayName = s.DisplayName, Category = s.Category, FilePath = s.FilePath, RequiresAdmin = s.RequiresAdmin, Scope = ConfigScope.User })]
                    }
                    : scopeOption == 2
                        ? new AppConfig
                        {
                            Categories = [.. _config.Categories.Where(c => c.Scope == ConfigScope.Global).Select(c => new Category { Name = c.Name, DefaultSort = c.DefaultSort, Scope = ConfigScope.Global })],
                            Scripts = [.. _config.Scripts.Where(s => s.Scope == ConfigScope.Global).Select(s => new ScriptItem { DisplayName = s.DisplayName, Category = s.Category, FilePath = s.FilePath, RequiresAdmin = s.RequiresAdmin, Scope = ConfigScope.Global })]
                        }
                        : _config;
                string json = System.Text.Json.JsonSerializer.Serialize(toWrite, JsonOptions);
                System.IO.File.WriteAllText(path, json);
            }
            catch { }
        }

        public event PropertyChangedEventHandler? PropertyChanged;
        private void OnPropertyChanged([CallerMemberName] string? name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }
    }
}