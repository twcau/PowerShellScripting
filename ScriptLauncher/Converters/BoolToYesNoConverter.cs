using System.Globalization;
using System.Windows.Data;

namespace ScriptLauncher.Converters
{
    public class BoolToYesNoConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value is bool b ? b ? "Yes" : "No" : string.Empty;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is string s)
            {
                if (string.Equals(s, "Yes", StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }

                if (string.Equals(s, "No", StringComparison.OrdinalIgnoreCase))
                {
                    return false;
                }
            }
            return false;
        }
    }
}