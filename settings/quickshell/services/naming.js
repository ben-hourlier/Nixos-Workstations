.pragma library

// Human-readable name of a window. Pure functions, so tests run them under node.
//
// A window is named after its desktop entry. A terminal is named after the
// program in its foreground, itself named after its desktop entry when it has
// one; an idle terminal keeps the terminal's name.

const shells = ["sh", "bash", "zsh", "fish", "dash", "ksh", "tcsh", "nu", "xonsh"];
const interpreters = ["python", "node", "bun", "deno", "perl", "ruby", "lua", "luajit", "java"];

function basename(path) {
    return String(path).split("/").pop();
}

// Nix wrappers run `.name-wrapped`; login shells run as `-name`.
function unwrap(name) {
    const wrapped = name.match(/^\.(.+)-wrapped$/);
    return (wrapped ? wrapped[1] : name).replace(/^-/, "");
}

function family(name) {
    return name.replace(/[\d.]+$/, "");
}

// Program a command line runs: "" for a bare shell.
function program(cmdline) {
    if (!cmdline || cmdline.length === 0)
        return "";
    const name = unwrap(basename(cmdline[0]));
    const args = cmdline.slice(1);

    if (name === "env") {
        const rest = args.findIndex(a => !a.startsWith("-") && !a.includes("="));
        return rest < 0 ? "" : program(args.slice(rest));
    }

    const kind = family(name);
    if (shells.includes(kind) || interpreters.includes(kind)) {
        const module = args.indexOf("-m");
        if (module >= 0 && args[module + 1])
            return args[module + 1].split(".")[0];
        if (args.includes("-c"))
            return shells.includes(kind) ? "" : kind;
        const script = args.find(a => !a.startsWith("-"));
        if (!script)
            return shells.includes(kind) ? "" : kind;
        return unwrap(basename(script)).replace(/\.(py|js|mjs|cjs|ts|pl|rb|lua|sh|bash|zsh|jar)$/, "");
    }
    return name;
}

// Program in the foreground of a terminal window: the process group leader,
// started first, so the lowest pid.
function foreground(processes) {
    if (!processes || processes.length === 0)
        return null;
    const leader = [...processes].sort((a, b) => a.pid - b.pid)[0];
    return program(leader.cmdline);
}

// Fallback when the terminal cannot be asked: its title starts with the
// command, unless it is a prompt (user@host:dir, a path).
function fromTitle(title) {
    const first = String(title ?? "").trim().split(/\s+/).find(t => /[A-Za-z0-9À-ɏ~\/]/.test(t)) ?? "";
    if (first === "" || /[@~\/]/.test(first))
        return "";
    const word = first.match(/[A-Za-z0-9À-ɏ][\wÀ-ɏ.+-]*/);
    return word ? word[0].replace(/[:.]+$/, "").toLowerCase() : "";
}

function pretty(name) {
    const short = String(name).replace(/\s+(wrapper|launcher)$/i, "").trim();
    return short.charAt(0).toUpperCase() + short.slice(1);
}

// Window shown by a kitty instance: the focused OS window, else the one whose
// title Hyprland reports. `ls` is the output of `kitten @ ls`.
function kittyWindow(ls, title) {
    const shown = [];
    for (const os of ls ?? []) {
        const tab = (os.tabs ?? []).find(t => t.is_active) ?? os.tabs?.[0];
        const win = (tab?.windows ?? []).find(w => w.is_active) ?? tab?.windows?.[0];
        if (win)
            shown.push({ focused: os.is_focused, title: win.title, processes: win.foreground_processes });
    }
    return shown.find(w => w.focused) ?? shown.find(w => w.title === title) ?? (shown.length === 1 ? shown[0] : null);
}

// window: { appId, title, processes } — processes are the foreground processes
// of a terminal ([{ pid, cmdline }]), null when unknown.
// lookup(id): { name, terminal } of the desktop entry matching id, or null.
function windowName(window, lookup) {
    const appId = window.appId ?? "";
    if (appId === "" && !window.title)
        return "";
    const entry = appId !== "" ? lookup(appId) : null;

    if (entry?.terminal) {
        const prog = window.processes ? foreground(window.processes) : fromTitle(window.title);
        if (!prog)
            return pretty(entry.name);
        const app = lookup(prog);
        return pretty(app && !app.terminal ? app.name : prog);
    }
    if (entry)
        return pretty(entry.name);
    return pretty(appId.split(".").pop() || window.title);
}
