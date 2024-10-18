#!/usr/bin/env python

from solcx import compile_standard, install_solc
import json
import os
from web3 import Web3
import eth_keys
from eth_account import account
from dotenv import load_dotenv
from web3.middleware import geth_poa_middleware


def get_private_key(password='My_pass', keystore_file='a.json'):
    keyfile = open('./' + keystore_file)
    keyfile_contents = keyfile.read()
    keyfile.close()
    private_key = eth_keys.keys.PrivateKey(account.Account.decrypt(keyfile_contents, password))
    private_key_str = str(private_key)
    return private_key_str


load_dotenv()

with open("./zen1155.sol", "r") as file:
    simple_storage_file = file.read()

    install_solc("0.6.2")

    compiled_sol = compile_standard(
        {
            "language": "Solidity",
            "sources": {"zen1155.sol": {"content": simple_storage_file}},
            "settings": {
                "outputSelection": {
                    "*": {"*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]}
                }
            },
        },
        solc_binary="/usr/local/lib/python3.9/site-packages/solcx/bin/solc-v0.6.2",
        allow_paths="/root/3.1.0/"
    )

with open("compiled_code.json", "w") as file:
    json.dump(compiled_sol, file)


# get bytecode
bytecode = compiled_sol["contracts"]["zen1155.sol"]["zen1155"]["evm"]["bytecode"]["object"]

# get abi
abi = json.loads(compiled_sol["contracts"]["zen1155.sol"]["zen1155"]["metadata"])["output"]["abi"]

print(abi)


# For connecting to geth_rpc
w3 = Web3(Web3.HTTPProvider(os.getenv("GETH_RPC_URL")))

#Check Connection
t=w3.is_connected()
print(f"Connected {t}")


chain_id = int(os.getenv("NETWORK_ID"))
private_key = get_private_key()

# Create a signer wallet
PA=w3.eth.account.from_key(private_key)

# Get public address from a signer wallet
my_address = PA.address
print(f"Account {my_address}")

#Print balance on current accaunt
BA=w3.eth.get_balance(my_address)
print(f"Balance {BA}")

# Create the contract in Python
SimpleStorage = w3.eth.contract(abi=abi, bytecode=bytecode)

# Get the latest transaction
nonce = w3.eth.get_transaction_count(my_address)

# Submit the transaction that deploys the contract
#transaction = SimpleStorage.constructor(my_address).build_transaction(
transaction = SimpleStorage.constructor().build_transaction(
    {
        "chainId": chain_id,
        "gasPrice": w3.eth.gas_price,
        "from": my_address,
        "nonce": nonce,
        'gas': 2000000,
    }
)

# Address of SmartContract in SMART_CONTRACT
nft_contract = w3.eth.contract(address=os.getenv('SMART_CONTRACT'), abi=abi)
print(f"Contract {os.getenv('SMART_CONTRACT')}")

nonce = w3.eth.get_transaction_count(my_address)
print(f"Nonce : {nonce}")

dict_transaction = {
  'chainId': w3.eth.chain_id,
  'from': my_address,
  'gasPrice': w3.eth.gas_price,
  'nonce': nonce,
}

number_of_nfts_to_mint = 1
transaction = nft_contract.functions.mint(
    my_address,
    1,
    number_of_nfts_to_mint,
    bytes('', 'utf-8')
).build_transaction(dict_transaction)


# Signed
signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
print(f"Sig. transaction : {signed_txn}")

# Mint
txn_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
print(f"Transaction {txn_hash.hex()}")

tx_receipt = w3.eth.wait_for_transaction_receipt(txn_hash)
print(f"Receipt {tx_receipt}")




nonce = w3.eth.get_transaction_count(my_address)
print(f"Nonce : {nonce}")

dict_transaction = {
  'chainId': w3.eth.chain_id,
  'from': my_address,
  'gasPrice': w3.eth.gas_price,
  'nonce': nonce,
}

transaction = nft_contract.functions.mint(
    my_address,
    2,
    number_of_nfts_to_mint,
    bytes('', 'utf-8')
).build_transaction(dict_transaction)

signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
#print(f"Sig. transaction : {signed_txn}")
txn_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
print(f"Transaction {txn_hash.hex()}")
tx_receipt = w3.eth.wait_for_transaction_receipt(txn_hash)
#print(f"Receipt {tx_receipt}")


print(nft_contract.all_functions())

i=1
amount  = nft_contract.functions.balanceOf(my_address, i).call()
print(f"Amount  of token : {amount} with index : {i} ")

transaction = nft_contract.functions.mint(
    my_address,
    1,
    number_of_nfts_to_mint,
    bytes('', 'utf-8')
).call({'from' : my_address})



print(f"Mint one more token {transaction} without sign")


amount  = nft_contract.functions.balanceOf(my_address, i).call()
print(f"Amount  of token : {amount} with index : {i} ")


nonce = w3.eth.get_transaction_count(my_address)
print(f"Nonce : {nonce}")


dict_transaction = {
  'chainId': w3.eth.chain_id,
  'from': my_address,
  'gasPrice': w3.eth.gas_price,
  'nonce': nonce,
}

number_of_nfts_to_mint = 1
transaction = nft_contract.functions.mint(
    my_address,
    1,
    number_of_nfts_to_mint,
    bytes('', 'utf-8')
).build_transaction(dict_transaction)

#Personal not work (IMHO it depend from geth settings)
#e = w3.eth.personal
#e.unlock_account()
#nft_contract.functions.getOwner().call({'from': e.account})
#nft_contract.functions.getOwner().transact({'from': e.account})
print(f"Mint one more token {transaction} with sign")


# Sign
signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
print(f"Sig. transaction : {signed_txn}")

# Mint
txn_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
print(f"Transaction {txn_hash.hex()}")

tx_receipt = w3.eth.wait_for_transaction_receipt(txn_hash)
print(f"Receipt {tx_receipt}")

print(f"Mint one more token {transaction} with sign")




for i in range(5):
    #i=1
    amount  = nft_contract.functions.balanceOf(my_address, i).call()
    print(f"Amount  of token : {amount} with index : {i} ")



