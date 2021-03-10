#!/bin/bash

set -ue

echo "Host: $(hostname)"
echo "Workdir: $(pwd)"

echo "Sourcing env vars"
. ~/CuPy_Team/rocm/profile_v2

echo "Setting up Python env"
pyenv local rocm-ci
pip install numpy cython fastrlock pytest pytest-html

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
pushd cupy-rocm-ci-report/docs
rm -rf *
cp -a ../../cupy/_output/* .
git add -A .
git commit -m "Test results for: https://github.com/cupy/cupy/commit/${COMMIT_INFO} - ${TEST_SUMMARY}"
popd

echo "Done!"
