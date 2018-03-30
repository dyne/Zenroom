#include "zenroom_jni.h"
#include "zenroom.h"

JNIEXPORT jint JNICALL Java_decode_zenroom_Zenroom_zenroom
  (JNIEnv *env, jobject obj, jstring jni_script, jstring jni_conf, jstring jni_keys, jstring jni_data) {
    char* script = (*env)->GetStringUTFChars(env, jni_script, 0);
    char* conf = (*env)->GetStringUTFChars(env, jni_conf, 0);
    char* keys = (*env)->GetStringUTFChars(env, jni_keys, 0);
    char* data = (*env)->GetStringUTFChars(env, jni_data, 0);

    int ret = zenroom_exec(script, conf, keys, data, 3);

    (*env)->ReleaseStringUTFChars(env, jni_script, script);
    (*env)->ReleaseStringUTFChars(env, jni_conf, conf);
    (*env)->ReleaseStringUTFChars(env, jni_keys, keys);
    (*env)->ReleaseStringUTFChars(env, jni_data, data);

    return ret;
}
