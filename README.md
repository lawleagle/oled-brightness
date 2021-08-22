# OLED Linux
**oled-linux.sh** will watch the backlight changes in **/sys/class/backlight/intel_backlight** and apply changes over there to OLED screens

## Features
- Brightness Change on OLED screens on Linux (main point of the repository)
- Smooth Brightness Control (changes in brightness will be applied gradually instead of just jumping to the new brightness)
- Night Light Support (with or without geolocation and with smooth cycle changes)
- Multiple Displays Support
- Works directly on X, is not tightly coupled to any desktop environment, so it should work well in almost any circumstance

## Dependencies
- **inotifywait** - used for watching for file changes with as little CPU usage as possible
```sh
sudo apt install inotify-tools
```
- **sunwait** - (optional) used for monitoring day/night cycle for night light feature
- **geoclue2** - (optional) used for getting current location for day/night cycle for night light feature. Optional because locaiton can be set manually

## Installation (Ubuntu)

```bash
sudo apt install inotify-tools
```

Clone the repository and add **oled-linux.sh** to your [startup applications](https://help.ubuntu.com/stable/ubuntu-help/startup-applications.html.en).
You can test the script by simply running it, but you should add it to startup applications to run it automatically.

Optionally you can add **get-current-location.sh**, **watch-location.sh**, **run-set-day-night.sh** for Redshift (Night Light) functionality.
This also requires installing:
```bash
sudo apt install redshift geoclue-2.0 geoclue-2.0 geoclue-2-demo
snap install sunwait
```

## Night Light
If night light is enabled in **oled-linux.sh**, all brightness changes are applied using `redshift`, which allows for Night Light support. If Night Light is disabled in the config, brightness changes will be applied with **xrandr**.
**oled-linux.sh** will also watch for the file **file-pipes/day-night.txt**, and if the contents of the file are **NIGHT**, a night filter will be applied

Default values for night filter:  
`DAY = 6500` (default, unchanged display)
`NIGHT = 3500` (default night-filter value)

We can change the night filter value to whatever you want by modifying **oled-linux.sh** (see configuration section). W can also adjuse the daylight value so we can add a filter during the day too.

Night Light can work without geolocation, in which case you can skip loading **get-current-location.sh** and **watch-location.sh**, but if this option is chosen, one must provide location manually in **file-pipes/location.txt** in the following format: **LATITUDE_DEGREES[N/S] LONGITUDE_DEGREES[E/W]**.
```bash
> cat location.txt
26.123000N 12.578000E
```

## Configuration
Configuration is provided at the top of **oled-linux.sh**.
```bash
##
# Backlight driver file location
backlight_dir="/sys/class/backlight/intel_backlight/"

##
# OLED Display Name
# If not set the script will attempt to guess it.
# Use `xrandr --current | grep ' connected'` to get a list of all conntected
# displays. Examples are: e-DP1, eDP-1, eDP-1-1
oled_screen=''

##
# Brightness step size
# How quickly to change the screen brightness?
# Values between 1(immediately) to 500(it takes about 10 seconds for the whole range) make sense.
# Default is 10.
brightness_step_size_factor=10

##
# Redshift (Night Light) functionality
# If enabled the script will also change the color temperature of the display.
use_redshift=true

##
# Color temperature during the day
daylight_temperature=6500

##
# Color temperature at night
night_temperature=4800

##
# Color temperature step
# how much to change the temperature of the night light on one frarme
# the lower the value, the longer it takes to transition to a new redshift temperature
# has to be an integer value, no fractional values are allowed
redshift_step_size=50
```

## Performance
**oled-linux.sh** uses inotifywait to watch for changes in **file-pipes/day-night.txt** and **/sys/class/backlight/intel_backlight**, so it will only work when there are some brightness changes to apply.

**get-current-location.sh** checks for location information using geoclue2 every 10 minutes and writes that info to **file-pipes/current-location.sh**

**watch-location.sh** watches for changes in **file-pipes/current-location.sh** and if the location changed, writes the new location to **file-pipes/location.txt**

**set-day-night.sh** writes **DAY** or **NIGHT** to **file-pipes/current-location.sh** whenever it becomes day/night outside according to location data and when the location data is changed. Whenever these things are not happening, this script will sleep.

## Troubleshooting
If you are running with geolocation enabled, it might take a few minutes for location data to become available. In most cases, location data is only available on active internet connection.
Maybe... oled-linux is controlling the wrong display? If so, manually set the **oled-screen** value to what it should be (check config section).

## Contribute
If you found bugs, report them on the issues page. If you modified something, make a pull request.

## Community
There is a channel for this project on this server. If more will be required, more will be provided.
Discord: https://discord.gg/t4nV3gpJbU
