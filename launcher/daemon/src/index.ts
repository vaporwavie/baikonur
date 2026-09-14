import { FileFinder, type FileFinderApi } from "@ff-labs/fff-bun";
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { AppIndex, stubDir } from "./apps";

const home = process.env.HOME ?? "";
const dataDir = join(home, ".local/share/baikonur");
mkdirSync(dataDir, { recursive: true });
const port = Number(process.env.BAIKONUR_PORT ?? 47421);

type Item = { id: string; kind: "app" | "file"; title: string; subtitle: string; icon: string };
type Section = { title: string; icon: string; items: Item[] };

function finder(basePath: string, name: string, extra: object = {}): FileFinderApi {
  const created = FileFinder.create({
    basePath,
    frecencyDbPath: join(dataDir, `${name}-frecency.db`),
    historyDbPath: join(dataDir, `${name}-history.db`),
    disableContentIndexing: true,
    ...extra,
  });
  if (!created.ok) throw new Error(`${name}: ${created.error}`);
  return created.value;
}

const apps = new AppIndex();
const appFinder = finder(stubDir, "apps", { disableWatch: false });
apps.onChange = () => appFinder.scanFiles();
const fileFinder = finder(home, "files", { enableHomeDirScanning: true });

function appItem(relativePath: string): Item | null {
  const app = apps.fromStub(relativePath);
  if (!app) return null;
  return { id: app.id, kind: "app", title: app.name, subtitle: app.comment, icon: app.icon };
}

const pinsPath = join(home, ".config/baikonur/pins.json");
function pins(): string[] {
  try { return JSON.parse(require("node:fs").readFileSync(pinsPath, "utf8")); } catch { return []; }
}

function favorites(limit = 6): Section {
  const res = appFinder.fileSearch("", { pageSize: 200 });
  const items: Item[] = [];
  for (const id of pins()) {
    const app = apps.byId(id);
    if (app) items.push({ id: app.id, kind: "app", title: app.name, subtitle: app.comment, icon: app.icon });
  }
  if (res.ok) {
    const sorted = [...res.value.items].sort((a, b) => b.totalFrecencyScore - a.totalFrecencyScore);
    for (const f of sorted) {
      if (items.length >= limit) break;
      const item = appItem(f.relativePath);
      if (item && !items.some(i => i.id === item.id)) items.push(item);
    }
  }
  return { title: "Favorite apps", icon: "starred-symbolic", items };
}

function search(text: string): Section[] {
  const sections: Section[] = [];
  const appRes = appFinder.fileSearch(text, { pageSize: 8 });
  const appItems: Item[] = [];
  if (appRes.ok) for (const f of appRes.value.items) { const i = appItem(f.relativePath); if (i) appItems.push(i); }
  const lower = text.toLowerCase();
  for (const app of apps.byStub.values()) {
    if (appItems.length >= 8) break;
    if (appItems.some(i => i.id === app.id)) continue;
    if (app.comment.toLowerCase().includes(lower) || app.keywords.some(k => k.toLowerCase().includes(lower)))
      appItems.push({ id: app.id, kind: "app", title: app.name, subtitle: app.comment, icon: app.icon });
  }
  if (appItems.length) sections.push({ title: "Applications", icon: "applications-all-symbolic", items: appItems });
  if (text.length >= 3) {
    const fileRes = fileFinder.fileSearch(text, { pageSize: 8 });
    if (fileRes.ok && fileRes.value.items.length) {
      sections.push({
        title: "Files",
        icon: "folder-symbolic",
        items: fileRes.value.items.map(f => ({
          id: join(home, f.relativePath),
          kind: "file",
          title: f.fileName,
          subtitle: "~/" + f.relativePath,
          icon: "text-x-generic",
        })),
      });
    }
  }
  return sections;
}

function launch(kind: string, id: string, query: string, spawn = true) {
  if (kind === "app") {
    const app = apps.byId(id);
    if (!app) return false;
    for (const [stub, a] of apps.byStub) if (a.id === id) appFinder.trackQuery(query, stub);
    if (spawn) Bun.spawn(["kioclient", "exec", app.path], { stdout: "ignore", stderr: "ignore" }).unref();
    return true;
  }
  fileFinder.trackQuery(query, id.startsWith(home + "/") ? id.slice(home.length + 1) : id);
  Bun.spawn(["xdg-open", id], { stdout: "ignore", stderr: "ignore" }).unref();
  return true;
}

const json = (body: unknown) => Response.json(body, { headers: { "access-control-allow-origin": "*" } });

Bun.serve({
  hostname: "127.0.0.1",
  port,
  async fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === "/q") {
      const text = (url.searchParams.get("text") ?? "").trim();
      return json({ sections: text ? search(text) : [favorites()] });
    }
    if (url.pathname === "/launch" && req.method === "POST") {
      const body = (await req.json()) as { kind: string; id: string; query?: string; spawn?: boolean };
      return json({ ok: launch(body.kind, body.id, body.query ?? "", body.spawn ?? true) });
    }
    if (url.pathname === "/health") {
      return json({ apps: apps.byStub.size, files: fileFinder.getScanProgress() });
    }
    return new Response("not found", { status: 404 });
  },
});
console.log(`baikonur daemon on http://127.0.0.1:${port}, ${apps.byStub.size} apps`);
