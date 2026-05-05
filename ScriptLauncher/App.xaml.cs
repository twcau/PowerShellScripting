using System.IO;
using System.Windows;
using Microsoft.Win32;
using ScriptLauncher.Services;
using ScriptLauncher.Models;

namespace ScriptLauncher
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            // Global safety net: log unhandled exceptions
            SetupGlobalExceptionLogging();

            // Initialize session trace
            TraceService.Initialize();
            TraceService.SafeLog("Startup", "Application starting");

            var settings = SettingsService.Load();

            // If no settings, offer to select an existing config file
            if (string.IsNullOrWhiteSpace(settings.ConfigPath))
            {
                string userPath = ConfigService.GetDefaultUserConfigPath();
                string fallback = ConfigService.GetFallbackAppConfigPath();

                // Ask user only if neither exists yet
                if (!File.Exists(userPath) && !File.Exists(fallback))
                {
                    var res = MessageBox.Show(
                        "Do you want to use an existing configuration file?\nClick Yes to browse, or No to create a default user config.",
                        "Configuration",
                        MessageBoxButton.YesNo,
                        MessageBoxImage.Question);

                    if (res == MessageBoxResult.Yes)
                    {
                        OpenFileDialog dlg = new()
                        {
                            Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*",
                            Title = "Select user configuration file"
                        };
                        if (dlg.ShowDialog() == true)
                        {
                            settings.ConfigPath = dlg.FileName;
                            SettingsService.Save(settings);
                        }
                        else
                        {
                            settings.ConfigPath = userPath; // will be created when saved
                            SettingsService.Save(settings);
                        }
                    }
                    else
                    {
                        settings.ConfigPath = userPath; // default per-user location
                        SettingsService.Save(settings);
                    }
                }
                else
                {
                    // Prefer user path; else fallback
                    settings.ConfigPath = File.Exists(userPath) ? userPath : fallback;
                    SettingsService.Save(settings);
                }
            }

            // Resolve global config: default to ProgramData for stability across builds
            if (string.IsNullOrWhiteSpace(settings.GlobalConfigPath))
            {
                string fallbackGlobal = ConfigService.GetFallbackAppConfigPath();
                try
                {
                    string? dir = Path.GetDirectoryName(fallbackGlobal);
                    if (!string.IsNullOrEmpty(dir))
                    {
                        Directory.CreateDirectory(dir);
                    }
                    // If file doesn't exist yet, seed with an empty config to ensure a concrete path exists
                    if (!File.Exists(fallbackGlobal))
                    {
                        new ConfigService(fallbackGlobal).Save(new AppConfig());
                    }
                }
                catch { }
                settings.GlobalConfigPath = fallbackGlobal;
                SettingsService.Save(settings);
            }

            // Share resolved paths with the app
            // settings.ConfigPath is set above; guard null by falling back to user default
            Current.Properties["ConfigPath"] = settings.ConfigPath ?? ConfigService.GetDefaultUserConfigPath();
            Current.Properties["GlobalConfigPath"] = settings.GlobalConfigPath;
            TraceService.SafeLog("ResolvedPaths", new Dictionary<string, object?>
            {
                ["User"] = settings.ConfigPath,
                ["Global"] = settings.GlobalConfigPath
            });

            // Create and show the main window after paths are set so it can read them reliably
            MainWindow win = new();
            TraceService.SafeLog("MainWindow", "Created and showing");
            win.Show();
        }

        private void SetupGlobalExceptionLogging()
        {
            string logPath = Path.Combine(Path.GetTempPath(), "ScriptLauncher.log");

            DispatcherUnhandledException += (s, exArgs) =>
            {
                try
                {
                    File.AppendAllText(logPath, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] UI Exception:\n{exArgs.Exception}\n\n");
                }
                catch { }
                exArgs.Handled = false; // allow default crash behavior so issues are visible
            };

            AppDomain.CurrentDomain.UnhandledException += (s, exArgs) =>
            {
                try
                {
                    File.AppendAllText(logPath, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Unhandled Exception:\n{exArgs.ExceptionObject}\n\n");
                }
                catch { }
            };
        }

        // Removed global Escape hook to avoid unintended interactions; dialogs handle ESC at Hwnd level.
    }
}
