#!/bin/bash
set -e
R=$(cd "$(dirname "$0")/.." && pwd); B=$R/build; SDK=${ANDROID_HOME:-$HOME/Android/Sdk}; BT=$SDK/build-tools/34.0.0; AJ=$SDK/platforms/android-34/android.jar
[ -n "$JAVA_HOME" ] && export PATH=$JAVA_HOME/bin:$PATH
VER=${VER:-1.0}; VC=${VC:-1}
rm -rf $B/site $B/apk; mkdir -p $B/site $B/apk
[ -d $B/icons ] || python3 $R/tools/icons.py $B/icons
APK_URL=${APK_URL:-SMD-packages-$VER.apk}
python3 - <<PY
import re
R="$R"
app=open(R+"/web/app.html",encoding="utf-8").read()
data=open(R+"/web/data.js",encoding="utf-8").read()
base=app.replace("/*DATA*/",data)
open(R+"/build/smd-packages.html","w",encoding="utf-8").write(base.replace("<!--PWA-HEAD-->",""))
pwa='<link rel="manifest" href="manifest.webmanifest"><link rel="icon" href="favicon-32.png"><link rel="apple-touch-icon" href="icon-192.png">'
open(R+"/build/app-index.html","w",encoding="utf-8").write(base.replace("<!--PWA-HEAD-->",pwa))
PY
mkdir -p $R/android/assets; cp $B/smd-packages.html $R/android/assets/index.html
# ---- APK
cd $B/apk
$BT/aapt2 compile --dir $R/android/res -o res.zip
$BT/aapt2 link -I $AJ --manifest $R/android/AndroidManifest.xml -A $R/android/assets --java gen -o unsigned.apk res.zip \
  --min-sdk-version 24 --target-sdk-version 34 --version-code $VC --version-name $VER
mkdir -p cls
javac -encoding UTF-8 -source 8 -target 8 -nowarn -Xlint:-options -classpath $AJ -d cls gen/ru/lymar/smdpackages/R.java $(find $R/android/src -name '*.java')
$BT/d8 --min-api 24 --release --lib $AJ --output . $(find cls -name '*.class')
zip -q -j unsigned.apk classes.dex
$BT/zipalign -f -p 4 unsigned.apk aligned.apk
KS=${KEYSTORE:-$R/android/release.keystore}; KSPASS=${KEYSTORE_PASS:-smdpackages}
[ -f $KS ] || keytool -genkeypair -keystore $KS -storepass $KSPASS -keypass $KSPASS -alias smd -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=SMD Packages, O=Lymar, C=RU" >/dev/null 2>&1
$BT/apksigner sign --ks $KS --ks-pass pass:$KSPASS --key-pass pass:$KSPASS --ks-key-alias smd --out $B/SMD-packages-$VER.apk aligned.apk
$BT/apksigner verify --print-certs $B/SMD-packages-$VER.apk | head -3
ls -la $B/SMD-packages-$VER.apk
# ---- site
S=$B/site; mkdir -p $S/app
cp $B/app-index.html $S/app/index.html
cp $B/icons/*.png $S/app/
cp $B/smd-packages.html $S/smd-packages.html
[ "$APK_URL" = "SMD-packages-$VER.apk" ] && cp $B/SMD-packages-$VER.apk $S/ || true
cat > $S/app/manifest.webmanifest <<MF
{"name":"SMD-корпуса — справочник","short_name":"SMD-корпуса","start_url":"index.html","scope":"./","display":"standalone","background_color":"#f3f5f8","theme_color":"#0b5cad","lang":"ru",
"icons":[{"src":"icon-192.png","sizes":"192x192","type":"image/png"},{"src":"icon-512.png","sizes":"512x512","type":"image/png"},{"src":"icon-maskable-512.png","sizes":"512x512","type":"image/png","purpose":"maskable"}]}
MF
cat > $S/app/sw.js <<SW
const C="smd-v$VER";const F=["index.html","manifest.webmanifest","icon-192.png","icon-512.png","favicon-32.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(C).then(c=>c.addAll(F)));self.skipWaiting()});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==C).map(x=>caches.delete(x)))));self.clients.claim()});
self.addEventListener("fetch",e=>{e.respondWith(caches.match(e.request,{ignoreSearch:true}).then(r=>r||fetch(e.request)))});
SW
SHA=$(sha256sum $S/SMD-packages-$VER.apk | cut -d' ' -f1); SIZE=$(( $(stat -c%s $S/SMD-packages-$VER.apk) / 1024 ))
read NS NC NT NAP < <(cd $R/web && node -e 'global.window={};require("./data.js");const d=window.SMD_DATA;const n=id=>d.find(t=>t.id===id).rows.length;console.log(n("semi"),n("chip"),n("tant"),n("alu")+n("poly"))')
sed -e "s|__APK_URL__|$APK_URL|g" -e "s/__VER__/$VER/g" -e "s/__SHA__/$SHA/" -e "s/__SIZE__/$SIZE/" -e "s/__N_SEMI__/$NS/" -e "s/__N_CHIP__/$NC/" -e "s/__N_TANT__/$NT/" -e "s/__N_AP__/$NAP/" $R/web/landing.html > $S/index.html
find $S -type f | sort
