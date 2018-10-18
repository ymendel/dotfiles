#!/bin/bash

ENCDIR=/share/Public/Encode
PROFILE=handbrake.profile
COMPEXT=complete
WORKFILE=$ENCDIR/working

if [ -a $WORKFILE ];
then
    echo "Encode already in progress ... exiting."
    exit 0
fi

IFS=$'\n'

echo "Looking for files to encode ..."
touch $WORKFILE

OLD_SHELLNOCASEMATCH=$(shopt -p nocasematch; true)
shopt -s nocasematch

# get list of directories to look in for video files / profiles
PROFDIRS=`find $ENCDIR -maxdepth 1 -type d -name "*"`

for DIR in $PROFDIRS
do
    if [ -a "$DIR/$PROFILE" ];
    then
        OPTIONS=`cat "$DIR/$PROFILE"`
        echo "$DIR has profile options : $OPTIONS"

        # look for any file with specified extensions
        # VIDFILES=`find $DIR -type f \( -name "*.avi" -o -name "*.mkv" \)`
        find $DIR -type f -iname "*.avi" -print0 > "$ENCDIR/avifiles"
        find $DIR -type f -iname "*.mkv" -print0 > "$ENCDIR/mkvfiles"
        find $DIR -type d -name "VIDEO_TS" -not -regex ".*complete/VIDEO_TS" -print0 > "$ENCDIR/videotses"

        VIDFILES=()
        while read -r -d ''; do
            VIDFILES+=("$REPLY")
        done < "$ENCDIR/avifiles"
        while read -r -d ''; do
            VIDFILES+=("$REPLY")
        done < "$ENCDIR/mkvfiles"
        while read -r -d ''; do
            VIDFILES+=("$REPLY")
        done < "$ENCDIR/videotses"

        rm -f "$ENCDIR/avifiles"
        rm -f "$ENCDIR/mkvfiles"
        rm -f "$ENCDIR/videotses"

        for VID in "${VIDFILES[@]}"
        do
            OUTFILE="${VID%.*}".mp4

            echo "Encoding video file $VID to file $OUTFILE"

            if [[ "${VID##*/}" == VIDEO_TS ]]
            then
                TOCHANGE="${VID%/*}"
            else
                TOCHANGE=$VID
            fi
            COMPLETED=$TOCHANGE.$COMPEXT

            if [[ "${VID##*.}" == mkv ]];
            then
                echo "ffmpeg encoding"
                ffmpeg -i $VID -c:v copy -c:a copy $OUTFILE
            else
                echo "HandBrake Encoding"
                HandBrakeCLI $OPTIONS --optimize -i $VID -o $OUTFILE
            fi
            mv $TOCHANGE $COMPLETED
            echo "Completed and renamed to $COMPLETED"
        done
    fi
done

eval $OLD_SHELLNOCASEMATCH

echo "Completed encoding."
rm $WORKFILE
