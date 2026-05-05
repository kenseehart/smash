# smash

Take a fullscreen screenshot, composite `smash.png` centered on top, and display it fullscreen. Press `Esc` or `q` to exit.

## Install

### Linux / macOS

```bash
curl -fsSL https://github.com/kenseehart/smash/archive/refs/heads/main.tar.gz | tar xz -C /tmp && bash /tmp/smash-main/install.sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/kenseehart/smash/main/install.ps1 | iex
```

### What it does

1. Drops `smash.py` and `smash.png` into `<prefix>/share/smash/` (Linux/macOS prefix `~/.local`, Windows `~\.local`).
2. Picks a Python with `tkinter` available (honours `SMASH_PYTHON`, otherwise probes `python3` / `python` / `py` and common system paths).
3. If none have `tkinter`, installs [`uv`](https://docs.astral.sh/uv/) (sandboxed, no admin/sudo) and runs `uv python install 3.12` to drop a self-contained CPython that ships with `tkinter` and `pip` baked in.
4. Creates a private venv at `<prefix>/share/smash/.venv/` from that interpreter, and `uv pip install`s `mss` and `Pillow` into it.
5. Writes a launcher (`smash` shell wrapper on Linux/macOS, `smash.cmd` on Windows) that execs the venv python on `smash.py`.

### Pin a tagged release

```bash
# Linux / macOS
curl -fsSL https://github.com/kenseehart/smash/archive/refs/tags/v0.1.0.tar.gz | tar xz -C /tmp && bash /tmp/smash-0.1.0/install.sh
```

```powershell
# Windows
$env:SMASH_REF='v0.1.0'; irm https://raw.githubusercontent.com/kenseehart/smash/v0.1.0/install.ps1 | iex
```

### Environment overrides

- `SMASH_PREFIX` — install root (default `~/.local` on all OSes)
- `SMASH_PYTHON` — python interpreter to use (default: auto-detect)
- `SMASH_REF` — git ref / tag to install from (default `main`)

## Run

```bash
smash
```

## Uninstall

```bash
# Linux / macOS
rm -rf ~/.local/share/smash ~/.local/bin/smash
```

```powershell
# Windows
Remove-Item -Recurse -Force "$env:USERPROFILE\.local\share\smash"
Remove-Item -Force "$env:USERPROFILE\.local\bin\smash.cmd"
```
