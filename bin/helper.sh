#!/bin/sh

BUILD_DIR=$1
CACHE_DIR=$2

CONFIG_DIR="${BUILD_DIR}/build/heroku"

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
	URL=$1
	TARGET=$2
	MD5=$3

	print_action "Downloading $URL"
	curl -# -f -o "$TARGET" "$URL"

	if [ ! -f "$TARGET" ]; then
		echo 1
	fi

	if [ ! -z "$MD5" ]; then
		if [ $(md5 "$TARGET") != "$MD5" ]; then
			echo 2
		fi
	fi

	echo 0
}


cached_download() {
	URL=$1
	TARGET=$2
	MD5=$3
	EXIT_ON_FAIL=$4

	if [ -f "$TARGET" ]; then
		if [ -z "$MD5" || $(md5 $TARGET) == "$MD5" ]; then
			return
		fi
	fi

	DOWNLOAD=$(download "$URL" "$TARGET" "$MD5")

	if [ $DOWNLOAD -gt 0 ]; then
		print_action "Was unable to download $URL or use a cached version, exiting."
		if [ -z "$EXIT_ON_FAIL" ]; then
			exit 1
		else
			echo 1
		fi
	fi

	echo 0
}