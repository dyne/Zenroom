
/**
 * This class contains the JNI bindings for the native Zenroom
 * library.  It's package and method names are tied to it, be careful
 * if you need changing them
 */

package dyne.zenroom;

public class Zencode {
    public native String zenroom(String script, String conf, String key, String data, String extra, String context);
    public String execute(String script, String conf, String key, String data, String extra, String context) {
        return zenroom(script, conf, key, data, extra, context);
    }
}
