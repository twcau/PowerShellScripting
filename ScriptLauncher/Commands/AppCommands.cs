using System.Windows.Input;

namespace ScriptLauncher.Commands
{
    public static class AppCommands
    {
        public static readonly RoutedUICommand RunScript = new("Run Selected Script", "RunScript", typeof(AppCommands));
        public static readonly RoutedUICommand OpenSettings = new("Open Settings", "OpenSettings", typeof(AppCommands));
        public static readonly RoutedUICommand OpenHistory = new("Open History", "OpenHistory", typeof(AppCommands));
        public static readonly RoutedUICommand ReloadConfig = new("Reload Config", "ReloadConfig", typeof(AppCommands));
        public static readonly RoutedUICommand OpenPreferences = new("Preferences", "OpenPreferences", typeof(AppCommands));
    }
}