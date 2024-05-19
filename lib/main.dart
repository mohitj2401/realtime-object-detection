import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:tflite_v2/tflite_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RealTimeObjectDetection(
        cameras: cameras,
      ),
    );
  }
}

class RealTimeObjectDetection extends StatefulWidget {
  final List<CameraDescription> cameras;

  RealTimeObjectDetection({required this.cameras});

  @override
  _RealTimeObjectDetectionState createState() =>
      _RealTimeObjectDetectionState();
}

class _RealTimeObjectDetectionState extends State<RealTimeObjectDetection> {
  late CameraController _controller;
  bool isModelLoaded = false;
  List<dynamic>? recognitions;
  int imageHeight = 0;
  int imageWidth = 0;

  @override
  void initState() {
    super.initState();
    loadModel();
    initializeCamera(null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: 'assets/detect.tflite',
      labels: 'assets/labelmap.txt',
    );
    setState(() {
      isModelLoaded = res != null;
    });
  }

  void toggleCamera() {
    final lensDirection = _controller.description.lensDirection;
    CameraDescription newDescription;
    if (lensDirection == CameraLensDirection.front) {
      newDescription = widget.cameras.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.back);
    } else {
      newDescription = widget.cameras.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.front);
    }

    if (newDescription != null) {
      initializeCamera(newDescription);
    } else {
      print('Asked camera not available');
    }
  }

  void initializeCamera(description) async {
    if (description == null) {
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
    } else {
      _controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
      );
    }

    await _controller.initialize();

    if (!mounted) {
      return;
    }
    _controller.startImageStream((CameraImage image) {
      if (isModelLoaded) {
        runModel(image);
      }
    });
    setState(() {});
  }

  void runModel(CameraImage image) async {
    if (image.planes.isEmpty) return;

    var recognitions = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      model: 'SSDMobileNet',
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResultsPerClass: 1,
      threshold: 0.4,
    );

    setState(() {
      this.recognitions = recognitions;
      // imageHeight = image.height;
      // imageWidth = image.width;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Object Detection'),
      ),
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Stack(
              children: [
                CameraPreview(_controller),
                if (recognitions != null)
                  BoundingBoxes(
                    recognitions: recognitions!,
                    previewH: imageHeight.toDouble(),
                    previewW: imageWidth.toDouble(),
                    screenH: MediaQuery.of(context).size.height * 0.8,
                    screenW: MediaQuery.of(context).size.width,
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    toggleCamera();
                  },
                  icon: Icon(
                    Icons.camera_front,
                    size: 30,
                  ))
            ],
          )
        ],
      ),
    );
  }
}

class BoundingBoxes extends StatelessWidget {
  final List<dynamic> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;

  BoundingBoxes({
    required this.recognitions,
    required this.previewH,
    required this.previewW,
    required this.screenH,
    required this.screenW,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: recognitions.map((rec) {
        var x = rec["rect"]["x"] * screenW;
        var y = rec["rect"]["y"] * screenH;
        double w = rec["rect"]["w"] * screenW;
        double h = rec["rect"]["h"] * screenH;

        return Positioned(
          left: x,
          top: y,
          width: w,
          height: h,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 3,
              ),
            ),
            child: Text(
              "${rec["detectedClass"]} ${(rec["confidenceInClass"] * 100).toStringAsFixed(0)}% Width:${(w).ceil()} Heght: ${h.ceil()}",
              style: TextStyle(
                color: Colors.red,
                fontSize: 15,
                background: Paint()..color = Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
