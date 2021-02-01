#!/bin/bash

while :; do
    echo "<<< $(date) >>> Starting..."
    srun "$(dirname "$0")/test_runner.sh"
    echo "<<< $(date) >>> Finished..."
    sleep $((3600))
done
