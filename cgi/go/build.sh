#!/bin/sh
# https://golang.org/doc/install/source#environment
#

cd "$(dirname "${0}")" || exit 1
# $ uname -s -m
# Darwin x86_64
# Linux x86_64
# Linux armv6l

say="say"
parm="" # "-u"
{
  "${say}" "go get"
    go get ${parm} \
    golang.org/x/net/html \
    \
    github.com/stretchr/testify \
    github.com/yhat/scrape
}

PROG_NAME="shaarlios.cgi"
VERSION="$(grep -F 'version = ' version.go | cut -d \" -f 2)"

rm "${PROG_NAME}"-*-"${VERSION}" 2>/dev/null

"${say}" "test"
umask 0022
go fmt && go vet && go test --short || { exit $?; }
"${say}" "ok"

"${say}" "build localhost"
go build -ldflags "-s -w -X main.GitSHA1=$(git rev-parse --short HEAD)" -o ~/"public_html/b/${PROG_NAME}" || { echo "Aua" 1>&2 && exit 1; }
"${say}" "ok"
# open "http://localhost/~$(whoami)/b/${PROG_NAME}"

"${say}" bench
go test -bench=.
"${say}" ok

"${say}" "linux build"
# http://dave.cheney.net/2015/08/22/cross-compilation-with-go-1-5
env GOOS=linux GOARCH=amd64 go build -ldflags="-s -w -X main.GitSHA1=$(git rev-parse --short HEAD)" -o "${PROG_NAME}-linux-amd64-${VERSION}" || { echo "Aua" 1>&2 && exit 1; }
# env GOOS=linux GOARCH=arm GOARM=6 go build -ldflags="-s -w -X main.GitSHA1=$(git rev-parse --short HEAD)" -o "${PROG_NAME}-linux-arm-${VERSION}" || { echo "Aua" 1>&2 && exit 1; }
# env GOOS=linux GOARCH=386 GO386=387 go build -o "${PROG_NAME}-linux-386-${VERSION}" # https://github.com/golang/go/issues/11631
# env GOOS=darwin GOARCH=amd64 go build -o "${PROG_NAME}-darwin-amd64-${VERSION}"


"${say}" "simply"
# scp "ServerInfo.cgi" simply:/var/www/lighttpd/h4u.r-2.eu/public_html/"info.cgi"
gzip --force --best "${PROG_NAME}"-*-"${VERSION}" \
&& chmod a-x "${PROG_NAME}"-*-"${VERSION}.gz" \
&& rsync -vp --bwlimit=1234 "${PROG_NAME}"-*-"${VERSION}.gz" "simply:/tmp/" \
&& ssh simply "sh -c 'cd /var/www/lighttpd/demo.mro.name/ && gunzip < "/tmp/${PROG_NAME}-linux-amd64-${VERSION}.gz" > shaarlios.cgi && chmod a+x shaarlios.cgi && ls -l shaarlios?cgi*'"

# ssh simply "sh -c 'cd /var/www/lighttpd/b.mro.name/public_html/u/ && cp /var/www/lighttpd/l.mro.name/public_html/shaarlios?cgi* . && ls -l shaarlios?cgi*'"
"${say}" "ok"
