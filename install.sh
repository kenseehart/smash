#!/usr/bin/env bash
set -euo pipefail

REPO="kenseehart/smash"
REF="${SMASH_REF:-main}"
PREFIX="${SMASH_PREFIX:-$HOME/.local}"
SHARE_DIR="$PREFIX/share/smash"
BIN_DIR="$PREFIX/bin"
TARBALL_URL="https://github.com/$REPO/archive/$REF.tar.gz"

echo ">> downloading $TARBALL_URL"
mkdir -p "$SHARE_DIR" "$BIN_DIR"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$TARBALL_URL" | tar -xz -C "$tmp" --strip-components=1

cp "$tmp/smash.py"  "$SHARE_DIR/smash.py"
cp "$tmp/smash.png" "$SHARE_DIR/smash.png"
chmod +x "$SHARE_DIR/smash.py"

echo ">> installing python deps (mss, Pillow)"
python3 -m pip install --user --quiet --upgrade mss Pillow

cat > "$BIN_DIR/smash" <<EOF
#!/usr/bin/env bash
exec python3 "$SHARE_DIR/smash.py" "\$@"
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
