# Testing TFLite Flutter Plugin speed

Object Detection app built using [TFLite Flutter Plugin](https://github.com/am15h/tflite_flutter_plugin).

It seems that newer versions are significantly slower than older ones. This repo can be used to test:

* tflite_flutter versions 0.9.5 and 0.10.4
* Flutter 3.13.9 and 3.16.9

#### **Important**

For tflite_flutter 0.9.5, following is needed:

* execute `install.sh`(linux) or `install.bat`(windows) for downloading tflite binaries.
More info [here](https://github.com/am15h/tflite_flutter_plugin#important-initial-setup).

## Test

### Environment

This was tested on the following environment:

* Built on Windows 10 with Java 11.0.12
* Run  on Pixel 5 (Android 14)

Just detected same blank(ish) camera image. Not too scientific (e.g. phone might heat up and give lower results), so few ms difference should not be taken too seriously, but the 7x or 16x difference is significant.

### Results

Average time until settles (times in ms).

| Test                                       | Inference | Pre-processing | Total predict | Total elapsed |
|--------------------------------------------|-----------|----------------|---------------|---------------|
| tflite_flutter: 0.9.5<br/>Flutter: 3.13.9  | 22        | 17             | 39            | 51            |
| tflite_flutter: 0.9.5<br/>Flutter: 3.16.9  | 359       | 18             | 378           | 387           |
| tflite_flutter: 0.10.4<br/>Flutter: 3.13.9 | 22        | 15             | 38            | 50            |
| tflite_flutter: 0.10.4<br/>Flutter: 3.16.9 | 351       | 16             | 368           | 376           |

### Conclusion

* No difference between tflite_flutter 0.9.5 and 0.10.4
* Big difference between Flutter 3.13.9 and Flutter 3.16.9 - 16x slower inference time and 7.5x slower total time.

Flutter 3.19.3 seemed to be as slow as 3.16.9. So it seems that the problem is not yet fixed.
