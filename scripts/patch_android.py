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
