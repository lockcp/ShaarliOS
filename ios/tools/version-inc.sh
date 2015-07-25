#!/bin/sh
cd "$(dirname "$0")"/..
#
# Increment version number parts as on commandline parameters.
# default: patch
#
# see http://semver.org/spec/v2.0.0.html
#     https://github.com/mro/iOS-OTA
#

# check prerequisites
agvtool help >/dev/null
if [ $? -ne 0 ] ; then
  echo "Are you sure you've got Xcode installed properly?" >&2
  exit 1
fi

semver=$(agvtool what-version -terse)
major=$(echo $semver | cut -d . -f 1)
minor=$(echo $semver | cut -d . -f 2)
patch=$(echo $semver | cut -d . -f 3)

if [ "$1" = "" ] ; then
  patch=$((patch+1))
else
  while [ "$1" != "" ] ; do
    case "$1" in
      major) major=$((major+1))
      			 minor=0
      			 patch=0
      			 ;;
      minor) minor=$((minor+1))
      			 patch=0
      			 ;;
      patch) patch=$((patch+1)) ;;
      *)     echo "Ouch" >&2 ; exit 1;;
    esac
    shift
  done
fi

agvtool new-version -all $major.$minor.$patch
echo "v$(agvtool what-version -terse)"