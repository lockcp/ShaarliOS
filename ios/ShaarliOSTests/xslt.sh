#!/bin/sh
cd "$(dirname "$0")"

for src in testdata/*/*.html
do
  echo "==== $src ==========================="
  base="$(dirname "$src")/$(basename "$src" .html)"
  xsltproc --html --output "$base.xml" response.xslt "$src"
  cat "$base.xml" ; rm "$base.xml"
done
