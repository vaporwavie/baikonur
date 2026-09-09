function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(value, maximum));
}

function scaleWindow(factor) {
    const window = workspace.activeWindow;
    if (!window || !window.resizeable || window.specialWindow || window.fullScreen) {
        return;
    }

    const frame = window.frameGeometry;
    const original = { x: frame.x, y: frame.y, width: frame.width, height: frame.height };
    const area = workspace.clientArea(KWin.MaximizeArea, window);
    const borderWidth = frame.width - window.clientGeometry.width;
    const borderHeight = frame.height - window.clientGeometry.height;
    const minWidth = Math.max(1, window.minSize.width + borderWidth);
    const minHeight = Math.max(1, window.minSize.height + borderHeight);
    const maxWidth = Math.max(minWidth, Math.min(area.width, window.maxSize.width + borderWidth));
    const maxHeight = Math.max(minHeight, Math.min(area.height, window.maxSize.height + borderHeight));
    const width = clamp(Math.round(original.width * factor), minWidth, maxWidth);
    const height = clamp(Math.round(original.height * factor), minHeight, maxHeight);

    if (width === original.width && height === original.height) {
        return;
    }

    if (window.tile) {
        window.tile = null;
    }
    window.setMaximize(false, false);
    window.frameGeometry = {
        x: clamp(original.x + (original.width - width) / 2, area.x, area.x + area.width - width),
        y: clamp(original.y + (original.height - height) / 2, area.y, area.y + area.height - height),
        width: width,
        height: height
    };
}

// KWin consumes Shift when the US layout turns = and - into + and _.
registerShortcut("baikonur-window-grow", "Grow Window Proportionally", "Alt++", function () {
    scaleWindow(1.1);
});

registerShortcut("baikonur-window-shrink", "Shrink Window Proportionally", "Alt+_", function () {
    scaleWindow(1 / 1.1);
});
