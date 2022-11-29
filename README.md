# Android-x86-Helper
Helper scripts for building Android-x86

These scripts allow fully automated Android-x86 project building and contain some patches for common problems, found around internet.

Please note: I'm experienced programmer, but I'm new to Linux and bash, so there can be better solutions for some tasks, like deteciting already installed patches, patching files and allowing patch reverting in case of config changes. For now config changes aren't supported. I.e. you should set your confing in stone before doing anything else.

Scripts aim at building on virtual machine or live session.

Recommendations:
1) Ubuntu 18.04 LTS 64bit is recommended Linux version

Instruction:
1) Provide enough space for sources (~100G per branch), OpenGApps (~20G per branch), building (~100G per target, can be on separate drive)
2) Put scripts to your source directory
3) Edit config.sh
4) Run prepare.sh
5) Run sync.sh
6) Run build.sh

Known issues:
1) Android 10 still can't be built due to source code problems. I don't want to take responsibilty and fix them.
2) Some cases aren't tested, like removing out dir
