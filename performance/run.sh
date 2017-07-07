#!/bin/sh

docker run -d -w /root/cosbench/ --rm -P s3test:performance
