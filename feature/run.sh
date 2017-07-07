#!/bin/sh

docker run --rm --name tmp-1 -w /root/runner/ -v ${PWD}/runner/:/root/runner:rw s3test:feature ./check.sh

