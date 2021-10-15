#!/bin/bash

#----------------------------------------------------------------------------------------------------
# THIS SECTION OF CODE CAN BE EDITED BY THE USER.

# Set location. Location codes can be found at: https://weather.codes
location="CAXX0301"  # Montreal, Canada
#location="UKXX1428"  # Greenwich, England
#location="CHXX0008"  # Beijing, China

# Set daytime and nighttime wallpapers.
daytime="/usr/share/backgrounds/odin.jpg"
nighttime="/usr/share/backgrounds/odin-dark.jpg"

#----------------------------------------------------------------------------------------------------

# Path to storage file.
storefile="/tmp/sunrise-sunset"

# Function to retrieve sunrise and sunset times from weather.codes, and store them in a file.
retrieveTimes()
{
    # Since wget stores the website data in a file, first delete any old files with this name to avoid an unexpected filename.
    tmpfile="/tmp/$location"
    if [ -f $tmpfile ]
    then
        rm $tmpfile
    fi
    # Retrieve the website data using wget.
    wget -q "https://weather.com/weather/today/l/$location" -O $tmpfile
    # Only continue if wget was successful.
    if [ $? -eq 0 ]
    then
        # Find the sunrise and sunset times in the website data.
        sunrise_UTC=$(grep -o 'sunriseTimeUtc\\\":[0-9]*,' $tmpfile | cut -d : -f 2 | cut -d , -f 1)
        sunset_UTC=$(grep -o 'sunsetTimeUtc\\\":[0-9]*,' $tmpfile | cut -d : -f 2 | cut -d , -f 1)
        # Store the location and sunrise and sunset times.
        echo $location > $storefile
        echo $sunrise_UTC >> $storefile
        echo $sunset_UTC >> $storefile
    else
        echo "ERROR: Could not connect to https://weather.com/weather/today/l/$location"
    fi
    # Delete the file containing the website data.
    rm $tmpfile
}

# If the date or location has changed, or if the storage file doesn't exist, retrieve new sunrise and sunset times.
if [ -f $storefile ]
then
    if [ "$(date -d @$(cat $storefile | cut -d $'\n' -f 2) +%F)" != "$(date +%F)" ] || [ "$(cat $storefile | cut -d $'\n' -f 1)" != $location ]
    then
        retrieveTimes
    fi
else
    # In case of both an unsuccessful wget and no previously-stored times to use, store some arbitrary location and times.
    echo "UKXX1428" > $storefile
    echo "$((6 * 60 * 60))" >> $storefile
    echo "$((18 * 60 * 60))" >> $storefile
    # If wget is successful, the above values will be overwritten.
    retrieveTimes
fi

# Read sunrise and sunset times from file.
location=$(cat $storefile | cut -d $'\n' -f 1)
sunrise_UTC=$(cat $storefile | cut -d $'\n' -f 2)
sunset_UTC=$(cat $storefile | cut -d $'\n' -f 3)

# Convert times to minutes so that date is not taken into account when comparing times.
sunrise=$((60 * 10#$(date -d @$sunrise_UTC +%H) + 10#$(date -d @$sunrise_UTC +%M)))
sunset=$((60 * 10#$(date -d @$sunset_UTC +%H) + 10#$(date -d @$sunset_UTC +%M)))

# Set environment for cron.
PID=$(pgrep gnome-session)
export DBUS_SESSION_BUS_ADDRESS=$(grep -z 'DBUS_SESSION_BUS_ADDRESS' /proc/$PID/environ | cut -d = -f 2-999 | cut -d $'\0' -f 1)

# Compare the current time to sunrise and sunset times, and change the wallpaper accordingly.
current_time=$((60 * 10#$(date +%H) + 10#$(date +%M)))
if [ $sunrise -lt $sunset ]
then
    if [ $sunrise -lt $current_time -a $current_time -lt $sunset ]
    then
        gsettings set org.gnome.desktop.background picture-uri $daytime
    else
        gsettings set org.gnome.desktop.background picture-uri $nighttime
    fi
else
    if [ $sunset -lt $current_time -a $current_time -lt $sunrise ]
    then
        gsettings set org.gnome.desktop.background picture-uri $nighttime
    else
        gsettings set org.gnome.desktop.background picture-uri $daytime
    fi
fi

# Function to print times.
printTimes()
{
    echo "Location: $location"
    echo "Sunrise:  $(date -d @$sunrise_UTC -R)"
    echo "Sunset:   $(date -d @$sunset_UTC -R)"
    echo "Current:  $(date -R)"
}
#printTimes

exit 0
