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

# Download a file to a target location and optionally validate the MD5 hash
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

# Download a file using `download` and cache the result.
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

# Extend an environment variable with a value
# This generates the .profile.d files required in the compiled app.
# This also sets the current environment variable.
env_extend() {
    local VAR
    local VAL
	local ORIGINAL
	local PKG_PROFILE

	PKG_PROFILE="${PACKAGE}"
	test -z "${PKG_PROFILE}" && PKG_PROFILE="general"

    VAR="$1"
    shift
    VAL="$@"

	mkdir -p "${BUILD_DIR}/.profile.d"
    echo "export $VAR=\"\$$VAR:$VAL\"" > "${BUILD_DIR}/.profile.d/${PKG_PROFILE}.sh"

    VAL="`echo $VAL | sed 's/^\/app//'`"
    test "$VAL" != "$@" && VAL="${BUILD_DIR}${VAL}"

	ORIGINAL="$(eval echo \$$VAR)"
	test ! -z "$ORIGINAL" && ORIGINAL="${ORIGINAL}:"
    export $VAR="${ORIGINAL}${VAL}"
}