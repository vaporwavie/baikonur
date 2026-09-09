import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

const script = readFileSync(new URL("./baikonur-window-scale/contents/code/main.js", import.meta.url), "utf8");

function setup(overrides = {}, area = { x: 0, y: 30, width: 1920, height: 1050 }) {
    const shortcuts = new Map();
    const window = {
        resizeable: true,
        specialWindow: false,
        fullScreen: false,
        frameGeometry: { x: 500, y: 300, width: 600, height: 400 },
        clientGeometry: { x: 500, y: 300, width: 600, height: 400 },
        minSize: { width: 100, height: 80 },
        maxSize: { width: 32767, height: 32767 },
        tile: null,
        setMaximize(horizontal, vertical) {
            this.maximized = horizontal || vertical;
        },
        ...overrides
    };
    let geometry = window.frameGeometry;
    const borderWidth = geometry.width - window.clientGeometry.width;
    const borderHeight = geometry.height - window.clientGeometry.height;
    Object.defineProperty(window, "frameGeometry", {
        get: () => geometry,
        set: value => {
            geometry = structuredClone(value);
            window.clientGeometry = { ...geometry, width: geometry.width - borderWidth, height: geometry.height - borderHeight };
        }
    });
    const workspace = { activeWindow: window, clientArea: () => area };
    vm.runInNewContext(script, {
        workspace,
        KWin: { MaximizeArea: 0 },
        registerShortcut: (id, description, key, callback) => shortcuts.set(id, { key, callback })
    });
    return {
        window,
        workspace,
        shortcuts,
        grow: () => shortcuts.get("baikonur-window-grow").callback(),
        shrink: () => shortcuts.get("baikonur-window-shrink").callback()
    };
}

test("registers the shifted symbols used by KWin for the requested US key combinations", () => {
    const { shortcuts } = setup();
    assert.equal(shortcuts.get("baikonur-window-grow").key, "Alt++");
    assert.equal(shortcuts.get("baikonur-window-shrink").key, "Alt+_");
});

test("repeated growth is exponential and keeps the center", () => {
    const { window, grow } = setup();
    grow();
    grow();
    assert.deepEqual(window.frameGeometry, { x: 437, y: 258, width: 726, height: 484 });
});

test("shrink reverses growth within pixel rounding", () => {
    const { window, grow, shrink } = setup();
    const original = structuredClone(window.frameGeometry);
    grow();
    grow();
    shrink();
    shrink();
    assert.deepEqual(window.frameGeometry, original);
});

test("growth stops at the monitor work area without covering panels", () => {
    const { window, grow } = setup();
    for (let i = 0; i < 20; i++) grow();
    assert.deepEqual(window.frameGeometry, { x: 0, y: 30, width: 1920, height: 1050 });
});

test("honors client minimums plus window decorations", () => {
    const { window, shrink } = setup({
        clientGeometry: { x: 504, y: 328, width: 592, height: 368 },
        minSize: { width: 320, height: 240 }
    });
    for (let i = 0; i < 20; i++) shrink();
    assert.equal(window.frameGeometry.width, 328);
    assert.equal(window.frameGeometry.height, 272);
});

test("honors client maximums plus window decorations", () => {
    const { window, grow } = setup({
        clientGeometry: { x: 504, y: 328, width: 592, height: 368 },
        maxSize: { width: 700, height: 500 }
    });
    for (let i = 0; i < 20; i++) grow();
    assert.equal(window.frameGeometry.width, 708);
    assert.equal(window.frameGeometry.height, 532);
});

test("keeps windows within a monitor with negative coordinates", () => {
    const { window, grow } = setup({
        frameGeometry: { x: -620, y: 680, width: 600, height: 400 }
    }, { x: -1920, y: 30, width: 1920, height: 1050 });
    grow();
    assert.deepEqual(window.frameGeometry, { x: -660, y: 640, width: 660, height: 440 });
});

test("retains app minimums larger than the screen and anchors at its origin", () => {
    const { window, shrink } = setup({ minSize: { width: 2200, height: 1200 } });
    shrink();
    assert.deepEqual(window.frameGeometry, { x: 0, y: 30, width: 2200, height: 1200 });
});

test("uses the visible size before restoring a maximized or tiled window", () => {
    const { window, shrink } = setup({
        tile: {},
        maximized: true,
        setMaximize() {
            this.maximized = false;
            this.frameGeometry = { x: 0, y: 30, width: 300, height: 200 };
        }
    });
    shrink();
    assert.equal(window.maximized, false);
    assert.equal(window.tile, null);
    assert.deepEqual(window.frameGeometry, { x: 527.5, y: 318, width: 545, height: 364 });
});

test("does not restore a maximized window when it cannot grow", () => {
    const { window, grow } = setup({
        maximized: true,
        frameGeometry: { x: 0, y: 30, width: 1920, height: 1050 },
        clientGeometry: { x: 0, y: 30, width: 1920, height: 1050 }
    });
    grow();
    assert.equal(window.maximized, true);
});

test("skips fixed-size, special, fullscreen, and absent windows", () => {
    for (const overrides of [{ resizeable: false }, { specialWindow: true }, { fullScreen: true }]) {
        const { window, grow, shrink } = setup(overrides);
        const original = structuredClone(window.frameGeometry);
        grow();
        shrink();
        assert.deepEqual(window.frameGeometry, original);
    }
    const { workspace, grow, shrink } = setup();
    workspace.activeWindow = null;
    assert.doesNotThrow(grow);
    assert.doesNotThrow(shrink);
});
