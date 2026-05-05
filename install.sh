#!/usr/bin/env bash
set -euo pipefail

REPO="kenseehart/smash"
REF="${SMASH_REF:-main}"
PREFIX="${SMASH_PREFIX:-$HOME/.local}"
SHARE_DIR="$PREFIX/share/smash"
BIN_DIR="$PREFIX/bin"
TARBALL_URL="https://github.com/$REPO/archive/$REF.tar.gz"
PY="${SMASH_PYTHON:-python3}"

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

cat > "$BIN_DIR/smash" <<EOF
#!/usr/bin/env bash
exec $PY "$SHARE_DIR/smash.py" "\$@"
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
