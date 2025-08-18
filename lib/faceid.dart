import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class Register extends StatefulWidget {
  late void Function(dynamic)? receiver;

  Register({this.receiver});

  @override
  _Register createState() => _Register();
}

class _Register extends State<Register> {
  List<CameraDescription> cameras = [];
  CameraController? _controller;
  List<double> vector1 = [];
  List<double> vector2 = [];
  bool screen = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras.length > 0) {
        int index = 0;
        for (var camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.front) {
            break;
          }
          index++;
        }
        _controller = CameraController(
          cameras[index],
          // ResolutionPreset.medium,
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        _controller!.initialize().then((_) {
          setState(() {});
        });
      } else {}
    });
  }

  void updateState(flag) {
    screen = flag;
    setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      img.Image flipedImage = img.decodeImage(imageBytes)!;
      img.Image decodedImage = img.flipHorizontal(flipedImage);

      int cropHeight = (decodedImage.height * 0.45).toInt();
      int cropWidth = (cropHeight / 1.2).toInt();
      int cropX = ((decodedImage.width - cropWidth) / 2).toInt();
      int cropY = 50;

      img.Image croppedImage = img.copyCrop(
        decodedImage,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      final Uint8List bytes = Uint8List.fromList(img.encodeJpg(croppedImage));
      final result = await FaceMethodChannel.getInstance().setImage(bytes);
      widget.receiver!(result);
    } catch (e) {}
  }

  Widget _bottom() {
    return Positioned(
      bottom: (0),
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Registro",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFffffff),
                fontSize: (35),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Coloque su cara dentro del circulo para obtener su identificacion facial",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF636363),
                fontSize: (17),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Container(
              child: ElevatedButton(
                onPressed: () async {
                  _takePicture();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Registrar",
                        style: TextStyle(
                          color: Color(0xFFffffff),
                          fontSize: (20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  side: BorderSide(width: 2, color: Color(0xFF04b4ae)),
                  backgroundColor: Color(0xFF04b4ae),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !(_controller?.value.isInitialized ?? false)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: (1 / _controller!.value.aspectRatio),
                child: Stack(
                  children: [
                    CameraPreview(_controller!),
                    CustomPaint(
                      size: Size.infinite,
                      painter: SerieMaskPainter(),
                    ),
                  ],
                ),
              ),
            ),
            _bottom(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class SerieMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    double boxHeight = size.height * 0.45;
    double boxWidth = boxHeight / 1.2;

    double left = (size.width - boxWidth) / 2;
    double top = 50;

    path.addOval(Rect.fromLTWH(left, top, boxWidth, boxHeight));
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final paintStroke =
        Paint()
          ..color = Color(0xff4ac24a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;

    final cPath = Path();

    cPath.addOval(
      Rect.fromLTWH(left + 6, top + 6, boxWidth - 12, boxHeight - 12),
    );
    canvas.drawPath(cPath, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FaceMethodChannel {
  static FaceMethodChannel? _obj;
  late MethodChannel _platform;
  late void Function(MethodCall)? _receiver;

  FaceMethodChannel._();

  static FaceMethodChannel getInstance() {
    if (_obj == null) {
      _obj = FaceMethodChannel._();
      _obj!._init();
    }
    return _obj!;
  }

  void _init() {
    _platform = MethodChannel("com.lionintel.faceid/faceid");
    _methodCallHandler();
  }

  void _methodCallHandler() {
    _platform.setMethodCallHandler((call) async {
      if (_receiver != null) {
        _receiver!(call);
      }
    });
  }

  void setReceiver([receiver]) {
    _receiver = receiver;
  }

  dynamic setImage(Uint8List image) async {
    try {
      return await _platform.invokeMethod<dynamic>("getVectors", {
        "image": image,
      });
    } on PlatformException catch (e) {
      return e;
    }
  }

  dynamic isFace(vector1, vector2) async {
    try {
      return await _platform.invokeMethod<dynamic>("compareEmbeddings", {
        "embedding1": vector1,
        "embedding2": vector2,
      });
    } on PlatformException catch (e) {
      return e;
    }
  }
}

class Validate extends StatefulWidget {
  late void Function(dynamic)? receiver;

  Validate({this.receiver});

  @override
  _Validate createState() => _Validate();
}

class _Validate extends State<Validate> {
  List<CameraDescription> cameras = [];
  CameraController? _controller;
  List<double> vector1 = [];
  List<double> vector2 = [];
  bool screen = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras.length > 0) {
        int index = 0;
        for (var camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.front) {
            break;
          }
          index++;
        }
        _controller = CameraController(
          cameras[index],
          // ResolutionPreset.medium,
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        _controller!.initialize().then((_) {
          setState(() {});
        });
      } else {}
    });
  }

  void updateState(flag) {
    screen = flag;
    setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      img.Image flipedImage = img.decodeImage(imageBytes)!;
      img.Image decodedImage = img.flipHorizontal(flipedImage);

      int cropHeight = (decodedImage.height * 0.45).toInt();
      int cropWidth = (cropHeight / 1.2).toInt();
      int cropX = ((decodedImage.width - cropWidth) / 2).toInt();
      int cropY = 50;

      img.Image croppedImage = img.copyCrop(
        decodedImage,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      final Uint8List bytes = Uint8List.fromList(img.encodeJpg(croppedImage));
      final result = await FaceMethodChannel.getInstance().setImage(bytes);
      widget.receiver!(result);
    } catch (e) {}
  }

  Widget _bottom() {
    return Positioned(
      bottom: (0),
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Identificacion",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFffffff),
                fontSize: (35),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Coloque su cara dentro del circulo para obtener su identificacion facial",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF636363),
                fontSize: (17),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Container(
              child: ElevatedButton(
                onPressed: () async {
                  _takePicture();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Validar",
                        style: TextStyle(
                          color: Color(0xFFffffff),
                          fontSize: (20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  side: BorderSide(width: 2, color: Color(0xFF04b4ae)),
                  backgroundColor: Color(0xFF04b4ae),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !(_controller?.value.isInitialized ?? false)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: (1 / _controller!.value.aspectRatio),
                child: Stack(
                  children: [
                    CameraPreview(_controller!),
                    CustomPaint(
                      size: Size.infinite,
                      painter: SerieMaskPainter(),
                    ),
                  ],
                ),
              ),
            ),
            _bottom(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
