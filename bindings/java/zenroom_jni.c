#include <zenroom_jni.h>
#include <zenroom.h>

#if defined(__ANDROID__)
#include <android/log.h>
#endif

#define BUFSIZE 1024000
static char z_output[BUFSIZE];
static char z_error[BUFSIZE];

JNIEXPORT jstring JNICALL Java_dyne_zenroom_Zencode_zenroom
  (JNIEnv *env, jobject obj, jstring jni_script, jstring jni_conf, jstring jni_keys, jstring jni_data, jstring jni_extra, jstring jni_context) {

    jstring result;
    const char* script = (*env)->GetStringUTFChars(env, jni_script, 0);
    const char* conf = (*env)->GetStringUTFChars(env, jni_conf, 0);
    const char* keys = (*env)->GetStringUTFChars(env, jni_keys, 0);
    const char* data = (*env)->GetStringUTFChars(env, jni_data, 0);
    const char* extra = (*env)->GetStringUTFChars(env, jni_extra, 0);
    const char* context = (*env)->GetStringUTFChars(env, jni_context, 0);

    // size_t outputSize = 1024 * 128;
    // char *z_output = (char*)malloc(outputSize * sizeof(char));
    // size_t  errorSize = 1024 * 128;
    // char *z_error = (char*)malloc(errorSize * sizeof(char));

    int ret = zencode_exec_tobuf(script, conf, keys, data, extra, context, z_output, BUFSIZE, z_error, BUFSIZE);

#if defined(__ANDROID__)
// __android_log_print(ANDROID_LOG_VERBOSE, "Zenroom", "len %i", strlen(z_output));
// __android_log_print(ANDROID_LOG_VERBOSE, "Zenroom", "output %s", z_output);
// __android_log_print(ANDROID_LOG_WARN, "Zenroom", "len %i", strlen(z_error));

__android_log_print(ANDROID_LOG_WARN,    "Zenroom/stderr", "%s", z_error);
// __android_log_print(ANDROID_LOG_VERBOSE, "Zenroom/stdout", "%s", z_output);
#endif

    (*env)->ReleaseStringUTFChars(env, jni_script, script);
    (*env)->ReleaseStringUTFChars(env, jni_conf, conf);
    (*env)->ReleaseStringUTFChars(env, jni_keys, keys);
    (*env)->ReleaseStringUTFChars(env, jni_data, data);
    (*env)->ReleaseStringUTFChars(env, jni_extra, extra);
    (*env)->ReleaseStringUTFChars(env, jni_context, context);
    result = (*env)->NewStringUTF(env, z_output);
    // result will be a jstring available until last exec call 
    return result;
}
