namespace ScriptLauncher.ViewModels
{
    public enum ScopeAvailability { User, Global, Both }

    public class CategoryDisplay
    {
        public string Name { get; set; } = string.Empty;
        public ScopeAvailability Availability { get; set; } = ScopeAvailability.User;
        public string Label => Availability switch
        {
            ScopeAvailability.Both => $"{Name} (Both)",
            ScopeAvailability.Global => $"{Name} (Global)",
            ScopeAvailability.User => throw new NotImplementedException(),
            _ => $"{Name} (User)"
        };
    }
}
