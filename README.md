# TensorFlow Lite Flutter Object Detection

Object Detection app built using [TFLite Flutter Plugin](https://github.com/am15h/tflite_flutter_plugin)
and [TFLite Flutter Helper Library](https://github.com/am15h/tflite_flutter_helper)

#### **Important**

* execute `install.sh`(linux) or `install.bat`(windows) for downloading tflite binaries.
More info [here](https://github.com/am15h/tflite_flutter_plugin#important-initial-setup).

#### Environment

This was tested on the following environment:

* Flutter
  * Flutter 3.13.9, Dart 3.1.5 (last major, that is Fast)
  * Flutter 3.16.9, Dart 3.2.6 (first major, that is Slow)
* Java 11.0.12
* Built on Windows 10
* Run  on Pixel 5 (Android 14)

## Speed

Average time until settles (time in ms).

| Key             | Flutter 3.13 | Flutter 3.16 |
|-----------------|--------------|--------------|
| Inference       | 23 ms        | 365 ms       |
| Pre-processing  | 7 ms         | 18  ms       |
| Total predict   | 51 ms        | 393 ms       |
| Total elapsed   | 66 ms        | 401 ms       |

