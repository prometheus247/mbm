#!/bin/bash

# This script scans for all running bot screensessions and kills them if running.
# Useful if you pulled a new release of the bot or if you want to make central config changes. 

# Declare Variables
. /opt/mbm/config

cd $WDIR

# How many bots do we have?
SUMBOTS=$(find $CDIR/config_* | wc -l)
echo "\nBoss, we have $SUMBOTS Bots playing around here."
echo "Lets kill them all.\n"
# Start the for loop for each bot 
for file in $CDIR/config_* ; do
        BOT=$(grep username $file | cut -d'"' -f4 | sed 's/@gmail.com//')
        fname=$(basename "$file")
        echo "----------------------------------------------\n"
        echo "Instance $fname! Bot: $BOT."
        SCREENID=$(su $WUSR -c "screen -ls | grep $BOT | cut -d"." -f1")
        if [ -z $SCREENID ] ; then
                echo "Is killed already."
        else
                kill $SCREENID
                echo "Killed."
        fi
done
