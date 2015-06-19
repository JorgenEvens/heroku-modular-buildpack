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

	if [ -z "`which md5sum`" ]; then
		echo $(md5 "$FILE" | cut -d" " -f4)
	else
		echo $(md5sum "$FILE" | cut -d" " -f1)
	fi
}

unpack() {
	local CUR_DIR

	local URL
	local BASENAME
	local MD5
	local INTO
	local CLEAN

	URL="$1"
	BASENAME="`basename $URL`"
	MD5="$2"
	INTO="$3"
	CLEAN="$4"

	if [ -z "$INTO" ]; then
		INTO="vendor"
	fi

	if [ ! -z "$CLEAN" ]; then
		CLEAN="--recursive-unlink"
	fi

	print_action "Downloading $BASENAME"
	cached_download "$URL" "${CACHE_DIR}/${BASENAME}" "$MD5" true

	print_action "Unpacking $BASENAME to /app/$INTO"
	mkdir -p "${BUILD_DIR}/$INTO"

	CUR_DIR=`pwd`

	cd "${BUILD_DIR}/$INTO"
	tar $CLEAN -xf "${CACHE_DIR}/${BASENAME}"
	cd "${CUR_DIR}"
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