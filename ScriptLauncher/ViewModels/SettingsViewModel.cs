using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Data;
using ScriptLauncher.Models;
using ScriptLauncher.Services;

namespace ScriptLauncher.ViewModels
{
    /// <summary>
    /// View-model for the Settings window. Manages Categories and Scripts across User/Global scopes,
    /// enforces strict scope-filtered category selection for scripts, exposes commands for add/update/delete,
    /// and provides diagnostics counts and views for the UI (including a grouped Script tree).
    /// </summary>
    public class SettingsViewModel : INotifyPropertyChanged
    {
        /// <summary>
        /// All configured categories (both scopes), always maintained in alphabetical order.
        /// </summary>
        public ObservableCollection<Category> Categories { get; } = [];

        /// <summary>
        /// All configured scripts (both scopes).
        /// </summary>
        public ObservableCollection<ScriptItem> Scripts { get; } = [];

        /// <summary>
        /// View over Scripts, filtered by <see cref="ScriptsScopeFilterIndex"/> and sorted by Category then DisplayName.
        /// </summary>
        public ICollectionView ScriptsView { get; }

        /// <summary>
        /// View over Categories, filtered by <see cref="CategoriesScopeFilterIndex"/> for the Categories tab.
        /// </summary>
        public ICollectionView? CategoriesView { get; }

        /// <summary>
        /// Raw categories filtered by the current script scope; used to derive <see cref="CategoryNameOptions"/>.
        /// </summary>
        public ICollectionView CategoriesForScriptView { get; }

        /// <summary>
        /// Category name options for the script Category dropdown (includes the sentinel value "Unassigned").
        /// </summary>
        public ObservableCollection<string> CategoryNameOptions { get; } = [];

        /// <summary>
        /// Node used by the Scripts tree, grouping scripts by Category and Scope.
        /// </summary>
        public class CategoryNode
        {
            /// <summary>
            /// Category name (or "Unassigned").
            /// </summary>
            public string Name { get; set; } = string.Empty;

            /// <summary>
            /// Scope of the grouped scripts (User or Global).
            /// </summary>
            public ConfigScope Scope { get; set; } = ConfigScope.User;

            /// <summary>
            /// Scripts contained in this group.
            /// </summary>
            public ObservableCollection<ScriptItem> Scripts { get; } = [];

            /// <summary>
            /// Convenience header used by the UI tree.
            /// </summary>
            public string Header => $"{Name} ({(Scope == ConfigScope.Global ? "Global" : "User")})";
        }

        /// <summary>
        /// Tree model of scripts grouped by category and scope for the Scripts tab.
        /// </summary>
        public ObservableCollection<CategoryNode> ScriptTree { get; } = [];

        // Diagnostics summary for visible counts
        /// <summary>
        /// Count of User-scope categories (diagnostics line in UI).
        /// </summary>
        public int UserCategoryCount { get; private set { field = value; OnPropertyChanged(); } }

        /// <summary>
        /// Count of Global-scope categories (diagnostics line in UI).
        /// </summary>
        public int GlobalCategoryCount { get; private set { field = value; OnPropertyChanged(); } }

        /// <summary>
        /// Count of User-scope scripts (diagnostics line in UI).
        /// </summary>
        public int UserScriptCount { get; private set { field = value; OnPropertyChanged(); } }

        /// <summary>
        /// Count of Global-scope scripts (diagnostics line in UI).
        /// </summary>
        public int GlobalScriptCount { get; private set { field = value; OnPropertyChanged(); } }

        // Mode flags to gate Add vs Update availability
        /// <summary>
        /// Indicates the UI is in Add Category mode.
        /// </summary>
        public bool IsAddingCategoryMode { get; set; }

        /// <summary>
        /// Indicates the UI is in Add Script mode.
        /// </summary>
        public bool IsAddingScriptMode { get; set; }

        /// <summary>
        /// Currently selected category (Categories tab). Setting this syncs the edit buffers.
        /// </summary>
        public Category? SelectedCategory
        {
            get;
            set { field = value; IsAddingCategoryMode = false; OnPropertyChanged(); SyncCategoryFields(); }
        }

        /// <summary>
        /// Currently selected script. Setting this syncs the edit buffers and scope/category selection.
        /// </summary>
        public ScriptItem? SelectedScript
        {
            get;
            set { field = value; IsAddingScriptMode = false; OnPropertyChanged(); SyncScriptFields(); }
        }

        // Editable fields
        /// <summary>
        /// Editable category display name buffer.
        /// </summary>
        public string CategoryName { get; set { field = value; OnPropertyChanged(); } } = string.Empty;

        /// <summary>
        /// Sort index for category default sort (0 = A→Z, 1 = Z→A).
        /// </summary>
        public int CategorySortIndex { get; set { field = value; OnPropertyChanged(); } }

        /// <summary>
        /// Target scope for the category being edited (0 = User, 1 = Global).
        /// </summary>
        public int CategoryScopeIndex { get; set { field = value; OnPropertyChanged(); } }

        /// <summary>
        /// Editable script display name buffer.
        /// </summary>
        public string ScriptName { get; set { field = value; OnPropertyChanged(); } } = string.Empty;

        /// <summary>
        /// Selected category name for the script editor ("Unassigned" allowed).
        /// </summary>
        public string ScriptCategoryName { get; set { field = value; OnPropertyChanged(); } } = string.Empty;

        /// <summary>
        /// File path to the script.
        /// </summary>
        public string ScriptPath { get; set { field = value; OnPropertyChanged(); } } = string.Empty;

        /// <summary>
        /// Whether the script requires elevation to run.
        /// </summary>
        public bool ScriptRequiresAdmin { get; set { field = value; OnPropertyChanged(); } }

        /// <summary>
        /// Target scope for the script being edited (0 = User, 1 = Global). Changing this refreshes category options
        /// and resets the selected category to "Unassigned" to avoid cross-scope leakage.
        /// </summary>
        public int ScriptScopeIndex { get; set { field = value; OnPropertyChanged(); CategoriesForScriptView?.Refresh(); RebuildCategoryNameOptions(); ScriptCategoryName = "Unassigned"; } }

        /// <summary>
        /// PowerShell version selector (0 = PS7 default, 1 = PS5).
        /// </summary>
        public int ScriptPowerIndex { get; set { field = value; OnPropertyChanged(); } }

        /// <summary>
        /// Scripts tree/list scope filter (0 = Both, 1 = User, 2 = Global).
        /// </summary>
        public int ScriptsScopeFilterIndex { get; set { field = value; OnPropertyChanged(); ScriptsView.Refresh(); RebuildScriptTree(); } }

        /// <summary>
        /// Categories tab scope filter (0 = Both, 1 = User, 2 = Global).
        /// </summary>
        public int CategoriesScopeFilterIndex { get; set { field = value; OnPropertyChanged(); CategoriesView?.Refresh(); } }

        /// <summary>
        /// Command to add a new category.
        /// </summary>
        public RelayCommand AddCategoryCommand { get; }

        /// <summary>
        /// Command to update the selected category.
        /// </summary>
        public RelayCommand UpdateCategoryCommand { get; }

        /// <summary>
        /// Command to add a new script.
        /// </summary>
        public RelayCommand AddScriptCommand { get; }

        /// <summary>
        /// Command to update the selected script.
        /// </summary>
        public RelayCommand UpdateScriptCommand { get; }

        /// <summary>
        /// Command to delete the selected script.
        /// </summary>
        public RelayCommand DeleteScriptCommand { get; }

        /// <summary>
        /// Creates a new settings view-model from the provided configuration, initialising views, counts, and diagnostics.
        /// </summary>
        public SettingsViewModel(AppConfig cfg)
        {
            // Load preferences
            var settings = SettingsService.Load();
            PrefAutoRefreshMinutes = settings.AutoRefreshMinutes;
            PrefShowBadgeNotification = settings.ShowBadgeNotification;
            PrefShowToastNotification = settings.ShowToastNotification;

            foreach (Category c in cfg.Categories.OrderBy(c => c.Name))
            {
                Categories.Add(new Category { Name = c.Name, DefaultSort = c.DefaultSort, Scope = c.Scope });
            }
            foreach (ScriptItem s in cfg.Scripts.OrderBy(s => s.Category).ThenBy(s => s.DisplayName))
            {
                Scripts.Add(new ScriptItem { DisplayName = s.DisplayName, Category = s.Category, FilePath = s.FilePath, RequiresAdmin = s.RequiresAdmin, Scope = s.Scope, PowerShellVersion = s.PowerShellVersion });
            }
            ResortCategories();
            // Update counts and listen for changes in Categories
            UpdateCategoryCounts();
            Categories.CollectionChanged += (_, __) => UpdateCategoryCounts();
            Categories.CollectionChanged += (_, __) => { UpdateCategoryCounts(); CategoriesView?.Refresh(); };
            UpdateScriptCounts();
            Scripts.CollectionChanged += (_, __) => UpdateScriptCounts();
            Scripts.CollectionChanged += (_, __) => { UpdateScriptCounts(); RebuildScriptTree(); };

            ScriptsView = CollectionViewSource.GetDefaultView(Scripts);
            ScriptsView.Filter = o => o is ScriptItem si && (ScriptsScopeFilterIndex switch
            {
                1 => si.Scope == ConfigScope.User,
                2 => si.Scope == ConfigScope.Global,
                _ => true
            });
            ScriptsView.SortDescriptions.Add(new SortDescription(nameof(ScriptItem.Category), ListSortDirection.Ascending));
            ScriptsView.SortDescriptions.Add(new SortDescription(nameof(ScriptItem.DisplayName), ListSortDirection.Ascending));

            CategoriesView = CollectionViewSource.GetDefaultView(Categories);
            CategoriesView?.Filter = o => o is Category c && (CategoriesScopeFilterIndex switch
            {
                1 => c.Scope == ConfigScope.User,
                2 => c.Scope == ConfigScope.Global,
                _ => true
            });

            CategoriesForScriptView = CollectionViewSource.GetDefaultView(Categories);
            CategoriesForScriptView.Filter = o => o is Category c && c.Scope == (ScriptScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User);

            // Build initial category name options for the current scope (with 'Unassigned' first)
            RebuildCategoryNameOptions();
            RebuildScriptTree();

            // Diagnostics: log initial counts by scope
            int userCats = Categories.Count(c => c.Scope == ConfigScope.User);
            int globCats = Categories.Count(c => c.Scope == ConfigScope.Global);
            int userScr = Scripts.Count(s => s.Scope == ConfigScope.User);
            int globScr = Scripts.Count(s => s.Scope == ConfigScope.Global);
            TraceService.SafeLog("SettingsVM.Init", new Dictionary<string, object?>
            {
                ["UserCategories"] = userCats,
                ["GlobalCategories"] = globCats,
                ["UserScripts"] = userScr,
                ["GlobalScripts"] = globScr
            });

            LogScopeDiagnostics("Init");

            AddCategoryCommand = new RelayCommand(
                () =>
                {
                    SortOrder sort = CategorySortIndex == 1 ? SortOrder.ZtoA : SortOrder.AtoZ;
                    ConfigScope scope = CategoryScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    Categories.Add(new Category { Name = CategoryName, DefaultSort = sort, Scope = scope });
                    ResortCategories();
                    // reset fields
                    CategoryName = string.Empty; CategorySortIndex = 0; CategoryScopeIndex = 0;
                },
                () =>
                {
                    if (!IsAddingCategoryMode)
                    {
                        return false;
                    }
                    if (string.IsNullOrWhiteSpace(CategoryName))
                    {
                        return false;
                    }
                    ConfigScope scope = CategoryScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    // Allow duplicates across scopes; disallow within the same scope
                    return !Categories.Any(c => c.Name == CategoryName && c.Scope == scope);
                }
            );

            UpdateCategoryCommand = new RelayCommand(
                () =>
                {
                    Category? selected = SelectedCategory;
                    if (selected == null)
                    {
                        return;
                    }
                    string oldName = selected.Name;
                    ConfigScope oldScope = selected.Scope;
                    selected.Name = CategoryName;
                    selected.DefaultSort = CategorySortIndex == 1 ? SortOrder.ZtoA : SortOrder.AtoZ;
                    selected.Scope = CategoryScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    foreach (ScriptItem s in Scripts.Where(s => s.Category == oldName && s.Scope == oldScope))
                    {
                        s.Category = CategoryName;
                    }
                    // After update, resort and re-select the edited category to sync buffers
                    ResortCategories();
                    ConfigScope targetScope = CategoryScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    Category? match = Categories.FirstOrDefault(c => c.Name == CategoryName && c.Scope == targetScope);
                    if (match != null)
                    {
                        SelectedCategory = match;
                    }
                    RebuildCategoryNameOptions();
                },
                () =>
                {
                    if (IsAddingCategoryMode)
                    {
                        return false;
                    }
                    Category? selected = SelectedCategory;
                    if (selected == null || string.IsNullOrWhiteSpace(CategoryName))
                    {
                        return false;
                    }
                    ConfigScope targetScope = CategoryScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    // Allow rename to the same name within the same scope; block only if another category with same name exists within target scope
                    bool isSame = CategoryName == selected.Name && targetScope == selected.Scope;
                    bool duplicateInScope = Categories.Any(c => c != selected && c.Name == CategoryName && c.Scope == targetScope);
                    return isSame || !duplicateInScope;
                }
            );

            AddScriptCommand = new RelayCommand(
                () =>
                {
                    ConfigScope scope = ScriptScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    // Map UI 'Unassigned' to persisted empty string
                    string catPersist = string.Equals(ScriptCategoryName, "Unassigned", StringComparison.OrdinalIgnoreCase) ? string.Empty : ScriptCategoryName;
                    Scripts.Add(new ScriptItem { DisplayName = ScriptName, Category = catPersist, FilePath = ScriptPath, RequiresAdmin = ScriptRequiresAdmin, Scope = scope, PowerShellVersion = ScriptPowerIndex == 1 ? 5 : 7 });
                    // reset fields
                    ScriptName = string.Empty; ScriptCategoryName = "Unassigned"; ScriptPath = string.Empty; ScriptRequiresAdmin = false; ScriptScopeIndex = 0; ScriptPowerIndex = 0;
                },
                () =>
                {
                    if (!IsAddingScriptMode)
                    {
                        return false;
                    }
                    if (string.IsNullOrWhiteSpace(ScriptName) || string.IsNullOrWhiteSpace(ScriptCategoryName) || string.IsNullOrWhiteSpace(ScriptPath))
                    {
                        return false;
                    }
                    ConfigScope scope = ScriptScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    // Disallow duplicates within the same scope only
                    return !Scripts.Any(s => s.DisplayName == ScriptName && s.Category == ScriptCategoryName && s.Scope == scope);
                }
            );

            UpdateScriptCommand = new RelayCommand(
                () =>
                {
                    ScriptItem? selected = SelectedScript;
                    if (selected == null)
                    {
                        return;
                    }
                    selected.DisplayName = ScriptName;
                    selected.Category = string.Equals(ScriptCategoryName, "Unassigned", StringComparison.OrdinalIgnoreCase) ? string.Empty : ScriptCategoryName;
                    selected.FilePath = ScriptPath;
                    selected.RequiresAdmin = ScriptRequiresAdmin;
                    selected.Scope = ScriptScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    selected.PowerShellVersion = ScriptPowerIndex == 1 ? 5 : 7;
                    // Ensure list refresh reflects updated values when ScriptItem doesn't notify
                    ScriptsView.Refresh();
                    // Clear buffers to avoid false pending state
                    ScriptName = selected.DisplayName;
                    ScriptCategoryName = string.IsNullOrEmpty(selected.Category) ? "Unassigned" : selected.Category;
                    ScriptPath = selected.FilePath;
                    ScriptRequiresAdmin = selected.RequiresAdmin;
                },
                () =>
                {
                    if (IsAddingScriptMode)
                    {
                        return false;
                    }
                    ScriptItem? selected = SelectedScript;
                    if (selected == null)
                    {
                        return false;
                    }
                    if (string.IsNullOrWhiteSpace(ScriptName) || string.IsNullOrWhiteSpace(ScriptCategoryName) || string.IsNullOrWhiteSpace(ScriptPath))
                    {
                        return false;
                    }
                    ConfigScope targetScope = ScriptScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
                    // Allow updating to same values; block only if another script in the target scope has same Category+DisplayName
                    bool isSame = ScriptName == selected.DisplayName && ScriptCategoryName == selected.Category && targetScope == selected.Scope;
                    bool duplicateInScope = Scripts.Any(s => s != selected && s.DisplayName == ScriptName && s.Category == ScriptCategoryName && s.Scope == targetScope);
                    return isSame || !duplicateInScope;
                }
            );

            DeleteScriptCommand = new RelayCommand(
                () =>
                {
                    ScriptItem? selected = SelectedScript;
                    if (selected == null)
                    {
                        return;
                    }
                    _ = Scripts.Remove(selected);
                },
                () => SelectedScript != null
            );
        }

        // Preferences properties (File > Settings > Preferences tab)
        public int PrefAutoRefreshMinutes { get; set { field = value; OnPropertyChanged(); } } = 15;

        public bool PrefShowBadgeNotification { get; set { field = value; OnPropertyChanged(); } } = true;

        public bool PrefShowToastNotification { get; set { field = value; OnPropertyChanged(); } } = true;

        /// <summary>
        /// Indicates whether the Preferences buffers differ from the saved settings.
        /// </summary>
        public bool HasPendingPreferences()
        {
            var current = SettingsService.Load();
            return current.AutoRefreshMinutes != PrefAutoRefreshMinutes
                || current.ShowBadgeNotification != PrefShowBadgeNotification
                || current.ShowToastNotification != PrefShowToastNotification;
        }

        /// <summary>
        /// Persists the current Preferences buffers to the settings store.
        /// </summary>
        public void SavePreferences()
        {
            var current = SettingsService.Load();
            current.AutoRefreshMinutes = PrefAutoRefreshMinutes;
            current.ShowBadgeNotification = PrefShowBadgeNotification;
            current.ShowToastNotification = PrefShowToastNotification;
            SettingsService.Save(current);
        }

        /// <summary>
        /// Produces an <see cref="AppConfig"/> snapshot from the current collections suitable for save/export.
        /// </summary>
        public AppConfig ToResultConfig()
        {
            return new AppConfig
            {
                Categories = [.. Categories.OrderBy(c => c.Name)],
                Scripts = [.. Scripts.Select(s => new ScriptItem
                {
                    DisplayName = s.DisplayName,
                    Category = string.Equals(s.Category, "Unassigned", StringComparison.OrdinalIgnoreCase) ? string.Empty : s.Category,
                    FilePath = s.FilePath,
                    RequiresAdmin = s.RequiresAdmin,
                    Scope = s.Scope,
                    PowerShellVersion = s.PowerShellVersion
                })]
            };
        }

        /// <summary>
        /// Attempts to delete a category. If scripts are assigned and a reassignment target is provided, reassigns them first.
        /// </summary>
        /// <param name="categoryName">The category name to delete.</param>
        /// <param name="scope">The scope of the category.</param>
        /// <param name="reassignTarget">Optional target category name within the same scope.</param>
        public void TryDeleteCategory(string categoryName, ConfigScope scope, string? reassignTarget)
        {
            Category? cat = Categories.FirstOrDefault(c => c.Name == categoryName && c.Scope == scope);
            if (cat == null)
            {
                return;
            }
            List<ScriptItem> assigned = [.. Scripts.Where(s => s.Category == categoryName && s.Scope == scope)];
            if (assigned.Count > 0 && !string.IsNullOrEmpty(reassignTarget))
            {
                foreach (ScriptItem s in assigned)
                {
                    s.Category = reassignTarget;
                }
            }
            _ = Categories.Remove(cat);
            ResortCategories();
        }

        private void RefreshCommandStates()
        {
            // Guard commands which may not yet be initialised during constructor
            AddCategoryCommand?.RaiseCanExecuteChanged();
            UpdateCategoryCommand?.RaiseCanExecuteChanged();
            AddScriptCommand?.RaiseCanExecuteChanged();
            UpdateScriptCommand?.RaiseCanExecuteChanged();
            DeleteScriptCommand?.RaiseCanExecuteChanged();
        }

        private void SyncCategoryFields()
        {
            if (SelectedCategory == null)
            {
                return;
            }
            CategoryName = SelectedCategory.Name;
            CategorySortIndex = SelectedCategory.DefaultSort == SortOrder.AtoZ ? 0 : 1;
            CategoryScopeIndex = SelectedCategory.Scope == ConfigScope.Global ? 1 : 0;
            RefreshCommandStates();
        }

        private void SyncScriptFields()
        {
            if (SelectedScript == null)
            {
                return;
            }
            ScriptName = SelectedScript.DisplayName;
            ScriptPath = SelectedScript.FilePath;
            ScriptRequiresAdmin = SelectedScript.RequiresAdmin;
            // Set scope first so options are rebuilt for correct scope before selecting category
            ScriptScopeIndex = SelectedScript.Scope == ConfigScope.Global ? 1 : 0;
            // Map empty string to 'Unassigned' for UI selection to avoid blank dropdown
            ScriptCategoryName = string.IsNullOrWhiteSpace(SelectedScript.Category) ? "Unassigned" : SelectedScript.Category;
            ScriptPowerIndex = SelectedScript.PowerShellVersion == 5 ? 1 : 0; // default to 7 (index 0) when not 5
            RefreshCommandStates();
        }

        /// <summary>
        /// Property change notification event for bindings.
        /// </summary>
        public event PropertyChangedEventHandler? PropertyChanged;
        private void OnPropertyChanged([CallerMemberName] string? name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
            if (name is (nameof(CategoryName)) or (nameof(CategorySortIndex)) or (nameof(CategoryScopeIndex)) or
                (nameof(ScriptName)) or (nameof(ScriptCategoryName)) or
                (nameof(ScriptPath)) or (nameof(ScriptRequiresAdmin)) or (nameof(ScriptScopeIndex)) or (nameof(ScriptPowerIndex)))
            {
                RefreshCommandStates();
            }
        }

        private void ResortCategories()
        {
            // Preserve current selection across resort to keep buffers in sync
            string? selName = SelectedCategory?.Name;
            ConfigScope? selScope = SelectedCategory?.Scope;

            List<Category> sorted = [.. Categories.OrderBy(c => c.Name).ThenBy(c => c.Scope)];
            Categories.Clear();
            foreach (Category c in sorted)
            {
                Categories.Add(c);
            }

            if (!string.IsNullOrEmpty(selName) && selScope != null)
            {
                Category? match = Categories.FirstOrDefault(x => x.Name == selName && x.Scope == selScope);
                if (match != null)
                {
                    SelectedCategory = match; // triggers SyncCategoryFields
                }
            }
            CategoriesForScriptView?.Refresh();
            CategoriesView?.Refresh();
            RebuildCategoryNameOptions();
            RefreshCommandStates();
            UpdateCategoryCounts();
        }

        // Removed synthesis of categories from scripts to keep Categories authoritative to config

        private void RebuildCategoryNameOptions()
        {
            ConfigScope scope = ScriptScopeIndex == 1 ? ConfigScope.Global : ConfigScope.User;
            // Strictly use Categories of the current scope so the dropdown never shows cross-scope names
            List<string> names = [.. Categories
                .Where(c => c.Scope == scope)
                .Select(c => c.Name)
                .Distinct()
                .OrderBy(n => n)];
            CategoryNameOptions.Clear();
            CategoryNameOptions.Add("Unassigned");
            foreach (string n in names)
            {
                CategoryNameOptions.Add(n);
            }
            LogScopeDiagnostics("RebuildCategoryNameOptions");
        }

        private void RebuildScriptTree()
        {
            ScriptTree.Clear();
            IEnumerable<ScriptItem> items = Scripts;
            if (ScriptsScopeFilterIndex == 1)
            {
                items = items.Where(s => s.Scope == ConfigScope.User);
            }
            else if (ScriptsScopeFilterIndex == 2)
            {
                items = items.Where(s => s.Scope == ConfigScope.Global);
            }

            var groups = items
                .Select(s => new { Key = new { s.Scope, Cat = string.IsNullOrWhiteSpace(s.Category) ? "Unassigned" : s.Category }, Script = s })
                .GroupBy(x => x.Key)
                .OrderBy(g => g.Key.Cat)
                .ThenBy(g => g.Key.Scope);

            foreach (var g in groups)
            {
                CategoryNode node = new() { Name = g.Key.Cat, Scope = g.Key.Scope };
                foreach (ScriptItem s in g.Select(x => x.Script).OrderBy(s => s.DisplayName))
                {
                    node.Scripts.Add(s);
                }
                ScriptTree.Add(node);
            }
        }

        private void LogScopeDiagnostics(string stage)
        {
            try
            {
                int userCats = Categories.Count(c => c.Scope == ConfigScope.User);
                int globCats = Categories.Count(c => c.Scope == ConfigScope.Global);
                List<string> userNames = [.. Categories.Where(c => c.Scope == ConfigScope.User).Select(c => c.Name).Distinct().OrderBy(n => n)];
                List<string> globNames = [.. Categories.Where(c => c.Scope == ConfigScope.Global).Select(c => c.Name).Distinct().OrderBy(n => n)];
                List<string> userPairs = [.. Categories.Where(c => c.Scope == ConfigScope.User).OrderBy(c => c.Name).Select(c => $"{c.Name} (User)").Take(20)];
                List<string> globPairs = [.. Categories.Where(c => c.Scope == ConfigScope.Global).OrderBy(c => c.Name).Select(c => $"{c.Name} (Global)").Take(20)];
                List<string> opts = [.. CategoryNameOptions];
                TraceService.SafeLog($"SettingsVM.ScopeDiag.{stage}", new Dictionary<string, object?>
                {
                    ["ScriptScopeIndex"] = ScriptScopeIndex,
                    ["UserCategories"] = userCats,
                    ["GlobalCategories"] = globCats,
                    ["UserNames"] = string.Join(", ", userNames),
                    ["GlobalNames"] = string.Join(", ", globNames),
                    ["DropdownOptions"] = string.Join(", ", opts),
                    ["UserPairsSample"] = string.Join(", ", userPairs),
                    ["GlobalPairsSample"] = string.Join(", ", globPairs)
                });
            }
            catch { }
        }

        private void UpdateCategoryCounts()
        {
            UserCategoryCount = Categories.Count(c => c.Scope == ConfigScope.User);
            GlobalCategoryCount = Categories.Count(c => c.Scope == ConfigScope.Global);
        }

        private void UpdateScriptCounts()
        {
            UserScriptCount = Scripts.Count(s => s.Scope == ConfigScope.User);
            GlobalScriptCount = Scripts.Count(s => s.Scope == ConfigScope.Global);
        }

        /// <summary>
        /// Helper used by SettingsWindow unsaved-checks to normalise category comparison.
        /// Maps "Unassigned" to an empty string to match persisted storage.
        /// </summary>
        /// <param name="value">Category name from the UI.</param>
        /// <returns>Normalised category name for comparison/storage.</returns>
        public static string NormaliseCategoryForComparison(string value)
        {
            return string.Equals(value, "Unassigned", StringComparison.OrdinalIgnoreCase) ? string.Empty : value;
        }
    }
}