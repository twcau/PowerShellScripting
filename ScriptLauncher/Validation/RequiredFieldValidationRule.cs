using System.Globalization;
using System.Windows.Controls;

namespace ScriptLauncher.Validation
{
    // Simple required field rule for strings; returns invalid if null/empty/whitespace.
    public class RequiredFieldValidationRule : ValidationRule
    {
        public override ValidationResult Validate(object value, CultureInfo cultureInfo)
        {
            string? s = value as string;
            return string.IsNullOrWhiteSpace(s) ? new ValidationResult(false, "Required") : ValidationResult.ValidResult;
        }
    }
}
