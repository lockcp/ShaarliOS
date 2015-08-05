#!/bin/sh
#
#  Copyright (c) 2015 Marcus Rohrmoser http://mro.name/me. All rights reserved.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# I suggest to use doxygen 1.5.9 as it works fine whereas later versions 
# might choke on categories.
# https://bugzilla.gnome.org/show_bug.cgi?id=655941
# http://stackoverflow.com/questions/2042595/doxygen-and-objective-c-categories

if [ ! -e "$DOXYGEN" ] ; then
    DOXYGEN=/Applications/Doxygen.app/Contents/Resources/doxygen
fi
if [ ! -e "$DOXYGEN" ] ; then
    # use most recent
    DOXYGEN=$(ls -t /Applications/Doxygen*/Contents/Resources/doxygen | head -n 1)
fi
if [ ! -e "$DOXYGEN" ] ; then
    echo "I cannot find doxygen. Please install doxygen from" >&2
#   echo "\n    http://www.stack.nl/~dimitri/doxygen/download.html#latestsrc" >&2
    echo "\n    ftp://ftp.stack.nl/pub/users/dimitri/Doxygen-1.5.9.dmg" >&2
    echo "\ninto 'Applications', or set" >&2
    echo "\n    export DOXYGEN=..." >&2
    echo "\nto point to the location you installed it to." >&2
    exit 1
fi
echo "Found doxygen $($DOXYGEN --version) at $DOXYGEN" >&2

if [ ! -e "$DOT_PATH"/dot ] ; then
    # use packaged with doxygen
    DOT_PATH=$(dirname "$DOXYGEN")
fi
if [ ! -e "$DOT_PATH"/dot ] ; then
    # search in path
    DOT_PATH=$(which dot | head -n 1)
    DOT_PATH=$(dirname "$DOT_PATH")
fi
if [ ! -e "$DOT_PATH"/dot ] ; then
    # search in /usr/local
    DOT_PATH=$(find /usr/local -maxdepth 4 -type f -name dot | head -n 1)
    DOT_PATH=$(dirname "$DOT_PATH")
fi
if [ ! -e "$DOT_PATH"/dot ] ; then
    echo "I cannot find graphviz. I could run without, but that's only half the fun. So please install graphviz from" >&2
    echo "\n    http://www.ryandesign.com/graphviz/" >&2
    echo "\nsomewhere in \$PATH or under /usr/local, or set" >&2
    echo "\n    export DOT_PATH=..." >&2
    echo "\nto point to the directory you installed dot into." >&2
    exit 2
fi
echo "Found $("$DOT_PATH"/dot -V 2>&1) at $DOT_PATH/dot" >&2

echo "Found mscgen $(mscgen -l | head -2 | tail -1) at $(which mscgen)" >&2

PLANTUML=$(which plantuml 2>/dev/null)
if [ $? -eq 0 ] && [ -x "$PLANTUML" ] ; then
    echo "Found $("$PLANTUML" -version | head -n 1) at $PLANTUML" >&2
else
    echo "!!! Cannot find plantuml - so no UML diagrams." >&2
fi

PROJECT_BUNDLE_ID="name.mro.ShaarliOS"
PROJECT_NAME="ShaarliOS"
PROJECT_VERSION="$(cat VERSION)"
PROJECT_SOURCE="ShaarliOS Share"

cd `dirname $0`/..
if [[ "$PROJECT_NAME" == "" ]] ; then
    tmp=`pwd`
    PROJECT_NAME=`basename "$tmp"`
fi

# set up some paths
BUILD_DIR=./build
DOXYGEN_DIR="$BUILD_DIR"/doxygen
DOXYGEN_CFG="tools/doxygen.config"
DOXYGEN_CFG_GENERATED="$BUILD_DIR/doxygen/doxygen.config.generated"

echo copying "$DOXYGEN_CFG" to "$DOXYGEN_CFG_GENERATED"
mkdir -p `dirname "$DOXYGEN_CFG_GENERATED"` 2> /dev/null
cp "$DOXYGEN_CFG" "$DOXYGEN_CFG_GENERATED"
echo inject settings into "$DOXYGEN_CFG_GENERATED"
sed -i '' -e "s|DOT_PATH *=.*|DOT_PATH       = $DOT_PATH|g" "$DOXYGEN_CFG_GENERATED"
sed -i '' -e "s|HAVE_DOT *=.*|HAVE_DOT       = YES|g" "$DOXYGEN_CFG_GENERATED"
sed -i '' -e "s/PROJECT_NUMBER *=.*/PROJECT_NUMBER       = \"$PROJECT_VERSION\"/g" "$DOXYGEN_CFG_GENERATED"
sed -i '' -e "s/PROJECT_NAME *=.*/PROJECT_NAME       = \"$PROJECT_NAME\"/g" "$DOXYGEN_CFG_GENERATED"
sed -i '' -e "s|INPUT *=.*|INPUT       = $PROJECT_SOURCE README.md|g" "$DOXYGEN_CFG_GENERATED"
sed -i '' -e "s|OUTPUT_DIRECTORY *=.*|OUTPUT_DIRECTORY       = \"$DOXYGEN_DIR\"|g" "$DOXYGEN_CFG_GENERATED"
sed -i '' -e "s|DOCSET_BUNDLE_ID *=.*|DOCSET_BUNDLE_ID       = $PROJECT_BUNDLE_ID|g" "$DOXYGEN_CFG_GENERATED"
sed -i '' -e "s|DOCSET_FEEDNAME *=.*|DOCSET_FEEDNAME       = $PROJECT_BUNDLE_ID|g" "$DOXYGEN_CFG_GENERATED"

if [ -x "$PLANTUML" ] ; then
    echo running plantuml
    mkdir -p "$BUILD_DIR/plantuml-images" 2> /dev/null
    # echo "\"$PLANTUML\"" -tsvg -charset UTF8 -o "\"$(pwd)/$BUILD_DIR/plantuml-images\"" "\"MROGeometry/**.(c|m|h)\"" >&2
    "$PLANTUML" -tsvg -charset UTF8 -o "$(pwd)/$BUILD_DIR/plantuml-images" "MROGeometry/**.(c|m|h)" >&2
fi

echo running doxygen with "$DOXYGEN_CFG_GENERATED"
"$DOXYGEN" "$DOXYGEN_CFG_GENERATED"

# size_before=$(du -kc "$DOXYGEN_DIR"/*.png | tail -1)
# time (ls "$DOXYGEN_DIR"/*.png | xargs -L 5 -P 16 optipng -o 7)
# echo before: $size_before
# echo after : $(du -kc "$DOXYGEN_DIR"/*.png | tail -1)

echo launch browser with "$DOXYGEN_DIR/./index.html"
open "$DOXYGEN_DIR/./index.html"
