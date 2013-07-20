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

download() {
	URL=$1
	TARGET=$2

	curl -q -o "$2" "$1"
}
