# Android-x86-Helper
Helper scripts for building Android-x86

These scripts allow fully automated Android-x86 project building and contain some patches for common problems, found around internet.

Scripts are provided as is without any warranty - explicit or implicit. I do it just for fun. I'm neither AOSP, nor Android-x86 maintainer. Therefore I'm not responsible for quality of images themselves. No guarantees, that they are suitable for any particular purposes. I just try to fix problems, that prevent building process from being completed successfully.

Please note: I'm experienced programmer, but I'm new to Linux and bash, so there can be better solutions for some tasks, like detecting already applied patches, patching files and reverting patches in case of config changes.

Scripts aim at building on virtual machine or live session. Builing on real system is possible, but not recommended.

Recommendations:
1) Ubuntu 18.04 LTS 64bit is recommended Linux version (I personally prefer Mate version)
2) 8Gb of RAM are enough for building Android 9 and 10
3) 16Gb are recommended for Android 8.1 and 11 (8.1 doesn't seem to have memory usage optimization, that 11 has)
4) According to tests 14Gb are actually enough. It's important, if you use VM, your host has exactly 16Gb and would hang in case of allocating them all. But there is small chance, that virtual PC will crash in this case, as 2Gb still aren't enough for host system. May be it's better to use 13Gb+3Gb configuration.
5) Overall common formula is - around 2-3Gb per CPU core used plus 4Gb for OS itself (so 4 cores = 16Gb)

Instruction:
1) Provide enough space for sources (~100Gb per branch), OpenGApps (~20Gb per branch) and building (~100Gb per target, can be on separate drive)
2) Put scripts to your source directory
3) Edit config.sh
4) Run prepare.sh (1-2 minutes)
5) Run sync.sh (1-2 hours per branch, depending on your ISP's throughput)
6) Run build.sh (several hours per target, depending on number of CPU cores used and disk's throughput)

Or just run start.sh, if you want to do everything in fully automated mode. Just don't forget to override all queries. Another script - startnosync.sh is provided for case, when you want to run in fully automated mode, but don't want to waste time on resyncing things. Use finish.sh to restore all backups.

Scripts can be interrupted at any moment and continue from exactly the same stage, except small overhead to refresh current state (2-5 minutes). Just don't remove ISO files from export directory before completing build process. Especially if you remove out directories to free disk space. They're used to detect, what tasks are already completed. But if something gets broken (sometimes it happens, when sync process is interrupted) - just remove .git from corresponding directory, remove broken files if neccessary and then resync.

Known issues:
1) Android 10 requires source code fixing
2) SetupWizard crashes on Android 11, but you can skip it via boot menu or via SETUPWIZARD=0 kernel command line parameter
3) Cursor is blinking in graphic mode on Android 11
4) Navigation bar is broken for some non-standard resolutions, like 1280x1024
5) Virtio GPU drivers aren't enabled in kernel, so emulation is slow
6) Some cases aren't tested, like removing out dir
