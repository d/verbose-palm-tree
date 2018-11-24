#!/bin/bash

_main() {
	shellcheck -f gcc --shell bash pg-bear-rebuild.bash ci/shellcheck.bash
}

_main "$@"
