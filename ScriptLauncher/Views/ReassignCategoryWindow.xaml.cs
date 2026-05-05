using System.Windows;
using System.Windows.Interop;

namespace ScriptLauncher.Views
{
    public partial class ReassignCategoryWindow : Window
    {
        public string? SelectedCategoryName { get; private set; }

        public ReassignCategoryWindow(IEnumerable<string> categoryNames)
        {
            InitializeComponent();
            foreach (string n in categoryNames)
            {
                TargetCombo.Items.Add(n);
            }
            if (TargetCombo.Items.Count > 0)
            {
                TargetCombo.SelectedIndex = 0;
            }
            SetupEscClose();
        }

        private void Ok_Click(object? _, RoutedEventArgs e)
        {
            _ = e; // suppress IDE0060 for unused parameter
            if (TargetCombo.SelectedItem is string name)
            {
                SelectedCategoryName = name;
                DialogResult = true;
                Close();
            }
            else
            {
                MessageBox.Show("Please select a target category.", "Reassign", MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

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
        private static void SetupEscClose() { }
    }
}
