#!/bin/bash

shopt -s extglob

BDUSS='<change-to-your-bduss>'

BDUSS+=';'

# Http Header
ACCEPT='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
ACCPET_LANGUAGE='zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3'
ACCPET_ENCODING='identity'
CACHE_CONTROL='no-cache'
CONNECTION='keep-alive'
DNT=1
HOST='c.pcs.baidu.com'
ORIGIN='http://pan.baidu.com'
PRAGMA='no-cache'
REFERER='http://pan.baidu.com/disk/home'

#UA='Mozilla/5.0 (X11; Linux; rv:5.0) Gecko/5.0 Firefox/5.0'
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36'

# Http Post Params
ondup="overwrite"
appid="250528"
upload_uriprefix='https://c.pcs.baidu.com/rest/2.0/pcs/file?method=upload&'
download_uriprefix='https://d.pcs.baidu.com/rest/2.0/pcs/file?method=download&'

function urlencode() {
	local length="${#1}"
	local c
	for (( i = 0; i < length; i++ )); do
		c="${1:i:1}"
		case $c in
			[a-zA-Z0-9.~_-]) printf "%s" "$c" ;;
			*) printf "%s" "$c" | xxd -p -c1 | while read x;do printf "%%%s" "$x";done
		esac
	done
}

function stream() {
	case "$1" in
		"gz" )
			gzip -c3 "$2" ;;
		"plain" )
			cat "$2" ;;
		* )
			return 1 ;;
	esac
}


# simple json parser
function json() {
	local string="$(echo "$1" | tr -d '"')"
	local key="$2"

	echo "$string" | sed 's/.*'$key':\([^,}]*\).*/\1/'
}


function print_result() {
	local file="$1"; shift
	local json="$@"
	local path=$(json "$json" "path")
	local size=$(json "$json" "size")
	
	echo -ne "\e[033;1;5;34m::\e[033;0m"
	echo -e "Upload \e[033;1;33m${file}\e[033;0m to \e[033;1;33m${path}\e[033;0m, size=\e[033;1;33m${size}\e[033;0mb"
}


function baiduyun_upload() {
	local filepath="$1"
	local use_gz="$2"
	local silent="$3"
	
	local filename=$(basename "$filepath")
	local format="plain"

	local remote_path="/upload"

	if [[ "$use_gz" == true ]];then
		format="gz"
		filename+=".gz"
	fi
	
	local arg="--progress-bar"
	if [[ "$silent" == true ]];then
		arg="-s"
	fi

	local encoded_remote_path=$(urlencode "$remote_path")
	local encoded_filename=$(urlencode "$filename")

	print_result "$filepath" "$(
		stream "$format" "$filepath" | curl -k \
			$arg \
			-X POST \
			-F file=@- \
			-F filename="$filename" \
			-H "Accept: $ACCEPT" \
			-H "Accept-Language: $ACCPET_LANGUAGE" \
			-H "Cache-Control: $CACHE_CONTROL" \
			-H "Connection: $CONNECTION" \
			-H "DNT: $DNT" \
			-H "Host: $HOST" \
			-H "Origin: $ORIGIN" \
			-H "Pragma: $PRAGMA" \
			-H "Referer: $REFERER" \
			-H "Accept-Encoding: $ACCPET_ENCODING" \
			-H "User-Agent: $UA" \
			-H "Cookie: BDUSS=$BDUSS" \
			-o /proc/self/fd/1 \
			"${upload_uriprefix}ondup=$ondup&app_id=$appid&dir=${encoded_remote_path}&filename=${encoded_filename}" 2>/dev/tty
		)"
}



function baiduyun_download() {
	local file="$1"
	local save

	if [[ "$2"x != ""x ]];then
		save="$2"
	else
		save="$(basename $file)"
	fi

	local encoded_filename="$(urlencode "$file")"

	curl -Lk \
		--progress-bar \
		-X GET \
		-H "Accept: $ACCEPT" \
		-H "Accept-Language: $ACCPET_LANGUAGE" \
		-H "Cache-Control: $CACHE_CONTROL" \
		-H "Connection: $CONNECTION" \
		-H "DNT: $DNT" \
		-H "Host: $HOST" \
		-H "Origin: $ORIGIN" \
		-H "Pragma: $PRAGMA" \
		-H "Referer: $REFERER" \
		-H "Accept-Encoding: $ACCPET_ENCODING" \
		-H "User-Agent: $UA" \
		-H "Cookie: BDUSS=$BDUSS" \
		-o /proc/self/fd/1 \
		"${download_uriprefix}app_id=$appid&path=${encoded_filename}" > "$save"
}


function do_download() {
	if [[ "$#" != 1 ]]; then
		echo "download: invalid arguments"
		usage
		return
	fi

	baiduyun_download "$1" "$2"
}


function do_upload() {
	if [[ "$#" == 0 ]]; then
		echo "upload: invalid arguments"
		usage
		return
	fi

	local use_gz silent

	while [[ "$1"x != ""x ]];do
		case "$1" in
			"-z" )
				use_gz=true
				shift
				continue ;;
			"-s" )
				silent=true
				shift;
				continue ;;
		esac

		if [[ -f "$1" ]];then
			baiduyun_upload "$1" "$use_gz" "$silent"
		fi

		shift
	done
}


function usage() {
	echo
	echo "usage: $0 <command> [args]"
	echo "available commands:"
	echo "  download          <remoteFile> [saveTo]"
	echo "  upload  [-s] [-z] <file1> [file2] ..."
	echo
}


function main() {
	if [[ "$#" -lt 1 ]]; then
		usage
		return
	fi

	case "$1" in
		"download" | "d" ) shift; do_download "$@" ;;
		"upload" | "u" ) shift; do_upload "$@" ;;
		* ) echo "Unsupported command: $1" ;;
	esac
}

main "$@"

