#!/bin/bash

#Just run everything except sync in fully automated mode
#Override queries in order to surpress them

#Prepare environment
./prepare.sh
#Download/sync repos - skip this stage
#./sync.sh
#Build targets
./build.sh
