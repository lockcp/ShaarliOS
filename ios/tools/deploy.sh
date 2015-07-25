#!/bin/sh

if [ ! -f "$1" ] ; then
	echo "File not found: '$1'" 1>&2
	exit 1
fi

app=ShaarliCompanion
host=simply
base="/var/www/lighttpd/drop.mro.name/public_html/dev"
tmp="/tmp/deploy.Info.plist"

# extract CFBundleVersion from Info.plist:
unzip -p "$1" "Payload/${app}.app/Info.plist" > "$tmp"
if [ $? -ne 0 ] ; then
	echo "Unzip issue: unzip -p \"$1\" \"Payload/${app}.app/Info.plist\" > \"$tmp\"" 1>&2
	exit 2
fi
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$tmp")

# prepare dir and upload
dst="${base}/${app}/deploy/v${version}/Debug/"
ssh "${host}" "mkdir -p '${dst}' && chmod a+rwx '${dst}' && rm '${dst}'*"
rsync --progress "$1" "${host}:${dst}/${app}.ipa"
ssh "${host}" "ls -l '${dst}'"

say -v Fiona "${app} version ${version} deployed, now comes doxygen docs upload"

cd "$(dirname "$0")"
sh doxygen.sh && rsync --progress --delete -avPz ../build/doxygen/ "${host}:${base}/${app}/docs/v${version}"

open "http://drop.mro.name/dev/${app}/docs/v${version}/"

say -v Fiona "all done."
