#!/bin/bash

set -uex

while :; do
    echo "<<< $(date) >>> Starting..."
    # max 8 hours for test session
    srun -t 0-8 "$(dirname "$0")/test_runner.sh"
    echo "<<< $(date) >>> Finished..."
    sleep $((3600 * 12))
done
