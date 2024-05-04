import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as imageLib;
import 'package:image/image.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../utils/nms_util.dart';
import 'stats.dart';

/// Classifier
class Classifier {
  /// Instance of Interpreter
  Interpreter? _interpreter;

  /// Labels file loaded as list
  List<String>? _labels;

  static const String MODEL_FILE_NAME = "yolov8n.tflite";
  static const String LABEL_FILE_NAME = "labelmap.txt";

  /// Input size of image (height = width = 300)
  // static const int INPUT_SIZE = 300;

  /// Result score threshold
  static const double THRESHOLD = 0.5;

  /// Padding the image to transform into square
  // int padSize = INPUT_SIZE;

  /// Number of results to show
  static const int NUM_RESULTS = 10;

  Classifier({
    Interpreter? interpreter,
    List<String>? labels,
  }) {
    loadModel(interpreter: interpreter);
    loadLabels(labels: labels);
  }

  /// Loads interpreter from asset
  void loadModel({Interpreter? interpreter}) async {
    try {
      if (interpreter == null) {
        final file = await rootBundle.load('assets/$MODEL_FILE_NAME');
        _interpreter = Interpreter.fromBuffer(
          file.buffer.asUint8List(),
          options: InterpreterOptions()..threads = 4,
        );
      } else {
        _interpreter = interpreter;
      }
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  /// Loads labels from assets
  void loadLabels({List<String>? labels}) async {
    try {
      _labels = labels ?? (await rootBundle.loadString("assets/" + LABEL_FILE_NAME)).split('\n');
    } catch (e) {
      print("Error while loading labels: $e");
    }
  }

  Map<String, dynamic> predict(imageLib.Image image) {
    var predictStartTime = DateTime.now().millisecondsSinceEpoch;
    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    // stats
    final inputTensors = _interpreter!.getInputTensors();
    final outputTensors = _interpreter!.getOutputTensors();
    final _outputShapes = [];

    var i = 0;
    for (var tensor in inputTensors) {
      print("input ${i++}: ${tensor.shape} as ${tensor.type}");
    }
    i = 0;
    for (var tensor in outputTensors) {
      _outputShapes.add(tensor.shape);
      print("output ${i++}: ${tensor.shape} as ${tensor.type}");
    }

    final inputType = inputTensors.first.type;
    final imageWidth = inputTensors.first.shape[1];
    final imageHeight = inputTensors.first.shape[2];
    final imageSize = imageWidth;

    /// Pre-process the image
    /// Resizing image for model [300, 300]
    final imageInput = imageLib.copyResize(
      image,
      width: imageWidth,
      height: imageHeight,
      interpolation: Interpolation.linear,
    );

    Object imageMatrix;
    if (inputType == TensorType.uint8) {
      print("Input type is uint8");
      imageMatrix = imageInput.getBytes(format: Format.rgb);
    } else {
      print("Input type is not uint8");

      final rgba = Uint8List.view(imageInput.data.buffer);

      final bytes = Float32List(imageInput.width * imageInput.height * 3);

      for (var i = 0, j = 0, len = bytes.length; j < len; i += 4, j += 3) {
        bytes[j + 0] = rgba[i + 0] / 255.0;
        bytes[j + 1] = rgba[i + 1] / 255.0;
        bytes[j + 2] = rgba[i + 2] / 255.0;
      }
      // imageMatrix = imageInput.getBytes(format: Format.rgb);
      // final intBytes = imageInput.getBytes(format: Format.rgb);
      // Float32List floatList = Float32List.fromList(
      //   intBytes.map((e) => e / 255.0).toList(),
      // );
      imageMatrix = bytes.buffer;
      // final data = List.generate(
      //   imageInput.height,
      //   (y) => List.generate(
      //     imageInput.width,
      //     (x) {
      //       final pixel = imageInput.getPixel(x, y);
      //       // pixel.
      //       // pixel.
      //       return [0, 0, 0];
      //       // return [pixel.red / 255, pixel.g / 255, pixel.b / 255];
      //     },
      //   ),
      // );
      // imageMatrix = [data];

      // List<num> floatList = [
      //   for (final byte in intBytes) byte / 255.0,
      // ];
      // ByteBuffer
    }

    var preProcessElapsedTime = DateTime.now().millisecondsSinceEpoch - preProcessStart;

    final input = [imageMatrix];

    // Set output tensor
    // Locations: [1, 10, 4]
    // Classes: [1, 10],
    // Scores: [1, 10],
    // Number of detections: [1]
    final outputShape = outputTensors.first.shape;
    final outputLocations = [List<List<num>>.filled(outputShape[1], List<num>.filled(outputShape[2], 0))];
    final outputClasses = [List<num>.filled(10, 0)];
    final outputScores = [List<num>.filled(10, 0)];
    final numLocations = [0.0];

    final output = {
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: numLocations,
    };

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    _interpreter!.runForMultipleInputs(input, output);

    var inferenceElapsedTime = DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;
    print("Inference time: $inferenceElapsedTime");

    ///// output for single

    List<Recognition> detections = [];

    final labels = [
      'erson',
      'icycle',
      'ar',
      'otorcycle',
      'irplane',
      'us',
      'rain',
      'ruck',
      'oat',
      'raffic light',
      ' fire hydrant',
      ' stop sign',
      ' parking meter',
      ' bench',
      ' bird',
      ' cat',
      ' dog',
      ' horse',
      ' sheep',
      ' cow',
      ' elephant',
      ' bear',
      ' zebra',
      ' giraffe',
      ' backpack',
      ' umbrella',
      ' handbag',
      ' tie',
      ' suitcase',
      ' frisbee',
      ' skis',
      ' snowboard',
      ' sports ball',
      ' kite',
      ' baseball bat',
      ' baseball glove',
      ' skateboard',
      ' surfboard',
      ' tennis racket',
      ' bottle',
      ' wine glass',
      ' cup',
      ' fork',
      ' knife',
      ' spoon',
      ' bowl',
      ' banana',
      ' apple',
      ' sandwich',
      ' orange',
      ' broccoli',
      ' carrot',
      ' hot dog',
      ' pizza',
      ' donut',
      ' cake',
      ' chair',
      ' couch',
      ' potted plant',
      ' bed',
      ' dining table',
      ' toilet',
      ' tv',
      ' laptop',
      ' mouse',
      ' remote',
      ' keyboard',
      ' cell phone',
      ' microwave',
      ' oven',
      ' toaster',
      ' sink',
      ' refrigerator',
      ' book',
      ' clock',
      ' vase',
      ' scissors',
      ' teddy bear',
      ' hair drier',
      ' toothbrush',
    ];

    // const labels = {
    //   0: 1,
    //   1: 10,
    //   2: 11,
    //   3: 12,
    //   4: 2,
    //   5: 3,
    //   6: 4,
    //   7: 5,
    //   8: 6,
    //   9: 7,
    //   10: 8,
    //   11: 9,
    // };

    for (int i = 0; i < _outputShapes[0][2]; i++) {
      // iterate over the detection classifications scores
      for (var j = 4; j < _outputShapes[0][1]; j++) {
        /// Drop classifications below threshold
        if (outputLocations[0][j][i] > 0.5) {
          // Converts the raw output to BBoxs, confidence scores and classes
          // print(
          //   "x: ${outputLocations[0][0][i]}; y: ${outputLocations[0][1][i]}; w: ${outputLocations[0][2][i]}; h: ${outputLocations[0][3][i]}; score: ${outputLocations[0][j][i]}; class: ${j - 4}",
          // );
          detections.add(
            Recognition(
              (j * _outputShapes[0][2] + i).toInt(),
              (labels?[j - 4] ?? "nope").toString(),
              outputLocations[0][j][i] as double,
              Rect.fromLTWH(
                (outputLocations[0][0][i] - outputLocations[0][2][i] / 2) * imageSize,
                (outputLocations[0][1][i] - outputLocations[0][3][i] / 2) * imageSize,
                (outputLocations[0][2][i] as double) * imageSize,
                (outputLocations[0][3][i] as double) * imageSize,
              ),
            ),
          );
        }
      }
    }

    detections = nms(detections, 0.5);

    return {
      "recognitions": detections,
      "stats": Stats(
        totalPredictTime: 0,
        inferenceTime: inferenceElapsedTime,
        preProcessingTime: preProcessElapsedTime,
      )
    };

    // Location
    final locationsRaw = outputLocations.first as List<List<double>>;

    final List<Rect> locations = locationsRaw
        .map((list) => list.map((value) => (value * imageWidth)).toList())
        .map((rect) => Rect.fromLTRB(rect[1], rect[0], rect[3], rect[2]))
        .toList();

    // Classes
    final classesRaw = outputClasses.first as List<double>;
    final classes = classesRaw.map((value) => value.toInt()).toList();

    // Scores
    final scores = outputScores.first as List<double>;

    // Number of detections
    final numberOfDetectionsRaw = numLocations.first;
    final numberOfDetections = numberOfDetectionsRaw.toInt();

    // Using labelOffset = 1 as ??? at index 0
    int labelOffset = 1;

    final List<String> classification = [];
    for (var i = 0; i < numberOfDetections; i++) {
      classification.add(_labels![classes[i] + labelOffset]);
    }

    /// Generate recognitions
    List<Recognition> recognitions = [];
    for (int i = 0; i < numberOfDetections; i++) {
      // Prediction score
      var score = scores[i];
      // Label string
      var label = classification[i];

      if (score > THRESHOLD) {
        final originalSize = Size(imageWidth.toDouble(), imageHeight.toDouble());
        Size targetSize = Size(image.width.toDouble(), image.height.toDouble());
        final transformedRect = transformRectForImage(locations[i], originalSize, targetSize);
        recognitions.add(
          Recognition(i, label, score, transformedRect),
        );
      }
    }

    var predictElapsedTime = DateTime.now().millisecondsSinceEpoch - predictStartTime;

    return {
      "recognitions": recognitions,
      "stats": Stats(
        totalPredictTime: predictElapsedTime,
        inferenceTime: inferenceElapsedTime,
        preProcessingTime: preProcessElapsedTime,
      )
    };
  }

  Rect transformRectForImage(Rect originalRect, fromImageSize, Size toImageSize) {
    final double widthScale = toImageSize.width / fromImageSize.width;
    final double heightScale = toImageSize.height / fromImageSize.height;

    // Calculate new dimensions
    double newLeft = originalRect.left * widthScale;
    double newTop = originalRect.top * heightScale;
    double newRight = originalRect.right * widthScale;
    double newBottom = originalRect.bottom * heightScale;

    // Adjust for center alignment if necessary
    double dx = (toImageSize.width - fromImageSize.width * widthScale) / 2;
    double dy = (toImageSize.height - fromImageSize.height * heightScale) / 2;
    newLeft += dx;
    newRight += dx;
    newTop += dy;
    newBottom += dy;

    return Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
  }

  /// Gets the interpreter instance
  Interpreter? get interpreter => _interpreter;

  /// Gets the loaded labels
  List<String>? get labels => _labels;
}
