
public class Zenroom {

    public native int zenroom(String script, String conf, String key, String data);

    public void run(string script, string conf, string key, string data) {
        System.loadLibrary("zenroom");

	zenroom(script, conf, key, data);
    }
}
