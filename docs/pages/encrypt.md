# Web Encryption Demo

Demo of in-browser asymmetric AES-GCM encryption.

Zencode Smart Contract in human language (WASM-web build)

For more information see [Zenroom.org](https://zenroom.org).

<span class="big"> <span class="mdi mdi-code-braces"></span> [Code for this example](code)</span>

# Zencode contract

<pre id="encrypt_contract"></pre>


## Alice keypair

<code id="alice"></code>

## Bob public key

<code id="bob"></code>

------------------------

# Upload file

Select a file on the local hard disk of maximum size 400KiB.

Nothing will be uploaded to any server.

Files are encrypted on the fly inside the browser.

  <form method="post" enctype="multipart/form-data">
    <input type="file" name="rawfile" />
    <input type="submit" value="Upload File" name="submit" />
  </form>
  <hr/>
  <div>Speed: <span id="speed"></span> ms</div>
  <hr/>
  <small><code id="result"></code></small>

<script async type="text/javascript" src="../_media/js/zenroom.js"></script>
<script type="text/javascript" src="../_media/js/encrypt.js"></script>

