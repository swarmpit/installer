#!/bin/bash
docker build --build-arg tag=$1 -t swarmpit/install:$1 .
