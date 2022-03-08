# Use Zenroom as library in Java

## The binders

Zenroom binders for Java are written using The Java Native Interface (JNI) with Android applications in mind, and allow a Java application to pass a smart contract to Zenroom (via a buffer), then Zenroom returns the output to a buffer.
Zenroom assumes the code passed to it via buffers is Zencode (and not Lua). *Important*: Zenroom's Zencode parser expects each line to end with a 'newline', therefore each line of a Zencode smart contract should end with *\n* (see example below).

## Example

The following example generates a keypair. 

```javascript
package com.example.zencode;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;

import decode.zenroom.Zenroom;

public class MainActivity extends AppCompatActivity {

    String script, data, keys, conf;

    static {
        try {
            System.loadLibrary("zenroom");
            Log.d("testZenroom", "Loaded zenroom native library");
        } catch (Throwable exc) {
            Log.d("testZeroom", "Could not load zenroom native library: " + exc.getMessage());
        }
    }
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d("testZenroom", "Starting the test....");

//  Important:
//  Each Zencode line should end with a "\n" 

        script = "rule check version 1.0.0\n"
        + "Scenario 'simple':Create the keypair\n"
        + "Given that I am known as 'Alice'\n"
        + "When I create the keypair\n"
        + "Then print all data";
        keys = "";
        data= "";
        conf = "debug=1";

        String result = (new Zenroom()).execute(script, conf, keys, data);
    //       Log.d("testseb",(new Zenroom()).execute(script, conf, keys, data));
    //       Log.d("result",result);
        setContentView(R.layout.activity_main);
        findViewById(R.id.result).setText(result);

        setContentView(R.layout.activity_main);

    }
}
```

The result should look like this:


```json
{
   "Alice":{
      "credential_keypair":{
         "private":"AZNuDnEujJlccuejLIHihxFeKzzuReL3mwikvtcCVHlFaYo7rCdR",
         "public":"AhMBC4woNICc0OZyQS3kPE5q6EVlwyn5VTsBKG1ulsxmDfN1f9Kmqc0fgWUsRxRSIhSsJnSsP1CUjNk"
      }
   }
}

```

## Source

The Java binders can are [zenroom_jni.c](https://github.com/DECODEproject/Zenroom/blob/master/src/zenroom_jni.c) and [zenroom_jni.h](https://github.com/DECODEproject/Zenroom/blob/master/src/zenroom_jni.h)
