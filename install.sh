#!/usr/bin/env bash
set -euo pipefail

REPO="kenseehart/smash"
REF="${SMASH_REF:-main}"
PREFIX="${SMASH_PREFIX:-$HOME/.local}"
SHARE_DIR="$PREFIX/share/smash"
BIN_DIR="$PREFIX/bin"
VENV_DIR="$SHARE_DIR/.venv"
TARBALL_URL="https://github.com/$REPO/archive/$REF.tar.gz"

mkdir -p "$SHARE_DIR" "$BIN_DIR"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$script_dir/smash.py" ] && [ -f "$script_dir/smash.png" ]; then
  echo ">> using local payload from $script_dir"
  src_dir="$script_dir"
else
  echo ">> downloading $TARBALL_URL"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "$TARBALL_URL" | tar -xz -C "$tmp" --strip-components=1
  src_dir="$tmp"
fi

cp "$src_dir/smash.py"  "$SHARE_DIR/smash.py"
cp "$src_dir/smash.png" "$SHARE_DIR/smash.png"
chmod +x "$SHARE_DIR/smash.py"

ensure_uv() {
  PATH="$HOME/.local/bin:$PATH"
  if command -v uv >/dev/null 2>&1; then return 0; fi
  echo ">> installing uv (sandboxed, no sudo)..." >&2
  curl -fsSL https://astral.sh/uv/install.sh | sh >&2
  PATH="$HOME/.local/bin:$PATH"
  command -v uv >/dev/null 2>&1
}

has_tkinter() {
  command -v "$1" >/dev/null 2>&1 && "$1" -c "import tkinter" >/dev/null 2>&1
}

pick_python() {
  local candidates=()
  [ -n "${SMASH_PYTHON:-}" ] && candidates+=("$SMASH_PYTHON")
  candidates+=(
    python3
    /usr/bin/python3
    /usr/bin/python3.12 /usr/bin/python3.11 /usr/bin/python3.10
    /usr/local/bin/python3
    /opt/homebrew/bin/python3
    /Library/Frameworks/Python.framework/Versions/Current/bin/python3
  )
  for py in "${candidates[@]}"; do
    if has_tkinter "$py"; then
      echo "$py"
      return 0
    fi
  done

  echo ">> no system python has tkinter; falling back to uv-managed cpython" >&2
  ensure_uv >&2 || { echo ">> ERROR: failed to install uv" >&2; return 1; }
  echo ">> installing managed cpython 3.12 via uv..." >&2
  uv python install 3.12 >&2
  local managed="$HOME/.local/bin/python3.12"
  has_tkinter "$managed" && { echo "$managed"; return 0; }
  echo ">> ERROR: uv-managed python at $managed lacks tkinter" >&2
  return 1
}

PY="$(pick_python)"
echo ">> base python: $PY"

ensure_uv || { echo ">> ERROR: uv required to create venv" >&2; exit 1; }

echo ">> creating venv at $VENV_DIR"
rm -rf "$VENV_DIR"
uv venv --quiet --python "$PY" "$VENV_DIR"
echo ">> installing mss + Pillow into venv"
uv pip install --quiet --python "$VENV_DIR/bin/python" mss Pillow

VENV_PY="$VENV_DIR/bin/python"
"$VENV_PY" -c "import tkinter, mss, PIL.Image, PIL.ImageTk" \
  && echo ">> verified: tkinter + mss + Pillow available"

cat > "$BIN_DIR/smash" <<EOF
#!/usr/bin/env bash
exec "$VENV_PY" "$SHARE_DIR/smash.py" "\$@"
EOF
chmod +x "$BIN_DIR/smash"

echo ">> installed:"
echo "   $SHARE_DIR/smash.py"
echo "   $SHARE_DIR/smash.png"
echo "   $VENV_DIR/  (mss, Pillow)"
echo "   $BIN_DIR/smash"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo ">> NOTE: $BIN_DIR is not on \$PATH; add it to use 'smash' directly." ;;
esac
