import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, basename } from "node:path";

export type AppEntry = {
  id: string;
  path: string;
  name: string;
  comment: string;
  icon: string;
  keywords: string[];
};

const home = process.env.HOME ?? "";
export const appDirs = [
  join(home, ".local/share/applications"),
  join(home, ".local/share/flatpak/exports/share/applications"),
  "/var/lib/flatpak/exports/share/applications",
  "/usr/local/share/applications",
  "/usr/share/applications",
].filter(existsSync);

function parse(path: string): AppEntry | null {
  const text = readFileSync(path, "utf8");
  const start = text.indexOf("[Desktop Entry]");
  if (start < 0) return null;
  const body = text.slice(start + 15);
  const end = body.search(/^\[/m);
  const section = end < 0 ? body : body.slice(0, end);
  const kv = new Map<string, string>();
  for (const line of section.split("\n")) {
    const eq = line.indexOf("=");
    if (eq < 0 || line.startsWith("#")) continue;
    kv.set(line.slice(0, eq).trim(), line.slice(eq + 1).trim());
  }
  if (kv.get("Type") !== "Application") return null;
  if (kv.get("NoDisplay") === "true" || kv.get("Hidden") === "true") return null;
  const onlyShowIn = kv.get("OnlyShowIn");
  if (onlyShowIn && !onlyShowIn.split(";").includes("KDE")) return null;
  const notShowIn = kv.get("NotShowIn");
  if (notShowIn && notShowIn.split(";").includes("KDE")) return null;
  const name = kv.get("Name");
  if (!name) return null;
  return {
    id: basename(path),
    path,
    name,
    comment: kv.get("Comment") ?? kv.get("GenericName") ?? "",
    icon: kv.get("Icon") ?? "application-x-executable",
    keywords: (kv.get("Keywords") ?? "").split(";").filter(Boolean),
  };
}

export function scanApps(): AppEntry[] {
  const seen = new Map<string, AppEntry>();
  for (const dir of appDirs) {
    for (const file of readdirSync(dir)) {
      if (!file.endsWith(".desktop") || seen.has(file)) continue;
      try {
        const entry = parse(join(dir, file));
        if (entry) seen.set(file, entry);
      } catch {}
    }
  }
  return [...seen.values()];
}
