#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

HOST="http://test.fabchain.net:8545"
MY_ADDRESS="ef5dca69e9c573f6acce1b4c641b2b526217328f"
# token erc20 on fabchian
ERC20_TOKEN="8Cf60F37Cf8EFebEFC567BdCDb61446b7230dB28"
# receiver
RECEIVER_SK="85d26b5c8b0da6eddb55aa1022eea46e31de276d581d9e7e005d40afce4f9124"
RECEIVER_ADDRESS="828bddf0231656fb736574dfd02b7862753de64b"

function send() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}' $HOST 2>/dev/null | jq '.result'
    sleep 1
)

function asknonce() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'"$1"'", "latest"],"id":42}' $HOST 2>/dev/null | jq '.result'
    sleep 1
)

function gasprice() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":42}' $HOST 2>/dev/null | jq ".result"
    sleep 1
)

function txreceipt() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["'"$1"'"],"id":42}' $HOST 2>/dev/null | jq '.result'
    sleep 1
)

function balance() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["'"$1"'", "latest"],"id":42}' $HOST 2>/dev/null | jq '.result'
    sleep 1
)

function send_coins() (
    NONCE=`asknonce "0x${MY_ADDRESS}" | xargs`
    cat <<EOF > send_coins.json
{
	"keyring": {
      		   "ethereum": "634f3f80fc087ad90866012d74c41ccc698b43592dee7ed27ecb89333c2e3d1c"
   	},
	"gas price": "`echo "print($(gasprice | xargs))" | python3`",
	"gas limit": "100000",
	"token value": "1",
	"erc20": "`echo $ERC20_TOKEN`",	
	"receiver": "`echo $RECEIVER_ADDRESS`",
	"ethereum nonce": "`echo $(($NONCE))`",
        "details": "31323334"
}
EOF

    cat <<EOF > send_coins.zen 
Scenario ethereum
Given I have the 'keyring'
Given I have a 'ethereum address' named 'receiver'
Given I have a 'ethereum address' named 'erc20'
Given I have a 'ethereum nonce'
and a 'gas price'
and a 'gas limit'
and a 'number' named 'token value'
Given I have a 'hex' named 'details'
When I create the ethereum transaction to 'erc20'
and I use the ethereum transaction to transfer 'token value' erc20 tokens to 'receiver' with details 'details'
When I create the signed ethereum transaction for chain 'fabt'
Then print the 'signed ethereum transaction'
EOF
    RAW=`$Z -z send_coins.zen -a send_coins.json 2>/dev/null | jq ".signed_ethereum_transaction" | xargs`
    TXID=`send "0x$RAW" | xargs`
    echo $TXID
    sleep 5
    for i in $(seq 10); do
	RECEIPT=`txreceipt "$TXID"`
	if [[ ! "$RECEIPT" == "null" && ! "$RECEIPT" == "" ]]; then
	    STATUS=`echo $RECEIPT | jq ".status" | xargs`
	    if [[ "$STATUS" == "0x1" ]]; then
		echo "`date -u "+%y/%m/%d_%H:%M:%S_%Z"`;$((5+10*i));$TXID"
		exit 0
	    elif [[ ! "$STATUS" == "0x1" ]]; then
		echo "`date -u "+%y/%m/%d_%H:%M:%S_%Z"`;FAILED;$TXID"
		exit 1
	    fi
	fi
	sleep 10
    done
    echo "`date -u "+%y/%m/%d_%H:%M:%S_%Z"`;ERROR;$TXID"
    exit 1
)

BALANCE=`balance "0x${MY_ADDRESS}" | xargs`
if(( $(($BALANCE)) == 0 )); then
    echo
    echo "There are no FABT in your address."
    echo "Please enter your address:"
    echo $MY_ADDRESS
    echo "in the following site:"
    echo "http://test.fabchain.net:5000/"
    echo "to obtain a fabt."
    echo "Be aware you can obatin one fabt per address per day."
    echo
    rm *.json *.keys
    exit 1
fi
echo "Balance: " $(($BALANCE))

send_coins

# clean the folder
rm *.json *.keys
