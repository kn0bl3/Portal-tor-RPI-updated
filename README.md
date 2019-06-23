# Portal-tor-RPI-updated
Based on the_grugq's Portal tor router


Tested on RPI 3 Model B (Should work on RPI 2 & 3)


Needed:
 - Raspberry PI (1 Wired network interface for LAN and 1 Wireless network interface for WAN) // you can use a Wifi usb dongle
 - Ethernet cord and publci wifi (obviously)
 - microsd card (for RPI storage)
 - A method of accessing the microsd card from a Linux machine
 - a Linux machine with bash
Instructions:
 - Identify the name and location of the microsd cards special device file on the linux machine that will be used for preparing the SD card.
 - run stage1.sh as root EX: "sudo ./stage1.sh".
   -- answer the questions when prompted (SD Card's device file path)
   -- At some points it may seem like its hung on something, this is normal (while the script unpacks the ARM img into the SD Card's root partition)
 - Boot the RPI and establish an internet connection before running stage2.sh otherwise it will fail.
 - Once you have a temporary connection to the internet on the raspberry pi, run the stage2.sh script that is located in the root directory as root. EX: "/stage2.sh"
 - Answer the questions when prompted. If something fails please report it. Tested and working on RPI 3 Model B as of release.
