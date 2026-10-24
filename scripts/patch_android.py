"""Adds ResQMitra's permissions to the generated AndroidManifest and sets minSdk 23."""
import pathlib, re

root = pathlib.Path('android/app')
man = root / 'src/main/AndroidManifest.xml'
s = man.read_text()

perms = [
    'INTERNET', 'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION', 'CAMERA', 'RECORD_AUDIO',
    'CALL_PHONE', 'READ_CONTACTS', 'SEND_SMS', 'READ_PHONE_STATE', 'POST_NOTIFICATIONS',
    'VIBRATE', 'WAKE_LOCK', 'FLASHLIGHT',
]
block = ''.join(f'    <uses-permission android:name="android.permission.{p}"/>\n' for p in perms)
block += '''    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.telephony" android:required="false"/>
    <queries>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="sms"/></intent>
    </queries>
'''
if 'ACCESS_FINE_LOCATION' not in s:
    s = s.replace('<application', block + '    <application', 1)
s = s.replace('android:label="resqmitra"', 'android:label="ResQMitra"')
man.write_text(s)

for name in ('build.gradle.kts', 'build.gradle'):
    g = root / name
    if g.exists():
        t = g.read_text()
        t = t.replace('minSdk = flutter.minSdkVersion', 'minSdk = 23')
        t = t.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 23')
        g.write_text(t)
        print('patched', g)
print('manifest patched')

# Some plugins (e.g. another_telephony) compile Java as 11 but Kotlin as 1.8, which
# Kotlin 1.9+/2.x rejects. Downgrade that check from an error to a warning.
gp = pathlib.Path('android/gradle.properties')
gtxt = gp.read_text() if gp.exists() else ''
if 'kotlin.jvm.target.validation.mode' not in gtxt:
    gtxt = gtxt.rstrip('\n') + '\nkotlin.jvm.target.validation.mode=warning\n'
    gp.write_text(gtxt)
print('gradle.properties patched')

# Some plugins (e.g. geocoding_android) are hard-coded to compileSdk 33, but the AndroidX
# libraries they pull in need compileSdk 34+. Raise compileSdk on every plugin subproject.
SNIPPET = '''
// ---- ResQMitra: force a modern compileSdk on plugin subprojects ----
subprojects {
    if (name != "app") {
        fun fixSdk() {
            val ext = extensions.findByName("android")
            if (ext != null) {
                try {
                    ext.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType).invoke(ext, 36)
                } catch (e: Exception) {
                    try {
                        ext.javaClass.getMethod("setCompileSdk", Int::class.javaObjectType).invoke(ext, 36)
                    } catch (e2: Exception) {
                        println("compileSdk override skipped for $name")
                    }
                }
            }
        }
        if (state.executed) fixSdk() else afterEvaluate { fixSdk() }
    }
}
'''
MARK = 'force a modern compileSdk'
done = False
kts = pathlib.Path('android/build.gradle.kts')
if kts.exists():
    k = kts.read_text()
    if MARK not in k:
        kts.write_text(k.rstrip('\n') + '\n' + SNIPPET)
    print('root build.gradle.kts patched (compileSdk override)')
    done = True
else:
    grv = pathlib.Path('android/build.gradle')
    if grv.exists():
        g = grv.read_text()
        if MARK not in g:
            g += '''
// ---- ResQMitra: force a modern compileSdk on plugin subprojects ----
subprojects {
    if (project.name != 'app') {
        afterEvaluate {
            def ext = project.extensions.findByName('android')
            if (ext != null) { ext.compileSdkVersion 36 }
        }
    }
}
'''
            grv.write_text(g)
        print('root build.gradle patched (compileSdk override)')
        done = True
if not done:
    print('WARNING: no root android build file found')
