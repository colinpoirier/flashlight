import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flashlight/flashlight.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zippo_app/draggers.dart';
import 'package:zippo_app/helper_widgets.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarBrightness: Brightness.dark,
    // ));
    const greyIconTheme = IconThemeData(color: Colors.grey);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lighter Flashlight',
      theme: ThemeData(
        primarySwatch: greyIconTheme.color,
        primaryIconTheme: greyIconTheme,
        accentIconTheme: greyIconTheme,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _hasFlash = false;
  bool _isOn = false;
  bool _islit = false;
  double _width = 0.0;
  double _height = 0.0;
  double _imWidth = 175;
  double _slidePercent = 0.0;
  double _verticalSlidePercent = 0.0;
  double _padLeft = 85;
  double _padTop = 100;
  double _padRight = 85;
  int _myNumWidth = 1;
  int _myNumHeight = 1;

  StreamController<HorizontalDragUpdate> _dragUpdateStream;
  StreamController<VerticalDragUpdate> _verticalDragUpdateStream;

  String _path = '';
  String _imageHistoryFileContents = '';
  DateTime _dateTime = DateTime.now();
  File _image;

  File _initDisplay;
  File _imageHistoryFile;
  List<String> _imageList = [];

  @override
  initState() {
    initPlatformState();
    handleInitImageDisplay();
    super.initState();
  }

  initPlatformState() async {
    bool hasFlash = await Flashlight.hasFlash;
    print("Device has flash ? $hasFlash");
    setState(() {
      _hasFlash = hasFlash;
    });
  }

  @override
  void dispose() {
    _dragUpdateStream.close();
    _verticalDragUpdateStream.close();
    super.dispose();
  }

  void handleInitImageDisplay() async {
    final appDir = await getApplicationDocumentsDirectory();
    _path = appDir.path;

    final imagePath = '$_path/im.txt';
    final readDisplayFile = File(imagePath).existsSync()
        ? File(imagePath)
        : await File(imagePath).create();

    final historyPath = '$_path/imHis.txt';
    final readImageHistoryFile = File(historyPath).existsSync()
        ? File(historyPath)
        : await File(historyPath).create();

    print('initDis = ${readDisplayFile.readAsStringSync()}');
    print('imageHis = ${readImageHistoryFile.readAsStringSync()}');

    setState(() {
      _initDisplay = readDisplayFile;
      _imageHistoryFile = readImageHistoryFile;
    });

    final contents = await _initDisplay.readAsString();
    if (contents != '0' && contents != '') {
      final image = File('$_path/$contents.jpg');
      await getImageSize(image);
      setState(() {
        _image = image;
      });
    }

    _imageHistoryFileContents = await _imageHistoryFile.readAsString();
    _imageList = _imageHistoryFileContents.split(',');
    _imageList.removeWhere((i) => i == '');
    print(_imageList);
  }

  Future handleInitImageDisplaySaveRemove({int val}) async {
    if (_image != null) {
      val == null
          ? await _initDisplay
              .writeAsString('${_dateTime.millisecondsSinceEpoch}')
          : await _initDisplay.writeAsString('$val');
    } else {
      await _initDisplay.writeAsString('0');
    }
  }

  _MyHomePageState() {
    _dragUpdateStream = StreamController();

    _dragUpdateStream.stream.listen((HorizontalDragUpdate event) {
      _slidePercent = event.slidePercent;
      if (_slidePercent < 0.3) {
        _width = 200 * (_slidePercent);
        _height = 120 * (_slidePercent);
      } else if (_islit) {
        _width = 200;
        _height = 120;
      }
      if (_slidePercent < 0.2) {
        _islit = false;
        _width = 0;
        _height = 0;
        if (_isOn && _hasFlash) {
          Flashlight.flashOff;
          _isOn = false;
        }
      }
      _padLeft = ((1 - (_slidePercent * 2)) * 85).clamp(0, 85).toDouble();
      _padRight = 85 + (300 * _slidePercent).clamp(0, 150).toDouble();
      _padTop = 100 - (400 * _slidePercent).clamp(0, 100).toDouble();
      setState(() {});
    });

    _verticalDragUpdateStream = StreamController();

    _verticalDragUpdateStream.stream.listen((VerticalDragUpdate event) {
      _verticalSlidePercent = event.slidePercent;
      if (_verticalSlidePercent == -1 && _slidePercent >= 0.3) {
        _islit = true;
        _width = 200;
        _height = 120;
        if (_hasFlash) {
          Flashlight.flashOn;
          _isOn = true;
        }
      }
      setState(() {});
    });
  }

  void _isLitToggle() {
    if (_hasFlash) {
      setState(() {
        _isOn = !_isOn;
      });
      _isOn ? Flashlight.flashOn : Flashlight.flashOff;
    }
  }

  Future getImageCamera() async {
    if (_hasFlash) {
      Flashlight.flashOff;
      _isOn = false;
    }

    final image = await ImagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      await getImageSize(image)
          .then((_) => handleImage(image))
          .then((_) => handleInitImageDisplaySaveRemove())
          .catchError((_) => ooops());
    }
  }

  Future getImageGallery() async {
    final image = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      await getImageSize(image)
          .then((_) => handleImage(image))
          .then((_) => handleInitImageDisplaySaveRemove())
          .catchError((_) => ooops());
    }
  }

  Future getImageSize(File image) async {
    final completer = Completer<ui.Image>();
    Image.file(
      image,
    ).image.resolve(ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(info.image));
    if (completer.future != null) {
      await completer.future.then((ui.Image data) {
        double aspectRatio = data.height / data.width;
        if (aspectRatio >= 0.5 && aspectRatio <= 2) {
          setState(() {
            _myNumWidth = data.width;
            _myNumHeight = data.height;
          });
        } else {
          throw Exception();
        }
      });
    }
  }

  Future handleImage(File image) async {
    _dateTime = DateTime.now();
    final dtMilli = _dateTime.millisecondsSinceEpoch;

    image.copy('$_path/$dtMilli.jpg');

    _imageHistoryFileContents += '$dtMilli,';
    print(_imageHistoryFileContents);
    await _imageHistoryFile.writeAsString(_imageHistoryFileContents);

    _imageList.add('$dtMilli');

    setState(() {
      _image = image;
    });
  }

  void imageNullerOnLongPress() async {
    setState(() {
      _image = null;
    });
    await handleInitImageDisplaySaveRemove();
  }

  void imageNullerOnTap() {
    imageHistory();
  }

  void ooops() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          title: const Text('Oops'),
          content: const Text(
            'Please use another image with\na different aspect ratio.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            FlatButton(
              child: const Text(
                'Go back',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  void update() {
    setState(() {});
  }

  void imageHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String savedInitImage = _initDisplay.readAsStringSync();
            Widget imageHistoryList;
            if (_imageList.isNotEmpty) {
              imageHistoryList = ListView.builder(
                itemCount: _imageList.length,
                itemBuilder: (context, index) {
                  final listImage = _imageList[index];
                  Widget leading, trailingButton;
                  if (listImage == savedInitImage) {
                    leading = const Icon(
                      Icons.wallpaper,
                      size: 25,
                    );
                    trailingButton = ImageHistoryListButton(
                      onPressed: () async {
                        _image = null;
                        await handleInitImageDisplaySaveRemove();
                        update();
                        setState(() {});
                      },
                      child: const Text('Unselect'),
                    );
                  } else {
                    leading = const SizedBox(
                      width: 25,
                    );
                    trailingButton = ImageHistoryListButton(
                      onPressed: () async {
                        File image = File('$_path/$listImage.jpg');
                        await getImageSize(image);
                        _image = image;
                        await handleInitImageDisplaySaveRemove(
                          val: int.parse(listImage),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Select'),
                    );
                  }
                  return ImageHistoryListItem(
                    leading: leading,
                    image: Image.file(
                      File('$_path/$listImage.jpg'),
                      height: 40,
                      width: 40,
                      fit: BoxFit.scaleDown,
                    ),
                    deleteButton: ImageHistoryListButton(
                      child: const Text('Delete'),
                      onPressed: () async {
                        if (listImage == savedInitImage) {
                          _image = null;
                          await handleInitImageDisplaySaveRemove();
                          update();
                        }
                        await File('$_path/$listImage.jpg').delete();
                        _imageList.remove(listImage);
                        _imageHistoryFileContents = _imageList.join(',') +
                            (_imageList.isEmpty ? '' : ',');
                        print(_imageHistoryFileContents);
                        await _imageHistoryFile
                            .writeAsString(_imageHistoryFileContents);
                        setState(() {});
                      },
                    ),
                    trailingButton: trailingButton,
                  );
                },
              );
            } else {
              imageHistoryList = const Center(
                child: Text('No image history'),
              );
            }
            return SimpleDialog(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 24,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              title: const Text('Image History'),
              children: <Widget>[
                Container(
                  height: 150,
                  width: 200,
                  child: imageHistoryList,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FlatButton(
                    padding: const EdgeInsets.all(0),
                    child: const Text(
                      'Go back',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget flame, topImage, bottomImage;
    if (_islit) {
      flame = FlareActor(
        'assets/animations/flame.flr',
        animation: 'flame',
        fit: BoxFit.scaleDown,
        shouldClip: false,
        alignment: Alignment.bottomCenter,
      );
    }
    if (_image != null) {
      topImage = ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
        ),
        child: Image.file(
          _image,
          alignment: Alignment.topCenter,
          fit: BoxFit.fitWidth,
          width: _imWidth,
          height: 132 * _myNumHeight / (_myNumWidth * 2),
        ),
      );
      bottomImage = ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(8),
        ),
        child: Image.file(
          _image,
          fit: BoxFit.fitWidth,
          width: _imWidth,
          height: 218 * _myNumHeight / (_myNumWidth * 2),
          alignment: Alignment.bottomCenter,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        actions: <Widget>[
          ImageHistoryFAB(
            onLongPress: imageNullerOnLongPress,
            onTap: imageNullerOnTap,
          ),
        ],
        title: const Text(
          'Lighter Flashlight',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 250.0,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 90.0),
                    child: GestureDetector(
                      onTap: _isLitToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _width,
                        height: _height,
                        child: flame,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 55.0),
                    child: Transform(
                      transform: Matrix4.rotationZ(-pi * _verticalSlidePercent),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/wheel.png',
                        width: 80.0,
                        height: 80.0,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 55.0),
                    child: Container(
                      width: 90,
                      height: 100,
                      child: VerticalDragger(
                        verticalDragUpdateStream: _verticalDragUpdateStream,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/cage.png',
                    width: 90.0,
                    height: 90.0,
                  ),
                  Transform(
                    transform: Matrix4.rotationZ(-pi * _slidePercent),
                    alignment: Alignment.bottomLeft,
                    child: Material(
                      elevation: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      color: const Color.fromRGBO(88, 88, 88, 1.0),
                      child: Container(
                        width: 198.0,
                        height: 134.0,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: topImage,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _padLeft,
                      _padTop,
                      _padRight,
                      0,
                    ),
                    child: HorizontalDragger(
                      dragUpdateStream: _dragUpdateStream,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              elevation: 12,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              color: const Color.fromRGBO(88, 88, 88, 1.0),
              child: Container(
                width: 198.0,
                height: 222.0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: bottomImage,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () async => await getImageGallery(),
              backgroundColor: Colors.black,
              tooltip: 'Take from gallery',
              child: const Icon(
                Icons.add_photo_alternate,
              ),
            ),
            FloatingActionButton(
              onPressed: () async => await getImageCamera(),
              backgroundColor: Colors.black,
              tooltip: 'Take from camera',
              child: const Icon(
                Icons.add_a_photo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
