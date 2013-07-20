#!/bin/sh

# Location to keep packages
PACKAGE_LIST="${CACHE_DIR}/packages"

# The maximum age of the package list before refreshing.
PACKAGE_LIST_MAX_AGE="120"

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

	echo "${FOUND}" | cut -d" " -f2
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

	URL=$(package_search $1)
	print "Package ${1} found at ${URL}."
}

# Install a given package
package_install() {
	mkdir -p "$PACKAGE_CACHE" 2> /dev/null
	PACKAGE_URL=$(package_search $1)

	print_action "Installing package ${1} through package manager"
	print "from location ${PACKAGE_URL}."

	TARGET="$PACKAGE_CACHE/$(basename $PACKAGE_URL)"
	download "${PACKAGE_URL}" "$TARGET"
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

# Update when commandline flag --update-manager was given.
echo "$*" | grep -q "\--update-manager"
if [ $? -eq 0 ]; then
	package_update_repo
fi

# Check the age of the current package list
$(find "${PACKAGE_LIST}" -mmin +${PACKAGE_LIST_MAX_AGE}) 2> /dev/null
if [ $? -eq 0 ]; then
	package_update_repo
fi

# If no package list is available create it.
if [ ! -f "$PACKAGE_LIST" ]; then
	package_update_repo
fi

