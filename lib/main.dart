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

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lighter Flashlight',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(title: 'Lighter Flashlight'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _hasFlash = false;
  bool _isOn = false;
  bool islit = false;
  double _width = 0.0;
  double _height = 0.0;
  double imWidth = 175;
  double slidePercent = 0.0;
  double verticalSlidePercent = 0.0;
  double padLeft = 85;
  double padTop = 100;
  double padRight = 85;
  int myNumWidth = 1;
  int myNumHeight = 1;

  StreamController<DragUpdate> dragUpdateStream;
  StreamController<VerticalDragUpdate> verticalDragUpdateStream;

  SlideDirection slideDirection = SlideDirection.none;

  String path = '';
  String contents = '';
  String imageHistoryContents = '';
  DateTime dateTime = DateTime.now();
  File _image;

  File initDisplay;
  File imageHistoryFile;
  List<String> imList = [];

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
    dragUpdateStream.close();
    verticalDragUpdateStream.close();
    super.dispose();
  }

  void handleInitImageDisplay() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    path = appDir.path;
    File tempDis = File('$path/im.txt').existsSync()
        ? File('$path/im.txt')
        : await File('$path/im.txt').create();
    File tempHis = File('$path/imHis.txt').existsSync()
        ? File('$path/imHis.txt')
        : await File('$path/imHis.txt').create();
    print('initDis = ${tempDis.readAsStringSync()}');
    print('imageHis = ${tempHis.readAsStringSync()}');
    setState(() {
      initDisplay = tempDis;
      imageHistoryFile = tempHis;
    });
    try {
      contents = await initDisplay.readAsString();
      if (contents != '0' && contents != '') {
        File image = File('$path/$contents.jpg');
        getImageSize(image);
        setState(() {
          _image = image;
        });
      }
    } catch (e) {
      print('from init $e');
    }
    try {
      imageHistoryContents = await imageHistoryFile.readAsString();
      imList = imageHistoryContents.split(',');
      imList.removeWhere((i) => i == '');
      print(imList);
    } catch (e) {
      print('from his $e');
    }
  }

  void handleInitImageDisplayDispose({int val}) async {
    if (_image != null) {
      val == null
          ? initDisplay.writeAsString('${dateTime.millisecondsSinceEpoch}')
          : initDisplay.writeAsString('$val');
    } else {
      //imageHistoryFile.delete();
      initDisplay.writeAsString('0');
    }
  }

  _MyHomePageState() {
    dragUpdateStream = StreamController<DragUpdate>();

    dragUpdateStream.stream.listen((DragUpdate event) {
      slideDirection = event.direction;
      slidePercent = event.slidePercent;
      if (slidePercent < 0.3) {
        _width = 200 * (slidePercent);
        _height = 120 * (slidePercent);
      } else if (islit) {
        _width = 200;
        _height = 120;
      }
      if (slidePercent < 0.2) {
        islit = false;
        _width = 0;
        _height = 0;
        if (_isOn && _hasFlash) {
          Flashlight.flashOff;
          _isOn = false;
        }
      }
      padLeft = ((1 - (slidePercent * 2)) * 85).clamp(0, 85).toDouble();
      padRight = 85 + (300 * slidePercent).clamp(0, 150).toDouble();
      padTop = 100 - (400 * slidePercent).clamp(0, 100).toDouble();
      setState(() {});
    });

    verticalDragUpdateStream = StreamController<VerticalDragUpdate>();

    verticalDragUpdateStream.stream.listen((VerticalDragUpdate event) {
      slideDirection = event.direction;
      verticalSlidePercent = event.slidePercent;
      if (verticalSlidePercent == -1 && slidePercent >= 0.3) {
        islit = true;
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

  void isLitToggle() {
    if (_hasFlash) {
      setState(() {
        _isOn = !_isOn;
      });
      if (_isOn) {
        Flashlight.flashOn;
      } else {
        Flashlight.flashOff;
      }
    }
  }

  Future getImageCamera() async {
    if (_hasFlash) {
      Flashlight.flashOff;
      _isOn = false;
    }

    var image = await ImagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      await getImageSize(image);
      handleImage(image);
      handleInitImageDisplayDispose();
    }
    //if(_hasFlash){ Future.delayed(Duration(seconds: 2)).then((_){Flashlight.flashOn;});}
  }

  Future getImageGallery() async {
    var image = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      await getImageSize(image);
      handleImage(image);
      handleInitImageDisplayDispose();
    }
  }

  Future getImageSize(File image) async {
    Completer<ui.Image> completer = new Completer<ui.Image>();
    Image.file(
      image,
    ).image.resolve(ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(info.image));
    AsyncSnapshot<ui.Image> snapshot =
        AsyncSnapshot<ui.Image>.withData(ConnectionState.none, null);
    if (completer.future != null) {
      //print('pre-then');
      await completer.future.then((ui.Image data) {
        snapshot = AsyncSnapshot.withData(ConnectionState.done, data);
        setState(() {
          myNumWidth = snapshot.data.width;
          myNumHeight = snapshot.data.height;
          //print('data set');
          //print('expected AR ${snapshot.data.height/snapshot.data.width}');
        });
      });
    }
    snapshot = snapshot.inState(ConnectionState.waiting);
  }

  void handleImage(File image) {
    dateTime = DateTime.now();
    double _aspectRatio = myNumHeight / myNumWidth;
    //print('AR used $_aspectRatio');
    if (_aspectRatio >= 0.5 && _aspectRatio <= 2) {
      try {
        image.copy('$path/${dateTime.millisecondsSinceEpoch}.jpg');
        imageHistoryContents += '${dateTime.millisecondsSinceEpoch},';
        print(imageHistoryContents);
        imageHistoryFile.writeAsString(imageHistoryContents);
        imList.add('${dateTime.millisecondsSinceEpoch}');
      } catch (e) {
        print(e);
      }
      setState(() {
        if (image != null) {
          _image = image;
        }
      });
    } else {
      ooops(context);
    }
  }

  void imageNullerOnDoubleTap() {
    setState(() {
      _image = null;
    });
    handleInitImageDisplayDispose();
  }

  void imageNullerOnTap() {
    imageHistory(context);
  }

  Future<void> ooops(BuildContext context) async {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Oops'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Please use another image with\na different aspect ratio.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  'Go back',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void update() {
    setState(() {});
  }

  Future imageHistory(BuildContext context) async {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              String temp = initDisplay.readAsStringSync();
              return SimpleDialog(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text('Image History'),
                children: <Widget>[
                  Container(
                    height: 150,
                    width: 200,
                    child: imList.isNotEmpty
                      ? ListView(children: imList.map((f) => Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            f == temp
                              ? Icon(Icons.wallpaper,size: 25,)
                              : SizedBox(width: 25,),
                            Image.file(
                              File('$path/$f.jpg'),
                              height: 40,
                              width: 40,
                              fit: BoxFit.scaleDown,
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 60,
                                  child: MaterialButton(
                                    padding: EdgeInsets.all(0),
                                    onPressed: () {
                                      if (f == temp) {
                                        print('here');
                                        _image = null;
                                        handleInitImageDisplayDispose();
                                        update();
                                      }
                                      File('$path/$f.jpg').delete();
                                      imList.remove(f);
                                      imageHistoryContents = imList.join(',') +',';
                                      print(imageHistoryContents);
                                      imageHistoryFile.writeAsString(imageHistoryContents);
                                      setState(() {});
                                    },
                                    child: Text('Delete'),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  child: f == temp
                                      ? MaterialButton(
                                          padding: const EdgeInsets.all(0),
                                          onPressed: () {
                                            _image = null;
                                            handleInitImageDisplayDispose();
                                            update();
                                            setState(() {});
                                          },
                                          child: Text('Unselect'),
                                        )
                                      : MaterialButton(
                                          padding:const EdgeInsets.all(0),
                                          onPressed: () {
                                            File image = File('$path/$f.jpg');
                                            getImageSize(image);
                                            _image = image;
                                            handleInitImageDisplayDispose(val:int.parse(f));
                                            Navigator.of(context).pop();
                                          },
                                          child:
                                            Text('Select'),
                                        ),
                                ),
                              ])
                          ]))
                        .toList())
                      : Text('No image history.'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FlatButton(
                      padding: EdgeInsets.all(0),
                      child: Text(
                        'Go back',
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        actions: <Widget>[
          ImageHistory(
            onLongPress: imageNullerOnDoubleTap,
            onTap: imageNullerOnTap,
          ),
        ],
        title: Text(widget.title, style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 85),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 250.0,
                //color: Colors.red.withOpacity(0.3),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 90.0),
                      child: GestureDetector(
                        onTap: isLitToggle,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: _width,
                          height: _height,
                          child: islit == true
                              ? FlareActor(
                                  'assets/animations/flame.flr',
                                  animation: 'flame',
                                  fit: BoxFit.scaleDown,
                                  shouldClip: false,
                                  alignment: Alignment.bottomCenter,
                                )
                              : Container(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 55.0),
                      child: Transform(
                        transform:
                            Matrix4.rotationZ(-pi * verticalSlidePercent),
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
                        //color: Colors.red.withOpacity(0.3),
                        width: 90,
                        height: 100,
                        child: VerticalDragger(
                          verticalDragUpdateStream:
                              this.verticalDragUpdateStream,
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/cage.png',
                      width: 90.0,
                      height: 90.0,
                    ),
                    Transform(
                      transform: Matrix4.rotationZ(-pi * slidePercent),
                      alignment: Alignment.bottomLeft,
                      child: Material(
                        type: MaterialType.canvas,
                        elevation: 12,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(8)),
                        color: Color.fromRGBO(88, 88, 88, 1.0),
                        child: Container(
                          //color: Colors.blue,
                          width: 198.0,
                          height: 134.0,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _image == null
                                ? Container()
                                : ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(8)),
                                    child: Image.file(
                                      _image,
                                      alignment: Alignment.topCenter,
                                      fit: BoxFit.fitWidth,
                                      width: imWidth,
                                      height: 132 *
                                          (myNumHeight / (myNumWidth * 2)),
                                    ),
                                  ),
                          ),
                        ),
                        // child: new Image.asset('assets/top.png',
                        // width: 198.0,
                        // height: 134.0,
                        //   ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(padLeft, padTop, padRight, 0),
                      child: HorizontalDragger(
                        dragUpdateStream: this.dragUpdateStream,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                //color: Colors.blue,
                height: 222,
                child: Stack(
                  //alignment: Alignment.center,
                  children: <Widget>[
                    Center(
                      child: Material(
                        elevation: 12,
                        //margin: EdgeInsets.all(0),
                        // shape: RoundedRectangleBorder(
                        //   borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                        // ),
                        //borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                        //borderRadius: BorderRadius.only(bottomLeft: Radius.circular(1),bottomRight: Radius.circular(1)),
                        //color: Color.fromRGBO(88, 88, 88, 1.0),
                        color: Colors.transparent,
                        //child: Container(width: 200.0,height: 222.0,)
                        child: Image.asset(
                          'assets/bottom.png',
                          width: 200.0,
                          height: 222.0,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: _image == null
                          ? Container()
                          : ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(8)),
                              child: Image.file(
                                _image,
                                fit: BoxFit.fitWidth,
                                width: imWidth,
                                height: 218 * (myNumHeight / (myNumWidth * 2)),
                                alignment: Alignment.bottomCenter,
                              ),
                            ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              onPressed: getImageGallery,
              backgroundColor: Colors.black,
              tooltip: 'Take from gallery',
              child: Icon(
                Icons.add_photo_alternate,
                color: Colors.grey,
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: getImageCamera,
            backgroundColor: Colors.black,
            tooltip: 'Take from camera',
            child: Icon(
              Icons.add_a_photo,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class ImageHistory extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ImageHistory({
    this.onTap,
    this.onLongPress,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.black,
        elevation: 2,
        shape: CircleBorder(),
        child: Container(
          height: 40,
          width: 40,
          child: Stack(
            alignment: Alignment(-0.1, 0),
            children: <Widget>[
              //Butt,
              Icon(Icons.history, color: Colors.grey),
              InkWell(
                customBorder: CircleBorder(),
                onTap: this.onTap,
                onLongPress: this.onLongPress,
              )
            ],
          ),
        ),
      ),
    );
  }
}
