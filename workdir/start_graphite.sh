#!/bin/bash

docker run -d \
  --name graphite \
  -p 8080:80 \
  -p 2003:2003 \
  sitespeedio/graphite
