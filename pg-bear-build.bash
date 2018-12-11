#!/bin/bash

set -e -u -o pipefail

declare DIRECTORY COMPDB
declare -i REBUILD=0
declare -i NCPU
declare -i MAXLOAD

build() {
	git_pull_with_backoff
	if (( REBUILD == 1 )); then
		gmake -s clean -C "${DIRECTORY}"
		rm -f "${COMPDB}"
	else
		gmake -s clean -C "${DIRECTORY}/src/interfaces"
	fi
	bear_make -s -j"${NCPU}" -l"${MAXLOAD}" --output-sync -C "${DIRECTORY}"
}

git_pull_with_backoff() {
	git_pull && return 0
	local -i i
	for (( i = 0; i < 2; ++i )); do
		sleep $((RANDOM % 4 + 1))
		git_pull && return 0
	done
	false
}

git_pull() {
	git -C "${DIRECTORY}" pull --ff-only
}

_main() {
	while getopts C:r opt; do
		case $opt in
			C)
				DIRECTORY=$OPTARG
				;;
			r)
				REBUILD=1
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

	COMPDB=${DIRECTORY}/compile_commands.json
	NCPU=$(ncpu)
	MAXLOAD=$(( 2 * NCPU ))

	readonly DIRECTORY COMPDB
	readonly REBUILD
	readonly NCPU
	readonly MAXLOAD

	set -x
	build
}

ncpu() {
	getconf _NPROCESSORS_ONLN
}

bear_append() {
	command bear --cdb "${COMPDB}" --append "$@"
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
