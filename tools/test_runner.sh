#!/bin/bash

set -ue

. ~/CuPy_Team/rocm/profile_v2
echo "Host: $(hostname)"

WORKDIR="$(mktemp -d)"
trap _clean_workdir EXIT
_clean_workdir() {
  echo "Cleaning up the work dir: ${WORKDIR}"
  rm -rf "${WORKDIR}"
}

echo "Using work dir: ${WORKDIR}"
cd "${WORKDIR}"

pyenv local rocm-ci
# TODO: use latest numpy
pip install 'numpy<1.20' cython fastrlock pytest pytest-html
# TODO: use master branch
#git clone --recursive https://github.com/cupy/cupy.git
git clone --recursive --branch fix-rocm-test-import https://github.com/kmaehashi/cupy.git

pushd cupy
COMMIT_INFO="$(git show --no-patch --oneline)"
mkdir _output
echo "Building CuPy... ${COMMIT_INFO}"
CUPY_NUM_BUILD_JOBS=64 python setup.py develop &> _output/output_build.log || echo "Build failed."
echo "Running Test..."
python -m pytest -m "not slow" -rfEX --html _output/report.html --self-contained-html tests &> _output/output_test.log || echo "Test failed."
TEST_SUMMARY="$(cat _output/output_test.log | tail -n 1)"
popd

echo "Publishing results..."
git clone --branch gh-pages git@github.com:kmaehashi/cupy-rocm-ci-report.git
pushd cupy-rocm-ci-report/docs
rm -rf *
cp -a ../../cupy/_output/* .
git add -A .
git commit -m "Test results for: ${COMMIT_INFO}

${TEST_SUMMARY}"
git push
popd

echo "Done!"
