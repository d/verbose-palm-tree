#!/bin/bash

_main() {
	shellcheck -f gcc --shell bash pg-bear-build.bash ci/shellcheck.bash
}

_main "$@"
