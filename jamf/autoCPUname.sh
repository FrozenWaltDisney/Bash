#!/bin/bash

MACADDRESS=$(networksetup -getmacaddress en0 | awk '{ print $3 }')
JSS=https://yourcompany.jamfcloud.com:443
API_USER=api
API_PASS=password


## Get JAMF XML
XML=$( curl -H "Accept:text/xml" -ksu $API_USER:$API_PASS $JSS/JSSResource/computers/macaddress/$MACADDRESS -X GET )

##Find ID
#String to search
STRI="<id>"
#Find Position in string
IDPOS=${XML%%$STRI*}
IDPOSNUM=${#IDPOS}
#Find length of search variable
STRLNGT=${#STRI}
#Start after Tag
IDFPOS=`echo "$STRLNGT + $IDPOSNUM" | bc`
#Terminate string Length
IDFPOST=`echo "$STRLNGT + $IDPOSNUM + 10" | bc`
#Grab String and cut excess
ID=`echo ${XML:$IDFPOS:$IDFPOST} | cut -d "<" -f 1`

##Find Department
#String to search
STRD="<department>"
#Find Position in string
DPTPOS=${XML%%$STRD*}
DPTPOSNUM=${#DPTPOS}
#Find length of search variable
STRLNGTD=${#STRD}
#Start after Tag
DPTFPOS=`echo "$STRLNGTD + $DPTPOSNUM" | bc`
#terminate string length
DPTFPOST=`echo "$STRLNGTD + $DPTPOSNUM + 10" | bc`
#Grab string and cut excess
DEPT=`echo ${XML:$DPTFPOS:$DPTFPOST} | cut -d "<" -f 1`

##Find Location
#String to search
STRL="<building>"
#Find Position in string
LOCPOS=${XML%%$STRL*}
LOCPOSNUM=${#LOCPOS}
#Find length of search variable
STRLNGTL=${#STRL}
#Start after Tag
LOCFPOS=`echo "$STRLNGTL + $LOCPOSNUM" | bc`
#terminate string length
LOCFPOST=`echo "$STRLNGTL + $LOCPOSNUM + 10" | bc`
#Grab string and cut excess
LOCATION=`echo ${XML:$LOCFPOS:$LOCFPOST} | cut -d "<" -f 1`


#Find if it's a laptop
IS_LAPTOP=`/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book"`
#find ID length
idlength=`echo ${#ID}`

#Add Location
if [ "$LOCATION" = "Home Office" ]; then
   PREFIX=HO
else
  echo "Unknown Location"
  exit 1
fi

#Determine Laptop or Not
if [ "$IS_LAPTOP" != "" ]; then
    PREFIX=$PREFIX"L"
else
    PREFIX=$PREFIX"D"
fi

#Sort Department Naming
if [ "$DEPT" = "IT" ]; then
    PREFIX=$PREFIX"777"
elif [ "$DEPT" = "Marketing" ]; then
    PREFIX=$PREFIX"666"
elif [ "$DEPT" = "Web" ]; then
    PREFIX=$PREFIX"555"
elif [ "$DEPT" = "Private Label" ]; then
    PREFIX=$PREFIX"444"
else
    PREFIX=$PREFIX"XXX"
fi

#format ID to 3 characters
if [ $idlength -gt 3 ]; then
    ID=echo ${ID: -3}
    Name=$PREFIX$ID
elif [ $idlength -lt 3 ]; then
    ID="0"$ID
    Name=$PREFIX$ID
else
    Name=$PREFIX$ID
fi


#set name to match
/usr/sbin/scutil --set ComputerName "$Name"
/usr/sbin/scutil --set LocalHostName "$Name"
/usr/sbin/scutil --set HostName "$Name"

#Flush naming cache
dscacheutil -flushcache

#Report to Jamf
jamf recon

exit 0