using System.Diagnostics;
using System.IO;
using ScriptLauncher.Models;

namespace ScriptLauncher.Services
{
    public enum RunResult { Success, InvalidPath, FailedToStart }

    public class ProcessRunner
    {
        /// <summary>
        /// Executes a script using PowerShell 7 by default (or Windows PowerShell 5 when specified),
        /// optionally elevating via UAC when <see cref="ScriptItem.RequiresAdmin"/> is true. Short-circuits
        /// with a single warning if the path is invalid or missing.
        /// </summary>
        /// <param name="item">Script metadata to run, including path, scope, and PowerShell version.</param>
        /// <returns>RunResult indicating success, invalid path, or failure to start.</returns>
        public static RunResult Run(ScriptItem item)
        {
            if (string.IsNullOrWhiteSpace(item.FilePath) || !File.Exists(item.FilePath))
            {
                System.Windows.MessageBox.Show("The script path is invalid or missing.", "Invalid Path", System.Windows.MessageBoxButton.OK, System.Windows.MessageBoxImage.Warning);
                return RunResult.InvalidPath;
            }

            string shell = item.PowerShellVersion == 5 ? "powershell.exe" : "pwsh.exe";
            ProcessStartInfo psi = new()
            {
                FileName = shell,
                UseShellExecute = true
            };
            psi.ArgumentList.Add("-NoProfile");
            if (shell == "powershell.exe")
            {
                psi.ArgumentList.Add("-ExecutionPolicy");
                psi.ArgumentList.Add("Bypass");
                psi.ArgumentList.Add("-File");
                psi.ArgumentList.Add(item.FilePath);
            }
            else
            {
                psi.ArgumentList.Add("-ExecutionPolicy");
                psi.ArgumentList.Add("Bypass");
                psi.ArgumentList.Add("-File");
                psi.ArgumentList.Add(item.FilePath);
            }

            if (item.RequiresAdmin)
            {
                psi.Verb = "runas"; // triggers UAC elevation
            }

            try
            {
                Process.Start(psi);
                return RunResult.Success;
            }
            catch
            {
                return RunResult.FailedToStart;
            }
        }
    }
}
