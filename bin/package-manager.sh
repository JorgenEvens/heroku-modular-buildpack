#!/bin/sh

# Location to keep packages
PACKAGE_LIST="${CACHE_DIR}/packages"

# The maximum age of the package list in minutes before refreshing.
PACKAGE_LIST_MAX_AGE="5"

PACKAGE_CACHE="${CACHE_DIR}/package_cache"

# Searches if a package exists by this name.
package_search() {
	FOUND=`cat "$PACKAGE_LIST" | grep -e "^${1} "`
	COUNT=`echo ${FOUND} | wc -l`

	if [ "$COUNT" -gt 1 ]; then
		echo ""
		return
	fi

	if [ -z "$FOUND" ]; then
		echo ""
		return
	fi

	echo "$FOUND"
}

# Extracts URL from package index
package_url() {
	echo "$1" | cut -d" " -f2
}

# Extracts MD5 from package index
package_md5() {
	echo "$1" | cut -d" " -f3
}

# Searches if a package exists by this name and display messages
package_search_interactive() {
	print_action "Searching package-manager for ${1}."

	FOUND=`cat "$PACKAGE_LIST" | grep -e "^${1} "`
	COUNT=`echo ${FOUND} | wc -l`

	if [ "$COUNT" -gt 1 ]; then
		print "Multiple packages found with name ${1}. Aborting."
		return
	fi

	if [ -z "$FOUND" ]; then
		print "No package found with name ${1}."
		return
	fi

	PACKAGE=$(package_search $1)
	URL=$(package_url "${PACKAGE}")
	print "Package ${1} found at ${URL}."
}

# Install a given package
package_install() {
	mkdir -p "$PACKAGE_CACHE" 2> /dev/null
	PACKAGE=$(package_search $1)
	PACKAGE_URL=$(package_url "${PACKAGE}")
	PACKAGE_MD5=$(package_md5 "${PACKAGE}")

	print_action "Installing package ${1} through package manager"
	print "from location ${PACKAGE_URL}."

	TARGET="$PACKAGE_CACHE/$(basename $PACKAGE_URL)"
	DOWNLOAD=$(cached_download "${PACKAGE_URL}" "${TARGET}" "${PACKAGE_MD5}" "false")
	
	if [ $DOWNLOAD -gt 0 ]; then
		print "MD5 still not correct, updating REPO and retrying"
		if [ -z "$2" ]; then
			package_update_repo
			package_install $1 "false"
			return
		else
			print_action "Unable to find correct version of $1"
			print "MD5 mismatch, expecting $PACKAGE_MD5 on $(basename $TARGET)"
			exit 1
		fi
	fi
	. "$TARGET"
}

# Update the package cache and package list
package_update_repo() {
	rm -R "$PACKAGE_CACHE" 2> /dev/null
	rm "$PACKAGE_LIST" 2> /dev/null

	print_action "Updating available packages"
	for repo in `cat ${CONFIG_DIR}/repos`; do
		curl -silent "$repo" -o - >> $PACKAGE_LIST
	done
}

# update repositories using heroku config:set RELOAD_REPOSITORY=true
if [ ! -z "$RELOAD_REPOSITORY" ]; then
	package_update_repo
fi

# Check the age of the current package list
if test `find "${PACKAGE_LIST}" -mmin +${PACKAGE_LIST_MAX_AGE} -print -quit 2> /dev/null`; then
	package_update_repo
fi

# If no package list is available create it.
if [ ! -f "$PACKAGE_LIST" ]; then
	package_update_repo
fi

