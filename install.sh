#!/bin/bash
 
# This is the installer script of the mbm project
 
# Declare Variables
. /opt/mbm/config

# Create folder for screen logs and set rights
mkdir -p $LDIR
chmod 777 $LDIR
 
# Create dummy logfiles
for file in $CDIR/config_* ; do
        # Cut the Botname into peaces
        BOT=$(grep username $file | cut -d'"' -f4 | sed 's/@gmail.com//')
        fname=$(basename "$file")
        su $WUSR -c "echo "["$(date '+%X')"]" >> $LDIR/$BOT.log"
done
 
