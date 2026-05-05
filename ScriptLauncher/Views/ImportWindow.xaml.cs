using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;

namespace ScriptLauncher.Views
{
    public partial class ImportWindow : Window
    {
        public int ScopeSelection { get; private set; } = 1; // 1 User, 2 Global
        public ImportWindow()
        {
            InitializeComponent();
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

        private void Ok_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            ScopeSelection = ScopeCombo.SelectedIndex == 0 ? 1 : 2;
            DialogResult = true;
            Close();
        }

        private void Cancel_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            DialogResult = false;
            Close();
        }

        protected override void OnPreviewKeyDown(KeyEventArgs e)
        {
            if (e.Key == Key.Escape)
            {
                e.Handled = true;
                DialogResult = false;
                Close();
                return;
            }
            base.OnPreviewKeyDown(e);
        }
    }
}