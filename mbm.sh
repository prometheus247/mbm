#!/bin/bash
### BEGIN INFO
# Short-Description: This is the main script of the mbm project
# Project:           https://github.com/prometheus247/mbm
# Author:            prometheus247 & viruz82
# Version:           1.0 beta
### END INFO

# Declare Variables
. /opt/mbm/config

SICK=0
OK=0
NORUN=0
BANNED=0

start() {
		# How many bots are out there
		SUMBOTS=$(find $CDIR/config_* | wc -l)
		# Let's get the rights properly
		chown -R $WUSR $WDIR
		# Just in case, move in to the correct folder
		cd $WDIR
        echo -e "\nBoss, we have $SUMBOTS Bots playing around here."
        echo -e "Let's see if these splashers are doing their fucking jobs.\n"
        # One run for each bot
        for file in $CDIR/config_* ; do
                # Cut the Botname into peaces
                BOT=$(grep username $file | cut -d'"' -f4 | sed 's/\@gmail.com//')
                fname=$(basename "$file")
                echo "----------------------------------------------"
                echo -e "Instance \033[1m$fname\033[0m! Bot: \033[1m$BOT\033[0m."
                # Get the Screen ID for later purposses
                SCREENID=$(su $WUSR -c "screen -ls | grep $BOT | cut -d"." -f1")
                USERNAME=$(cat $file | grep username | cut -d'"' -f4)
                PASSWORD=$(cat $file | grep password | cut -d'"' -f4)
                LOCATION=$(cat $file | grep location | cut -d'"' -f4)
                GMAP=$(cat $file | grep gmapkey | cut -d'"' -f4)
        
						# Check if the screen ID is actually set (not null)
                        if [ -z $SCREENID ] ; then
                                echo -e "\033[31mHe isnt running at all???!\033[0m He aborted with:"
                                # Get the last 2 logentries
                                echo "$(tail -2 $LDIR/$BOT.log)"
                                # Start the bot in a screen session
                                su $WUSR -c "screen -dmS $BOT python $WDIR/pokecli.py --config $file"
                                # Add +1 to the counter
                                NORUN=$(($NORUN + 1))
                                echo -e "\033[32mStarted.\033[0m"
                                # Write Log
                                echo "$(date '+%x %X'): $BOT didnt run - STARTING" >> $LOG
                        else
                                echo "Screen is running. Let's see if he is actually working."
        
                                # Cut the Bot log into peaces to gather the last timestamp
                                THEN=$(cat $LDIR/$BOT.log | grep '[0-9][0-9]\:' | cut -d" " -f1 | tail -1 | sed 's/\[//' | sed 's/\]//')
                                # Retrieve the delta from the recent time, and the time of the last logentry
                                DELTA=$(( $(date +%s) - $(date -d $THEN +%s) ))
                                # Combine movements, walking and exchanging around as one "HITS" thing
                                HITS=$(tail -$LINES $LDIR/$BOT.log | grep -e Walking -e move -e Exchanging | wc -l)
                                # Count the pokemons captured
                                POKEMON=$(tail -$LINES $LDIR/$BOT.log | grep "Captured" |  wc -l)
                                # Is the bot banned?
                                BAN=$(tail -5 $LDIR/$BOT.log | grep -i "softbanned" )
		
										if [ -z $BAN ] ; then
					
											# Check hits and Delta with an OR. If one is failing, it will restart
											if [ "$HITS" -lt 1 ] || [  "$DELTA" -gt $SECONDS ] ; then

												echo -e "\033[35mLooks sick to me, Boss:\033[0m"
												echo "The Gnassel only moved $HITS times - chillaxed for $DELTA sec!?"
												echo -e "Famous last words before he went down:\n"
												# Last log lines
												echo "$(tail -5 $LDIR/$BOT.log)"
												# Kill the screen
												kill $SCREENID
												# Start the screen again
												su $WUSR -c "screen -dmS $BOT python $WDIR/pokecli.py --config $file"
												echo "$(date '+%x %X'): $BOT was defect - reSTARTING" >> $LOG
												# Add to the counter
												SICK=$(($SICK + 1))
												echo -e "\033[35mRestarted.\033[0m"
											else
												echo -e "\nStats - last $LINES entries:"
												echo -e "\033[33m$POKEMON Pokemon captured.\033[0m"
												echo -e "\033[33m$HITS times moved.\033[0m"
												echo -e "\033[33m$DELTA sec since last update.\033[0m"
												echo "$(date '+%x %X'): $BOT OK. Last Run $THEN - $HITS moves in the last $LINES lines!" >> $LOG
												echo -e "\033[32mHes OK\033[0m."
												# Add to the counter
												OK=$(($OK + 1))
											fi
										else
												echo -e "\033[36mThat's a banned bot!\033[0m"
												BANNED=$(($BANNED + 1))
												# Start the screen again
												su $WUSR -c "screen -dmS $BOT python $WDIR/pokecli.py --config $file"
												echo "$(date '+%x %X'): $BOT is softbanned!" >> $LOG
										fi
						fi


		done
        
        echo "----------------------------------------------"
        echo -e "Summary:\n"
        echo -e "\033[32mOK\033[0m:\t\t$OK / $SUMBOTS Bots"
        echo -e "\033[35mSick\033[0m:\t\t$SICK / $SUMBOTS Bots"
        echo -e "\033[31mDidn't run\033[0m:\t$NORUN / $SUMBOTS Bots\n"
}

stop() {
		# How many bots are out there
		SUMBOTS=$(find $CDIR/config_* | wc -l)
        echo -e "\nBoss, we have $SUMBOTS Bots playing around here."
        echo -e "Lets kill them all.\n"
        # Start the for loop for each bot 
        for file in $CDIR/config_* ; do
                BOT=$(grep username $file | cut -d'"' -f4 | sed 's/@gmail.com//')
                fname=$(basename "$file")
                echo -e "----------------------------------------------\n"
                echo "Instance $fname! Bot: $BOT."
                SCREENID=$(su $WUSR -c "screen -ls | grep $BOT | cut -d"." -f1")
                if [ -z $SCREENID ] ; then
                        echo -e "\033[31mIs killed already\033[0m"
                else
        				su $WUSR -c "screen -S $SCREENID -X quit"
                        echo -e "\033[32mKilled\033[0m"
                fi
        done
}

install() {
        echo -e "PokemonGo-Bot already installed in /opt?\nType \033[31mno\033[0m for installing or just enter if it's installed."
         read ANSWER1
         if [ "$ANSWER1" == "no" ]
             then
        		 echo -e "\033[33mInstalling PokemonGo-Bot...\033[0m"
        		 cd /opt
        		 git clone -b dev https://github.com/PokemonGoF/PokemonGo-Bot.git
        		 cd $WDIR
        		 pip install --upgrade -r requirements.txt > /dev/null 2>&1
                 echo -e "\033[32mPokemonGo-Bot successfully installed. :-)\033[0m"
             else
        		 cd $WDIR
        		 echo -e "\033[33mUpdating PokemonGo-Bot...\033[0m"
        		 sleep 3
        		 git pull
        		 echo -e "\n\033[33mUpdating requirements...\033[0m"
        		 pip install --upgrade -r requirements.txt > /dev/null 2>&1
                 echo -e "\n\033[32mPokemonGo-Bot successfully updated. :-)\033[0m"
         fi
        
        # Create folder for screen logs and set rights
        mkdir -p $LDIR
        chmod 777 $LDIR
        
        # Create dummy logfiles
        for file in $CDIR/config_* ; do
                # Cut the Botname into peaces
                BOT=$(grep username $file | cut -d'"' -f4 | sed 's/@gmail.com//')
                fname=$(basename "$file")
                su $WUSR -c "echo ""$(date '+%x %X')"" >> $LDIR/$BOT.log"
        done
        
        # Enable screen logging
        cat /etc/screenrc | grep -vE '(logging|logfile|deflog)' > /etc/screenrc.tmp
        echo -e "#\n# Enable logging.\nlogfile $LDIR/%S.log\ndeflog on" >> /etc/screenrc.tmp
        mv /etc/screenrc.tmp /etc/screenrc
        
        # Move in to the mbm folder
		cd $MBMDIR
        echo -e "Start PokemonGo-Bot?\nType \033[32myes\033[0m to start or just enter to not start."
        read ANSWER2
        if [ "$ANSWER2" == "yes" ]
            then
        		bash $0 start
            else
                echo -e "Thanks for using our installer. :-)\n"
        		bash $0 help
        fi
}

case "$1" in
	start)
       start
       ;;
	stop)
       stop
       ;;
	restart)
       stop
       start
       ;;
	install)
       install
       ;;
	help)
       echo "Usage: bash $0 {start|stop|restart|install|help}"
	   ;;
        *)
       start
esac
