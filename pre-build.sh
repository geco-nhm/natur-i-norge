#!/bin/sh
# sh ./install.sh -d
# flutter pub get
cp -r tf_lib/android/* ./android/app/src/main/jniLibs
cp -r tf_lib/ios/TensorFlowLiteC.framework ~/.pub-cache/hosted/pub.dartlang.org/tflite_flutter-0.9.0/ios
cp -r tf_lib/ios/TensorFlowLiteCMetal.framework ~/.pub-cache/hosted/pub.dartlang.org/tflite_flutter-0.9.0/ios
cp -r tf_lib/ios/tflite_flutter.podspec ~/.pub-cache/hosted/pub.dartlang.org/tflite_flutter-0.9.0/ios
