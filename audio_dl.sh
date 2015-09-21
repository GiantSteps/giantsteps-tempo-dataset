#!/bin/bash -       
#title           :audio_dl.sh
#description     :This script will download all audio files for the dataset from beatport.
#author		 :richard vogl (richard.vogl@jku.at)
#date            :2015 09 16  (2015 07 17)
#version         :0.2    
#usage		 :bash audio_dl.sh
#notes           :uses curl and md5 / md5sum
#bash_version    :3.2.57(1)-release
#==============================================================================

md5_for()
{
  if builtin command -v md5 > /dev/null; then
    echo $(cat "$1" | md5 | awk '{print $1}')
  elif builtin command -v md5sum > /dev/null ; then
    echo $(cat "$1" | md5sum | awk '{print $1}')
  else
    echo "Neither md5 nor md5sum were found in the PATH"
    return 1
  fi

  return 0
}

DEBUG=0

FILES=./md5/*

BASEURL=http://geo-samples.beatport.com/lofi/
BACKUPBASEURL=http://www.cp.jku.at/datasets/giantsteps/backup/
AUDIOPATH=./audio/

RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'

errors=$(expr 0)
successful=$(expr 0)
backup=$(expr 0)
totalcount=$(expr 0)

printf "\n"

mkdir ${AUDIOPATH}

for f in $FILES
do
    # construct names
  filename=$(basename "$f")
  mp3filename="${filename%.*}".mp3
  mp3url=${BASEURL}${mp3filename}
  mp3backupurl=${BACKUPBASEURL}${mp3filename}
  audiofilename=${AUDIOPATH}$mp3filename
  md5filename=$f
  
  if (( $DEBUG > 0 )); then
    echo $audiofilename
    echo $md5filename
    echo $mp3url
  fi
  
  totalcount=$(expr $totalcount + 1)
  
  printf "\n${WHITE}Downloading file: $mp3filename ... ${NC} \n"

  # download file and check md5 hash
  if curl -o"$audiofilename" "$mp3url"; then
	# md5value=$(md5 -q "$audiofilename")
	md5value=$(md5_for "$audiofilename")
  else
	md5value="0"  
  fi
  md5file=$(cat "$md5filename")
  
  if (( $DEBUG > 0 )); then
	printf "MD5 should be: ${md5file}  \n"
	printf "MD5 is: ${md5value} \n"
  fi
 
  if [ $md5value = $md5file ]; then
	printf "${GREEN}MD5 OK!${NC} \n"
	successful=$(expr $successful + 1)
  else
	printf "${YELLOW}MD5 did not match! Downloading from backup location...${NC}  \n"
	if curl -o"$audiofilename" "$mp3backupurl"; then
	    md5value=$(md5_for "$audiofilename")
	else
             md5value="0"  
	fi
	md5file=$(cat "$md5filename")
	if [ $md5value = $md5file ]; then
	    printf "${GREEN}MD5 OK!${NC}  \n"
	    successful=$(expr $successful + 1)
	    backup=$(expr $backup + 1)
	else
	    printf "${RED}MD5 did not match! Giving up for file: ${mp3filename}!${NC}  \n"
	    errors=$(expr $errors + 1)
	    rm "$audiofilename"
	fi
  fi
done

printf "\nSummary: \n"
printf "Files succesfully downloaded: ${successful}/${totalcount}\n"
printf "Files from backup location: ${backup}/${successful}\n"
printf "Errors: ${errors}\n"

