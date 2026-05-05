using System.IO;
using System.Text;

namespace ScriptLauncher.Services
{
    public static class TraceService
    {
        private static readonly Lock _sync = new();
        private static bool _initialized;

        public static void Initialize(string? customPath = null)
        {
            lock (_sync)
            {
                if (_initialized)
                {
                    return;
                }

                if (!string.IsNullOrWhiteSpace(customPath))
                {
                    TracePath = customPath;
                }

                try
                {
                    string? dir = Path.GetDirectoryName(TracePath);
                    if (!string.IsNullOrEmpty(dir))
                    {
                        Directory.CreateDirectory(dir);
                    }

                    File.WriteAllText(TracePath, $"# ScriptLauncher session trace\n# Started: {DateTime.Now:yyyy-MM-dd HH:mm:ss}\n\n");
                    _initialized = true;
                }
                catch { /* best-effort trace */ }
            }
        }

        public static void LogEvent(string name, string detail)
        {
            try
            {
                string line = $"[{DateTime.Now:HH:mm:ss.fff}] {name}: {detail}\n";
                lock (_sync)
                {
                    File.AppendAllText(TracePath, line, Encoding.UTF8);
                }
            }
            catch { /* best-effort trace */ }
        }

        // Null-safe logging helper that normalises nulls and multiple details.
        // If one detail string is supplied, it's logged as-is (or "null").
        // If multiple details are supplied, their ToString() values are joined with "; ".
        public static void SafeLog(string name, params object?[] details)
        {
            try
            {
                string detailStr;
                if (details == null || details.Length == 0)
                {
                    detailStr = string.Empty;
                }
                else if (details.Length == 1 && details[0] is string s)
                {
                    detailStr = s ?? "null";
                }
                else
                {
                    // avoid LINQ to keep dependencies minimal
                    StringBuilder sb = new();
                    for (int i = 0; i < details.Length; i++)
                    {
                        if (i > 0)
                        {
                            sb.Append("; ");
                        }

                        sb.Append(details[i] == null ? "null" : details[i]!.ToString());
                    }
                    detailStr = sb.ToString();
                }
                LogEvent(name, detailStr);
            }
            catch { /* best-effort trace */ }
        }

        public static void SafeLog(string name, IDictionary<string, object?> fields)
        {
            try
            {
                if (fields == null || fields.Count == 0)
                {
                    LogEvent(name, string.Empty);
                    return;
                }
                StringBuilder sb = new();
                bool first = true;
                foreach (var kvp in fields)
                {
                    if (!first)
                    {
                        sb.Append("; ");
                    }

                    first = false;
                    string? valStr = kvp.Value == null ? "null" : kvp.Value.ToString();
                    sb.Append(kvp.Key);
                    sb.Append('=');
                    sb.Append(valStr);
                }
                LogEvent(name, sb.ToString());
            }
            catch { /* best-effort trace */ }
        }

        public static void LogException(string name, Exception ex)
        {
            LogEvent(name, ex.ToString());
        }

        public static string TracePath { get; private set; } = Path.Combine(Path.GetTempPath(), $"ScriptLauncher-trace-{DateTime.Now:yyyyMMdd-HHmmss}.log");
    }
}
