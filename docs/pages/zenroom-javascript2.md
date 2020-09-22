# Make ❤️  with Zenroom and Javascript (part 2)

## 🔬 Zenroom in the browser: let’s look at WASM

So we saw before that the way we have to interact from Zenroom to JS is via transpilation of our C code into WebAssembly (WASM).

The output of this operation is a binary `.wasm` file and a `.js` file that we will call glue code. In this glue code there are mostly helper functions to interact with the components inside the wasm file, starting with where to retrieve them and so on.

Zenroom itself exposes two main family of functions to interact with other languages `zenroom_exec` and `zencode_exec` as documented in [Zenroom as a lib](/pages/how-to-embed) that are exactly the functions exported and available in our `.wasm` file.

Making the WASM working within the browser, months ago was a hard thing, but nowadays a huge effort has spent, and all the new major browsers support it natively.

## 🕹️ Let’s get our hands dirty

Create a new directory, and add Zenroom as a dependency like

```bash
mkdir zenroom-web-test
cd zenroom-web-test
yarn init
yarn add zenroom
```

Now let’s create a new file `index.html` with the following content

```html
<!DOCTYPE html>
<html>
        <head>
                <meta charset="utf-8" />
                <script src="./node_modules/zenroom/dist/lib/zenroom.js"></script>
                <script>
console.log(Module)
                </script>
        </head>
</html>
```

To see the output of our `html` file, since the `.wasm` file has to be serverd with the correct mimetype, we must run a small http server in localhost, the fastsest way I actually know is with the standard python library. So you want to go with

```bash
$ python3 -m http.server
```

This will serve your pages by default on the 8000 port so point your browser to [http://localhost:8000](http://localhost:8000)

Back to the code, that simply print the emscripten module that you can now interact with like native calls. Documentation on how to interact is available on [emscripten.org](https://emscripten.org/docs/porting/connecting_cpp_and_javascript/Interacting-with-code.html?highlight=cwrap#interacting-with-code-ccall-cwrap)

You should have seen something like this in your browser inspector:

![Result screenshot of zenroom on browser](https://www.dyne.org/wp-content/uploads/2019/10/Screenshot_2019-10-16_07-21-00.png)

That is great now let’s instruct our Module to do something useful like generate a keypair as we seen in the previous episode.

Edit your `index.html` file with the following content:

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <script src="./node_modules/zenroom/dist/lib/zenroom.js"></script>
    <script>
        const keygen_contract = `rule check version 1.0.0
Scenario 'ecdh': Create the keypair
Given that I am known as 'Puria'
When I create the keypair
Then print my data`
        const Wasm = Module()
        Wasm.exec_error = function(){}
        Wasm.exec_ok = function(){}
        Wasm.print = console.log

        Wasm.onRuntimeInitialized = async _ => {
        const zenroom = {
          zencode_exec: Wasm.cwrap('zencode_exec', 'number',
                                     ['string', 'string', 'string', 'string', 'number']),
        }
        zenroom.zencode_exec(keygen_contract, null, null, null, 0)
        }

    </script>
  </head>
</html>
```

The expected result is something like

![Result screenshot of zenroom on browser](https://www.dyne.org/wp-content/uploads/2019/10/Screenshot_2019-10-16_07-54-40.png)

Cool let’s celebrate 🎉🎉🎉 and let’s go through the code, we instantiate an object `Wasm` from our module, then we added some mandatory facilities `exec_error`, `exec_ok` and `print`

So `exec_error` and `exec_ok` are callbacks defined in zenroom that are executed after something goes wrong or goes successfully after each zenroom call. By zenroom call we intend each time a Zenroom VM is created and run. In our case are empty functions as are not needed for the purpose of this exercise

Then obviously `print` is the way we want to see the output, the standard function `console.log` is pretty okay 😉 so we just use that in this case, but sometimes you want to instruct it to print maybe directly on the DOM, that is up to you.

Let’s go now to the next line that is fundamental the `onRuntimeInitialized` [(reference here)](https://emscripten.org/docs/api_reference/module.html?highlight=onruntime#Module.onRuntimeInitialized) is a callback that is executed when everything Wasm-side is okay is something you want always put as a wrapper of your interaction with the wasm module.

Now we are able to define our `cwrap` call as mentioned previously from the emscripten documentation, and define our `zencode_exec` as defined in the [Zenroom as a lib](/pages/how-to-embed) documentation.

Briefly we passed to the `zencode_exec` our contract without any of `conf`, `keys` and `data` and with and muted with `0` `verbosity`

That’s all folks let’s see you next time for the React part.

 

