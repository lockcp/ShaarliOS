#!/bin/sh
#

name=onepassword-app-extension
git_url=https://github.com/AgileBits/$name.git
base_dir=$HOME/Downloads/3rdparty

git --version >/dev/null || { echo "oh, I need git." && exit 1; }

cd `dirname $0`
cwd=`pwd`

mkdir -p "$base_dir" 2> /dev/null
cd "$base_dir"
if [ -d "$name" ] ; then
	cd "$name"
	git pull
else
	git clone "$git_url" "$name"
	cd "$name"
fi

cd "$cwd"
rm -rf README.* LICENSE* *.? 1Password.xcassets 2> /dev/null

cd "$base_dir/$name"
cp -rp README* LICENSE* 1Password.xcassets OnePasswordExtension.? "$cwd"
git log -1 > "$cwd"/version.log
cd "$cwd"
