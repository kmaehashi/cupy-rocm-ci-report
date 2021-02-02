#!/bin/bash


CURRENT_DIR="$(cd $(dirname "$0"); pwd)"

_run_test() {

    WORKDIR="$(mktemp -d --tmpdir "${CURRENT_DIR}")"
    trap _clean_workdir EXIT
    _clean_workdir() {
      echo "Cleaning up the work dir: ${WORKDIR}"
      rm -rf "${WORKDIR}"
    }

    pushd "${WORKDIR}"
    git clone --recursive https://github.com/cupy/cupy.git
    git clone --branch gh-pages git@github.com:kmaehashi/cupy-rocm-ci-report.git
    popd

    srun "$(dirname "$0")/test_runner.sh" "${WORKDIR}"

    pushd "${WORKDIR}/cupy-rocm-ci-report"
    git push
    popd

    _clean_workdir
}

main() {
    while :; do
        echo "<<< $(date) >>> Starting..."
        _run_test
        echo "<<< $(date) >>> Finished..."
        sleep $((3600))
    done
}

main
