#!/bin/sh
# firenvim#install が生成する wrapper に NVIM_APPNAME=firenvim-nvim を注入する
# wrapper は exec nvim ... を呼ぶ shell script で、その前に export を差し込む
set -eu

WRAPPER="${HOME}/.local/share/firenvim/firenvim"
APPNAME="firenvim-nvim"

if [ ! -f "$WRAPPER" ]; then
  echo "Error: wrapper not found at $WRAPPER" >&2
  echo "Run firenvim#install(0) first." >&2
  exit 1
fi

if grep -q "NVIM_APPNAME=${APPNAME}" "$WRAPPER"; then
  echo "Already patched: $WRAPPER"
  exit 0
fi

TMP="$(mktemp)"
awk -v appname="$APPNAME" '
  NR==1 {
    print
    if ($0 ~ /^#!/) {
      print "export NVIM_APPNAME=" appname
      injected=1
    }
    next
  }
  NR==2 && !injected {
    print "export NVIM_APPNAME=" appname
    injected=1
  }
  { print }
' "$WRAPPER" > "$TMP"

chmod +x "$TMP"
mv "$TMP" "$WRAPPER"
echo "Patched: $WRAPPER"
