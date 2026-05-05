#!/usr/bin/env python3

import os
import sys
import subprocess

try:
    import tkinter as tk
except ImportError:
    sys.stderr.write(
        "tkinter is required but not available. "
        "On Debian/Ubuntu install with: sudo apt install python3-tk\n"
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


def take_screenshot() -> Image.Image:
    with mss.mss() as sct:
        monitor = sct.monitors[0]
        shot = sct.grab(monitor)
        return Image.frombytes("RGB", shot.size, shot.rgb).convert("RGBA")


def composite_centered(background: Image.Image, overlay: Image.Image) -> Image.Image:
    result = background.copy()

    x = (background.width - overlay.width) // 2
    y = (background.height - overlay.height) // 2

    result.alpha_composite(overlay, (x, y))
    return result


def show_fullscreen(image: Image.Image) -> None:
    root = tk.Tk()
    root.attributes("-fullscreen", True)
    root.configure(background="black")

    root.bind("<Escape>", lambda event: root.destroy())
    root.bind("q", lambda event: root.destroy())

    photo = ImageTk.PhotoImage(image)

    label = tk.Label(root, image=photo, borderwidth=0, highlightthickness=0)
    label.image = photo
    label.pack(expand=True)

    root.mainloop()


def main() -> None:
    overlay = load_png(PNG_PATH)
    screenshot = take_screenshot()
    result = composite_centered(screenshot, overlay)
    show_fullscreen(result)


if __name__ == "__main__":
    main()
