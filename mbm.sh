#!/bin/bash

# This is the main script of the mbm project

# Declare Variables

WDIR=/opt/PokemonGo-Bot
CDIR=$WDIR/configs
LDIR=/var/log/
LOG=$LDIR/lastruns.log
LINES=200
SECONDS=300
WUSR=nobody

SICK=0
OK=0
NORUN=0

# Lets get the rights properly
chown -R $WUSR $WDIR
# Just in case, move in to the correct folder
cd $WDIR

# How many bots are out there
SUMBOTS=$(find $CDIR/config_* | wc -l)
echo "\nBoss, we have $SUMBOTS Bots playing around here."
echo "Lets see if these splashers are doing their fucking jobs.\n"
# One run for each bot
for file in $CDIR/config_* ; do
        # Cut the Botname into peaces
        BOT=$(grep username $file | cut -d'"' -f4 | sed 's/@gmail.com//')
        fname=$(basename "$file")
        echo "----------------------------------------------"
        echo "Instance \033[1m$fname\033[0m! Bot: \033[1m$BOT\033[0m."
        # Get the Screen ID for later purposses
        SCREENID=$(su $WUSR -c "screen -ls | grep $BOT | cut -d"." -f1")

                # Check if the screen ID is actually set (not null)
                if [ -z $SCREENID ] ; then
                        echo "\033[31mHe isnt running at all???!\033[0m He aborted with:"
                        # Get the last 2 logentries
                        echo "$(tail -2 $LDIR/screen-$BOT.log)"
                        # Start the bot in a screen session
                        su $WUSR -c "screen -dmS $BOT python $WDIR/pokecli.py --config $file"
                        # Add +1 to the counter
                        NORUN=$(($NORUN + 1))
                        echo "\033[31mStarted.\033[0m"
                        # Write Log
                        echo "$(date '+%x %X'): $BOT didnt run - STARTING" >> $LOG
                else
                        echo "Screen is running. Lets see if he is actually working."

                        # Cut the Bot log into peaces to gather the last timestamp
                        THEN=$(cat $LDIR/screen-$BOT.log | grep '[0-9][0-9]\:' |  cut -d" " -f1 | tail -1 | sed 's/\[//' | sed 's/\]//')
                        # Retrieve the delta from the recent time, and the time of the last logentry
                        DELTA=$(( $(date +%s) - $(date -d $THEN +%s) ))
                        # Combine movements and walking around as one "HITS" thing
                        HITS=$(tail -$LINES $LDIR/screen-$BOT.log | grep -e Walking -e move |  wc -l)
                        # Count the pokemons captured
                        POKEMON=$(tail -$LINES $LDIR/screen-$BOT.log | grep "Captured" |  wc -l)

                                # Check hits and Delta with an OR. If one is failing, it will restart
                                if [ "$HITS" -lt 1 ] || [  "$DELTA" -gt $SECONDS ] ; then

                                        echo "\033[35mLooks sick to me, Boss:\033[0m"
                                        echo "The Gnassel only moved $HITS times - chillaxed for $DELTA sec!?"
                                        echo "Famous last words before he went down:\n"
                                        # Last log lines
                                        echo "$(tail -5 $LDIR/screen-$BOT.log)"
                                        # Kill the screen
                                        kill $SCREENID
                                        # Start the screen again
                                        screen -dmS $BOT python $WDIR/pokecli.py --config $file
                                        echo "$(date '+%x %X'): $BOT was defect - reSTARTING" >> $LOG
                                        # Add to the counter
                                        SICK=$(($SICK + 1))
                                        echo "\033[35mRestarted.\033[0m"
                                else
                                        echo "\nStats - last $LINES entries:"
                                        echo "\033[33m$POKEMON Pokemon captured.\033[0m"
                                        echo "\033[33m$HITS times moved.\033[0m"
                                        echo "\033[33m$DELTA sec since last update.\033[0m"
                                        echo "$(date '+%x %X'): $BOT OK. Last Run $THEN - $HITS moves in the last $LINES lines!" >> $LOG
                                        echo "\033[32mHes OK\033[0m."
                                        # Add to the counter
                                        OK=$(($OK + 1))
                                fi

                fi

done

echo "----------------------------------------------"
echo "Summary:\n"
echo "\033[32mOK\033[0m:                $OK / $SUMBOTS Bots"
echo "\033[35mSick\033[0m:              $SICK / $SUMBOTS Bots"
echo "\033[31mDidnt run\033[0m:         $NORUN / $SUMBOTS Bots\n"