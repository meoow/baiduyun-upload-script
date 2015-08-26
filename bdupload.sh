#!/bin/bash

#USAGE: $0 <FILE> [PATH]

shopt -s extglob

#replace this BDUSS with your own.
BDUSS='ehgiafhaeuflargaukrhfailrfiulhilhufialrglirahgliarjfoahuirhgilaafbvjxfefjaleihgralilihiafehrlhbWVvb3cAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACfrhFUn64RVTk;'
KEEPDIR=${KEEPDIR:-0}

#HEADER
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
UA='Mozilla/5.0 (X11; Linux; rv:5.0) Gecko/5.0 Firefox/5.0'

#params
ondup=overwrite  #newcopy overwrite
appid=250528
uriprefix='https://c.pcs.baidu.com/rest/2.0/pcs/file?method=upload&'

urlencode() {
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

_cat() {
  # _cat FORMAT FILENAME
  # FORMAT: gz, plain
  if [[ $# < 2 ]];then
	return 1
  fi
  case "$1" in
	gz)
	  gzip -c3 "$2"
		;;
	plain)
	  cat "$2"
		;;
	  *)
	  return 1
		;;
	esac    # --- end of case ---
}

while [[ $# -ne 0 ]];do

case "$1" in
  -z)
	export BDUPLOAD_GZ=1
	shift
	continue
	;;
esac

if [[ -f "$1" || -L "$1" ]];then
  filepath="$1"
  filename="$(basename "$filepath")"
elif [[ -d "$1" ]];then
  export KEEPDIR=1
  if [[ "$1" =~ / ]];then
	export KEEPDIR_BASE="$(basename "$1")"
  else
	export KEEPDIR_BASE="$1"
  fi
  cd "$1" || exit 1
  find . -type f | sed 's/^\.\///' | tr \\n \\0 | xargs -0 -n1 "$0" 
  exit 0
else
  exit 1
fi

if [[ $KEEPDIR -eq 0 ]];then
  dir=/upload
else
  if [[ ! "$1" =~ / ]];then
	dir=/upload/$KEEPDIR_BASE
  else
	dir=/upload/$KEEPDIR_BASE/${1%/+([^/])}
  fi
fi
# if [[ ! "${dir:=/upload}" =~ ^/ ]];then
#   dir="/$dir"
# fi
# cat <<_EOF_
echo $BDUPLOAD_GZ

if [[ -n "$BDUPLOAD_GZ" ]];then
  FORMAT=gz
else
  FORMAT=plain
fi

_cat $FORMAT "$filepath" | curl -k \
  -X POST \
  -F file=@- \
  -F filename="${filename}${BDUPLOAD_GZ:+.gz}" \
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
  -o /dev/fd/1 \
  "${uriprefix}ondup=$ondup&app_id=$appid&dir=$(urlencode "$dir")&filename=$(urlencode "${filename}${BDUPLOAD_GZ:+.gz}")"
# _EOF_
echo

shift
done
