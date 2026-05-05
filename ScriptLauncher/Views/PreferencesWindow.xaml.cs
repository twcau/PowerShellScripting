using System.Globalization;
using System.Windows;
using System.Windows.Interop;
using ScriptLauncher.Services;

namespace ScriptLauncher.Views
{
    public partial class PreferencesWindow : Window
    {
        private AppSettings _settings = new();

        public PreferencesWindow()
        {
            InitializeComponent();
            LoadSettings();
            SetupEscClose();
        }

        private void LoadSettings()
        {
            try
            {
                _settings = SettingsService.Load();
                MinutesBox.Text = Math.Max(1, _settings.AutoRefreshMinutes).ToString(CultureInfo.CurrentCulture);
                BadgeCheck.IsChecked = _settings.ShowBadgeNotification;
                ToastCheck.IsChecked = _settings.ShowToastNotification;
            }
            catch { }
        }

        private void Save_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            if (!int.TryParse(MinutesBox.Text, out int mins) || mins < 1)
            {
                MessageBox.Show("Please enter a valid number of minutes (>=1).", "Invalid Input", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            _settings.AutoRefreshMinutes = mins;
            _settings.ShowBadgeNotification = BadgeCheck.IsChecked == true;
            _settings.ShowToastNotification = ToastCheck.IsChecked == true;
            SettingsService.Save(_settings);
            DialogResult = true;
            Close();
        }

        // Per-dialog ESC handling
        protected override void OnSourceInitialized(EventArgs e)
        {
            base.OnSourceInitialized(e);
            HwndSource source = System.Windows.Interop.HwndSource.FromHwnd(new System.Windows.Interop.WindowInteropHelper(this).Handle);
            source?.AddHook(WndProc);
        }

        private const int WM_KEYDOWN = 0x0100;
        private const int WM_SYSKEYDOWN = 0x0104;
        private const int VK_ESCAPE = 0x1B;
        private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            if ((msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) && wParam.ToInt32() == VK_ESCAPE)
            {
                handled = true;
                Close();
            }
            return IntPtr.Zero;
        }

        private static void SetupEscClose() { /* Hook added in OnSourceInitialized per standards */ }
    }
}
