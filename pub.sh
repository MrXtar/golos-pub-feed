#!/bin/bash

# cli_wallet --rpc-http-endpoint url
WALLET=http://127.0.0.1:8093

# cli_wallet unlock password
PASSWORD="PASSWORD"

# publish_feed nickname:
NICKNAME="xtar"


function is_locked {
	LOCKED=`curl -s --data-binary '{"id":"1","method":"is_locked","params":[""]}' "$WALLET" | jq -r '.result'`
}

function checkLockAndExit {
	if [ "$EXITLOCK" = true ]; then
		echo -n "Locking wallet again..."
		curl -s --data-binary '{"id":0,"method":"lock","params":[]}' "$WALLET" > /dev/null
		echo ""
		echo "Locked."
	fi
}

is_locked
if [ "$LOCKED" == "true" ]; then
	EXITLOCK=true
	echo -n "Wallet is locked. Trying to unlock..."
	curl -s --data-binary '{"id":"1","method":"unlock","params":["'"$PASSWORD"'"]}' "$WALLET" > /dev/null
	echo ""
	is_locked
	if [ "$LOCKED" == "true" ]; then
		echo "Can't unlock wallet, exiting."
		checkLockAndExit		
	else
		echo "Wallet unlocked."
	fi
else
	if [ "$LOCKED" == "false" ]; then
		EXITLOCK=false
		echo "Wallet was unlocked before."
	else
		echo "Some error. Is cli_wallet running? Exit."
		exit
	fi
fi

# примерно раз в 60 минут обновлять фид
RANGE=60
number=$RANDOM
let "number %= $RANGE"
if [ $number -eq 30 ]; then
	BASE="1.000"
	QUOTE=`curl -s "http://www.steeme.ru/gf.html?mode=feed"`
	PUB=`curl -s --data-binary '{"id":"2","method":"publish_feed","params":["'"$NICKNAME"'",{"base":"'"$BASE GBG"'", "quote":"'"$QUOTE GOLOS"'"}, true],"jsonrpc":"2.0"}' "$WALLET" | jq -r '.id'`
	if [ $PUB -eq 2 ]; then
		echo "Feed was updated successfully. 'base'=${BASE} 'quote'=${QUOTE}"		
	else
		echo "Some error. Feed wasn't updated."		
	fi
fi

checkLockAndExit