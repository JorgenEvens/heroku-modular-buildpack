#!/bin/sh

NGINX_VERSION="1.4.2"
NGINX_HOST="http://jorgen.evens.eu/heroku"

nginx_compile() {
	VERSION=$NGINX_VERSION
	BINARIES="${CACHE_DIR}/nginx-${VERSION}.tar.gz"

	nginx_download "$BINARIES"
	nginx_install "$BINARIES"
	nginx_generate_boot
}

nginx_download() {
	TARGET=$1
	HOST=$NGINX_HOST
	URL="${HOST}/$(basename $TARGET)"

	print_action "Checking cache for $TARGET."
	if [ ! -f "$TARGET" ]; then
		print_action "Downloading Nginx ${VERSION} from ${URL} to ${TARGET}"
		curl --silent -o "$TARGET" "$URL"
	fi
	if [ ! -f "$TARGET" ]; then
		print "Unable to download the package"
		exit 1
	fi
}

nginx_install() {
	print_action "Installing Nginx ${VERSION} to ${BUILD_DIR}/vendor"

	mkdir -p "${BUILD_DIR}/vendor"

	FOLDER_NAME=`basename "$BINARIES" ".tar.gz"`
	CUR_DIR=`pwd`

	# Extract Nginx
	cd "${BUILD_DIR}/vendor"
	rm -R nginx 2> /dev/null
	tar -xf "${BINARIES}"

	# Disabled daemonization
	NGINX_CONF="${BUILD_DIR}/vendor/nginx/conf/nginx.conf"
	mv "${NGINX_CONF}" "${NGINX_CONF}.orig"
	echo "daemon off;" > "${NGINX_CONF}"
	cat "${NGINX_CONF}.orig" >> "${NGINX_CONF}"
	rm "${NGINX_CONF}.orig"

	sed -i "s/root\s\+[^;]\+/root \/app\/src/g" "${NGINX_CONF}"

	# Return to original directory
	cd "$CUR_DIR"
}

nginx_generate_boot() {
	print_action "Generating boot portion for nginx"
	echo 'sed -i "s/listen\s\+80;/listen $PORT;/g" "/app/vendor/nginx/conf/nginx.conf"' >> "${BUILD_DIR}/boot.sh"
	echo "/app/vendor/nginx/sbin/nginx" >> "${BUILD_DIR}/boot.sh"
}

nginx_compile
