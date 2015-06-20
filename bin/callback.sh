#!/bin/sh

CALLBACK_LIST=""
CALLBACK_SEP="
"

callback_register() {
	local PARAM
	local SPLIT

	PARAM="'$1'"
	shift

	# Escape each parameter using single quotes such
	# that we can use eval when triggering the callback
	# and still group the parameters correctly when
	# containing a space.
	for p in "$@"; do
		PARAM="$PARAM '$p'"
	done

	CALLBACK_LIST="${CALLBACK_LIST}${PARAM}${CALLBACK_SEP}"
}

callback_run() {
	if [ "$1" = "$2" ]; then
		shift 2
		"$@"
	fi
}

callback_trigger() {
	local CALLBACK_TRIGGER
	local OLD_IFS
	local cb

	CALLBACK_TRIGGER="$1"
	OLD_IFS="$IFS"

	shift

	IFS="$CALLBACK_SEP"

	echo "$CALLBACK_LIST"

	for cb in $CALLBACK_LIST; do
		echo "# $cb"
		echo "# callback_run '$CALLBACK_TRIGGER' $cb $@"
		eval "callback_run '$CALLBACK_TRIGGER' $cb $@"
	done

	IFS="$OLD_IFS"
}