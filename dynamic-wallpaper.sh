#!/bin/bash

#Set location.
#location="CHXX0008" #Beijing, China
#location="UKXX1428" #Greenwich, England
location="CAXX0301" #Montreal, Canada
#location="CAXX1026" #Almonte, Canada

#Path to storage file.
storefile="/tmp/sunrise-sunset.txt"

#Function to retrieve sunrise and sunset times from weather.com, and store them in a file.
retrieveTimes()
{
    #Since wget stores the website data in a file, first delete any old files with this name to avoid an unexpected filename.
    tmpfile="/tmp/$location"
    if [ -f $tmpfile ]
    then
        rm $tmpfile
    fi
    #Retrieve the website data using wget.
    wget -q "https://weather.com/weather/today/l/$location" -O $tmpfile
    #Only continue if wget was successful.
    if [ $? -eq 0 ]
    then
        #Find the sunrise and sunset times in the website data.
        sunrise_UTC=$(grep -o 'sunriseTimeUtc\\\":[0-9]*,' $tmpfile | cut -d : -f 2 | cut -d , -f 1)
        sunset_UTC=$(grep -o 'sunsetTimeUtc\\\":[0-9]*,' $tmpfile | cut -d : -f 2 | cut -d , -f 1)
        #Store the location, date, and sunrise and sunset times.
        echo $location > $storefile
        echo $sunrise_UTC >> $storefile
        echo $sunset_UTC >> $storefile
    else
        echo "ERROR: Could not connect to https://weather.com/weather/today/l/$location"
    fi
    #Delete the file containing the website data.
    rm $tmpfile
}

#If the date or location has changed, or if the storage file doesn't exist, retrieve new sunrise and sunset times.
if [ -f $storefile ]
then
    if [ "$(date -d @$(cat $storefile | cut -d $'\n' -f 2) +%F)" != "$(date +%F)" ] || [ "$(cat $storefile | cut -d $'\n' -f 1)" != $location ]
    then
        retrieveTimes
    fi
else
    #In case of both an unsuccessful wget and no previously-stored times to use, store some arbitrary location and times.
    echo "UKXX1428" > $storefile
    echo "$((6 * 60 * 60))" >> $storefile
    echo "$((18 * 60 * 60))" >> $storefile
    #If wget was successful, the above values will be overwritten.
    retrieveTimes
fi

#Read sunrise and sunset times from file (as well as location).
location=$(cat $storefile | cut -d $'\n' -f 1)
sunrise_UTC=$(cat $storefile | cut -d $'\n' -f 2)
sunset_UTC=$(cat $storefile | cut -d $'\n' -f 3)

#Convert times to minutes so that date is not taken into account when comparing to current time.
sunrise=$((60 * 10#$(date -d @$sunrise_UTC +%H) + 10#$(date -d @$sunrise_UTC +%M)))
sunset=$((60 * 10#$(date -d @$sunset_UTC +%H) + 10#$(date -d @$sunset_UTC +%M)))
if [ $sunrise -gt $sunset ]
then
    sunrise=$(($sunrise - 1440))
fi

#Set environment for cron.
PID=$(pgrep gnome-session)
export DBUS_SESSION_BUS_ADDRESS=$(grep -z 'DBUS_SESSION_BUS_ADDRESS' /proc/$PID/environ | cut -d = -f 2-999 | cut -d $'\0' -f 1)

#Check the current time, and change the wallpaper accordingly.
current_time=$((60 * 10#$(date +%H) + 10#$(date +%M)))
if [ $current_time -gt $sunrise -a $current_time -lt $sunset ]
then
    gsettings set org.gnome.desktop.background picture-uri "/usr/share/backgrounds/odin.jpg"
else
    gsettings set org.gnome.desktop.background picture-uri "/usr/share/backgrounds/odin-dark.jpg"
fi

#Function to print times.
printTimes()
{
    echo "Location: $location"
    echo "Sunrise:  $(date -d @$sunrise_UTC -R)"
    echo "Sunset:   $(date -d @$sunset_UTC -R)"
    echo "Current:  $(date -R)"
}
#printTimes

exit 0
