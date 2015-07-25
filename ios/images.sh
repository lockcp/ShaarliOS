#!/bin/sh

cd "$(dirname "$0")"

img=iPhone-App
siz=60
sips --resampleHeightWidthMax "$(($siz * 1))" iTunesArtwork.png --out "$img.png"
sips --resampleHeightWidthMax "$(($siz * 2))" iTunesArtwork.png --out "$img@2x.png"
sips --resampleHeightWidthMax "$(($siz * 3))" iTunesArtwork.png --out "$img@3x.png"

img=iPhone-Settings
siz=29
sips --resampleHeightWidthMax "$(($siz * 1))" iTunesArtwork.png --out "$img.png"
sips --resampleHeightWidthMax "$(($siz * 2))" iTunesArtwork.png --out "$img@2x.png"
sips --resampleHeightWidthMax "$(($siz * 3))" iTunesArtwork.png --out "$img@3x.png"

img=iPhone-Spotlight
siz=40
sips --resampleHeightWidthMax "$(($siz * 1))" iTunesArtwork.png --out "$img.png"
sips --resampleHeightWidthMax "$(($siz * 2))" iTunesArtwork.png --out "$img@2x.png"
sips --resampleHeightWidthMax "$(($siz * 3))" iTunesArtwork.png --out "$img@3x.png"

img=iPad-App
siz=76
sips --resampleHeightWidthMax "$(($siz * 1))" iTunesArtwork.png --out "$img.png"
sips --resampleHeightWidthMax "$(($siz * 2))" iTunesArtwork.png --out "$img@2x.png"
