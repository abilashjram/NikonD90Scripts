#!/bin/sh

######################################################################################################
#   USAGE	: ./takeHDRNikonD90.sh --fstop <value> --processHDR
#   DESCRIPTION	: Script to take 7 Bracketed photos using Aperture Prio (A) mode with specified A-value
#   AUTHOR	: abilashjram
#   COMPANY	: WhiteLotus
#   VERSION	: 0.1
#   DATE	: 10/04/2015
#   NOTES	: Initial Version
######################################################################################################


######################################################################################################
#   Set defaults
######################################################################################################

usage="Script to take 7 bracketd photos using AV mode

usage: $0 --fstop <value> --processHDR

where
	fstop = to set AV value (0 to 16 ) (Lens 18-105mm f5.6)
	processHDR = converts bracketed shots to single HDR image
	
"
NEFPATH=/home/abilashjram/NikonD90/images
OUTPUTPATH=/home/abilashjram/NikonD90/images/HDRoutput
HDRPATH=/home/abilashjram/NikonD90/images/HDR
######################################################################################################
#   Parse Arguments
######################################################################################################

if [ $# -eq 0 ] ; then
   echo >&2 "$usage"
   exit 1;
fi

while [ $# -gt 0 ]
do
	case $1 in
	   --fstop) FSTOP="$2"; shift;;
	   --processHDR) PROCESSHDR=1;;
	   -*) echo >&2 "$usage"
	       exit 1;;
           *) break;;  # terminate while loop
	esac
	shift
done

echo "Captureing 7 Bracketed image with "
echo "APERTURE: $FSTOP"

######################################################################################################
#   Validate Environment
######################################################################################################

HASNIKON=`lsusb | grep "Nikon" | wc -l | awk '{print $1}'`
if [ -z "$HASNIKON" ] || [ $HASNIKON -ne 1 ] ; then
  echo "Nikon camera not detected, exiting"
  exit 1
fi

if [ -z "$FSTOP" ] ; then
  echo "Aperture not specified, exiting"
  exit 1
fi


######################################################################################################
# capture HDR
######################################################################################################


CURRMODE=`gphoto2 --get-config /main/capturesettings/expprogram | grep Current | awk '{print $2}'`

if [ "$CURRMODE" != "A" ] ; then
	echo "Please set the camera in Aperture Mode, exiting"
	exit 1
fi

# TODO CHECK FOR EXPOSURE COMPENSATION SETTINGS 2, ENABLE IF DISABLED
#Set capture to camera and take 7 bracketed photo

gphoto2 --set-config /main/capturesettings/capturemode=0 
gphoto2	--set-config /main/capturesettings/f-number=$FSTOP 
gphoto2 --set-config /main/capturesettings/exposurecompensation=9 
gphoto2 --capture-image 
sleep 5
gphoto2 --set-config /main/capturesettings/exposurecompensation=11 
gphoto2 --capture-image 
sleep 5
gphoto2 --set-config /main/capturesettings/exposurecompensation=13 
gphoto2 --capture-image 
sleep 5
gphoto2 --set-config /main/capturesettings/exposurecompensation=15 
gphoto2 --capture-image 
sleep 5
gphoto2 --set-config /main/capturesettings/exposurecompensation=17 
gphoto2 --capture-image 
sleep 5
gphoto2 --set-config /main/capturesettings/exposurecompensation=19 
gphoto2 --capture-image 
sleep 5
gphoto2 --set-config /main/capturesettings/exposurecompensation=21 
gphoto2 --capture-image 



gphoto2 --set-config /main/capturesettings/exposurecompensation=15



######################################################################################################
# Perform HDR Processing
######################################################################################################

if [ $PROCESSHDR -eq 1 ] ; then
	echo "ProcessHDR"
	
   if [ ! -d "$NEFPATH" ] ; then
	mkdir -p "$NEFPATH"
   fi
   
   FIRSTNEFTMP=`gphoto2 --list-files | grep "NEF" | tail -6 | sed 's/#//g'`
   FIRSTNEFNUM=`echo "$FIRSTNEFTMP" | awk '{print $1}'`
   FIRSTNEFFILE=`echo "$FIRSTNEFTMP" | awk '{print $2}'`

   LASTNEFTMP=`gphoto2 --list-files | grep "NEF" | tail -1 | sed 's/#//g'`
   LASTNEFNUM=`echo "$LASTNEFTMP" | awk '{print $1}'`
   LASTNEFFILE=`echo "$LASTNEFTMP" | awk '{print $2}'`

   cd $NEFPATH

   gphoto2 --get-file ${FIRSTNEFNUM}-${LASTNEFNUM}

   UFRAMESETTINGS="--compression=96"
   if [ ! -d "$OUTPUTPATH" ] ; then
	mkdir -p "$OUTPUTPATH"
   fi
   if [ ! -d "$HDRPATH" ] ; then
	mkdir -p "$HDRPATH"
   fi

   ENFUSEFIL="IMG*.jpg"
   ENFUSESIZE="--size 4288x2848"

   FIRSTFILE=`ls -al $NEFPATH | grep NEF | head -1 | awk '{print $9}' | sed 's/.NEF//g'`
   LASTFILE=`ls -al $NEFPATH | grep NEF | tail -1 | awk '{print $9}' | sed 's/.NEF//g'`

   ufraw-batch --wb=camera --rotate=camera --out-type="jpg" $UFRAWSETTINGS $ENFUSESIZE --out-path=$OUTPUTPATH $NEFPATH/*.NEF
   align_image_stack -a AIS_ $OUTPUTPATH/*.jpg
   enfuse -o $HDRPATH/${FIRSTFILE}_to_${LASTFILE}.jpg $OUTPUTPATH/*.jpg
   
fi

exit 0
