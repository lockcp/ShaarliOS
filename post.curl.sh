#!/bin/sh
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