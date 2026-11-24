# Auto-Start-Scheduled.sh
Runs any program at a specific date, time and time zone.

## Usage:
   `sudo ./Auto-Start-Scheduled.sh PROGRAM DATE TIME TIMEZONE [INTERFACE] [-- extra args...]`

 ## Examples:
 
   `sudo ./Auto-Start-Scheduled.sh wireshark 2026-11-24 09:00 America/New_York wlan0mon`
   `sudo ./Auto-Start-Scheduled.sh tcpdump   2026-11-24 16:00 America/Los_Angeles wlan0mon`
   `sudo ./Auto-Start-Scheduled.sh airodump-ng 2026-11-24 16:00 UTC wlan0mon`
   `sudo ./Auto-Start-Scheduled.sh tshark 2026-11-24 16:00 UTC wlan0mon -- -i {IFACE} -w /root/cap.pcapng`
   `sudo ./Auto-Start-Scheduled.sh /root/myscript.sh 2026-11-24 16:00 UTC`


   PROGRAM   command name or full path
   DATE      YYYY-MM-DD
   TIME      24-hour HH:MM (16:00 = 4:00 PM)
   TIMEZONE  IANA name, not an abbreviation like PST/EST
             (e.g. America/Los_Angeles, America/New_York, UTC)
             Full list: timedatectl list-timezones
   INTERFACE optional. If given, it's passed to the program automatically
             (-i IFACE for most tools, positional for the aircrack-ng suite,
             -c IFACE for kismet).
   -- args   optional. Everything after "--" is passed to the program exactly
             as written, and {IFACE} is replaced with INTERFACE. When used,
             no automatic interface arguments are added.
