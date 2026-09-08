import { mkdirSync, readdirSync, writeFileSync, unlinkSync, watch } from "node:fs";
import { join } from "node:path";
import { scanApps, appDirs, type AppEntry } from "./desktop";

export const stubDir = join(process.env.HOME ?? "", ".cache/baikonur/apps");

export class AppIndex {
  byStub = new Map<string, AppEntry>();
  onChange: () => void = () => {};

  constructor() {
    mkdirSync(stubDir, { recursive: true });
    this.sync();
    for (const dir of appDirs) {
      try {
        watch(dir, () => this.scheduleSync());
      } catch {}
    }
  }

  private timer: ReturnType<typeof setTimeout> | null = null;
  private scheduleSync() {
    if (this.timer) clearTimeout(this.timer);
    this.timer = setTimeout(() => this.sync(), 500);
  }

  sync() {
    const apps = scanApps();
    const wanted = new Map<string, AppEntry>();
    for (const app of apps) {
      let stub = `${app.name.replace(/[\/\0]/g, " ")}.app`;
      if (wanted.has(stub)) stub = `${app.name} (${app.id}).app`;
      wanted.set(stub, app);
    }
    const existing = new Set(readdirSync(stubDir));
    for (const stub of existing) if (!wanted.has(stub)) unlinkSync(join(stubDir, stub));
    for (const [stub, app] of wanted) {
      if (!existing.has(stub)) writeFileSync(join(stubDir, stub), app.id + "\n");
    }
    this.byStub = wanted;
    this.onChange();
  }

  fromStub(relativePath: string): AppEntry | undefined {
    return this.byStub.get(relativePath);
  }

  byId(id: string): AppEntry | undefined {
    for (const app of this.byStub.values()) if (app.id === id) return app;
    return undefined;
  }
}
