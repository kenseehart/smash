#!/usr/bin/env python3

import os
import tkinter as tk
import subprocess

try:
    import mss
except ImportError:
    print("mss not found, installing...")
    subprocess.run(["pip", "install", "mss"])
    import mss

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
