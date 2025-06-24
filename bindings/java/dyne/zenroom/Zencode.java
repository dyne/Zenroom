
/**
 * This class contains the JNI bindings for the native Zenroom
 * library.  It's package and method names are tied to it, be careful
 * if you need changing them
 */

package dyne.zenroom;

public class Zencode {
    // Declare the native method
    public native String zenroom(String script, String conf, String key, String data, String extra, String context);

    // Wrapper method for easier invocation
    public String execute(String script, String conf, String key, String data, String extra, String context) {
        return zenroom(script, conf, key, data, extra, context);
    }

    // Load the native library (typically done in a static block)
    static {
        System.loadLibrary("zenroom"); // Make sure 'libzenroom.so' is correctly named and available
    }
}
