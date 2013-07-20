#!/bin/sh

# Location to keep packages
PACKAGE_LIST="${CACHE_DIR}/packages"

# The maximum age of the package list before refreshing.
PACKAGE_LIST_MAX_AGE="120"

PACKAGE_CACHE="${CACHE_DIR}/package_cache"

# Searches if a package exists by this name.
package_search() {
	FOUND=`cat $PACKAGE_LIST | grep -e "^${1}\s"`
	COUNT=`echo ${FOUND} | wc -l`

	if [ "$COUNT" -gt 1 ]; then
		print "Multiple packages found with name ${1}. Aborting."
		exit 1
	fi

	echo "${FOUND}" | cut -d" " -f2
}

# Install a given package
package_install() {
	PACKAGE_URL=$(package_search $1)

	curl "${PACKAGE_URL}" -o - | sh
}

# Update the package cache and package list
package_update_repo() {
	rm -R "$PACKAGE_CACHE" 2> /dev/null
	rm "$PACKAGE_LIST" 2> /dev/null

	print_action "Updating available packages"
	for repo in `cat ${CONFIG_DIR}/repos`; do
		curl repo -o - >> $PACKAGE_LIST
	done
}

# Check the age of the current package list
if test `find "${PACKAGE_LIST}" -mmin +${PACKAGE_LIST_MAX_AGE}`; then
	package_update_repo
fi

# Update when commandline flag --update-manager was given.
echo "$*" | grep -q "--update-manager"
if [ $? -eq 0 ]; then
	package_update_repo
fi

# If no package list is available create it.
if [ ! -f "$PACKAGE_LIST" ]; then
	package_update_repo
fi

