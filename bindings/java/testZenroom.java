import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

import dyne.zenroom.Zencode;

public class testZenroom {

    static {
        try {
            System.loadLibrary("zenroom");
            // System.out.printf("Loaded zenroom native library\n");
        } catch(Throwable exc) {
            System.out.printf("Could not load zenroom native library: %s\n", exc.getMessage());
        }
    }

    public static String conf = "debug=1";
    public static String keys = "";
    public static String data = "";
    public static String extra = "";
    public static String context = "";

    public static void main(String[] args) {
		String script = "";
        script = new String (readAllBytesJava7(args[0]));
        String result = (new Zencode()).execute(script, conf, keys, data, extra, context);
		System.out.printf("testZenroom result: %s", result);
    }

    private static String readAllBytesJava7(String filePath) {
        String content = "";

        try {
            content = new String (Files.readAllBytes(Paths.get(filePath)));
        } catch (IOException e) {
            e.printStackTrace();
        }

        return content;
    }

}
