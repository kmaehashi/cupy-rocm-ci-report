#!/bin/bash

set -u

CURRENT_DIR="$(cd $(dirname "$0"); pwd)"
LAST_TESTED_COMMIT=""

_run_test() {
    WORKDIR="$(mktemp -d -p "${CURRENT_DIR}")"
    trap _clean_workdir EXIT
    _clean_workdir() {
      echo "Cleaning up the work dir: ${WORKDIR}"
      rm -rf "${WORKDIR}"
    }

    pushd "${WORKDIR}"
    git clone --depth 1 --recursive https://github.com/cupy/cupy.git
    CURRENT_COMMIT="$(git -C cupy rev-parse HEAD)"
    popd

    if [ "${CURRENT_COMMIT}" == "${LAST_TESTED_COMMIT}" ]; then
        echo "-> Skipping as already tested: ${CURRENT_COMMIT}"
        _clean_workdir
        return
    else
        echo "-> Testing commit: ${CURRENT_COMMIT}"
    fi

    pushd "${WORKDIR}"
    git clone --depth 1 --branch gh-pages git@github.com:kmaehashi/cupy-rocm-ci-report.git
    srun -p MI100 "${CURRENT_DIR}/test_runner.sh"
    popd

    pushd "${WORKDIR}/cupy-rocm-ci-report"
    git push
    popd

    LAST_TESTED_COMMIT="${CURRENT_COMMIT}"
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
        sleep $((300))
    done
}

main
