#!/usr/bin/env python3

import os
import sys
import subprocess

try:
    import tkinter as tk
except ImportError:
    sys.stderr.write(
        "tkinter is required but not available.\n"
        "  - Linux (Debian/Ubuntu): sudo apt install python3-tk\n"
        "  - macOS (Homebrew):       brew install python-tk\n"
        "  - Windows:                use the official python.org installer\n"
        "  - Or run smash via the bundled installer, which uses uv to fetch\n"
        "    a self-contained CPython that ships with tkinter.\n"
    )
    raise


def _ensure_pip() -> None:
    py = sys.executable
    if subprocess.call(
        [py, "-m", "pip", "--version"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ) == 0:
        return
    print("pip not available; bootstrapping...")
    if subprocess.call([py, "-m", "ensurepip", "--upgrade", "--default-pip"]) == 0:
        return
    import urllib.request

    print("ensurepip unavailable; fetching get-pip.py...")
    with urllib.request.urlopen("https://bootstrap.pypa.io/get-pip.py") as r:
        get_pip = r.read()
    if subprocess.run([py], input=get_pip).returncode != 0:
        raise RuntimeError(
            f"could not bootstrap pip for {py}; "
            f"install pip manually and retry"
        )


def _autoinstall(pkg: str) -> None:
    print(f"{pkg} not found, installing...")
    _ensure_pip()
    py = sys.executable
    in_venv = sys.prefix != sys.base_prefix
    user_flag = [] if in_venv else ["--user"]
    attempts = [
        [py, "-m", "pip", "install", *user_flag, pkg],
        [py, "-m", "pip", "install", *user_flag, "--break-system-packages", pkg],
    ]
    for cmd in attempts:
        if subprocess.call(cmd) == 0:
            return
    raise RuntimeError(
        f"failed to autoinstall {pkg}; install manually with: "
        f"{py} -m pip install {pkg}"
    )


try:
    import mss
except ImportError:
    _autoinstall("mss")
    import mss

try:
    from PIL import Image, ImageTk
except ImportError:
    _autoinstall("Pillow")
    from PIL import Image, ImageTk


PNG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "smash.png")


def load_png(path: str) -> Image.Image:
    return Image.open(path).convert("RGBA")


def pick_active_monitor(sct: "mss.base.MSSBase") -> dict:
    """Return the monitor dict for the screen the user is currently on.

    Strategy: pick the monitor containing the mouse cursor; if that fails,
    fall back to the first non-union monitor (mss `monitors[0]` is the union
    of all displays, which is what we want to avoid).
    """
    physicals = sct.monitors[1:] if len(sct.monitors) > 1 else sct.monitors
    try:
        r = tk.Tk()
        r.withdraw()
        r.update_idletasks()
        cx, cy = r.winfo_pointerx(), r.winfo_pointery()
        r.destroy()
        for m in physicals:
            if (m["left"] <= cx < m["left"] + m["width"]
                    and m["top"] <= cy < m["top"] + m["height"]):
                return m
    except Exception:
        pass
    for m in physicals:
        if m.get("is_primary"):
            return m
    return physicals[0]


def take_screenshot(monitor: dict) -> Image.Image:
    with mss.MSS() as sct:
        shot = sct.grab(monitor)
        return Image.frombytes("RGB", shot.size, shot.rgb).convert("RGBA")


def composite_full(background: Image.Image, overlay: Image.Image) -> Image.Image:
    """Scale overlay to the size of background and alpha-composite."""
    scaled = overlay.resize(background.size, Image.LANCZOS)
    result = background.copy()
    result.alpha_composite(scaled)
    return result


def show_on_monitor(image: Image.Image, monitor: dict) -> None:
    root = tk.Tk()
    root.overrideredirect(True)
    root.geometry(
        f"{monitor['width']}x{monitor['height']}"
        f"+{monitor['left']}+{monitor['top']}"
    )
    root.attributes("-topmost", True)
    root.configure(background="black")

    root.bind("<Escape>", lambda event: root.destroy())
    root.bind("q", lambda event: root.destroy())

    photo = ImageTk.PhotoImage(image)

    label = tk.Label(root, image=photo, borderwidth=0, highlightthickness=0)
    label.image = photo
    label.pack(expand=True, fill="both")

    root.focus_force()
    root.mainloop()


def main() -> None:
    overlay = load_png(PNG_PATH)
    with mss.MSS() as sct:
        monitor = pick_active_monitor(sct)
    screenshot = take_screenshot(monitor)
    result = composite_full(screenshot, overlay)
    show_on_monitor(result, monitor)


if __name__ == "__main__":
    main()
