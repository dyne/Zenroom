# Intro

While Zenroom can be used in JS as a library, both natively as well as WASM, we've incidentally gathered more experience with React Native integration. The first experiment was the [DECODE App](https://github.com/DECODEproject/decode-app) which we have mantained and updated into the [DECODE Proximity App](https://github.com/dyne/decode-proximity-app) and part of this integration has been used in the [Global Passport Project App](https://github.com/LedgerProject/GPP_app), here we are reporting some of their internal documentation used to setup Zenroom. 

We have been using Zenroom built as native libraries, for mobile applications, because at the moment of writing, React Native does not yet support WASM, although currently experiments are being performed in that direction, so we hope that the situation will change at some point. 

### The libraries 

You can download the latest nightly builds as well as the point releases on [https://zenroom.org/#downloads](https://zenroom.org/#downloads). We will add more builds as soon as we implement them.


### ***Important***: how to manage empty strings

One of the major headaches, for reasons that go beyond human comprehension, was the management of empty strings. Zenroom accepts parameters only as strings, meaning that you'll need to use *JSON.stringify* when passing a JSON object to it. Passing an empty JSON to *JSON.stringify* will return an object looking like this:

```json
{}
```

which on some (!) Zenroom builds will produce a crash. Therefore, whenever you're passing an empty parameter, you'll need ***pass an empty string*** ( [Android](https://github.com/LedgerProject/GPP_app/blob/409e626956a9c9e0950fb45c1ab06343485a8acf/android/app/src/main/java/decode/zenroom/ZenroomModule.java#L51-L58) ). 


## Android Setup

How to configure Zenroom in React Native on Android. Based on the DECODE APP's [commit](https://github.com/DECODEproject/decode-app/commit/9b6c9322f941bf91319556f2838409551e0aa2c7): 

### Step 1: build.gradle
In the file *android/app/build.gradle* in the *dependencies*, insert the string:
```javascript
implementation fileTree(dir: "jniLibs", include: ["*.so"])
```

The result should look like: 

```javascript
implementation project(':react-native-gesture-handler')
implementation project(':react-native-device-info')
implementation fileTree(dir: "libs", include: ["*.jar"])
implementation fileTree(dir: "jniLibs", include: ["*.so"])

implementation "com.android.support:appcompat-v7:${rootProject.ext.supportLibVersion}"
implementation "com.facebook.react:react-native:+"
```

Also make sure you tell gradle what ABIs it has use, which you do by adding to *build.gradle* the following lines (as you can see [here](https://github.com/LedgerProject/GPP_app/blob/409e626956a9c9e0950fb45c1ab06343485a8acf/android/app/build.gradle#L137-L139)):

```javascript
android {

   \\  ... stuff here

        ndk {
            abiFilters "armeabi-v7a", "arm64-v8a", "mips" //  "x86" are "x86_64" are coming soon
        }
    }
```




### Step 2: java setup
In the file *android/app/src/main/java/com/company-name/app-name/MainApplication.java* insert the string:

```java
import decode.zenroom.ZenroomPackage;
```

The result should look like: 

```java
import java.util.Arrays;
import java.util.List;
import decode.zenroom.ZenroomPackage;
```


As well as the string:
```java
packages.add(new ZenroomPackage());
```

The result should look like:

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
Copy the folder *decode* in *android/app/src/main/java*. The structure of the folder should be as following:

 - android\app\src\main\java\decode\zenroom\Zenroom.java
 - android\app\src\main\java\decode\zenroom\ZenroomModule.java
 - android\app\src\main\java\decode\zenroom\ZenroomPackage.java


### Step 4: the libraries

Copy the folder *jniLibs* and its content into *android/app/src/main*. The structure of the folder should be as following:
 - android\app\src\main\jniLibs\arm64-v8a\libzenroom.so
 - android\app\src\main\jniLibs\armeabi-v7a\libzenroom.so
 - android\app\src\main\jniLibs\x86\libzenroom.so

The files named *libzenroom.so* need to have the same name, although they will have different sizes, as there is one per architecture.

### Execute a Zenroom smart contract:

 - Create a file named zenroom-client.js containing the code:
```javascript
import { NativeModules } from 'react-native';
export default NativeModules.Zenroom;
```

 - In order to execute a smart contract, create a file containing the code:

```javascript
       import zenroom from 'percorso/file/zenroom-client';

		//   ...  your code here

       const keys = {“key”: “value”}; //Insert here "keys" parameter to pass
       const data = {“key”: “value”}; //Insert here "data" parameter to pass

		// Important: you can execute JSON.stringify only if the object is NOT EMPTY
		// else you need to pass Zenroom an empty string 

		const keysStr = JSON.stringify(keys);
		const dataStr = JSON.stringify(data);

		const zenroomContract = `
         Scenario coconut: issuer keygen
         Given that I am known as 'Alice'
         When I create the issuer keypair
         Then print my 'issuer keypair'
		`; // <-- Insert the Zenroom smart contract here

		// Important: if the parameters “keys” or “data” are empty, 
		// you need to pass an empty string to zenroom.execute instead of using 
		// JSON.stringify, else Zenroom will return an exception 

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


--------

## iOS setup


Configuration of the Zenroom library on React Native (iOS). You'll want to use the function **zencode_exec_tobuf** whose signature you can find in [zenroom.h](https://github.com/dyne/Zenroom/blob/master/src/zenroom.h#L37-L40). 

### Step 1: copy libs and headers
Copy in the folder *ios* the files:
 - Zenroom.h
 - Zenroom.m
 - zenroomInternal.h
 - zenroom-ios-arm64.a
 - zenroom-ios-armv7.a
 - zenroom-ios-x86_64.a

### Step 2: install
If you haven't done it yet, from your console, open the *ios* folder and run:

```bash
pod install –-repo-update
```

### Step 3: include files
Open in Xcode the workspace *yourAppName.xcworkspace* and include the files you have just copied.

### Step 4: Build settings
Select the project and in the tab *Build Settings* set the parameter *Validate Workspace* to *Yes*.

### Execute a Zenroom smart contract

 - Create a file name *zenroom-client.js* containing the code:
 
```javascript
import { NativeModules } from 'react-native';
export default NativeModules.Zenroom;
```

 - Create one more a file named like *mySmartContract.js* containing the code (and the smart contract):

```javascript
 import zenroom from 'path/file/zenroom-client';
	   
       // ... your code here
    
	const keys = {}; //insert here keys you want to pass, usually this contains keys, credentials etc
       	const data = {}; //insert here data you want to pass, this usually contains generic data 
       	const zenroomContract = `
         Scenario coconut: issuer keygen
         Given that I am known as 'Alice'
         When I create the issuer keypair
         Then print my 'issuer keypair'
       `; // <-- write here your Zenroom smart contract

       try {
         const response = await zenroom.execute(
           zenroomContract,
           JSON.stringify(keys),
           JSON.stringify(data)
         );

         return JSON.parse(response); //Zenroom result
       } catch (e) {
         console.log(e);
       }
```

      



<!-- commented
 



-->
