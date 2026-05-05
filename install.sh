#!/usr/bin/env bash
set -euo pipefail

REPO="kenseehart/smash"
REF="${SMASH_REF:-main}"
PREFIX="${SMASH_PREFIX:-$HOME/.local}"
SHARE_DIR="$PREFIX/share/smash"
BIN_DIR="$PREFIX/bin"
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

has_tkinter() {
  command -v "$1" >/dev/null 2>&1 && "$1" -c "import tkinter" >/dev/null 2>&1
}

pick_python() {
  local candidates=()
  [ -n "${SMASH_PYTHON:-}" ] && candidates+=("$SMASH_PYTHON")
  candidates+=(python3 /usr/bin/python3 /usr/bin/python3.12 /usr/bin/python3.11 /usr/bin/python3.10)
  for py in "${candidates[@]}"; do
    if has_tkinter "$py"; then
      echo "$py"
      return 0
    fi
  done

  echo ">> no python with tkinter found; falling back to uv-managed python (no sudo)" >&2
  PATH="$HOME/.local/bin:$PATH"
  if ! command -v uv >/dev/null 2>&1; then
    echo ">> installing uv..." >&2
    curl -fsSL https://astral.sh/uv/install.sh | sh >&2
    PATH="$HOME/.local/bin:$PATH"
  fi
  echo ">> installing managed cpython 3.12 via uv (includes tkinter + pip)..." >&2
  uv python install 3.12 >&2
  local managed="$HOME/.local/bin/python3.12"
  if has_tkinter "$managed"; then
    echo "$managed"
    return 0
  fi
  echo ">> ERROR: uv-managed python at $managed lacks tkinter" >&2
  return 1
}

PY="$(pick_python)"
echo ">> selected python: $PY"

cat > "$BIN_DIR/smash" <<EOF
#!/usr/bin/env bash
exec "$PY" "$SHARE_DIR/smash.py" "\$@"
EOF
chmod +x "$BIN_DIR/smash"

echo ">> installed:"
echo "   $SHARE_DIR/smash.py"
echo "   $SHARE_DIR/smash.png"
echo "   $BIN_DIR/smash"
echo ">> python deps (mss, Pillow) will auto-install on first run."
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo ">> NOTE: $BIN_DIR is not on \$PATH; add it to use 'smash' directly." ;;
esac
