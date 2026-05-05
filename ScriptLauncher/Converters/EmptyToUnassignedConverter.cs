using System.Globalization;
using System.Windows.Data;

namespace ScriptLauncher.Converters
{
    /// <summary>
    /// Converts null/empty/whitespace strings to the literal "Unassigned" for UI display.
    /// Passes through non-empty values unchanged.
    /// </summary>
    public class EmptyToUnassignedConverter : IValueConverter
    {
        public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            string? s = value as string;
            return string.IsNullOrWhiteSpace(s) ? "Unassigned" : s;
        }

        public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            string? s = value as string;
            // Map display "Unassigned" back to empty string to align with persisted model
            return string.Equals(s, "Unassigned", StringComparison.OrdinalIgnoreCase) ? string.Empty : s;
        }
    }
}
