#!/bin/bash

#Just run everything in fully automated mode
#Override queries in order to surpress them

#Prepare environment
./prepare.sh
#Download/sync repos
./sync.sh
#Build targets
./build.sh
