# Make ❤️  with Zenroom and Javascript (part 3)


## Howto use Zenroom with React

We all know, React is one of the most adopted frameworks for client-side nowadays. Even if we have an open debate with Facebook that tried to undermine our project, read here the whole story, by stealing from us and take advantage for his Calibra/Libra stuff.

Anyhow having React working with WASM is not as straightforward as it seems and there are several attempts and several ways to achieve it (try to search on the web: wasm + react)

What we propose here is, in our opinion, the more pragmatic way with less steps freely inspired by [Marvin Irwin's article](https://medium.com/@marvin_78330/webassembly-react-and-create-react-app-8b73346c9b65).

## 🎮 Let’s get our hands dirty

Let’s start by creating a standard React project with the [CRA](https://reactjs.org/docs/create-a-new-react-app.html) tool, and add Zenroom as a dependency

```bash
npx create-react-app zenroom-react-test
cd zenroom-react-test
yarn add zenroom
```

So now we have to know that the `create-react-app` is not able to bundle by default the `.wasm` binary file, so the twearky solution to this is serving it as a static file, hence we are going to

```bash
cd public
ln -s ../node_modules/zenroom/dist/lib/zenroom.wasm .
```

link it in our `/public` folder.
This means that when we are going to start the webserver it will serve the file under `/zenroom.wasm` (cause we put it in the root directory)

But now our glue code (look at the previous post entry if you don’t know about the glue code) doesn’t have the correct address to resolve the binary we have to change a couple of lines in `node_modules/zenroom/dist/lib/zenroom.js` file.

Open the file and search for the string `zenroom.wasm`. Then change the lines

from this

```javascript
var wasmBinaryFile = 'zenroom.wasm';
if (!isDataURI(wasmBinaryFile)) {
  wasmBinaryFile = locateFile(wasmBinaryFile);
}
```

to this

```javascript
var wasmBinaryFile = '/zenroom.wasm';
if (!isDataURI(wasmBinaryFile)) {
  // wasmBinaryFile = locateFile(wasmBinaryFile);
}
```

we added an absolute path and commented the line that looks for the localFile that now is served as a public static one.

Now we can start to use our zenroom js lib per needed by editing the `src/App.js` that will look like:

```javascript
import React from 'react';
import logo from './logo.svg';
import './App.css';

import zenroom from 'zenroom'

const keygen_contract = `rule check version 1.0.0
Scenario 'ecdh': Create the keypair
Given that I am known as 'Puria'
When I create the keypair
Then print my data`

zenroom.script(keygen_contract).zencode_exec()

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
```

and now if you run the server with

```bash
yarn start
```

The expected result is

![Result of zenCode on React](https://www.dyne.org/wp-content/uploads/2019/10/Screenshot_2019-10-16_09-26-40-951x1024.png)

Hoorayyy!!! 🥳🥳🥳 And with this now you are able to maybe create your `<Zencode>` or `<Zenroom>` components and endless creative and secure possibilities.

