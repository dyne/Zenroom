#!/usr/bin/env python
# -*- coding: utf-8 -*-

import base64
import json
import requests
import logging

from telegram.ext import (Updater, CommandHandler, Filters, MessageHandler,
                          ConversationHandler)

# The two API endpoints that perform encryption and decryption
# using https://apiroom.net 
TOKENENCRYPT_ENDPOINT = "https://apiroom.net/api/danyspin97/Encrypt-message"
DECRYPT_ENDPOINT = "https://apiroom.net/api/danyspin97/Decrypt-Message"

(
    ENCRYPT_WAIT_PASSWORD,
    ENCRYPT_WAIT_MESSAGE,
    DECRYPT_WAIT_PASSWORD,
    DECRYPT_WAIT_MESSAGE
) = range(4)

# Store user password while waiting for cleartext message/ciphertext
passwords = {}


def encrypt_start(update, context):
    update.message.reply_text('Send me the password')

    return ENCRYPT_WAIT_PASSWORD


def encrypt_wait_password(update, context):
    user = update.message.from_user
    passwords[user] = update.message.text
    update.message.reply_text('Send me the message to encrypt:')

    return ENCRYPT_WAIT_MESSAGE


# The strucutre of the secret message depends on the AES protocol
# it must include a "message" and a "header"
def encrypt_wait_message(update, context):
    user = update.message.from_user
    payload = {
        "data": {
            "header": "my secret header",
            "message": update.message.text,
            "password": passwords[user]
        },
        "keys": {}
    }
    # Delete the password stored
    del passwords[user]

    r = requests.post(ENCRYPT_ENDPOINT, json=payload)
    if not r or r.status_code != 200:
        update.message.reply_text("There has been an error while encrypting"
                                  " the message. Please retry")

    ciphertext = base64.b64encode(r.text.encode())
    update.message.reply_text(ciphertext.decode())

    return ConversationHandler.END


def decrypt_start(update, context):
    update.message.reply_text('Send me the password')

    return DECRYPT_WAIT_PASSWORD


def decrypt_wait_password(update, context):
    user = update.message.from_user
    passwords[user] = update.message.text
    update.message.reply_text('Send me the message to decrypt:')

    return DECRYPT_WAIT_MESSAGE


def decrypt_wait_message(update, context):
    user = update.message.from_user
    secret_message = json.loads(base64.b64decode(update.message.text.encode()).decode())
    payload = {
        "data": secret_message,
        "keys": {
            "password": passwords[user]
        }
    }
    # Delete the password stored
    del passwords[user]

    r = requests.post(DECRYPT_ENDPOINT, json=payload)
    if not r or r.status_code != 200:
        update.message.reply_text("There has been an error while decrypting"
                                  " the message. Please retry")

    message = json.loads(r.text)
    update.message.reply_text(message["textDecrypted"])

    return ConversationHandler.END


def main():
    # Create the Updater and pass it your bot's token.
    updater = Updater("TOKEN", use_context=True)

    # Get the dispatcher to register handlers
    dp = updater.dispatcher

    encrypt_handler = ConversationHandler(
        entry_points=[CommandHandler('encrypt', encrypt_start)],
        states={
            ENCRYPT_WAIT_PASSWORD: [
                    MessageHandler(Filters.text, encrypt_wait_password)],
            ENCRYPT_WAIT_MESSAGE: [
                    MessageHandler(Filters.text, encrypt_wait_message)],
        },
        fallbacks=[MessageHandler(Filters.text, None)]
    )
    dp.add_handler(encrypt_handler)

    decrypt_handler = ConversationHandler(
        entry_points=[CommandHandler('decrypt', decrypt_start)],
        states={
            DECRYPT_WAIT_PASSWORD: [
                    MessageHandler(Filters.text, decrypt_wait_password)],
            DECRYPT_WAIT_MESSAGE: [
                    MessageHandler(Filters.text, decrypt_wait_message)],
        },
        fallbacks=[MessageHandler(Filters.text, None)]
    )
    dp.add_handler(decrypt_handler)

    # Start the Bot
    updater.start_polling()

    # Run the bot until you press Ctrl-C
    updater.idle()


if __name__ == '__main__':
    main()
