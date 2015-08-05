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
cd "$(dirname "$0")"

# rm head cook trace 2>/dev/null

BASE_URL="http://links.mro.name"

url="${BASE_URL}?post=http://blog.mro.name/foo&title=Title&description=desc&source=curl"
TOKEN=$(curl --dump-header head --cookie-jar cook --location --url "$url" | grep token | cut -c 46-85)
echo ================

url="${BASE_URL}?do=login&post=http://blog.mro.name/foo&title=Title&description=desc&source=curl"
curl --dump-header head --cookie cook --cookie-jar cook --location  --form "login=mro" --form "password=Jahahw7zahKi" --form "token=$TOKEN" --url "$url" | egrep -hoe "<input.*"
echo ================

cat head