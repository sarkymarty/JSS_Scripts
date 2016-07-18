#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                             #
#  JSS script to check the JSS for an asset tag record, to create a local file containing the #
#  recorded asset tag number, to prompt a user to enter the number if the file doesn't exist, #
#  and to contact IT if there is no asset label on their machine.                             #
#                                                                                             #
#                -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -                #
#                                                                                             #
#                 This script was created by Martyn Powell on 18th July 2016                  #
#                                                                                             #
#                -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -                #
#                                                                                             #
#  This program is free software: you can redistribute it and/or modify it under the terms    #
#  of the GNU General Public License as published by the Free Software Foundation, either     #
#  version 3 of the License, or (at your option) any later version.                           #
#                                                                                             #
#  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;  #
#  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  #
#  See the GNU General Public License for more details.                                       #
#                                                                                             #
#  You should have received a copy of the GNU General Public License along with this program. #
#  If not, see <http://www.gnu.org/licenses/>.                                                #
#                                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# - - - - - - - - - - - - - - - - SET REQUIRED VARIABLES HERE - - - - - - - - - - - - - - - - #

# The JSS URL, minus "https://" but including any specified port numbers:
JSS_URL="jss.mycompany.com:8443"

# The username for an API user account in the JSS, only requiring read access:
API_Username="USERNAME"

# The password for the above specified API user account:
API_Password="PASSWORD"

# - - - - - - - - - - - - - - - - DO NOT EDIT BELOW THIS LINE - - - - - - - - - - - - - - - - #

# Check asset tag recorded in the JSS for the device using the device's's UDID:

deviceUDID=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')

assignedAssetTag=$(curl -s -u $API_Username:$API_Password -H "Accept: application/xml" "https://$JSS_URL/JSSResource/computers/udid/${deviceUDID}" | xpath '/computer/general/asset_tag' 2>/dev/null | sed -e 's|<asset_tag>||g;s|</asset_tag>||g;')

# If no asset tag is recorded in the JSS...
if [[ $assignedAssetTag = "<asset_tag />" ]]; then

	# ... prompt user to enter the number from the asset tag on the base of their machine...
	echo "Prompting user to enter an asset tag number."
	enteredAssetTag=`osascript -e 'tell application "Finder"' -e 'Activate' -e 'set foo to text returned of (display dialog "To assist with our asset management, please confirm the number on the asset-tag that can be found on the base of your laptop.\n\nIf your machine no longer has an asset tag, please enter 0000 and contact IT so that we can issue a new one.\n\nThank you!" buttons {"Confirm & Set"} default answer "####" with icon stop )' -e 'end tell'`

	# ... and record entered asset tag in the JSS.
	if [[ ! $enteredAssetTag == "" ]]; then
		rm -f /.ID-*
		touch "/.ID-$enteredAssetTag" && chmod 0444 "/.ID-$enteredAssetTag"
		jamf recon -assetTag $enteredAssetTag
		echo "Asset tag set. Updating JSS record."
	else
		echo "Asset tag not set. Will retry on next check-in."
	fi

# If an asset tag is recorded in the JSS...
else

	# ... and the computer's ID file matches...
	if [[ -f "/.ID-$assignedAssetTag" ]]; then
	
		# ... then exit as all is as expected.
		echo "The recorded asset tag and the computer's ID file match as expected."	
	
	# ... but the computer's ID file doesn't match...
	else
	
		# ... prompt user to confirm the number from the asset tag on the base of their machine...
		echo "Prompting user to confirm the correct asset tag number."
		enteredAssetTag=`osascript -e 'tell application "Finder"' -e 'Activate' -e 'set foo to text returned of (display dialog "To assist with our asset management, please confirm the four-digit number on the asset-tag that can be found on the base of your laptop.\n\nIf your machine no longer has an asset tag, please enter 0000 and contact IT so that we can issue a new one.\n\nThank you!" buttons {"Confirm & Set"} default answer "$assignedAssetTag" with icon stop )' -e 'end tell'`

		# ... and record entered asset tag in the JSS.
		if [[ ! $enteredAssetTag == "" ]]; then
			rm -f /.ID-*
			touch "/.ID-$enteredAssetTag" && chmod 0444 "/.ID-$enteredAssetTag"
			jamf recon -assetTag $enteredAssetTag
			echo "Asset tag set. Updating JSS record."
		else
			echo "Asset tag not set. Will retry on next check-in."
		fi
		
	fi
		
fi