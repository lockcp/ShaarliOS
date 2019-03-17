#!/bin/sh
cd "$(dirname "${0}")"

say="say"
umask 0022

go fmt \
&& go vet \
&& go test --short \
&& go build -ldflags "-s -w -X main.GitSHA1=$(git rev-parse --short HEAD)" -o ~/Sites/b/shaarlios.cgi \
|| { echo "Aua" 1>&2 && exit 1; }

"${say}" "pack mas"
ls -Al ~/Sites/b/shaarlios.cgi
echo "http://$(hostname)/~$(whoami)/b/"

curl --location "http://$(hostname)/~$(whoami)/b/shaarlios.cgi/v1/info"
