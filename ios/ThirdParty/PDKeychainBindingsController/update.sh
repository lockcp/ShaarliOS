#!/bin/sh
#
#  Copyright (c) 2015-2016 Marcus Rohrmoser http://mro.name/me. All rights reserved.
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
