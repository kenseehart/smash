# smash

Take a fullscreen screenshot, composite `smash.png` centered on top, and display it fullscreen. Press `Esc` or `q` to exit.

## Install

```bash
curl -fsSL https://github.com/kenseehart/smash/archive/refs/heads/main.tar.gz | tar xz -C /tmp && bash /tmp/smash-main/install.sh
```

This installs `smash.py` and `smash.png` to `~/.local/share/smash/` and creates a `smash` launcher in `~/.local/bin/`. It also installs `mss` and `Pillow` via pip.

Pin a tagged release:

```bash
curl -fsSL https://github.com/kenseehart/smash/archive/refs/tags/v0.1.0.tar.gz | tar xz -C /tmp && bash /tmp/smash-0.1.0/install.sh
```

Environment overrides:
- `SMASH_PREFIX=/some/path` — install root (default `~/.local`)
- `SMASH_PYTHON=/path/to/python3` — python interpreter to use (default `python3`)

## Run

```bash
smash
```

## Uninstall

```bash
rm -rf ~/.local/share/smash ~/.local/bin/smash
```
