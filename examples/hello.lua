hello = str("Hello World!")
print(hello:string())
print("in hex: "    .. hello:hex())
print("in base64: " .. hello:base64())

hello = hex("48656c6c6f20576f726c6421")
print("re-assign from hex, length "..#hello)
print("as string: " .. hello:string())
print("in base64: " .. hello:base64())

hello = base64("b64:SGVsbG8gV29ybGQh")
print("re-assign from base64, length "..#hello)
print("as string: " .. hello:string())
print("in hex: "    .. hello:hex())

