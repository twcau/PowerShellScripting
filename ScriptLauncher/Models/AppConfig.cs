namespace ScriptLauncher.Models
{
    public enum ConfigScope { Global, User }
    public enum SortOrder { AtoZ, ZtoA }

    public class Category
    {
        public string Name { get; set; } = string.Empty;
        public SortOrder DefaultSort { get; set; } = SortOrder.AtoZ;
        public ConfigScope Scope { get; set; } = ConfigScope.User;
        public string Label => $"{Name} ({(Scope == ConfigScope.Global ? "Global" : "User")})";
    }

    public class ScriptItem : System.ComponentModel.INotifyPropertyChanged
    {
        public string DisplayName { get; set { field = value; OnPropertyChanged(nameof(DisplayName)); } } = string.Empty;

        public string Category { get; set { field = value; OnPropertyChanged(nameof(Category)); } } = string.Empty;

        public string FilePath { get; set { field = value; OnPropertyChanged(nameof(FilePath)); } } = string.Empty;

        public bool RequiresAdmin { get; set { field = value; OnPropertyChanged(nameof(RequiresAdmin)); } }

        public ConfigScope Scope { get; set { field = value; OnPropertyChanged(nameof(Scope)); } } = ConfigScope.User;

        public int PowerShellVersion { get; set { field = value; OnPropertyChanged(nameof(PowerShellVersion)); } } = 7;

        public event System.ComponentModel.PropertyChangedEventHandler? PropertyChanged;
        private void OnPropertyChanged(string name)
        {
            PropertyChanged?.Invoke(this, new System.ComponentModel.PropertyChangedEventArgs(name));
        }
    }

    public class AppConfig
    {
        public List<Category> Categories { get; set; } = [];
        public List<ScriptItem> Scripts { get; set; } = [];
    }
}
