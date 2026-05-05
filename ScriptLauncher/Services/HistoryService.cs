using System.IO;
using System.Text.Json;
using ScriptLauncher.Models;

namespace ScriptLauncher.Services
{
    public class HistoryService
    {
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            WriteIndented = true
        };

        public record SnapshotInfo(string FilePath, DateTime Timestamp, ConfigScope Scope, string Note);

        /// <summary>
        /// Creates a configuration snapshot for the specified scope, writing a JSON copy and a metadata sidecar
        /// containing actor, per-scope change counts, item identifiers, and an optional note. Old snapshots are pruned
        /// based on the provided retention.
        /// </summary>
        /// <param name="liveConfigPath">Path to the live config file for the scope.</param>
        /// <param name="config">The configuration object to snapshot.</param>
        /// <param name="scope">The scope to associate with this snapshot (User or Global).</param>
        /// <param name="retention">Maximum number of snapshots to keep.</param>
        /// <param name="note">Optional note to include in snapshot metadata.</param>
        public static void Snapshot(string liveConfigPath, AppConfig config, ConfigScope scope, int retention = 20, string? note = null)
        {
            string historyDir = GetHistoryDirForScope(liveConfigPath, scope);
            Directory.CreateDirectory(historyDir);
            var ts = DateTime.Now;
            string fileName = $"scripts-{ts:yyyyMMdd-HHmmss}.json";
            string snapshotPath = Path.Combine(historyDir, fileName);

            // Write atomically
            string tmp = snapshotPath + ".tmp";
            string json = JsonSerializer.Serialize(config, JsonOptions);
            File.WriteAllText(tmp, json);
            if (File.Exists(snapshotPath))
            {
                File.Delete(snapshotPath);
            }

            File.Move(tmp, snapshotPath);

            // Compute diff vs current live config, then write meta sidecar
            var meta = ComputeMeta(liveConfigPath, config, scope, note ?? string.Empty);
            WriteMeta(snapshotPath, meta);

            Prune(historyDir, retention);
        }

        /// <summary>
        /// Lists available snapshots for the specified scope, including timestamp and summary note.
        /// </summary>
        /// <param name="liveConfigPath">Path to the live config file for the scope.</param>
        /// <param name="scope">Scope to list snapshots for.</param>
        /// <returns>Ordered list of snapshot info, newest first.</returns>
        public static List<SnapshotInfo> ListSnapshots(string liveConfigPath, ConfigScope scope)
        {
            string dir = GetHistoryDirForScope(liveConfigPath, scope);
            return !Directory.Exists(dir)
                ? []
                : [.. Directory.GetFiles(dir, "scripts-*.json")
                .Select(p => new SnapshotInfo(p, ParseTimestamp(Path.GetFileName(p)), scope, ReadNote(p)))
                .OrderByDescending(s => s.Timestamp)];
        }

        /// <summary>
        /// Restores the specified snapshot to the live config file, validating JSON before committing.
        /// </summary>
        /// <param name="liveConfigPath">Path where the config should be restored.</param>
        /// <param name="snapshotPath">Path to the snapshot JSON file.</param>
        /// <returns>True on success; false if validation or IO fails.</returns>
        public static bool Restore(string liveConfigPath, string snapshotPath)
        {
            try
            {
                string dir = Path.GetDirectoryName(liveConfigPath)!;
                Directory.CreateDirectory(dir);
                string json = File.ReadAllText(snapshotPath);
                // Validate
                var cfg = JsonSerializer.Deserialize<AppConfig>(json);
                if (cfg == null)
                {
                    return false;
                }

                string tmp = liveConfigPath + ".tmp";
                File.WriteAllText(tmp, JsonSerializer.Serialize(cfg, JsonOptions));
                if (File.Exists(liveConfigPath))
                {
                    File.Delete(liveConfigPath);
                }

                File.Move(tmp, liveConfigPath);
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Updates the note field in the snapshot metadata sidecar without altering counts or actor.
        /// </summary>
        /// <param name="snapshotPath">Path to the snapshot JSON file (used to resolve sidecar).</param>
        /// <param name="note">New note text; empty allowed.</param>
        public static void UpdateNote(string snapshotPath, string? note)
        {
            try
            {
                var meta = ReadMeta(snapshotPath) ?? new SnapshotMeta(Environment.UserName, 0, 0, 0, 0, [], [], string.Empty);
                meta = meta with { Note = note ?? string.Empty };
                WriteMeta(snapshotPath, new MetaNote
                {
                    Note = meta.Note,
                    Actor = meta.Actor,
                    CategoriesAdded = meta.CategoriesAdded,
                    CategoriesRemoved = meta.CategoriesRemoved,
                    ScriptsAdded = meta.ScriptsAdded,
                    ScriptsRemoved = meta.ScriptsRemoved,
                    ItemsAdded = meta.ItemsAdded,
                    ItemsRemoved = meta.ItemsRemoved
                });
            }
            catch { }
        }

        private static void Prune(string historyDir, int retention)
        {
            List<string> files = Directory.GetFiles(historyDir, "scripts-*.json")
                .OrderByDescending(f => ParseTimestamp(Path.GetFileName(f)))
                .ToList();
            if (files.Count <= retention)
            {
                return;
            }

            foreach (string? f in files.Skip(retention))
            {
                try { File.Delete(f); } catch { }
            }
        }

        private static DateTime ParseTimestamp(string fileName)
        {
            // scripts-YYYYMMDD-HHMMSS.json
            try
            {
                string stem = Path.GetFileNameWithoutExtension(fileName);
                string[] parts = stem.Split('-');
                if (parts.Length >= 3)
                {
                    string date = parts[1];
                    string time = parts[2];
                    return DateTime.ParseExact(date + time, "yyyyMMddHHmmss", System.Globalization.CultureInfo.InvariantCulture);
                }
            }
            catch { }
            return DateTime.MinValue;
        }

        private static string ReadNote(string snapshotPath)
        {
            try
            {
                string metaPath = snapshotPath + ".meta.json";
                if (!File.Exists(metaPath))
                {
                    return string.Empty;
                }

                string json = File.ReadAllText(metaPath);
                var obj = JsonSerializer.Deserialize<MetaNote>(json);
                if (obj == null)
                {
                    return string.Empty;
                }

                string summary = $"{obj.Note} (User: {obj.Actor}; Cats +{obj.CategoriesAdded}/-{obj.CategoriesRemoved}; Scripts +{obj.ScriptsAdded}/-{obj.ScriptsRemoved})";
                return summary;
            }
            catch { return string.Empty; }
        }

        private static void WriteMeta(string snapshotPath, MetaNote meta)
        {
            string metaPath = snapshotPath + ".meta.json";
            File.WriteAllText(metaPath, JsonSerializer.Serialize(meta, JsonOptions));
        }

        private sealed class MetaNote
        {
            public string Note { get; set; } = string.Empty;
            public string Actor { get; set; } = Environment.UserName;
            public int CategoriesAdded { get; set; }
            public int CategoriesRemoved { get; set; }
            public int ScriptsAdded { get; set; }
            public int ScriptsRemoved { get; set; }
            public List<string> ItemsAdded { get; set; } = [];
            public List<string> ItemsRemoved { get; set; } = [];
        }

        public record SnapshotMeta(string Actor, int CategoriesAdded, int CategoriesRemoved, int ScriptsAdded, int ScriptsRemoved, List<string> ItemsAdded, List<string> ItemsRemoved, string Note);

        /// <summary>
        /// Reads snapshot metadata from the sidecar file.
        /// </summary>
        /// <param name="snapshotPath">Path to the snapshot JSON file (used to resolve sidecar).</param>
        /// <returns>SnapshotMeta if available; null otherwise.</returns>
        public static SnapshotMeta? ReadMeta(string snapshotPath)
        {
            try
            {
                string metaPath = snapshotPath + ".meta.json";
                if (!File.Exists(metaPath))
                {
                    // Fallback: synthesize meta by comparing to previous snapshot in same folder
                    string dir = Path.GetDirectoryName(snapshotPath)!;
                    List<string> files = Directory.GetFiles(dir, "scripts-*.json").OrderBy(f => ParseTimestamp(Path.GetFileName(f))).ToList();
                    int idx = files.FindIndex(f => string.Equals(f, snapshotPath, StringComparison.OrdinalIgnoreCase));
                    string? prevPath = idx > 0 ? files[idx - 1] : null;
                    try
                    {
                        var scope = dir.EndsWith(Path.Combine("history", "user"), StringComparison.OrdinalIgnoreCase) ? ConfigScope.User : ConfigScope.Global;
                        string currentJson = File.ReadAllText(snapshotPath);
                        var current = JsonSerializer.Deserialize<AppConfig>(currentJson) ?? new AppConfig();
                        AppConfig prev;
                        if (!string.IsNullOrEmpty(prevPath) && File.Exists(prevPath))
                        {
                            string pj = File.ReadAllText(prevPath);
                            prev = JsonSerializer.Deserialize<AppConfig>(pj) ?? new AppConfig();
                        }
                        else
                        {
                            prev = new AppConfig();
                        }

                        // Compute diff prev -> current
                        HashSet<string> oldCats = prev.Categories.Where(c => c.Scope == scope).Select(c => c.Name).ToHashSet();
                        HashSet<string> newCats = current.Categories.Where(c => c.Scope == scope).Select(c => c.Name).ToHashSet();
                        List<string> catAdded = newCats.Except(oldCats).ToList();
                        List<string> catRemoved = oldCats.Except(newCats).ToList();

                        static string Key(ScriptItem s)
                        {
                            return $"{s.Scope}:{s.Category}|{s.DisplayName}";
                        }

                        HashSet<string> oldScr = prev.Scripts.Where(s => s.Scope == scope).Select(Key).ToHashSet();
                        HashSet<string> newScr = current.Scripts.Where(s => s.Scope == scope).Select(Key).ToHashSet();
                        List<string> scrAdded = newScr.Except(oldScr).ToList();
                        List<string> scrRemoved = oldScr.Except(newScr).ToList();

                        MetaNote synth = new()
                        {
                            Note = string.Empty,
                            CategoriesAdded = catAdded.Count,
                            CategoriesRemoved = catRemoved.Count,
                            ScriptsAdded = scrAdded.Count,
                            ScriptsRemoved = scrRemoved.Count,
                            ItemsAdded = [.. catAdded, .. scrAdded],
                            ItemsRemoved = [.. catRemoved, .. scrRemoved]
                        };
                        WriteMeta(snapshotPath, synth);
                    }
                    catch { }
                    if (!File.Exists(metaPath))
                    {
                        return null;
                    }
                }
                string json = File.ReadAllText(metaPath);
                var obj = JsonSerializer.Deserialize<MetaNote>(json);
                return obj == null
                    ? null
                    : new SnapshotMeta(obj.Actor, obj.CategoriesAdded, obj.CategoriesRemoved, obj.ScriptsAdded, obj.ScriptsRemoved, obj.ItemsAdded, obj.ItemsRemoved, obj.Note);
            }
            catch { return null; }
        }

        private static MetaNote ComputeMeta(string liveConfigPath, AppConfig newConfig, ConfigScope scope, string note)
        {
            try
            {
                AppConfig oldConfig;
                if (File.Exists(liveConfigPath))
                {
                    string json = File.ReadAllText(liveConfigPath);
                    oldConfig = JsonSerializer.Deserialize<AppConfig>(json) ?? new AppConfig();
                }
                else
                {
                    oldConfig = new AppConfig();
                }

                HashSet<string> oldCats = oldConfig.Categories.Where(c => c.Scope == scope).Select(c => c.Name).ToHashSet();
                HashSet<string> newCats = newConfig.Categories.Where(c => c.Scope == scope).Select(c => c.Name).ToHashSet();
                List<string> catAdded = newCats.Except(oldCats).ToList();
                List<string> catRemoved = oldCats.Except(newCats).ToList();

                static string Key(ScriptItem s)
                {
                    return $"{s.Scope}:{s.Category}|{s.DisplayName}";
                }

                HashSet<string> oldScr = oldConfig.Scripts.Where(s => s.Scope == scope).Select(Key).ToHashSet();
                HashSet<string> newScr = newConfig.Scripts.Where(s => s.Scope == scope).Select(Key).ToHashSet();
                List<string> scrAdded = newScr.Except(oldScr).ToList();
                List<string> scrRemoved = oldScr.Except(newScr).ToList();

                return new MetaNote
                {
                    Note = note,
                    CategoriesAdded = catAdded.Count,
                    CategoriesRemoved = catRemoved.Count,
                    ScriptsAdded = scrAdded.Count,
                    ScriptsRemoved = scrRemoved.Count,
                    ItemsAdded = [.. catAdded, .. scrAdded],
                    ItemsRemoved = [.. catRemoved, .. scrRemoved]
                };
            }
            catch
            {
                return new MetaNote { Note = note };
            }
        }

        private static string GetHistoryDirForScope(string liveConfigPath, ConfigScope scope)
        {
            if (scope == ConfigScope.User)
            {
                string root = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "ScriptLauncher", "history", "user");
                return root;
            }
            else
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                return Path.Combine(baseDir, "config", "history", "global");
            }
        }
    }
}
