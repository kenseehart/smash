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

echo ">> installing python deps (mss, Pillow)"
PY="${SMASH_PYTHON:-python3}"
install_deps() {
  $PY -m pip install --user --quiet --upgrade mss Pillow 2>/dev/null && return 0
  $PY -m pip install --user --break-system-packages --quiet --upgrade mss Pillow 2>/dev/null && return 0
  return 1
}
if ! install_deps; then
  echo ">> ERROR: could not install mss/Pillow with $PY -m pip."
  echo "   Install manually, then re-run, e.g.:"
  echo "     $PY -m pip install --user mss Pillow"
  echo "   or: pipx install mss && pipx install Pillow"
  exit 1
fi

cat > "$BIN_DIR/smash" <<EOF
#!/usr/bin/env bash
exec $PY "$SHARE_DIR/smash.py" "\$@"
EOF
chmod +x "$BIN_DIR/smash"

echo ">> installed:"
echo "   $SHARE_DIR/smash.py"
echo "   $SHARE_DIR/smash.png"
echo "   $BIN_DIR/smash"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo ">> NOTE: $BIN_DIR is not on \$PATH; add it to use 'smash' directly." ;;
esac
