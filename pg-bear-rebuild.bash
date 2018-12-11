#!/bin/bash

set -e -u -o pipefail

rebuild() {
	local directory=$1

	git -C "${directory}" pull --ff-only
	gmake -s clean -C "${directory}/src/interfaces"
	bear_make -s -j"${NCPU}" -l"${MAXLOAD}" --output-sync -C "${directory}"
}

_main() {
	local directory

	while getopts C: opt; do
		case $opt in
			C)
				directory=$OPTARG
				;;
			*)
				printf >&2 'Unexpected argument\n'
				exit 1
				;;
		esac
	done

	if [ "${directory:+x}" != x ]; then
		echo >&2 You need to specify a directory with -C

		false
	fi

	NCPU=$(ncpu)
	MAXLOAD=$(( 2 * NCPU ))
	rebuild "${directory}"
}

ncpu() {
	getconf _NPROCESSORS_ONLN
}

bear_append() {
	command bear --cdb "${directory}/compile_commands.json" --append "$@"
}

if [ "$(uname)" = Linux ]; then
	gmake() {
		command make "$@"
	}

	bear_make() {
		bear_append make "$@"
	}

else
	gmake() {
		command gmake "$@"
	}

	bear_make() {
		bear_append gmake "$@"
	}
fi

_main "$@"
