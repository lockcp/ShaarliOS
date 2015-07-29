#!/bin/sh

cd "$(dirname "$0")"

inkscape=/Applications/Inkscape.app/Contents/Resources/bin/inkscape

$inkscape --help >/dev/null 2>&1 || { echo "Inkscape is not installed." && exit 1; }
optipng -help >/dev/null 2>&1 || { echo "optipng is not installed." && exit 1; }

OPTS="--export-area-page --export-width=1024 --export-height=1024 --without-gui"

src="iTunesArtwork.dev.svg"
src="../shaarli-petal.svg"

dst="iTunesArtwork.png"
"$inkscape" --export-png="$(pwd)/$dst" $OPTS --file="$(pwd)/$src"
optipng -o 7 "$(pwd)/$dst" &

dst=iTunesArtwork.svg
cp "$src" "$dst"
# http://stackoverflow.com/a/10492912
$inkscape "$(pwd)/$dst" \
  --select=layer3 --verb=EditDelete \
  --select=g4737 --verb=EditDelete \
  --select=layer2 --verb=EditDelete \
  --select=g3001 --verb=EditDelete \
  --select=layer1 --verb=EditDelete \
  --verb=FileVacuum --verb=FileSave \
  --verb=FileClose --verb=FileQuit
$inkscape $OPTS --vacuum-defs --export-plain-svg="$(pwd)/$dst" --file="$(pwd)/$dst"

img=iPhone-App
siz=60
sips --resampleHeightWidthMax "$(($siz * 1))" iTunesArtwork.png --out "$img.png"
sips --resampleHeightWidthMax "$(($siz * 2))" iTunesArtwork.png --out "$img@2x.png"
sips --resampleHeightWidthMax "$(($siz * 3))" iTunesArtwork.png --out "$img@3x.png"
optipng -o 7 "$img*.png" &

img=iPhone-Settings
siz=29
sips --resampleHeightWidthMax "$(($siz * 1))" iTunesArtwork.png --out "$img.png"
sips --resampleHeightWidthMax "$(($siz * 2))" iTunesArtwork.png --out "$img@2x.png"
sips --resampleHeightWidthMax "$(($siz * 3))" iTunesArtwork.png --out "$img@3x.png"
optipng -o 7 "$img*.png" &

img=iPhone-Spotlight
siz=40
sips --resampleHeightWidthMax "$(($siz * 1))" iTunesArtwork.png --out "$img.png"
sips --resampleHeightWidthMax "$(($siz * 2))" iTunesArtwork.png --out "$img@2x.png"
sips --resampleHeightWidthMax "$(($siz * 3))" iTunesArtwork.png --out "$img@3x.png"
optipng -o 7 "$img*.png" &

img=iPad-App
siz=76
sips --resampleHeightWidthMax "$(($siz * 1))" iTunesArtwork.png --out "$img.png"
sips --resampleHeightWidthMax "$(($siz * 2))" iTunesArtwork.png --out "$img@2x.png"
optipng -o 7 "$img*.png" &

wait