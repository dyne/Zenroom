
Mostly for fun, we put together a tiny bot for [Telegram](https://web.telegram.org/) that allows you to encrypt and decrypt messages using a password. The encryption uses an AES-GCM algorythm and it's performed by APIs on [Apiroom](http://apiroom.net/). 

# How it works

 * Access the bot [here](https://web.telegram.org/#/im?p=@zenroom_bot) or by typing ***@zenroom_bot*** inside telegram
 * Encrypt your messages using the command ***/encrypt***
 * Decrypt using the command ***/decrypt***
 
# The script

The script is written in python3, find the source code here: 
  
[](../../examples/zenroom-bot.py ':include :type=code python')