#!/bin/bash

#Just run everything is fully automated mode
#Override queries in order to surpress them

#Prepare environment
./prepare.sh
#Download/sync repos
./sync.sh
#Build targets
./build.sh
