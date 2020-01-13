#!/usr/bin/env bash

VERBOSE=false
BASEDIR="$HOME/.cache/ofs"
MKDIRS=false

verbose() {
	[ "$VERBOSE" = "true" ]
}

usage() {
	echo "overlayfs management tool"
	echo "	ofs new [lowerdir] [mergeddir]"
	echo "	ofs rm [mergeddir]"
	echo "	ofs ls"
}

help() {
	usage
	echo "FLAGS:"
	echo "	-v|--verbose	Verbosity"
	echo "	-h|--help	Print this help screen"
	echo "	-b|--basedir	Override basedir from default ($BASEDIR)"
	echo "	-p		Create directories if they don't already exist"
}

new() {
	if [ $# -lt 2 ]; then
		echo "Missing LOWER and MERGED directory arguments"
		exit 1
	fi

	lower=$(realpath  "$1")
	merged=$(realpath "$2")

	if [ ! -d "$lower" ]; then
		echo "$lower doesn't exist"
		exit 3
	fi

	root="$BASEDIR/$(tr '/' '@' <<< "$merged")"

	if [ -d "$root" ]; then
		echo "$merged is already an overlay"
		exit 5
	fi

	mkdir -p "$root"
	if verbose; then
		echo "mkdir -p $root"
	fi

	if [ ! -d "$merged" ]; then
		mkdir -p "$merged"
		if verbose; then
			echo "mkdir -p $merged"
		fi
	fi

	upper="$root/upper"
	work="$root/work"
	dbinfo="$root/dbinfo"

	mkdir -p "$upper"
	if verbose; then
		echo "mkdir -p $upper"
	fi

	mkdir -p "$work"
	if verbose; then
		echo "mkdir -p $work"
	fi

	ln -s "$lower" "$root/lower"
	if verbose; then
		echo "ln -s $lower $root/lower"
	fi

	if verbose; then
		echo "sudo mount -t overlay overlay -o lowerdir=$lower,upperdir=$upper,workdir=$work $merged"
	fi

	if ! sudo mount -t overlay overlay -o lowerdir="$lower",upperdir="$upper",workdir="$work" "$merged"; then
		echo "Unable to create overlayfs in $merged"
		rm -r "$root"
		if verbose; then
			print "rm -r $root"
		fi
		exit 6
	fi
}

del() {
	if [ "$#" -lt 1 ]; then
		echo "Missing MERGED directory argument"
		exit 1
	fi

	merged=$(realpath "$1")

	if [ ! -d "$merged" ]; then
		echo "$merged isn't a directory"
		exit 2
	fi

	root="$BASEDIR/$(tr '/' '@' <<< "$merged")"

	if [ ! -d "$root" ]; then
		echo "$merged isn't an overlay"
		exit 3
	fi

	if verbose; then
		echo "sudo umount $merged"
	fi

	if ! sudo umount "$merged"; then
		echo "Unable to umount $merged"
		exit 4
	fi

	rm -fr "$root"
	if verbose; then
		echo "rm -fr $root"
	fi
}

info () {
	for entry in "$BASEDIR"/*; do
		ls $entry
	done
}

if [ $# -lt 1 ]; then
	usage
	exit 1
fi

PARAMS=
while (( "$#" )); do
	case "$1" in
		-b|--basedir)
			BASEDIR=$2
			shift 2
			;;
		-v|--verbose)
			VERBOSE=true
			shift
			;;
		-h|--help)
			help
			exit 0
			;;
		-p)
			MKDIRS=true
			shift
			;;
		*)
			PARAMS="$PARAMS $1"
			shift
			;;

	esac
done

eval set -- "$PARAMS"

if [ ! -d "$BASEDIR" ]; then
	mkdir -p "$BASEDIR"
	if verbose; then
		echo "Created $BASEDIR"
	fi
fi

case "$1" in
	new)
		shift
		new "$@"
		;;
	rm)
		shift
		del "$@"
		;;
	ls)
		shift
		info "$@"
		;;
	*)
		usage
		exit 1
esac

