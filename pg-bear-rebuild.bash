#!/bin/bash

set -e -u -o pipefail

declare DIRECTORY
declare -i NCPU
declare -i MAXLOAD

rebuild() {
	git -C "${DIRECTORY}" pull --ff-only
	gmake -s clean -C "${DIRECTORY}/src/interfaces"
	bear_make -s -j"${NCPU}" -l"${MAXLOAD}" --output-sync -C "${DIRECTORY}"
}

_main() {
	while getopts C: opt; do
		case $opt in
			C)
				DIRECTORY=$OPTARG
				;;
			*)
				printf >&2 'Unexpected argument\n'
				exit 1
				;;
		esac
	done

	if [ "${DIRECTORY:+x}" != x ]; then
		echo >&2 You need to specify a directory with -C

		false
	fi

	NCPU=$(ncpu)
	MAXLOAD=$(( 2 * NCPU ))
	readonly DIRECTORY
	readonly NCPU
	readonly MAXLOAD

	rebuild
}

ncpu() {
	getconf _NPROCESSORS_ONLN
}

bear_append() {
	command bear --cdb "${DIRECTORY}/compile_commands.json" --append "$@"
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
