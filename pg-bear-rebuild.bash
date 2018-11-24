#!/bin/bash

set -e -u -o pipefail

rebuild() {
	local directory=$1

	git -C "${directory}" pull --ff-only
	gmake -s clean -C "${directory}/src/interfaces"
	bear --cdb "${directory}/compile_commands.json" --append gmake -s -j"${NCPU}" -l"${MAXLOAD}" --output-sync -C "${directory}"
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

	NCPU=$(sysctl -n hw.ncpu)
	MAXLOAD=$(( 2 * NCPU ))
	rebuild "${directory}"
}


_main "$@"
