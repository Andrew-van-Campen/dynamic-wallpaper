# dynamic-wallpaper
A Bash script that switches wallpaper in sync with sunrise and sunset times.

### Installation Instructions
1. Download the shell script file [dynamic-wallpaper.sh](https://github.com/Andrew-van-Campen/dynamic-wallpaper/blob/main/dynamic-wallpaper.sh) and save it to the location of your choice (right-click on "Raw" and click "Save Link As...").

2. Make the script file executable using the command:
> `chmod +x [some/path/]dynamic-wallpaper.sh`

3. Open the script file with a text editor. You'll see a section of code labelled "`THIS SECTION OF CODE CAN BE EDITED BY THE USER`". Edit this section of code to set your location and your daytime and nighttime wallpapers, then save the file.

4. Set the script to run every minute using cron.
    1. First, ensure that cron is running using the command:
    > `/sbin/service cron start`

    2. Next, set the `EDITOR` environment variable to the text editor of your choice (Leafpad, in this example), as follows:
    > `export EDITOR=leafpad`

    3. Enter the following command to add a new cron task (it will open a file using your chosen text editor):
    > `crontab -e`

    4. Add the following line to the end of the file, then save the file and close the text editor:
    > `* * * * * [some/path/]dynamic-wallpaper.sh`

5. dynamic-wallpaper is now installed! If you change locations or wish to set new daytime and nighttime wallpapers, you'll have to make the appropriate edits to the script file.
