#!/bin/sh

declare -a CALLBACK_LIST

callback_register() {
	local CALLBACK_LEN
	local PARAM

	CALLBACK_LEN=${#CALLBACK_LIST[@]}
	PARAM=()

	# Escape each parameter using single quotes such
	# that we can use eval when triggering the callback
	# and still group the parameters correctly when
	# containing a space.
	for p in "$@"; do
		PARAM+=" '$p'"
	done

	CALLBACK_LIST["$CALLBACK_LEN"]="$PARAM"
}

callback_run() {
	if [ "$1" == "$2" ]; then
		shift 2
		"$@"
	fi
}

callback_trigger() {
	local CALLBACK_LEN
	local CALLBACK_TRIGGER
	local CALLBACK_ID

	CALLBACK_LEN=${#CALLBACK_LIST[@]}
	CALLBACK_TRIGGER="$1"

	shift

	for (( CALLBACK_ID=0; CALLBACK_ID<$CALLBACK_LEN; CALLBACK_ID++ )); do
		eval "callback_run '$CALLBACK_TRIGGER' ${CALLBACK_LIST[$CALLBACK_ID]} $@"
	done
}