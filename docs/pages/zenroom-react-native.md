# Intro

While Zenroom can be used in JS as a library, both natively as well as WASM, we've incidentally gathered more experience with React Native integration. The first experiment was the [DECODE App](https://github.com/DECODEproject/decode-app) which we have mantained and updated into the [DECODE Proximity App](https://github.com/dyne/decode-proximity-app) and part of this integration has been used in the [Global Passport Project App](https://github.com/LedgerProject/GPP_app), here we are reporting some of their internal documentation used to setup Zenroom. 

We have been using Zenroom built as native libraries, for mobile applications, because at the moment of writing, React Native does not yet support WASM, although currently experiments are being performed in that direction, so we hope that the situation will change at some point. 

## The libraries 

You can download the latest nightly builds as well as the point releases on [https://zenroom.org/#downloads](https://zenroom.org/#downloads). We will add more builds as soon as we implement them.

## Important: manage empty strings

One of the major headaches, for reasons that go beyond human comprehension, was the management of empty strings. Zenroom accepts parameters only as strings, meaning that you'll need to use 'JSON.stringify' when passing a JSON object to it. Passing an empty JSON to 'JSON.stringify' will return an object looking like this:

```json
{}
```

which on some Zenroom builds will produce a crash. Therefore, whenever you're passing an empty parameter, you'll need pass an empty string.


## Android Setup

Based on the [DECODE APP's commit] (https://github.com/DECODEproject/decode-app/commit/9b6c9322f941bf91319556f2838409551e0aa2c7): 

### Step 1: build.gradle
In the file “android/app/build.gradle” in “dependencies” insert the string:
```javascript
implementation fileTree(dir: "jniLibs", include: ["*.so"])
```

The result shoul look like: 

```javascript
implementation project(':react-native-gesture-handler')
implementation project(':react-native-device-info')
implementation fileTree(dir: "libs", include: ["*.jar"])
implementation fileTree(dir: "jniLibs", include: ["*.so"])

implementation "com.android.support:appcompat-v7:${rootProject.ext.supportLibVersion}"
implementation "com.facebook.react:react-native:+"
```

### Step 2: java setup
In the file “android/app/src/main/java/com/<company-name>/<app-name>/MainApplication.java” insert the string:

```java
import decode.zenroom.ZenroomPackage;
```

The result shoul look like: 

```java
import java.util.Arrays;
import java.util.List;
import decode.zenroom.ZenroomPackage;
```


as well as the string:
```java
packages.add(new ZenroomPackage());
```

The result shoul look like:

```java
protected List<ReactPackage> getPackages() {
  @SuppressWarnings("UnnecessaryLocalVariable")
  List<ReactPackage> packages = new PackageList(this).getPackages();
  packages.add(new SplashScreenPackage());
  packages.add(new ZenroomPackage());
  return packages;
}
```

### Step 3: more java setup
Copy the folder “decode” in “android/app/src/main/java”. The structure of the folder should be as following:

 - android\app\src\main\java\decode\zenroom\Zenroom.java
 - android\app\src\main\java\decode\zenroom\ZenroomModule.java
 - android\app\src\main\java\decode\zenroom\ZenroomPackage.java


### Step 4: the libraries

Copy the folder “jniLibs” and its content into “android/app/src/main”. The structure of the folder should be as following:
 - android\app\src\main\jniLibs\arm64-v8a\libzenroom.so
 - android\app\src\main\jniLibs\armeabi-v7a\libzenroom.so
 - android\app\src\main\jniLibs\x86\libzenroom.so

The files named “libzenroom.so” need to have the same name, although they will have different sizes, as there is one per architecture.

### Execute a Zenroom smart contract:
1. Create a file named zenroom-client.js containing the code:
```javascript
import { NativeModules } from 'react-native';
export default NativeModules.Zenroom;
```

1. In order to execute a smart contract, create a file containing the code:

```javascript
       import zenroom from 'percorso/file/zenroom-client';

/*       ...      */

       const keys = {“key”: “value”}; //Insert here "keys" parameter to pass
       const data = {“key”: “value”}; //Insert here "data" parameter to pass

/* Important: you can execute JSON.stringify only if the object is NOT EMPTY
 else you need to pass Zenroom an empty string */

		const keysStr = JSON.stringify(keys);
		const dataStr = JSON.stringify(data);

		const zenroomContract = `
         Scenario coconut: issuer keygen
         Given that I am known as 'Alice'
         When I create the issuer keypair
         Then print my 'issuer keypair'
       `; // <-- Insert the Zenroom script here

/* Important: if the parameters “keys” or “data” are empty, 
you need to pass an empty string to zenroom.execute instead of using 
JSON.stringify, else Zenroom will return an exception */

		try {
         const response = await zenroom.execute(
           zenroomContract,
           dataStr,
           keysStr
         );

         return JSON.parse(response); //Result of the Zenroom script
       } catch (e) {
         console.log(e);
       }
```












----- 

OLD 

Zenroom is designed to facilitate embedding into other native applications and high-level scripting languages. The stable releases distribute compiled library components for Apple/iOS and Google/Android platforms, as well MS/Windows DLL. Golang bindings and a Jupyter kernel are also in experimental phase.

To call Zenroom from an host program is very simple, since there isn't an API of calls, but a single call to execute scripts and return their results. The call is called `zenroom_exec` and prints results to the "stderr/stdout" terminal output. Its prototype is common to all libraries:

```c
int zenroom_exec(char *script, char *conf, char *keys,
                 char *data);
```
The input buffers are all read-only, here their functions:
- `script`: a long string containing the script to be executed
- `conf`: a short configuration string (for now only `umm` supported as value)
- `keys`: a string often JSON formatted that contains keys (sensitive information)
- `data`: a string (also JSON formatted) that contains data

In addition to this function there is another one that copies results (error messages and printed output) inside memory buffers:
```c
int zenroom_exec_tobuf(char *script, char *conf, char *keys,
                       char *data,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);
```
In addition to the previously explained arguments, the new ones are:
- `stdout_buf`: pre-allocated buffer by the caller where to copy stdout
- `stdout_len`: maximum length of the pre-allocated stdout buffer
- `stderr_buf`: pre-allocated buffer by the called where to copy stderr
- `stderr_len`: maximum length of the pre-allocated stderr buffer

At last a third call is provided not to execute the script, but to obtain its JSON formatted Abstract Syntax Tree (AST) inside a provided buffer:
```c
int zenroom_parse_ast(char *script,
                      char *stdout_buf, size_t stdout_len,
                      char *stderr_buf, size_t stderr_len);
```

# Language bindings

This API can be called in similar ways from a variety of languages and wrappers that already facilitate its usage.

# Zenroom header file

Here can you find the latest [zenroom.h header file](https://github.com/dyne/Zenroom/blob/master/src/zenroom.h), remember to add *#include <stddef.h>*.

## Javascript


💾 Installation
```
npm install zenroom
```

🎮 Quick Usage

```javascript
const {zenroom_exec} = require("zenroom");
const script = `print("Hello World!")`
zenroom_exec(script).then(({result}) => console.log(result)) //=> "Hello World!"
```

Detailed documentation of js is available [here](/pages/javascript)

Tutorials on how to use the zenRoom in the js world
  * [Node.js](/pages/zenroom-javascript1)
  * [Browser](/pages/zenroom-javascript2)
  * [React](/pages/zenroom-javascript3)

🌐 [Javascript NPM package](https://www.npmjs.com/package/zenroom)


<!-- Outdated
 



-->
