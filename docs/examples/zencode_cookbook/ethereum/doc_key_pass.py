from web3 import Web3
import eth_keys
from eth_account import account
from zenroom import zenroom
import json

password = 'My_pass'
keyfile = open('./UTC--2024-07-16T10-09-46.525942921Z--e...1')
keyfile_contents = keyfile.read()
keyfile.close()


private_key = eth_keys.keys.PrivateKey(account.Account.decrypt(keyfile_contents, password))
print(private_key)
public_key = private_key.public_key
print(public_key)

private_key_str = str(private_key)

conf = ""

keys = {
    "participant": {
        "keyring": {
            "ethereum": private_key_str
        }
    }
}

data = {
}





contract = """Scenario ethereum: sign ethereum message

# Here we are loading the private key and the message to be signed
Given I am 'participant'
Given I have my 'keyring'
When I create the ethereum address
Then print my 'ethereum address'
Then print the keyring
"""

result = zenroom.zencode_exec(contract, conf, json.dumps(keys), json.dumps(data))
print(result.output)
