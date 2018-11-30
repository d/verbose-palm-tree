#!/bin/bash

set -e -u -o pipefail
set -x

build() {
	local directory=$1

	git_pull_with_backoff
	gmake -s clean -C "${directory}/src/interfaces"
	bear --cdb "${directory}/compile_commands.json" --append gmake -s -j"${NCPU}" -l"${MAXLOAD}" --output-sync -C "${directory}"
}

git_pull() {
	git -C "${directory}" pull --ff-only
}

git_pull_with_backoff() {
	git_pull && return 0
	local -i x=2
	while [ $x -gt 0 ]; do
		x-=1
		sleep $((RANDOM % 4 + 1))
		git_pull && return 0
	done
	false
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
	MAXLOAD=$(( 3 * NCPU ))
	build "${directory}"
}


_main "$@"
