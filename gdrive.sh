#!/bin/bash
#
# ======= Dataclick Google Drive Client 1.0.0 ========
# Copyright (c) 2025 Eduardo Ruiz <eruiz@dataclick.es>
# https://github.com/EduardoRuizM/gdrive-bash
#

ACCOUNT_PATH="/etc/gdrive/accounts"

# Read parameters
while [[ $# -gt 0 ]]; do
	if [[ $1 == -* ]]; then
		VAR_NAME="${1#-}"
		declare "$VAR_NAME=$2"
		shift 2
	else
		declare "action=$1"
		shift 1
	fi
done

# Load account config
function load_config {
	if [ -z "$account" ]; then
		echo "gdrive: Missing -account"
		exit 1
	fi
	CONFIG_FILE="$ACCOUNT_PATH/$account"
	if [ ! -f $CONFIG_FILE ]; then
		echo "gdrive: Missing account file"
		exit 1
	fi
	source $CONFIG_FILE
	# IfJSON CLIENT_ID=$(grep -oP '"client_id":\s*"\K[^"]+' $CONFIG_FILE)
	REDIRECT_URI="http://localhost"
	TOKEN_URL="https://oauth2.googleapis.com/token"
	API_URL="https://www.googleapis.com/drive/v3"
	SCOPES="https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/drive.metadata.readonly"
}

# Check token and refresh if necessary
function check_token {
	load_config
	RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $ACCESS_TOKEN" "$API_URL/about?fields=storageQuota")
	if [ "$RESPONSE" -ne 200 ]; then
		RESPONSE=$(curl -s -X POST $TOKEN_URL -d client_id=$CLIENT_ID -d client_secret=$CLIENT_SECRET -d refresh_token=$REFRESH_TOKEN -d grant_type=refresh_token)
		ACCESS_TOKEN=$(echo $RESPONSE | grep -oP '"access_token":\s*"\K[^"]+')
		NEW_REFRESH_TOKEN=$(echo $RESPONSE | grep -oP '"refresh_token":\s*"\K[^"]+')
		if [ -z "$ACCESS_TOKEN" ]; then
			echo "gdrive: Error renew access_token"
			exit 1
 		fi
		if [ ! -z "$NEW_REFRESH_TOKEN" ] && [ "$NEW_REFRESH_TOKEN" != "$REFRESH_TOKEN" ]; then
			REFRESH_TOKEN=$NEW_REFRESH_TOKEN
			sed -i "s/^REFRESH_TOKEN=.*/REFRESH_TOKEN=$REFRESH_TOKEN/" $CONFIG_FILE
		fi
		sed -i "s/^ACCESS_TOKEN=.*/ACCESS_TOKEN=$ACCESS_TOKEN/" $CONFIG_FILE
	fi
}

case $action in

   list)
	ls $ACCOUNT_PATH
   ;;

   remove)
	load_config
	rm $CONFIG_FILE
   ;;

   create)
        if [ -z "$account" ]; then
		echo "gdrive: Missing -account"
                exit 1
        fi
        if [ -z "$client" ] || [ -z "$secret" ]; then
		read -p "CLIENT_ID: " client
		read -p "CLIENT_SECRET: " secret
	fi
        if [ -z "$client" ] || [ -z "$secret" ]; then
		echo "gdrive: Missing -client or -secret"
                exit 1
        fi
	echo -e "CLIENT_ID=\"$client\"\nCLIENT_SECRET=\"$secret\"" > $ACCOUNT_PATH/$account
   ;;

   init)
	load_config
	echo "Paste this URL in your browser:"
	echo "https://accounts.google.com/o/oauth2/auth?client_id=$CLIENT_ID&redirect_uri=$REDIRECT_URI&response_type=code&scope=$SCOPES"
	read -p "Type code GET parameter value from returned URL: " AUTH_CODE
	RESPONSE=$(curl -s -X POST $TOKEN_URL -d client_id=$CLIENT_ID -d client_secret=$CLIENT_SECRET -d redirect_uri=$REDIRECT_URI -d grant_type=authorization_code -d code=$AUTH_CODE)
	ACCESS_TOKEN=$(echo $RESPONSE | grep -oP '"access_token":\s*"\K[^"]+')
	REFRESH_TOKEN=$(echo $RESPONSE | grep -oP '"refresh_token":\s*"\K[^"]+')
	if [ -z "$ACCESS_TOKEN" ] || [ -z "$REFRESH_TOKEN" ]; then
		echo "gdrive: Error tokens not found"
		exit 1
	fi
	grep -q "^ACCESS_TOKEN=" "$CONFIG_FILE" && sed -i "s/^ACCESS_TOKEN=.*/ACCESS_TOKEN=$ACCESS_TOKEN/" "$CONFIG_FILE" || echo "ACCESS_TOKEN=$ACCESS_TOKEN" >> "$CONFIG_FILE"
	grep -q "^REFRESH_TOKEN=" "$CONFIG_FILE" && sed -i "s/^REFRESH_TOKEN=.*/REFRESH_TOKEN=$REFRESH_TOKEN/" "$CONFIG_FILE" || echo "REFRESH_TOKEN=$REFRESH_TOKEN" >> "$CONFIG_FILE"
   ;;

   quota)
	check_token
	RESPONSE=$(curl -s -X GET "$API_URL/about?fields=storageQuota" -H "Authorization: Bearer $ACCESS_TOKEN")
	LIMIT=$(echo $RESPONSE | grep -oP '"limit":\s*"\K[0-9]+')
	LIMIT_MB=$((LIMIT / 1024 / 1024))
	USAGE=$(echo $RESPONSE | grep -oP '"usage":\s*"\K[0-9]+')
	USAGE_MB=$((USAGE / 1024 / 1024))
	echo "{\"limit\": \"$LIMIT_MB\", \"usage\": \"$USAGE_MB\"}"
   ;;

   folders)
	check_token

	if [ -z "$search" ]; then
  		Q=""
	else
		Q="name+contains+'$search'+and+"
	fi
	if [ -n "$parent" ]; then
		Q="${Q}parents='$parent'+and+"
	fi
	curl -s -X GET "$API_URL/files?q=${Q}mimeType='application/vnd.google-apps.folder'&fields=files(id,name,parents)" -H "Authorization: Bearer $ACCESS_TOKEN"
   ;;

   files)
	check_token
	if [ -z "$search" ]; then
  		Q=""
	else
		Q="q=name%20contains%20'$search'&"
	fi
	if [ -n "$parent" ]; then
		Q="${Q}parents='$parent'+and+"
	fi
	curl -s -X GET "$API_URL/files?${Q}fields=files(id,name,mimeType,parents)" -H "Authorization: Bearer $ACCESS_TOKEN"
   ;;

   upload)
	check_token
        if [ -z "$file" ]; then
		eho "gdrive: Missing -file"
                exit 1
        fi
	if [ -z "$parent" ]; then
  		PARENTS=""
	else
		PARENTS=", \"parents\": [\"$parent\"]"
	fi
	curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: multipart/related; boundary=gdrv_ruiz_bnd" --data-binary @- \
	"https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" <<EOF
--gdrv_ruiz_bnd
Content-Type: application/json; charset=UTF-8

{
  "name": "$(basename "$file")"$PARENTS
}

--gdrv_ruiz_bnd
Content-Type: $(file --mime-type -b "$file")

$(cat $file)
--gdrv_ruiz_bnd--
EOF
   ;;

   download)
	check_token
        if [ -z "$id" ] || [ -z "$file" ]; then
		echo "gdrive: Missing -id or -file"
                exit 1
        fi
	curl -s -L -H "Authorization: Bearer $ACCESS_TOKEN" "$API_URL/files/$id?alt=media" -o $file
   ;;

   move)
	check_token
        if [ -z "$id" ]; then
		echo "gdrive: Missing -id"
                exit 1
        fi
	from="${from:-root}"
	parent="${parent:-root}"
	curl -X PATCH -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" "$API_URL/files/$id?addParents=$parent&removeParents=$from&fields=id,parents"
   ;;

   rename)
	check_token
        if [ -z "$id" ] || [ -z "$name" ]; then
		echo "gdrive: Missing -id or -name"
                exit 1
        fi
	curl -X PATCH -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -d "{\"name\": \"$name\"}" "$API_URL/files/$id"
   ;;

   md)
	check_token
        if [ -z "$name" ]; then
		echo "gdrive: Missing -name"
                exit 1
        fi
	d="{\"name\": \"$name\", \"mimeType\": \"application/vnd.google-apps.folder\""
        if [ -n "$parent" ]; then
		d="$d, \"parents\": [\"$parent\"]"
	fi
	d="$d}"
	curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -d "$d" "$API_URL/files"
   ;;

   delete)
	check_token
        if [ -z "$id" ]; then
		echo "gdrive: Missing -id"
                exit 1
        fi
	curl -s -X DELETE -H "Authorization: Bearer $ACCESS_TOKEN" "$API_URL/files/$id"
   ;;

   trash)
	check_token
        if [ -z "$id" ]; then
		echo "gdrive: Missing -id"
                exit 1
        fi
	curl -X PATCH -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -d '{"trashed": true}' "$API_URL/files/$id"
   ;;

   *)
   echo -e "*** DATACLICK GDRIVE COMMANDS ***"
   echo -e "First create new project in https://console.cloud.google.com, enable Google Drive API, get CLIENT_ID and CLIENT_SECRET from Credentials (Desktop APP), in Consent Screen select External, scopes: $SCOPES"
   echo -e "- List all accounts:"
   echo -e "  $0 list"
   echo -e "- Create account (input from keyboard if no client/secret):"
   echo -e "  $0 create -account <ACCOUNT> -client <CLIENT> -secret <SECRET>"
   echo -e "- Remove account:"
   echo -e "  $0 remove -account <ACCOUNT>"
   echo -e "- Initialize first time, then paste returned URL in the browser:"
   echo -e "  $0 init -account <ACCOUNT>"
   echo -e "- Show limit and usage in MB:"
   echo -e "  $0 quota -account <ACCOUNT>"
   echo -e "- Show folders, optional search name contains STRING and optional -parent folder"
   echo -e "  $0 folders -account <ACCOUNT> -search <STRING> -parent <ID_FOLDER>"
   echo -e "- Show files, optional search name contains STRING and optional -parent folder"
   echo -e "  $0 files -account <ACCOUNT> -search <STRING> -parent <ID_FOLDER>"
   echo -e "- Upload file FILE in optional ID_FOLDER"
   echo -e "  $0 upload -account <ACCOUNT> -file <FILE> -parent <ID_FOLDER>"
   echo -e "- Download ID file into FILE"
   echo -e "  $0 download -account <ACCOUNT> -id ID -file <FILE>"
   echo -e "- Move ID file to ID_FOLDER folder from ID_FROM folder"
   echo -e "  $0 move -account <ACCOUNT> -id <ID> -parent <ID_FOLDER> -from <ID_FROM>"
   echo -e "- Rename ID file to NAME"
   echo -e "  $0 rename -account <ACCOUNT> -id <ID> -name <NAME>"
   echo -e "- Create folder name, optional -parent folder"
   echo -e "  $0 md -account <ACCOUNT> -name <name> -parent <ID_FOLDER>"
   echo -e "- Delete ID file"
   echo -e "  $0 delete -account <ACCOUNT> -id <ID>"
   echo -e "- Send to trash ID file"
   echo -e "  $0 trash -account <ACCOUNT> -id <ID>"
   ;;
esac
