# smash

Take a fullscreen screenshot, composite `smash.png` centered on top, and display it fullscreen. Press `Esc` or `q` to exit.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/kenseehart/smash/main/install.sh | bash
```

This installs to `~/.local/share/smash/` and creates a `smash` launcher in `~/.local/bin/`.

Override location with `SMASH_PREFIX=/some/path` or pin a ref with `SMASH_REF=v0.1.0`.

## Run

```bash
smash
```

## Uninstall

```bash
rm -rf ~/.local/share/smash ~/.local/bin/smash
```
