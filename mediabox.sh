#!/bin/bash

# Check that script was run not as root or with sudo
if [ "$EUID" -eq 0 ]
  then echo "Please do not run this script as root or using sudo"
  exit
fi

# set -x

# See if we need to check GIT for updates
if [ -e .env ]; then
    # Stash any local changes to the base files
    git stash > /dev/null 2>&1
    printf "Updating your local copy of Mediabox.\\n\\n"
    # Pull the latest files from Git
    git pull
    # Check to see if this script "mediabox.sh" was updated and restart it if necessary
    changed_files="$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)"
    check_run() {
        echo "$changed_files" | grep --quiet "$1" && eval "$2"
    }
    # Provide a message once the Git check/update  is complete
    if [ -z "$changed_files" ]; then
        printf "Your Mediabox is current - No Update needed.\\n\\n"
    else
        printf "Mediabox Files Update complete.\\n\\nThis script will restart if necessary\\n\\n"
    fi
    # Rename the .env file so this check fails if mediabox.sh needs to re-launch
    mv .env 1.env
    read -r -p "Press any key to continue... " -n1 -s
    printf "\\n\\n"
    # Run exec mediabox.sh if mediabox.sh changed
    check_run mediabox.sh "exec ./mediabox.sh"
fi

# After update collect some current known variables
if [ -e 1.env ]; then
    # Grab the CouchPotato, NBZGet, & PIA usernames & passwords to reuse
    daemonun=$(grep TUSER 1.env | cut -d = -f2)
    daemonpass=$(grep TPASS 1.env | cut -d = -f2)
    piauname=$(grep PIAUNAME 1.env | cut -d = -f2)
    piapass=$(grep PIAPASS 1.env | cut -d = -f2)
    piaserv=$(grep PIASERV 1.env | cut -d = -f2)
    dldirectory=$(grep DLDIR 1.env | cut -d = -f2)
    tvdirectory=$(grep TVDIR 1.env | cut -d = -f2)
    moviedirectory=$(grep MOVIEDIR 1.env | cut -d = -f2)
    musicdirectory=$(grep MUSICDIR 1.env | cut -d = -f2)
    trratiol=$(grep TRATIOL 1.env | cut -d = -f2)
    trshareratio=$(grep TSHARER 1.env | cut -d = -f2)
    trsharel=$(grep TSHAREL 1.env | cut -d = -f2)
    trsharetime=$(grep TSHARET 1.env | cut -d = -f2)
    trdlimit=$(grep TDLIMIT 1.env | cut -d = -f2)
    trulimit=$(grep TULIMIT 1.env | cut -d = -f2)
    trupspeed=$(grep TUPSPEED 1.env | cut -d = -f2)
    trdnspeed=$(grep TDNSPEED 1.env | cut -d = -f2)
    trblist=$(grep TBLIST 1.env | cut -d = -f2)
    trblisturl=$(grep TBLISTURL 1.env | cut -d = -f2)
    trgpeers=$(grep TGPEERS 1.env | cut -d = -f2)
    trtpeers=$(grep TTPEERS 1.env | cut -d = -f2)
    trutp=$(grep TUTP 1.env | cut -d = -f2)
    trpex=$(grep TPEX 1.env | cut -d = -f2)
    trdht=$(grep TDHT 1.env | cut -d = -f2)
    trlpd=$(grep TLPD 1.env | cut -d = -f2)
    trauth=$(grep TAUTH 1.env | cut -d = -f2)
    trdqueue=$(grep TDQUEUE 1.env | cut -d = -f2)
    truqueue=$(grep TUQUEUE 1.env | cut -d = -f2)
    trwebui=$(grep TWEBUI 1.env | cut -d = -f2)
    # Echo back the media directioies to see if changes are needed
    printf "These are the Media Directory paths currently configured.\\n"
    printf "Your DOWNLOAD Directory is: %s \\n" "$dldirectory"
    printf "Your TV Directory is: %s \\n" "$tvdirectory"
    printf "Your MOVIE Directory is: %s \\n" "$moviedirectory"
    printf "Your MUSIC Directory is: %s \\n" "$musicdirectory"
    read  -r -p "Are these directiores still correct? (y/n) " diranswer
    # Echo back the Transmission settings to see if changes are needed
    printf "\\n\\nThese are the Transmission settings currently configured:\\n"
    printf "\\nYour upload ratio enabled is: %s \\n" "$trratiol"
    printf "Your upload ratio is: %s \\n" "$trshareratio"
    printf "Your upload time enabled is: %s \\n" "$trsharel"
    printf "Your upload time is: %s \\n" "$trsharetime"
    printf "Your upload limit enabled is: %s \\n" "$trulimit"
    printf "Your upload speed is: %s \\n" "$trupspeed"
    printf "Your download limit enabled is: %s \\n" "$trdlimit"
    printf "Your download speed: %s \\n" "$trdnspeed"
    printf "Your blocklist setting is: %s \\n" "$trblist"
    printf "Your current blocklist is: %s \\n" "$trblisturl"
    printf "Your global peers is: %s \\n" "$trgpeers"
    printf "Your torrent peers is: %s \\n" "$trtpeers"
    printf "Your UTP setting is: %s \\n" "$trutp"
    printf "Your PEX setting is: %s \\n" "$trpex"
    printf "Your DHT setting is: %s \\n" "$trdht"
    printf "Your LPD setting is: %s \\n" "$trlpd"
    printf "Your web auth setting is: %s \\n" "$trauth"
    printf "Your web ui is currently: %s \\n" "$trwebui"
    printf "Your download queue is: %s \\n" "$trdqueue"
    printf "Your upload queue is: %s \\n\\n" "$truqueue"
    read  -r -n 1 -p "Are these settings still correct? (y/n) " btanswer
    # Now we need ".env" to exist again so we can stop just the Medaibox containers
    mv 1.env .env
    # Stop the current Mediabox stack
    printf "\\n\\nStopping Current Mediabox containers.\\n\\n"
    docker-compose stop
    # Make a datestampted copy of the existing .env file
    mv .env "$(date +"%Y-%m-%d_%H:%M").env"
fi

# Get local Username
localuname=$(id -u -n)
# Get PUID
PUID=$(id -u "$localuname")
# Get GUID
PGID=$(id -g "$localuname")
# Get Docker Group Number
DOCKERGRP=$(grep docker /etc/group | cut -d ':' -f 3)
# Get Hostname
thishost=$(hostname)
# Get IP Address
locip=$(hostname -I | awk '{print $1}')
# Get Time Zone
time_zone=$(cat /etc/timezone)	
# Get CIDR Address
slash=$(ip a | grep "$locip" | cut -d ' ' -f6 | awk -F '/' '{print $2}')
lannet=$(awk -F"." '{print $1"."$2"."$3".0"}'<<<$locip)/$slash

# Get Private Internet Access Info
if [ -z "$piauname" ]; then
read -r -p "What is your PIA Username?: " piauname
read -r -s -p "What is your PIA Password? (Will not be echoed): " piapass
read -r -p "What PIA server? (Will not be echoed): " piaserv
printf "\\n\\n"
fi

# Configure the access for Transmission etc/
# The same credentials can be used for NZBGet/Minio webui
if [ -z "$daemonun" ]; then
echo "You need to set a username and password for programs to access"
echo "Transmission, NZBGet and Minio."
read -r -p "What would you like to use as the access username?: " daemonun
read -r -p "What would you like to use as the access password?: " daemonpass
printf "\\n\\n"
fi

# Get info needed for PLEX Official image
read -r -p "Which PLEX release do you want to run? By default 'public' will be used. (latest, public, plexpass): " pmstag
read -r -p "If you have PLEXPASS what is your Claim Token from https://www.plex.tv/claim/ (Optional): " pmstoken
# If not set - set PMS Tag to Public:
if [ -z "$pmstag" ]; then
   pmstag=public
fi

# Get the info for the style of Portainer to use
read -r -p "Which style of Portainer do you want to use? By default 'No Auth' will be used. (noauth, auth): " portainerstyle
if [ -z "$portainerstyle" ]; then
   portainerstyle=--no-auth
elif [ "$portainerstyle" == "noauth" ]; then
   portainerstyle=--no-auth
elif [ "$portainerstyle" == "auth" ]; then
   portainerstyle=
fi

# Ask user if they already have TV, Movie, and Music directories
if [ -z "$diranswer" ]; then
printf "\\n\\n"
printf "If you already have TV - Movie - Music directories you want to use you can enter them next.\\n"
printf "If you want Mediabox to generate it's own directories just press enter to these questions."
printf "\\n\\n"
read -r -p "Where do you store your DOWNLOADS? (Please use full path - /path/to/downloads ): " dldirectory
read -r -p "Where do you store your TV media? (Please use full path - /path/to/tv ): " tvdirectory
read -r -p "Where do you store your MOVIE media? (Please use full path - /path/to/movies ): " moviedirectory
read -r -p "Where do you store your MUSIC media? (Please use full path - /path/to/music ): " musicdirectory
fi
if [ "$diranswer" == "n" ]; then
read -r -p "Where do you store your DOWNLOADS? (Please use full path - /path/to/downloads ): " dldirectory
read -r -p "Where do you store your TV media? (Please use full path - /path/to/tv ): " tvdirectory
read -r -p "Where do you store your MOVIE media? (Please use full path - /path/to/movies ): " moviedirectory
read -r -p "Where do you store your MUSIC media? (Please use full path - /path/to/music ): " musicdirectory
fi

# Add torrent settings if not already found above
if [ -z "$btanswer" ]; then
printf "\\n"
printf "Here you can enter your Transmission settings, these cannot be configured through it's json.\\n"
printf "If you want to use the default settings just press enter to these questions."
printf "\\n"
read -e -p "Would you like to enable authentication? (true/false) false by default: " trauth
read -e -p "What web interface? (combustion, default and blahblah) combustion by default: " trwebui
read -e -p "Would you like to enable UTP? (true/false) true by default: " trutp
read -e -p "Would you like to enable PEX? (true/false) true by default: " trpex
read -e -p "Would you like to enable DHT? (true/false) true by default: " trdht
read -e -p "Would you like to enable LPD? (true/false) true by default: " trlpd
read -e -p "Would you like an upload ratio limit? False by default (true/false): " trratiol
read -e -p "What upload ratio would you like? By default 2 will be used. (0.1 - 0 (disabled)): " trshareratio
read -e -p "Would you like an upload time limit? False by default (true/false): " trsharel
read -e -p "What upload time would you like? By default 30 min wil be used. (1 - 0 (disabled)): " trsharetime
read -e -p "Would you like an upload speed limit? False by default (true/false): " trulimit
read -e -p "What upload speed would you like? Unlimited by default (Enter in kb/s): " trupspeed
read -e -p "Would you like a download speed limit? False by default (true/false): " trdlimit
read -e -p "What download speed would you like? Unlimited by default (Enter in kb/s): " trdnspeed
read -e -p "What download queue would you like? 5 by default (1 - 0 (disabled)): " trdqueue
read -e -p "What seed queue would you like? 10 by default (1 - 0 (disabled)): " truqueue
read -e -p "What global peer limit would you like? 200 default (1 - 0 (disabled): " trgpeers
read -e -p "What torrent peer limit would you like? 50 default (1 - 0 (disabled): " trtpeers
read -e -p "Would you like to use a blocklist? (true/false) false by default: " trblist
read -e -p "Enter your blocklist URL. http://john.bitsurge.net/public/biglist.p2p.gz is used by default: " trblisturl
fi
if [ "$btanswer" == "n" ]; then
printf "\\n"
printf "Here you can enter your Transmission settings, these cannot be configured through it's json.\\n"
printf "If you want to use the default settings just press enter to these questions."
printf "\\n"
read -e -p "Would you like to enable authentication? (true/false) false by default: " trauth
read -e -p "What web interface? (combustion, default and blahblah) combustion by default: " trwebui
read -e -p "Would you like to enable UTP? (true/false) true by default: " trutp
read -e -p "Would you like to enable PEX? (true/false) true by default: " trpex
read -e -p "Would you like to enable DHT? (true/false) true by default: " trdht
read -e -p "Would you like to enable LPD? (true/false) true by default: " trlpd
read -e -p "Would you like an upload ratio limit? False by default (true/false): " trratiol
read -e -p "What upload ratio would you like? By default 2 will be used. (0.1 - 0 (disabled)): " trshareratio
read -e -p "Would you like an upload time limit? False by default (true/false): " trsharel
read -e -p "What upload time would you like? By default 30 min wil be used. (1 - 0 (disabled)): " trsharetime
read -e -p "Would you like an upload speed limit? False by default (true/false): " trulimit
read -e -p "What upload speed would you like? Unlimited by default (Enter in kb/s): " trupspeed
read -e -p "Would you like a download speed limit? False by default (true/false): " trdlimit
read -e -p "What download speed would you like? Unlimited by default (Enter in kb/s): " trdnspeed
read -e -p "What download queue would you like? 5 by deault (1 - 0 (disabled)): " trdqueue
read -e -p "What seed queue would you like? 10 by default (1 - 0 (disabled)): " truqueue
read -e -p "What global peer limit would you like? 200 default (1 - 0 (disabled): " trgpeers
read -e -p "What torrent peer limit would you like? 50 default (1 - 0 (disabled): " trtpeers
read -e -p "Would you like to use a blocklist? (true/false) false by default: " trblist
read -e -p "Enter your blocklist URL. http://john.bitsurge.net/public/biglist.p2p.gz is used by default: " trblisturl
fi

# Defaults config for Transmission and PIA etc. - Added when enter is pressed for defaults
#If not set - set upload ratio enabled to false by default
if [ -z "$trratiol" ]; then
   trratiol=false
fi
# If not set - set upload ratio to 2 by default
if [ -z "$trshareratio" ]; then
   trshareratio=2
fi
#If not set - set upload time enabled to false by default
if [ -z "$trsharel" ]; then
   trsharel=false
fi
#If not set - set upload time to 30 min by default
if [ -z "$trsharetime" ]; then
   trsharetime=30
fi
#If not set - set upload speed limit to false by default
if [ -z "$trulimit" ]; then
   trulimit=false
fi
#If not set - set upload speed rate to 0 by default
if [ -z "$trupspeed" ]; then
   trupspeed=0
fi
#If not set - set download speed limit to false by default
if [ -z "$trdlimit" ]; then
   trdlimit=false
fi
#If not set - set download speed rate to 0 by default
if [ -z "$trdnspeed" ]; then
   trdnspeed=0
fi
#If not set - set use blocklist to false by default
if [ -z "$trblist" ]; then
   trblist=false
fi
#If not set - set the blocklist to http://john.bitsurge.net/public/biglist.p2p.gz by default
if [ -z "$trblisturl" ]; then
   trblisturl="http://john.bitsurge.net/public/biglist.p2p.gz"
fi
#If not set - set global peer limit to 200 by default
if [ -z "$trgpeers" ]; then
   trgpeers=200
fi
#If not set - set torrent peer limit to 50 by default
if [ -z "$trtpeers" ]; then
   trtpeers=50
fi
#If not set - set UTP enabled to true by default
if [ -z "$trutp" ]; then
   trutp=true
fi
#If not set - set PEX enabled to true by default
if [ -z "$trpex" ]; then
   trpex=true
fi
#If not set - set DHT enabled to true by default
if [ -z "$trdht" ]; then
   trdht=true
fi
#If not set - set LPD enabled to true by default
if [ -z "$trlpd" ]; then
   trlpd=true
fi
#If not set - set web authentication to false by default
if [ -z "$trauth" ]; then
   trauth=false
fi
#If not set - set the download queue to 5 by default
if [ -z "$trdqueue" ]; then
   trdqueue=5
fi
#If not set - set the upload queue to 10 by default
if [ -z "$truqueue" ]; then
   truqueue=15
fi
#If not set - set the web ui to combustion by default
if [ -z "$trwebui" ]; then
   trwebui=combustion
fi
#If not set - set the default PIA server to Sweden
if [ -z "piaserv" ]; then
   piaserv=Sweden
fi

# Create the directory structure
if [ -z "$dldirectory" ]; then
    mkdir -p content/completed
    mkdir -p content/incomplete
    dldirectory="$PWD/content"
else
  mkdir -p "$dldirectory"/completed
  mkdir -p "$dldirectory"/incomplete
fi
if [ -z "$tvdirectory" ]; then
    mkdir -p content/tv
    tvdirectory="$PWD/content/tv"
fi
if [ -z "$moviedirectory" ]; then
    mkdir -p content/movies
    moviedirectory="$PWD/content/movies"
fi
if [ -z "$musicdirectory" ]; then
    mkdir -p content/music
    musicdirectory="$PWD/content/music"
fi

# Adjust for Container name changes
[ -d "sickrage/" ] && mv sickrage/ sickchill  # Switch from Sickrage to SickChill

mkdir -p couchpotato
mkdir -p duplicati
mkdir -p duplicati/backups
mkdir -p headphones
mkdir -p historical/env_files
mkdir -p jackett
mkdir -p jellyfin
mkdir -p lidarr
mkdir -p minio
mkdir -p muximux
mkdir -p nzbget
mkdir -p ombi
mkdir -p "plex/Library/Application Support/Plex Media Server/Logs"
mkdir -p portainer
mkdir -p radarr
mkdir -p sickchill
mkdir -p sonarr
mkdir -p tautulli
mkdir -p tvpn

# Create the .env file
echo "Creating the .env file with the values we have gathered"
printf "\\n"
cat << EOF > .env
###  ------------------------------------------------
###  M E D I A B O X   C O N F I G   S E T T I N G S
###  ------------------------------------------------
###  The values configured here are applied during
###  $ docker-compose up
###  -----------------------------------------------
###  DOCKER-COMPOSE ENVIRONMENT VARIABLES BEGIN HERE
###  -----------------------------------------------
###
EOF
{
echo "LOCALUSER=$localuname"
echo "HOSTNAME=$thishost"
echo "IP_ADDRESS=$locip"
echo "PUID=$PUID"
echo "PGID=$PGID"
echo "DOCKERGRP=$DOCKERGRP"
echo "PWD=$PWD"
echo "DLDIR=$dldirectory"
echo "TVDIR=$tvdirectory"
echo "MOVIEDIR=$moviedirectory"
echo "MUSICDIR=$musicdirectory"
echo "PIAUNAME=$piauname"
echo "PIAPASS=$piapass"
echo "PIASERV=$piaserv"
echo "TUSER=$daemonun"
echo "TPASS=$daemonpass"
echo "CIDR_ADDRESS=$lannet"
echo "TZ=$time_zone"
echo "PMSTAG=$pmstag"
echo "PMSTOKEN=$pmstoken"
echo "PORTAINERSTYLE=$portainerstyle"
echo "VPN_REMOTE=$vpnremote"
echo "TRATIOL=$trratiol"
echo "TSHARER=$trshareratio"
echo "TSHAREL=$trsharel"
echo "TSHARET=$trsharetime"
echo "TULIMIT=$trulimit"
echo "TUPSPEED=$trupspeed"
echo "TDLIMIT=$trdlimit"
echo "TDNSPEED=$trdnspeed"
echo "TBLIST=$trblist"
echo "TBLISTURL=$trblisturl"
echo "TGPEERS=$trgpeers"
echo "TTPEERS=$trtpeers"
echo "TUTP=$trutp"
echo "TDHT=$trdht"
echo "TPEX=$trpex"
echo "TLPD=$trlpd"
echo "TAUTH=$trauth"
echo "TUQUEUE=$truqueue"
echo "TDQUEUE=$trdqueue"
echo "TWEBUI=$trwebui"
} >> .env
echo ".env file creation complete"
printf "\\n\\n"

# Adjust for the Switch to linuxserver/sickchill
docker rm -f sickchill > /dev/null 2>&1
# Adjust for the Tautulli replacement of PlexPy
docker rm -f plexpy > /dev/null 2>&1
# Adjust for the Ouroboros replacement of Watchtower
docker rm -f watchtower > /dev/null 2>&1
# Adjust for old uhttpd web container - Noted in issue #47
docker rm -f uhttpd > /dev/null 2>&1
[ -d "www/" ] && mv www/ historical/www/
# Move back-up .env files
mv 20*.env historical/env_files/ > /dev/null 2>&1
mv historical/20*.env historical/env_files/ > /dev/null 2>&1

# Download & Launch the containers
echo "The containers will now be pulled and launched"
echo "This may take a while depending on your download speed"
read -r -p "Press any key to continue... " -n1 -s
printf "\\n\\n"
docker-compose up -d --remove-orphans
printf "\\n\\n"

# Finish up the config
printf "Configuring Taransmission, NZBGet, Muximux, and Permissions \\n"
printf "This may take a few minutes...\\n\\n"

# Configure NZBGet
[ -d "content/nbzget" ] && mv content/nbzget/* content/ && rmdir content/nbzget
while [ ! -f nzbget/nzbget.conf ]; do sleep 1; done
docker stop nzbget > /dev/null 2>&1
perl -i -pe "s/ControlUsername=nzbget/ControlUsername=$daemonun/g"  nzbget/nzbget.conf
perl -i -pe "s/ControlPassword=tegbzn6789/ControlPassword=$daemonpass/g"  nzbget/nzbget.conf
perl -i -pe "s/{MainDir}\/intermediate/{MainDir}\/incomplete/g" nzbget/nzbget.conf
docker start nzbget > /dev/null 2>&1

# Configure Muximux settings and files
while [ ! -f muximux/www/muximux/settings.ini.php-example ]; do sleep 1; done
docker stop muximux > /dev/null 2>&1
cp settings.ini.php muximux/www/muximux/settings.ini.php
cp mediaboxconfig.php muximux/www/muximux/mediaboxconfig.php
sed '/^PIA/d' < .env > muximux/www/muximux/env.txt # Pull PIA creds from the displayed .env file
perl -i -pe "s/locip/$locip/g" muximux/www/muximux/settings.ini.php
perl -i -pe "s/locip/$locip/g" muximux/www/muximux/mediaboxconfig.php
perl -i -pe "s/daemonun/$daemonun/g" muximux/www/muximux/mediaboxconfig.php
perl -i -pe "s/daemonpass/$daemonpass/g" muximux/www/muximux/mediaboxconfig.php
docker start muximux > /dev/null 2>&1

# If PlexPy existed - copy plexpy.db to Tautulli
if [ -e plexpy/plexpy.db ]; then
    docker stop tautulli > /dev/null 2>&1
    mv tautulli/tautulli.db tautulli/tautulli.db.orig
    cp plexpy/plexpy.db tautulli/tautulli.db
    mv plexpy/plexpy.db plexpy/plexpy.db.moved
    docker start tautulli > /dev/null 2>&1
    mv plexpy/ historical/plexpy/
fi
if [ -e plexpy/plexpy.db.moved ]; then # Adjust for missed moves
    mv plexpy/ historical/plexpy/
fi

printf "Setup Complete - Open a browser and go to: \\n\\n"
printf "http://%s \\nOR http://%s If you have appropriate DNS configured.\\n\\n" "$locip" "$thishost"
printf "Start with the MEDIABOX Icon for settings and configuration info.\\n"
