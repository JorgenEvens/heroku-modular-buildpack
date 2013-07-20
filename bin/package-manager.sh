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

	# Multiple matches
	if [ "$COUNT" -gt 1 ]; then
		echo ""
		return
	fi

	# No Match at all
	if [ "$COUNT" -eq 0 ]; then
		echo ""
		return
	fi

	echo "${FOUND}" | cut -d" " -f2
}

# Install a given package
package_install() {
	print_action "Installing package ${1} through package manager"
	PACKAGE_URL=$(package_search $1)
	print "from location ${PACKAGE_URL}."

	curl -silent "${PACKAGE_URL}" -o - | sh
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

