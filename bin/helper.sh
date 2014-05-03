#!/bin/sh

BUILD_DIR=$1
CACHE_DIR=$2
ENV_DIR=$3

if [ -d "$ENV_DIR" ]; then
	for _env_variable in `ls "$ENV_DIR"`; do
		export ${_env_variable}=$(cat "${ENV_DIR}/${_env_variable}")
	done
fi

CONFIG_DIR="${BUILD_DIR}/build/heroku"

# Clean cache when CLEAN_CACHE environment variable is non-empty
if [ ! -z "$CLEAR_CACHE" ]; then
	rm -Rf "$CACHE_DIR"
fi
mkdir -p "$CACHE_DIR"
mkdir -p "$BUILD_DIR"

print_action() {
	echo "-----> $@"
}

print() {
	echo "       $@"
}

md5() {
	FILE="$1"

	echo $(md5sum "$FILE" | cut -d" " -f1)
}

download() {
	local URL
	local TARGET
	local MD5
	local TMP_MD5

	URL="$1"
	TARGET="$2"
	MD5="$3"

	curl -# -f -o "$TARGET" "$URL"

	if [ ! -f "$TARGET" ]; then
		echo 1
	fi

	if [ ! -z "$MD5" ]; then
		TMP_MD5=$(md5 "$TARGET")
		if [ "$TMP_MD5" != "$MD5" ]; then
			echo 2
		fi
	fi
}


cached_download() {
	local URL
	local TARGET
	local MD5
	local EXIT_ON_FAIL
	local TMP_MD5
	local DOWNLOAD

	URL="$1"
	TARGET="$2"
	MD5="$3"
	EXIT_ON_FAIL="$4"

	if [ -f "$TARGET" ]; then
		TMP_MD5=$(md5 "$TARGET")
		if ( [ -z "$MD5" ] || [ "$TMP_MD5" = "$MD5" ] ); then
			echo 0
			return
		fi
	fi

	DOWNLOAD=$(download "$URL" "$TARGET" "$MD5")

	if [ ! -z "$DOWNLOAD" ]; then
		if [ -z "$EXIT_ON_FAIL" ]; then
			print_action "Was unable to download $URL or use a cached version, exiting."
			exit 1
		else
			echo $DOWNLOAD
			return
		fi
	fi

	echo 0
}