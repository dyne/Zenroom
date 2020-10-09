
Mostly for fun, we put together a tiny bot for [Telegram](https://web.telegram.org/) that allows you to encrypt and decrypt messages using a password. The encryption uses an AES-GCM algorythm and it's performed by APIs on [Apiroom](http://apiroom.net/). 

# How it works

 - Access the bot [here](https://web.telegram.org/#/im?p=@zenroom_bot) or by typing ***@zenroom_bot*** inside telegram
 - Encrypt your messages using the command ***/encrypt***
 - Decrypt using the command ***/decrypt***

# Dependency and preparation


 - In the script, Replace **TOKEN** with your telegram token 
 - **sudo pip3 install python-telegram-bot**
 - **sudo pip3 install requests**
 - Run it by launching **python3 zenroombot.py**
 
# The script

The source code here: 
  
[](../../examples/zenroom-bot.py ':include :type=code python')