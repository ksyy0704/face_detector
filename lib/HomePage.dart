import 'package:camera/camera.dart';
import 'package:face_detector/Utils/FaceDetectorPainter.dart';
import 'package:face_detector/Utils/UtilsScanner.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

//late List<CameraDescription> cameras;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController cameraController;
  late CameraDescription cameraDescription;
  CameraLensDirection cameraLensDirection = CameraLensDirection.back;
  late FaceDetector faceDetector;
  bool isWorking = false;
  late Size size;
  late List<Face> facesList;

  initCamera() async {
    cameraDescription = await UtilsScanner.getCamera(cameraLensDirection);

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.medium);

    faceDetector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(
        enableClassification: true,
        minFaceSize: 0.1,
        mode: FaceDetectorMode.fast));

    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }

      Future.delayed(Duration(milliseconds: 200));

      cameraController.startImageStream((imageFromStream) {
        if (!isWorking) {
          isWorking = true;

          //implement FaceDetection
          performDetectionOnStreamFrame(imageFromStream);
        }
      });
    });
  }

  dynamic scannResult;

  performDetectionOnStreamFrame(CameraImage imageFromStream) {
    UtilsScanner.detect(
            image: imageFromStream,
            detectInImage: faceDetector.processImage,
            imageRotation: cameraDescription.sensorOrientation)
        .then((dynamic result) {
      setState(() {
        scannResult = result;
      });
    }).whenComplete(() {
      isWorking = false;
    });
  }

  @override
  void initState() {
    super.initState();
    //cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    //cameraController.initialize();
    initCamera() /*.whenComplete(() {
      setState(() {})*/
        ;
    //});
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
    faceDetector.close();
  }

  toggleCamera() async {
    if (cameraLensDirection == CameraLensDirection.back) {
      cameraLensDirection = CameraLensDirection.front;
    } else {
      cameraLensDirection = CameraLensDirection.back;
    }

    await cameraController.stopImageStream();
    await cameraController.dispose();

    setState(() {
      cameraController.initialize(); //여기 바꿈.. 원래는 =null;
    });

    initCamera();
  }

  Widget buildResult() {
    if (scannResult == null ||
        cameraController == null ||
        !cameraController.value.isInitialized) {
      return Container();
    }
    final Size imageSize = Size(cameraController.value.previewSize.height,
        cameraController.value.previewSize.width);
    // customPainter
    CustomPainter customPainter =
        FaceDetectorPainter(imageSize, scannResult, cameraLensDirection);

    return CustomPaint(
      painter: customPainter,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackWidgetChildren = [];
    size = MediaQuery.of(context).size;

    //add streaming camera
    if (cameraController != null) {
      stackWidgetChildren.add(Positioned(
          top: 30,
          left: 0,
          width: size.width,
          height: size.height - 250,
          child: Container(
            child: (cameraController.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: cameraController.value.aspectRatio,
                    child: CameraPreview(cameraController))
                : Container(),
          )));
    }

    // toggle camera
    stackWidgetChildren.add(
      Positioned(
        top: 0,
        left: 0,
        width: size.width,
        height: 250,
        child: Container(
          margin: EdgeInsets.only(bottom: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    toggleCamera();
                  },
                  icon: Icon(
                    Icons.switch_camera,
                    color: Colors.white,
                  ),
                  iconSize: 50,
                  color: Colors.black)
            ],
          ),
        ),
      ),
    );

    stackWidgetChildren.add(
      Positioned(
          top: 30,
          left: 0.0,
          width: size.width,
          height: size.height - 250,
          child: buildResult()),
    );

    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(
          children: stackWidgetChildren,
        ),
      ),
    );
  }
}
