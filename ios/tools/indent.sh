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
if [ ! -e "$UNCRUSTIFY" ] ; then
	UNCRUSTIFY=$(which uncrustify | head -n 1)
fi
if [ ! -e "$UNCRUSTIFY" ] ; then
	# use most recent
	UNCRUSTIFY=$(ls -t /Applications/UniversalIndentGUI*/indenters/uncrustify | head -n 1)
fi
if [ ! -e "$UNCRUSTIFY" ] ; then
	echo "I cannot find uncrustify. Please install e.g. from" >&2
	echo "\n    http://sourceforge.net/projects/uncrustify/files/uncrustify/uncrustify-0.59/uncrustify-0.59-osx-64bit.zip/download" >&2
	echo "\n    http://universalindent.sourceforge.net/" >&2
	echo "\ninto 'Applications', or set" >&2
	echo "\n    export UNCRUSTIFY=..." >&2
	echo "\nto point to the location you installed it to." >&2
	exit 1
fi
echo "Found $($UNCRUSTIFY --version) at $UNCRUSTIFY" >&2

cd `dirname $0`/..

if [[ "$@" == "" ]]
then
	echo "Got no files on commandline (which is fine), so I'll format those:"
	PROJECT_SOURCE=$(find Sha* \( -name "*.m" -or -name "*.c" -or -name "*.h" \) )
else
	PROJECT_SOURCE="$@"
fi

if [[ "$UNCRUSTIFY_OPTS" == "" ]] ; then
	UNCRUSTIFY_OPTS="-l OC --replace --no-backup -c tools/uncrustify.cfg"
fi

"$UNCRUSTIFY" $UNCRUSTIFY_OPTS $PROJECT_SOURCE 2>&1

for file2indent in $PROJECT_SOURCE ; do
	# http://code.google.com/p/core-plot/source/browse/scripts/format_core_plot.sh?spec=svn3daea3e540f8571d6e99b2cbfb832a88f0777d79&r=3daea3e540f8571d6e99b2cbfb832a88f0777d79
	# remove spaces before category names to keep Doxygen 1.6.0+ happy
	cp -p "$file2indent" .indent.tmp
	cat .indent.tmp | sed "s|\(@interface .*\) \((.*)\)|\1\2|g" | sed "s|\(@implementation .*\) \((.*)\)|\1\2|g" > "$file2indent"
	touch -r .indent.tmp "$file2indent"
	rm .indent.tmp
done