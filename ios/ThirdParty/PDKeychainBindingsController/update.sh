#!/bin/sh
#

name=PDKeychainBindingsController
git_url=https://github.com/carlbrown/$name.git
base_dir=$HOME/Downloads/3rdparty

# check if the command 'git' is there. http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
hash git &> /dev/null
if [ $? -eq 1 ]; then
    echo >&2 "$0: git: command not found"
    exit 1
fi

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
rm README.* LICENSE* *.? 2> /dev/null
cd "$base_dir/$name"
cp -p README* LICENSE* PDKeychainBindingsController/* "$cwd"
git log -1 > "$cwd"/version.log
cd "$cwd"
