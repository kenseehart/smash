# smash

Take a fullscreen screenshot, composite `smash.png` centered on top, and display it fullscreen. Press `Esc` or `q` to exit.

## Install

```bash
curl -fsSL https://github.com/kenseehart/smash/archive/refs/heads/main.tar.gz | tar xz -C /tmp && bash /tmp/smash-main/install.sh
```

This installs `smash.py` and `smash.png` to `~/.local/share/smash/` and creates a `smash` launcher in `~/.local/bin/`.

What it does, in order:
1. Drops `smash.py` and `smash.png` into `~/.local/share/smash/`.
2. Picks a Python with `tkinter` available (honours `$SMASH_PYTHON`, otherwise probes `python3`, `/usr/bin/python3*`).
3. If none have `tkinter`, installs [`uv`](https://docs.astral.sh/uv/) (if missing) and uses `uv python install 3.12` to drop a self-contained CPython into `~/.local/share/uv/python/`. **No `sudo`, no `apt`.** That standalone Python ships with `tkinter` built in.
4. Creates a private venv at `~/.local/share/smash/.venv/` from that interpreter, and `uv pip install`s `mss` and `Pillow` into it.
5. Writes a `smash` wrapper that execs the venv python on `smash.py`.

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
