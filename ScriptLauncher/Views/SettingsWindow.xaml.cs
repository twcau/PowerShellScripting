using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using Microsoft.Win32;
using ScriptLauncher.Models;
using ScriptLauncher.ViewModels;
using ScriptLauncher.Services;

namespace ScriptLauncher.Views
{
    public partial class SettingsWindow : Window
    {
        public AppConfig ResultConfig { get; private set; } = new();
        private readonly SettingsViewModel _vm;
        private bool _suppressClosePrompt;

        public SettingsWindow(AppConfig config)
        {
            InitializeComponent();
            _vm = new SettingsViewModel(config);
            DataContext = _vm;
            try
            {
                // Startup snapshot: counts and a sample of names/options to aid diagnosis
                List<string> userCats = _vm.Categories.Where(c => c.Scope == ConfigScope.User).Select(c => c.Name).OrderBy(n => n).ToList();
                List<string> globCats = _vm.Categories.Where(c => c.Scope == ConfigScope.Global).Select(c => c.Name).OrderBy(n => n).ToList();
                List<string> opts = _vm.CategoryNameOptions.ToList();
                TraceService.SafeLog("SettingsWindow.Opened", new Dictionary<string, object?>
                {
                    ["UserCategoryCount"] = userCats.Count,
                    ["GlobalCategoryCount"] = globCats.Count,
                    ["UserCategorySample"] = string.Join(", ", userCats.Take(10)),
                    ["GlobalCategorySample"] = string.Join(", ", globCats.Take(10)),
                    ["DropdownOptionsInitial"] = string.Join(", ", opts)
                });
            }
            catch
            {
                TraceService.SafeLog("SettingsWindow.Opened", "Trace snapshot failed");
            }
        }
        public void SelectPreferencesTab()
        {
            try { SettingsTabs.SelectedIndex = 2; } catch { }
        }
        protected override void OnSourceInitialized(EventArgs e)
        {
            base.OnSourceInitialized(e);
            HwndSource? src = PresentationSource.FromVisual(this) as HwndSource;
            src?.AddHook(WndProc);
        }

        private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            const int WM_KEYDOWN = 0x0100;
            const int WM_SYSKEYDOWN = 0x0104;
            const int VK_ESCAPE = 0x1B;
            if ((msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) && wParam.ToInt32() == VK_ESCAPE)
            {
                handled = true;
                try { DialogResult = false; } catch { }
                Close();
            }
            return IntPtr.Zero;
        }
        private void DeleteCategory_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            if (_vm.SelectedCategory is not Category c)
            {
                return;
            }

            TraceService.SafeLog("DeleteCategory_Click", $"Target={c.Name} ({c.Scope})");
            List<ScriptItem> assigned = _vm.Scripts.Where(s => s.Category == c.Name && s.Scope == c.Scope).ToList();
            if (assigned.Count > 0)
            {
                var res = MessageBox.Show($"{assigned.Count} scripts are assigned to '{c.Name}'.\nDo you want to reassign them to another category?", "Scripts Assigned", MessageBoxButton.YesNoCancel, MessageBoxImage.Question);
                if (res == MessageBoxResult.Cancel)
                {
                    return;
                }

                if (res == MessageBoxResult.Yes)
                {
                    List<string> choices = _vm.Categories
                        .Where(x => x.Name != c.Name && x.Scope == c.Scope)
                        .Select(x => x.Name)
                        .Distinct()
                        .OrderBy(n => n)
                        .ToList();
                    if (choices.Count == 0)
                    {
                        MessageBox.Show("No alternative category available.", "Reassign", MessageBoxButton.OK, MessageBoxImage.Information);
                        return;
                    }
                    ReassignCategoryWindow pick = new(choices) { Owner = this };
                    if (pick.ShowDialog() == true && !string.IsNullOrEmpty(pick.SelectedCategoryName))
                    {
                        TraceService.SafeLog("DeleteCategory_Reassign", $"To={pick.SelectedCategoryName}");
                        _vm.TryDeleteCategory(c.Name, c.Scope, pick.SelectedCategoryName);
                    }
                    else
                    {
                        // User cancelled selection; abort deletion to avoid orphaned scripts
                        TraceService.SafeLog("DeleteCategory_Reassign", "Cancelled by user");
                        return;
                    }
                }
                else if (res == MessageBoxResult.No)
                {
                    TraceService.SafeLog("DeleteCategory", "Cancelled to prevent orphaned scripts");
                    MessageBox.Show("Deletion cancelled to prevent orphaned scripts.", "Cancelled", MessageBoxButton.OK, MessageBoxImage.Information);
                    return;
                }
            }
            else
            {
                TraceService.SafeLog("DeleteCategory", "No assigned scripts; deleting");
                _vm.TryDeleteCategory(c.Name, c.Scope, null);
            }
        }

        private void BrowseScript_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            OpenFileDialog dlg = new()
            {
                Filter = "PowerShell scripts (*.ps1)|*.ps1|All files (*.*)|*.*",
                Title = "Select PowerShell Script"
            };
            if (dlg.ShowDialog() == true)
            {
                _vm.ScriptPath = dlg.FileName;
                TraceService.SafeLog("BrowseScript", $"Path={dlg.FileName}");
            }
        }
        private void Save_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            if (!ApplyPendingEditsPrompt())
            {
                return; // user cancelled
            }

            _suppressClosePrompt = true; // prevent duplicate prompt during Close
            ResultConfig = _vm.ToResultConfig();
            TraceService.SafeLog("SettingsWindow_Save", new Dictionary<string, object?>
            {
                ["Categories"] = ResultConfig.Categories.Count,
                ["Scripts"] = ResultConfig.Scripts.Count
            });
            // Save preferences if changed
            if (_vm.HasPendingPreferences())
            {
                _vm.SavePreferences();
            }
            DialogResult = true;
            Close();
        }

        private void OpenHistory_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            string userPath = Application.Current.Properties["ConfigPath"] as string ?? ConfigService.GetDefaultUserConfigPath();
            string? globalPath = Application.Current.Properties["GlobalConfigPath"] as string;
            HistoryWindow win = new(userPath, globalPath)
            {
                Owner = this
            };
            win.ShowDialog();
        }

        private void StartAddCategory_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            // Prepare fields for a new category and focus name input
            _vm.SelectedCategory = null;
            _vm.IsAddingCategoryMode = true;
            _vm.CategoryName = string.Empty;
            _vm.CategorySortIndex = 0;
            _vm.CategoryScopeIndex = 0;
            CategoryNameBox.Focus();
            TraceService.SafeLog("StartAddCategory", "Fields reset");
        }

        private void StartAddScript_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            // Prepare fields for a new script and focus name input
            _vm.SelectedScript = null;
            _vm.IsAddingScriptMode = true;
            _vm.ScriptName = string.Empty;
            _vm.ScriptCategoryName = "Unassigned";
            _vm.ScriptPath = string.Empty;
            _vm.ScriptRequiresAdmin = false;
            _vm.ScriptScopeIndex = 0;
            ScriptNameBox.Focus();
            TraceService.SafeLog("StartAddScript", "Fields reset");
        }

        private void ScriptsTreeView_SelectedItemChanged(object? _, RoutedPropertyChangedEventArgs<object> e)
        {
            if (e.NewValue is ScriptItem si)
            {
                _vm.SelectedScript = si;
                TraceService.SafeLog("ScriptsTree.Selected", si.DisplayName);
            }
        }

        private void ValidatePaths_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            List<string> missing = _vm.Scripts
                .Where(s => string.IsNullOrWhiteSpace(s.FilePath) || !System.IO.File.Exists(s.FilePath))
                .Select(s => $"{s.DisplayName} ({s.Category}, {s.Scope})")
                .ToList();

            if (missing.Count == 0)
            {
                MessageBox.Show("All script file paths look valid.", "Validate Paths", MessageBoxButton.OK, MessageBoxImage.Information);
                TraceService.SafeLog("ValidatePaths", "All valid");
            }
            else
            {
                string msg = "The following scripts have missing/invalid paths:\n\n" + string.Join("\n", missing);
                MessageBox.Show(msg, "Validate Paths", MessageBoxButton.OK, MessageBoxImage.Warning);
                TraceService.SafeLog("ValidatePaths", $"InvalidCount={missing.Count}");
            }
        }

        protected override void OnPreviewKeyDown(KeyEventArgs e)
        {
            // Ensure Esc closes once without unintended re-open behaviors
            if (e.Key == Key.Escape)
            {
                e.Handled = true;
                Cancel_Click(this, new RoutedEventArgs());
                return;
            }
            base.OnPreviewKeyDown(e);
        }

        private bool ApplyPendingEditsPrompt()
        {
            bool hasPendingCategory = !string.IsNullOrWhiteSpace(_vm.CategoryName) &&
                (_vm.SelectedCategory == null || _vm.CategoryName != _vm.SelectedCategory.Name ||
                 _vm.CategorySortIndex != (_vm.SelectedCategory?.DefaultSort == SortOrder.ZtoA ? 1 : 0) ||
                 _vm.CategoryScopeIndex != (_vm.SelectedCategory?.Scope == ConfigScope.Global ? 1 : 0));

            static string Norm(string v)
            {
                return SettingsViewModel.NormaliseCategoryForComparison(v);
            }

            bool hasPendingScript = !string.IsNullOrWhiteSpace(_vm.ScriptName) &&
                (
                    _vm.SelectedScript == null ||
                    _vm.ScriptName != _vm.SelectedScript.DisplayName ||
                    Norm(_vm.ScriptCategoryName) != Norm(_vm.SelectedScript.Category) ||
                    _vm.ScriptPath != _vm.SelectedScript.FilePath ||
                    _vm.ScriptRequiresAdmin != _vm.SelectedScript.RequiresAdmin ||
                    _vm.ScriptScopeIndex != (_vm.SelectedScript?.Scope == ConfigScope.Global ? 1 : 0) ||
                    _vm.ScriptPowerIndex != (_vm.SelectedScript?.PowerShellVersion == 5 ? 1 : 0)
                );

            bool hasPendingPreferences = _vm.HasPendingPreferences();

            if (!hasPendingCategory && !hasPendingScript && !hasPendingPreferences)
            {
                return true;
            }

            // Validate required script fields if script has pending edits
            if (hasPendingScript)
            {
                List<string> missing = [];
                if (string.IsNullOrWhiteSpace(_vm.ScriptName))
                {
                    missing.Add("Display name");
                }

                if (string.IsNullOrWhiteSpace(_vm.ScriptCategoryName))
                {
                    missing.Add("Category");
                }

                if (string.IsNullOrWhiteSpace(_vm.ScriptPath))
                {
                    missing.Add("File path");
                }
                // Scope is always one of the two indices; no null state.
                if (missing.Count > 0)
                {
                    MessageBox.Show("Please complete required fields before proceeding:\n\n" + string.Join("\n", missing), "Required Fields", MessageBoxButton.OK, MessageBoxImage.Warning);
                    return false;
                }
            }

            // Build a concise, surface-specific summary
            List<string> parts = [];
            if (hasPendingCategory)
            {
                parts.Add("Category edits");
            }

            if (hasPendingScript)
            {
                parts.Add("Script edits");
            }

            if (hasPendingPreferences)
            {
                parts.Add("Preferences changes");
            }

            string summary = parts.Count > 0 ? string.Join(", ", parts) : "changes";
            var res = MessageBox.Show(
                $"You have unsaved {summary}.\nDo you want to apply before proceeding?\nYes = Apply and continue, No = Discard, Cancel = stay here.",
                "Unsaved Changes",
                MessageBoxButton.YesNoCancel,
                MessageBoxImage.Question);
            TraceService.SafeLog("ApplyPendingEditsPrompt", new Dictionary<string, object?>
            {
                ["Result"] = res,
                ["HasPendingCategory"] = hasPendingCategory,
                ["HasPendingScript"] = hasPendingScript,
                ["HasPendingPreferences"] = hasPendingPreferences
            });

            if (res == MessageBoxResult.Cancel)
            {
                return false;
            }

            if (res == MessageBoxResult.No)
            {
                return true; // discard and proceed
            }

            // Apply pending edits
            if (hasPendingCategory)
            {
                if (_vm.SelectedCategory == null)
                {
                    if (!_vm.AddCategoryCommand.CanExecute(null) || string.IsNullOrWhiteSpace(_vm.CategoryName))
                    {
                        MessageBox.Show("Please complete required Category fields before proceeding.", "Required Fields", MessageBoxButton.OK, MessageBoxImage.Warning);
                        return false;
                    }
                    _vm.AddCategoryCommand.Execute(null);
                    TraceService.SafeLog("AddCategory", $"Name={_vm.CategoryName}; ScopeIndex={_vm.CategoryScopeIndex}; SortIndex={_vm.CategorySortIndex}");
                }
                else
                {
                    if (!_vm.UpdateCategoryCommand.CanExecute(null) || string.IsNullOrWhiteSpace(_vm.CategoryName))
                    {
                        MessageBox.Show("Please complete required Category fields before proceeding.", "Required Fields", MessageBoxButton.OK, MessageBoxImage.Warning);
                        return false;
                    }
                    _vm.UpdateCategoryCommand.Execute(null);
                    TraceService.SafeLog("UpdateCategory", $"Name={_vm.CategoryName}; ScopeIndex={_vm.CategoryScopeIndex}; SortIndex={_vm.CategorySortIndex}");
                }
            }
            if (hasPendingScript)
            {
                if (_vm.SelectedScript == null)
                {
                    if (!_vm.AddScriptCommand.CanExecute(null))
                    {
                        MessageBox.Show("Please complete required Script fields before proceeding.", "Required Fields", MessageBoxButton.OK, MessageBoxImage.Warning);
                        return false;
                    }
                    _vm.AddScriptCommand.Execute(null);
                    TraceService.SafeLog("AddScript", $"Name={_vm.ScriptName}; Cat={_vm.ScriptCategoryName}; Path={_vm.ScriptPath}; ScopeIndex={_vm.ScriptScopeIndex}; PSIndex={_vm.ScriptPowerIndex}; Admin={_vm.ScriptRequiresAdmin}");
                }
                else
                {
                    if (!_vm.UpdateScriptCommand.CanExecute(null))
                    {
                        MessageBox.Show("Please complete required Script fields before proceeding.", "Required Fields", MessageBoxButton.OK, MessageBoxImage.Warning);
                        return false;
                    }
                    _vm.UpdateScriptCommand.Execute(null);
                    TraceService.SafeLog("UpdateScript", $"Name={_vm.ScriptName}; Cat={_vm.ScriptCategoryName}; Path={_vm.ScriptPath}; ScopeIndex={_vm.ScriptScopeIndex}; PSIndex={_vm.ScriptPowerIndex}; Admin={_vm.ScriptRequiresAdmin}");
                }
            }
            if (hasPendingPreferences)
            {
                _vm.SavePreferences();
                TraceService.SafeLog("UpdatePreferences", new Dictionary<string, object?>
                {
                    ["Minutes"] = _vm.PrefAutoRefreshMinutes,
                    ["Badge"] = _vm.PrefShowBadgeNotification,
                    ["Toast"] = _vm.PrefShowToastNotification
                });
            }
            return true;
        }

        private void Cancel_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            if (!ApplyPendingEditsPrompt())
            {
                return; // stay open
            }

            TraceService.SafeLog("SettingsWindow_Cancel", "Close");
            _suppressClosePrompt = true; // prevent duplicate prompt during Close
            DialogResult = false;
            Close();
        }

        protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
        {
            base.OnClosing(e);
            // Ensure unsaved changes prompt on window close via [X]
            if (_suppressClosePrompt)
            {
                _suppressClosePrompt = false; // one-shot suppression
                return;
            }
            if (!ApplyPendingEditsPrompt())
            {
                e.Cancel = true;
                return;
            }
        }
    }
}
