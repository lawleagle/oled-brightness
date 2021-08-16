#!/bin/bash
cd "$(dirname ${BASH_SOURCE[0]})"



# where is the backlight directory?
backlight_dir="/sys/class/backlight/intel_backlight/"

# which screen is the oled panel?
# if not set, it will default to `xrandr | grep -m 1 ' connected ' | awk '{print $1}'`
# leaving it empty will "just work" in most cases
#
# do xrandr command for a list of screen names
# Examples are: e-DP1, eDP-1, eDP-1-1
oled_screen=''

# Not tested
# if true, the program will look for changes in 'day_night.txt' and update the redshift temperature accordingly
# check 'set_day_night.sh' to see how 'day_night.txt' is updated
use_redshift=false

# nightshift temperature during the day
daylight_temperature=6500

# nightshift temperature during the night
night_temperature=3500

# how much to change the temperature of the night light on one frarme
# the lower the value, the longer it takes to transition to a new redshift temperature
# has to be an integer value, no fractional values are allowed
redshift_step_size=50

# How quickly to change the screen brightness?
# Values between 1(immediately) to 500(it takes about 10 seconds for the whole range) make sense.
# Default is 10.
brightness_step_size_factor=10

# If no oled_screen is set - try to guess it
if [[ -z $oled_screen ]]; then
  oled_screen=$(xrandr --current | grep -m 1 ' connected' | awk '{print $1}')
  echo "Guessed OLED display as: $oled_screen"
fi

# check backlight folder
if ! test -d "$backlight_dir"
then
	echo "ERROR: wrong configuration. Backlight directory does not exist."
	exit 0
fi
# check dependency
if ! command -v inotifywait
then
	echo "ERROR: dependency 'inotifywait' is not installed. Sorry, but this script cannot run without inotifywait"
	exit 0
fi


max_brightness=$(cat "$backlight_dir/max_brightness")	


target_brightness=$(cat "$backlight_dir/brightness")
current_brightness=$max_brightness

target_shift=$daylight_temperature
current_shift=$daylight_temperature

while true;
do
	target_brightness=$(cat "$backlight_dir/brightness")

	day_night=$(cat "./file-pipes/day-night.txt")
	if $use_redshift && [ "$day_night" = "NIGHT" ]
	then
		target_shift=$night_temperature
	else
		target_shift=$daylight_temperature
	fi

	if [ $current_brightness -eq $target_brightness ] && [ $current_shift -eq $target_shift ]
	then
		inotifywait -e close_write $backlight_dir/brightness -e close_write './file-pipes/day-night.txt' > /dev/null
		continue
	fi

	step=$((current_brightness - target_brightness))
	if [ $step -lt 0 ]; then step=$((-step)); fi
	brightness_step_size=$((step / brightness_step_size_factor))
	if [ $brightness_step_size -lt $((max_brightness / 500)) ]; then brightness_step_size=$((max_brightness / 500)); fi
	if [ $step -gt $brightness_step_size ]; then step=$brightness_step_size; fi

	if [ $current_brightness -gt $target_brightness ]
	then
		current_brightness=$((current_brightness - step))
	else
		current_brightness=$((current_brightness + step))
	fi

	percent=`echo "$current_brightness / $max_brightness * 0.9 + 0.1" | bc -l`

	step=$((current_shift - target_shift))
	if [ $step -lt 0 ]; then step=$((-step)); fi
	if [ $step -gt $redshift_step_size ]; then step=$redshift_step_size; fi

	if [ $current_shift -gt $target_shift ]
	then
		current_shift=$((current_shift - step))
	else
		current_shift=$((current_shift + step))
	fi

	if $use_redshift
	then
		redshift -m randr:screen=$oled_screen -P -O $current_shift -b $percent
		xrandr | grep -m 1 ' connected ' | awk '{print $1}' | while read -r line
		do
			if ! [ "$line" == "$oled_screen" ]
			then
				redshift -m randr:screen=$line -P -O $current_shift
			fi
		done
	else
		xrandr --output $oled_screen --brightness $percent
	fi
done

