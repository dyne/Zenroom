#!/usr/bin/env bash
HOST="http://test.fabchain.net:8545"
ZENROOM_URL="https://files.dyne.org/zenroom/nightly/zenroom-linux-amd64"

Alice_ADDR="0ba910ba5fcced2a2538718367ea0a57c0ca881a"
Alice_SK="078ad84d6c7a50c6dcd983d644da65e30d8cea063d8ea49aeb7ee7f0aaf6a4f7"

Bob_ADDR="fe09cdf3da79f2cc1effa0a751a65e4fe6063177"
Bob_SK="33a4d3e77aafe3b343fcf8c7d1254b031d56558a2b2b751400e166f2e26872da"

#########
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
########

function balance() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["'"$1"'", "latest"],"id":42}' $HOST 2>/dev/null | jq '.result'
    sleep 1
)

function asknonce() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'"$1"'", "latest"],"id":42}' $HOST 2>/dev/null | jq '.result'
    sleep 1
)

function send() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}' $HOST 2>/dev/null | jq ".result"
    sleep 1
)

function txreceipt() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["'"$1"'"],"id":42}' $HOST 2>/dev/null | jq ".result"
    sleep 1
)

function gasprice() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":42}' $HOST 2>/dev/null | jq ".result"
    sleep 1
)

function clean() (
    rm -f send-coin.zen Alice-send-coin.keys Bob-send-coin.keys
)

cat <<EOF >send-coin.zen
Rule check version 2.0.0
Scenario ethereum
Given I have the 'keyring'
Given I have a 'ethereum address' named 'receiver'
Given I have a 'ethereum nonce'
and a 'gas price'
and a 'gas limit'
and a 'gwei value'
When I create the ethereum transaction of 'gwei value' to 'receiver'
When I create the signed ethereum transaction for chain 'fabt'
Then print the 'signed ethereum transaction'
Then print data
EOF

function send_tx_from() (
    sk="$1_SK"
    addr="$1_ADDR"
    balance=`balance "0x${!addr}" | xargs`
    HEXNONCE=`asknonce "0x${!addr}" | xargs`
    if(( $1 == "Alice" )); then
	receiver=$Bob_ADDR
    else
	receiver=$Alice_ADDR
    fi
    cat <<EOF > ${1}-send-coin.keys
{   
  "keyring": { "ethereum": "`echo ${!sk}`" },
  "my_address": "`echo ${!addr}`",
  "fabchain": "$HOST",
  "gas limit": "100000",
  "gas price": "`echo "print($(gasprice | xargs))" | python3`",
  "gwei value": "1",
  "receiver": "`echo $receiver`",
  "ethereum nonce": "$HEXNONCE",
}
EOF

    RAW=`$Z -z send-coin.zen -k ${1}-send-coin.keys 2>/dev/null | jq ".signed_ethereum_transaction" | xargs`
    TXID=`send "0x$RAW" | xargs`
    sleep 5
    flag=0
    for i in $(seq 10); do
	RECEIPT=`txreceipt "$TXID"`
	if [[ ! "$RECEIPT" == "null" && ! "$RECEIPT" == "" ]]; then
	    STATUS=`echo $RECEIPT | jq ".status" | xargs`
	    LOGS=`echo $RECEIPT | jq ".logs" | xargs`
	    if [[ "$STATUS" == "0x1" ]]; then
		echo "`date -u "+%y/%m/%d_%H:%M:%S_%Z"`;$((5+10*i));$TXID"
		flag=1
		break
	    elif [[ ! "$STATUS" == "0x1" ]]; then
		echo "`date -u "+%y/%m/%d_%H:%M:%S_%Z"`;FAILED;$TXID"
		clean
		exit 1
	    fi
	fi
	sleep 10
    done
    if(( $flag != 1)); then
	echo "`date -u "+%y/%m/%d_%H:%M:%S_%Z"`;ERROR;$TXID"
	clean
	exit 1
    fi
)

balance=`balance "0x$Alice_ADDR" | xargs`

if(( $(($balance)) == 0 )); then
    echo
    echo "There are no coins in Alice address."
    echo "Please enter the Alice address:"
    echo $Alice_ADDR
    echo "in the following site:"
    echo "http://test.fabchain.net:5000/"
    echo "to obtain a eth."
    echo "Be aware you can obatin one coin per address per day."
    echo
    clean
    exit 1
fi
echo "Alice balance before the transactions: " $(($balance))

balance=`balance "0x$Bob_ADDR" | xargs`
if(( $(($balance)) == 0 )); then
    echo 
    echo "There are no coins in Bob address."
    echo "Please enter the Bob address:"
    echo $Alice_ADDR
    echo "in the following site:"
    echo "http://test.fabchain.net:5000/"
    echo "to obtain a eth."
    echo "Be aware you can obatin one coin per address per day."
    echo
    clean
    exit 1
fi
echo "Bob balance before the transactions: " $(($balance))

for i in $(seq 5); do
    send_tx_from "Alice"
    send_tx_from "Bob"
done

balance=`balance "0x$Alice_ADDR" | xargs`
echo "Alice balance after the transactions: " $(($balance))
balance=`balance "0x$Bob_ADDR" | xargs`
echo "Bob balance after the transactions: " $(($balance))

clean
