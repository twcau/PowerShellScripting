using System.Windows;
using System.Windows.Input;
using System.Windows.Threading;
using Microsoft.Win32;
using ScriptLauncher.Services;
using ScriptLauncher.ViewModels;
using ScriptLauncher.Views;

namespace ScriptLauncher
{
    public partial class MainWindow : Window, IDisposable
    {
        // removed unused field to satisfy nullable warnings
        private readonly MainViewModel _vm = default!;
        private System.IO.FileSystemWatcher? _userWatcher;
        private System.IO.FileSystemWatcher? _globalWatcher;
        private DateTime _lastReload = DateTime.MinValue;

        public MainWindow()
        {
            InitializeComponent();
            string userPath = Application.Current.Properties["ConfigPath"] as string ?? ConfigService.GetDefaultUserConfigPath();
            string? globalPath = Application.Current.Properties["GlobalConfigPath"] as string;
            _vm = new MainViewModel(userPath, globalPath);
            DataContext = _vm;

            SetupConfigWatchers(userPath, globalPath);
            SetupAutoRefresh();
            TraceService.SafeLog("MainWindowInitialized", $"UserPath={userPath}; GlobalPath={globalPath}");
        }

        private void SetupConfigWatchers(string userPath, string? globalPath)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(userPath))
                {
                    _userWatcher = new System.IO.FileSystemWatcher(System.IO.Path.GetDirectoryName(userPath) ?? ".")
                    {
                        Filter = System.IO.Path.GetFileName(userPath),
                        NotifyFilter = System.IO.NotifyFilters.LastWrite | System.IO.NotifyFilters.Size | System.IO.NotifyFilters.FileName
                    };
                    _userWatcher.Changed += (_, __) => DebouncedReload();
                    _userWatcher.Created += (_, __) => DebouncedReload();
                    _userWatcher.Renamed += (_, __) => DebouncedReload();
                    _userWatcher.EnableRaisingEvents = true;
                }

                if (!string.IsNullOrWhiteSpace(globalPath))
                {
                    _globalWatcher = new System.IO.FileSystemWatcher(System.IO.Path.GetDirectoryName(globalPath) ?? ".")
                    {
                        Filter = System.IO.Path.GetFileName(globalPath),
                        NotifyFilter = System.IO.NotifyFilters.LastWrite | System.IO.NotifyFilters.Size | System.IO.NotifyFilters.FileName
                    };
                    _globalWatcher.Changed += (_, __) => DebouncedReload();
                    _globalWatcher.Created += (_, __) => DebouncedReload();
                    _globalWatcher.Renamed += (_, __) => DebouncedReload();
                    _globalWatcher.EnableRaisingEvents = true;
                }
            }
            catch { }
        }

        private void DebouncedReload()
        {
            // Avoid thrashing the UI with rapid successive file system events
            var now = DateTime.Now;
            if ((now - _lastReload).TotalMilliseconds < 300)
            {
                return;
            }

            _lastReload = now;
            Dispatcher.Invoke(() => { OnReloadCompleted(_vm.LoadConfigAndDetectChanges(false)); });
            TraceService.SafeLog("DebouncedReload", "Triggered by file watcher event");
        }

        private System.Windows.Threading.DispatcherTimer? _refreshTimer;
        private void SetupAutoRefresh()
        {
            try
            {
                var settings = SettingsService.Load();
                int minutes = Math.Max(1, settings.AutoRefreshMinutes);
                _refreshTimer = new System.Windows.Threading.DispatcherTimer
                {
                    Interval = TimeSpan.FromMinutes(minutes)
                };
                _refreshTimer.Tick += (_, __) => OnReloadCompleted(_vm.LoadConfigAndDetectChanges(false));
                _refreshTimer.Start();
            }
            catch { }
        }

        protected override void OnClosed(EventArgs e)
        {
            base.OnClosed(e);
            Dispose();
        }

        public void Dispose()
        {
            try { _userWatcher?.Dispose(); } catch { }
            try { _globalWatcher?.Dispose(); } catch { }
            try { _refreshTimer?.Stop(); _refreshTimer = null; } catch { }
            GC.SuppressFinalize(this);
        }

        private void OnReloadCompleted(bool hadChanges)
        {
            try
            {
                var settings = SettingsService.Load();
                if (hadChanges)
                {
                    if (settings.ShowBadgeNotification && TaskbarItemInfo != null)
                    {
                        TaskbarItemInfo.ProgressState = System.Windows.Shell.TaskbarItemProgressState.Normal;
                        TaskbarItemInfo.ProgressValue = 1.0;
                        // Reset after a moment
                        DispatcherTimer t = new() { Interval = TimeSpan.FromSeconds(4) };
                        t.Tick += (_, __) => { TaskbarItemInfo.ProgressState = System.Windows.Shell.TaskbarItemProgressState.None; (_ as System.Windows.Threading.DispatcherTimer)?.Stop(); };
                        t.Start();
                    }
                    // Toast notification not implemented without Windows Forms; reserved for future.
                }
                TraceService.SafeLog("ReloadCompleted", new Dictionary<string, object?>
                {
                    ["HadChanges"] = hadChanges
                });
            }
            catch { }
        }

        private void OpenSettings_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            var currentConfig = _vm.GetCurrentConfig();
            SettingsWindow win = new(currentConfig) { Owner = this };
            if (win.ShowDialog() == true)
            {
                TraceService.SafeLog("OpenSettings", "Accepted");
                _vm.ReplaceAndSave(win.ResultConfig);
                OnReloadCompleted(_vm.LoadConfigAndDetectChanges(true));
            }
            else
            {
                TraceService.SafeLog("OpenSettings", "Cancelled");
            }
        }

        // CommandBinding handlers
        private void RunSelected_CanExecute(object? _, CanExecuteRoutedEventArgs e)
        {
            e.CanExecute = _vm.SelectedScriptItem != null;
        }
        private void RunSelected_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            _vm.RunSelectedCommand.Execute(null);
        }
        private void ImportConfig_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            TraceService.SafeLog("ImportConfig", "Command executed");
            ImportConfig_Click(_, e as RoutedEventArgs ?? new RoutedEventArgs());
        }
        private void ExportConfig_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            TraceService.SafeLog("ExportConfig", "Command executed");
            ExportConfig_Click(_, e as RoutedEventArgs ?? new RoutedEventArgs());
        }
        private void OpenSettings_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            TraceService.SafeLog("OpenSettings", "Command executed");
            OpenSettings_Click(_, e as RoutedEventArgs ?? new RoutedEventArgs());
        }
        private void OpenHistory_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            TraceService.SafeLog("OpenHistory", "Command executed");
            OpenHistory_Click(_, e as RoutedEventArgs ?? new RoutedEventArgs());
        }
        private void OpenAbout_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            TraceService.SafeLog("OpenAbout", "Command executed");
            OpenAbout_Click(_, e as RoutedEventArgs ?? new RoutedEventArgs());
        }
        private void Exit_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            TraceService.SafeLog("Exit", "Command executed");
            Exit_Click(_, e as RoutedEventArgs ?? new RoutedEventArgs());
        }

        private void OpenAbout_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            AboutWindow win = new()
            {
                Owner = this
            };
            win.ShowDialog();
        }

        private void ReloadConfig_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            TraceService.SafeLog("ReloadConfig", "Command executed");
            OnReloadCompleted(_vm.LoadConfigAndDetectChanges(true));
        }

        private void OpenPreferences_Executed(object? _, ExecutedRoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            TraceService.SafeLog("OpenPreferences", "Command executed");
            var currentConfig = _vm.GetCurrentConfig();
            SettingsWindow win = new(currentConfig) { Owner = this };
            win.SelectPreferencesTab();
            win.ShowDialog();
            // restart timer with new interval
            try
            {
                _refreshTimer?.Stop();
                SetupAutoRefresh();
            }
            catch { }
            TraceService.SafeLog("PreferencesUpdated", "AutoRefresh restarted");
        }

        private void Exit_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            Close();
        }

        private void ImportConfig_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            // Choose scope first, then browse for file, to reduce confusion
            ImportWindow chooser = new() { Owner = this };
            if (chooser.ShowDialog() == true)
            {
                OpenFileDialog dlg = new()
                {
                    Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*",
                    Title = "Import configuration"
                };
                if (dlg.ShowDialog() == true)
                {
                    TraceService.SafeLog("ImportConfig", new Dictionary<string, object?>
                    {
                        ["File"] = dlg.FileName,
                        ["ScopeSelection"] = chooser.ScopeSelection
                    });
                    _vm.ImportConfigWithScope(dlg.FileName, chooser.ScopeSelection);
                }
            }
        }

        private void ExportConfig_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            ExportWindow chooser = new() { Owner = this };
            if (chooser.ShowDialog() == true)
            {
                SaveFileDialog dlg = new()
                {
                    Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*",
                    Title = "Export configuration",
                    FileName = "scripts-export.json"
                };
                if (dlg.ShowDialog() == true)
                {
                    TraceService.SafeLog("ExportConfig", new Dictionary<string, object?>
                    {
                        ["File"] = dlg.FileName,
                        ["ScopeSelection"] = chooser.ScopeSelection
                    });
                    _vm.ExportByScope(dlg.FileName, chooser.ScopeSelection);
                }
            }
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
            // After restore, reload current config to reflect changes
            TraceService.SafeLog("HistoryClosed", "Reloading after potential restore");
            OnReloadCompleted(_vm.LoadConfigAndDetectChanges(true));
        }

        private void OpenShortcuts_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            TraceService.SafeLog("OpenShortcuts", "Click");
            ShortcutsWindow win = new()
            {
                Owner = this
            };
            win.ShowDialog();
        }

        private void ScriptsGrid_GotKeyboardFocus(object? _, KeyboardFocusChangedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            // Select the first row when focus enters the grid for immediate highlight
            if (_vm.SelectedScriptItem == null && _vm.Scripts.Any())
            {
                _vm.SelectedScriptItem = _vm.Scripts.First();
            }
        }

        private void ScriptsGrid_PreviewKeyDown(object? _, KeyEventArgs e)
        {
            if (e.Key == Key.Tab)
            {
                e.Handled = true;
                bool isShift = (Keyboard.Modifiers & ModifierKeys.Shift) == ModifierKeys.Shift;
                if (isShift)
                {
                    RunButton.Focus();
                }
                else
                {
                    FileMenuItem.Focus();
                }
            }
        }
    }
}
