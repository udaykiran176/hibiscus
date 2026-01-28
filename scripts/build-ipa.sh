#!/bin/bash

cd "$( cd "$( dirname "$0"  )" && pwd  )/.."
fvm flutter build ios --no-codesign --release
cd build/ios/
rm -rf Payload Payload.ipa
mv iphoneos Payload
zip -r -9 Payload.ipa Payload
