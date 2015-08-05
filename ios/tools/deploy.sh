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

if [ ! -f "$1" ] ; then
	echo "File not found: '$1'" 1>&2
	exit 1
fi

app=ShaarliOS
host=simply
base="/var/www/lighttpd/drop.mro.name/public_html/dev/$app"
tmp="/tmp/deploy.Info.plist"

# extract CFBundleVersion from Info.plist:
unzip -p "$1" "Payload/${app}.app/Info.plist" > "$tmp"
if [ $? -ne 0 ] ; then
	echo "Unzip issue: unzip -p \"$1\" \"Payload/${app}.app/Info.plist\" > \"$tmp\"" 1>&2
	exit 2
fi
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$tmp")

# prepare dir and upload
dst="${base}/deploy/v${version}/Debug/"
ssh "${host}" "mkdir -p '${dst}' && chmod a+rwx '${dst}' && rm '${dst}'*"
rsync --progress "$1" "${host}:${dst}/${app}.ipa"
ssh "${host}" "ls -l '${dst}'"

say -v Fiona "${app} version ${version} deployed, now comes doxygen docs upload"

cd "$(dirname "$0")"
sh doxygen.sh && rsync --progress --delete -avPz ../build/doxygen/ "${host}:${base}/docs/v${version}"

open "http://drop.mro.name/dev/${app}/docs/v${version}/"

say -v Fiona "all done."
