using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;

namespace ScriptLauncher.Views
{
    public partial class AboutWindow : Window
    {
        public AboutWindow()
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
