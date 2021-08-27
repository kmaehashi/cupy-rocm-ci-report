#!/bin/bash

set -ue

BRANCH=$1
GPU_MODEL=$(~/CuPy_Team/rocm/detect-target)

echo "Host: $(hostname) [${GPU_MODEL}]"
echo "Workdir: $(pwd)"

echo "Sourcing env vars"
. ~/CuPy_Team/rocm-4.3.0/profile

echo "Setting up Python env"
pyenv local rocm-ci
pip install numpy scipy cython fastrlock pytest pytest-html

pushd cupy
COMMIT_INFO="$(git show --no-patch --oneline)"
OUTPUT_DIR="$PWD/_output"
mkdir "${OUTPUT_DIR}"
echo "Building CuPy... ${BRANCH} ${COMMIT_INFO}"
echo "${BRANCH}: ${COMMIT_INFO}" > _output/output_build.log
echo "${BRANCH}: ${COMMIT_INFO}" > _output/output_test.log
CUPY_NUM_BUILD_JOBS=64 python setup.py develop &>> _output/output_build.log || echo "Build failed."
echo "Running Test..."
python -m pytest -m "not slow" -rfEX --html _output/report.html --self-contained-html tests &>> _output/output_test.log || echo "Test failed."
TEST_SUMMARY="$(cat _output/output_test.log | tail -n 1)"
popd

echo "Publishing results..."
pushd cupy-rocm-ci-report/docs
mkdir -p "${BRANCH}"
pushd "${BRANCH}"
rm -rf *
cp -a ${OUTPUT_DIR}/* .
git add -A .
git commit -m "Test Result [${GPU_MODEL}]: ${BRANCH} - https://github.com/cupy/cupy/commit/${COMMIT_INFO} - ${TEST_SUMMARY}"
popd
popd

echo "Done!"
