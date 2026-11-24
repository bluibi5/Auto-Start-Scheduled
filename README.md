# Auto-Start-Scheduled.sh
Auto-Start-Scheduled is a vibe-coded script that simply starts a tool at a specified date, time, and timezone. Optionally you can also specify the network interface you would like the tool to use.

This script was written to automatically start a tool such as wireshark or airodump-ng, but obviously you can schedule just about any tool to run with it.

## Usage: 

### Download the script & cd into the folder:
```
git clone https://github.com/bluibi5/Auto-Start-Scheduled.sh
cd Auto-Start-Scheduled
```

### Change access permissions:
`chmod +x Auto-Start-Scheduled.sh`

### Run the script: 
`sudo ./Auto-Start-Scheduled.sh date time time_zone interface`

Date must be in the format year-month-day: example 2026-11-23
Time must be in 24 hour time with a colon: example 14:00
Time zone should not have any spaces instead using underscores: example America/Los_Angeles 

The script accepts any time zone name in the IANA database installed on your system (the files under /usr/share/zoneinfo). There are around 600. 
You can find them with the following commands: 
```
timedatectl list-timezones                 # all canonical names
timedatectl list-timezones | grep -i york  # search for one
```
The interface name is optional and defaults to `wlan0mon` where relevant. 

#### Full example script command: 
`sudo ./Auto-Start-Scheduled.sh 2026-11-23 14:00 America/Los_Angeles wlan0mon`
