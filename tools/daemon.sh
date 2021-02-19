#!/bin/bash

set -u

CURRENT_DIR="$(cd $(dirname "$0"); pwd)"

_run_test() {
    WORKDIR="$(mktemp -d -p "${CURRENT_DIR}")"
    trap _clean_workdir EXIT
    _clean_workdir() {
      echo "Cleaning up the work dir: ${WORKDIR}"
      rm -rf "${WORKDIR}"
    }

    pushd "${WORKDIR}"
    git clone --recursive https://github.com/cupy/cupy.git
    git clone --branch gh-pages git@github.com:kmaehashi/cupy-rocm-ci-report.git
    srun "${CURRENT_DIR}/test_runner.sh"
    popd

    pushd "${WORKDIR}/cupy-rocm-ci-report"
    git push
    popd

    _clean_workdir
}


_trim_cache() {
    ${CURRENT_DIR}/trim_cupy_kernel_cache.py --max-size $((5*1024*1024*1024)) --rm
}

main() {
    while :; do
        echo "<<< $(date) >>> Starting..."
        _trim_cache
        _run_test
        _trim_cache
        echo "<<< $(date) >>> Finished..."
        sleep $((3600))
    done
}

main
