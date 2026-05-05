using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using ScriptLauncher.Models;
using ScriptLauncher.Services;

namespace ScriptLauncher.Views
{
	public partial class HistoryWindow : Window
	{
		private readonly string _userPath = ConfigService.GetDefaultUserConfigPath();
		private readonly string _globalPath = ConfigService.GetFallbackAppConfigPath();

		private sealed record SnapshotDisplay(string Content, HistoryService.SnapshotInfo Info);

		public HistoryWindow()
		{
			InitializeComponent();
			ScopeCombo.SelectedIndex = 0;
			LoadSnapshots();
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

		public HistoryWindow(string userConfigPath, string? globalConfigPath) : this()
		{
			_userPath = userConfigPath;
			_globalPath = globalConfigPath ?? ConfigService.GetFallbackAppConfigPath();
			LoadSnapshots();
		}

		private ConfigScope CurrentScope => ScopeCombo.SelectedIndex == 0 ? ConfigScope.User : ConfigScope.Global;
		private string CurrentLivePath => CurrentScope == ConfigScope.User ? _userPath : _globalPath;

		private void LoadSnapshots()
		{
			List<SnapshotDisplay> items = HistoryService.ListSnapshots(CurrentLivePath, CurrentScope)
				.Select(s =>
				{
					var meta = HistoryService.ReadMeta(s.FilePath);
					string actor = meta?.Actor ?? "(unknown)";
					string counts = meta == null ? string.Empty : $"Cats +{meta.CategoriesAdded}/-{meta.CategoriesRemoved}; Scripts +{meta.ScriptsAdded}/-{meta.ScriptsRemoved}";
					string? noteVal = meta?.Note;
					string notePart = string.IsNullOrWhiteSpace(noteVal) ? string.Empty : $" — {noteVal}";
					string label = $"{s.Timestamp:yyyy-MM-dd HH:mm:ss} — User: {actor}{(string.IsNullOrEmpty(counts) ? string.Empty : "; " + counts)}{notePart}";
					return new SnapshotDisplay(label, s);
				})
				.ToList();
			SnapshotsList.ItemsSource = items;
		}

		private void ScopeCombo_SelectionChanged(object? _, SelectionChangedEventArgs e)
		{
			_ = e; // suppress IDE0060 for unused parameter
			LoadSnapshots();
		}

		private void ViewDiff_Click(object? _, RoutedEventArgs e)
		{
			_ = e; // suppress IDE0060 for unused parameter
			if (SnapshotsList.SelectedItem is not SnapshotDisplay sd) { MessageBox.Show("Select a snapshot first."); return; }
			try
			{
				var meta = HistoryService.ReadMeta(sd.Info.FilePath);
				if (meta == null)
				{
					MessageBox.Show("No summary metadata available for this snapshot.", "Diff Summary", MessageBoxButton.OK, MessageBoxImage.Information);
					return;
				}

				string ts = sd.Info.Timestamp.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.CurrentCulture);
				string scope = sd.Info.Scope == ConfigScope.User ? "User" : "Global";
				string header = $"Snapshot: {ts} | Scope: {scope} | User: {meta.Actor}";
				string counts = $"Categories: +{meta.CategoriesAdded}/-{meta.CategoriesRemoved}\nScripts: +{meta.ScriptsAdded}/-{meta.ScriptsRemoved}";
				string added = meta.ItemsAdded != null && meta.ItemsAdded.Count > 0 ? string.Join("\n  • ", meta.ItemsAdded) : "(none)";
				string removed = meta.ItemsRemoved != null && meta.ItemsRemoved.Count > 0 ? string.Join("\n  • ", meta.ItemsRemoved) : "(none)";
				string note = string.IsNullOrWhiteSpace(meta.Note) ? "(no note)" : meta.Note;

				string body = $"{header}\n\n{counts}\n\nAdded:\n  • {added}\n\nRemoved:\n  • {removed}\n\nNote: {note}";

				MessageBox.Show(body, "Diff Summary", MessageBoxButton.OK, MessageBoxImage.Information);
			}
			catch { MessageBox.Show("Failed to read snapshot summary."); }
		}

		private void SnapshotsList_SelectionChanged(object? _, SelectionChangedEventArgs e)
		{
			_ = e; // suppress IDE0060 for unused parameter
			if (SnapshotsList.SelectedItem is SnapshotDisplay sd)
			{
				var meta = HistoryService.ReadMeta(sd.Info.FilePath);
				NoteBox.Text = meta?.Note ?? string.Empty;
			}
			else
			{
				NoteBox.Text = string.Empty;
			}
		}

		private void SaveNote_Click(object? _, RoutedEventArgs e)
		{
			_ = e; // suppress IDE0060 for unused parameter
			if (SnapshotsList.SelectedItem is not SnapshotDisplay sd) { MessageBox.Show("Select a snapshot first."); return; }
			HistoryService.UpdateNote(sd.Info.FilePath, NoteBox.Text);
			LoadSnapshots();
		}

		private void Restore_Click(object? _, RoutedEventArgs e)
		{
			_ = e; // suppress IDE0060 for unused parameter
			if (SnapshotsList.SelectedItem is not SnapshotDisplay sd) { MessageBox.Show("Select a snapshot first."); return; }
			bool ok = HistoryService.Restore(CurrentLivePath, sd.Info.FilePath);
			if (ok)
			{
				MessageBox.Show("Configuration restored.", "Restore", MessageBoxButton.OK, MessageBoxImage.Information);
				LoadSnapshots();
			}
			else
			{
				MessageBox.Show("Restore failed.", "Restore", MessageBoxButton.OK, MessageBoxImage.Error);
			}
		}

		private void Close_Click(object? _, RoutedEventArgs e)
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
