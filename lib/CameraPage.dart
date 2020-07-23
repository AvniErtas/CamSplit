import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {

  Animation animation;
  AnimationController animationController;
  Duration myDuration = Duration(milliseconds: 500);

  CameraController controller;
  List cameras;
  int selectedCameraIndex;
  String imgPath;
  int selectedIndex = 0;
  bool isMenuOpen = true;
  TextEditingController klasorAdicontroller = new TextEditingController();

  List<String> photoMainCategory = [
    "Family",
    "Work",
    "Travel",
    "Private",
    "Ekle",
  ];

  @override
  void initState() {
    // TODO: implement initState

    animationController = AnimationController(
        vsync: this, duration: myDuration, lowerBound: -55, upperBound: 5);
    animationController.addListener(() {
      setState(() {});
    });


    animationController.forward();

    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        _initCameraController(cameras[selectedCameraIndex]).then((void v) {});
      } else {
        print('No camera available');
      }
    }).catchError((err) {
      print('Error :${err.code}Error message : ${err.message}');
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose

    animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: _cameraPreviewWidget(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: height * 0.18,
                    width: double.infinity,
                    padding: EdgeInsets.all(15),
                    color: Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _cameraToggleRowWidget(),
                        _cameraControlWidget(context),
                        //_cameraPreviewWidget(),
                        _getPreviewPicture(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            left: isMenuOpen == true ? animationController.value : -55,
            top: height/8,
            bottom: height/5.6,
            right: 0,
            duration: myDuration,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: photoMainCategory.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: () {

                        if (index == (photoMainCategory.length - 1) && photoMainCategory.length<7) {
                          _showDialog(context);
                        }
                        if (index != (photoMainCategory.length-1))
                        setState(() {
                          selectedIndex = index;
                        });
                        debugPrint(index.toString());
                      },
                      onLongPress: (){
                        setState(() {
                          selectedIndex = index;
                        });
                        _changeFolderName(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircleAvatar(
                          backgroundColor: selectedIndex == index
                              ? Colors.greenAccent
                              : Colors.transparent,
                          child: Container(
                            height: 75,
                            width: 75,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(
                                        "assets/images/${photoMainCategory[index]}.png"))),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      photoMainCategory[index],
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),

                  ],
                );
              },
            ),
          ),
          InkWell(
            onTap: () {
              setState((){
                if (isMenuOpen) animationController.reverse();
                else animationController.forward();
                isMenuOpen = !isMenuOpen;
              });
            },
            child: Container(
              height: 75,
              width: 75,
              child: Icon(Icons.arrow_forward_ios,color: Colors.white,),
            ),
          ),
        ],
      ),
    );
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  Widget _cameraToggleRowWidget() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Align(
      alignment: Alignment.centerLeft,
      child: FlatButton.icon(
        onPressed: _onSwitchCamera,
        icon: Icon(
          _getCameraLensIcon(lensDirection),
          color: Colors.white,
          size: 24,
        ),
        label: Text(
          '${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1).toUpperCase()}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _cameraControlWidget(context) {
    return FloatingActionButton(
      child: Icon(
        Icons.camera,
        color: Colors.black,
      ),
      backgroundColor: Colors.white,
      onPressed: () {
        _onCapturePressed(context);
      },
    );
  }

  _getPreviewPicture() {
    return Container(
      width: 75,
      height: 75,
      // TODO Önceki Resim Getirilecek
      /* decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("") )
          ),*/
    );
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error:${e.code}\nError message : ${e.description}';
    print(errorText);
  }

  void _onSwitchCamera() {
    selectedCameraIndex =
        selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    _initCameraController(selectedCamera);
  }

  void _onCapturePressed(context) async {
    try {
      callFileMethod(photoMainCategory[selectedIndex]);
      final path =
          join((await getExternalStorageDirectory()).path+"/"+photoMainCategory[selectedIndex], '${DateTime.now()}.png');
      await controller.takePicture(path);
      debugPrint(getTemporaryDirectory().toString());
      /* Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PreviewScreen(
                  imgPath: path,
                )),
      );*/
    } catch (e) {
      _showCameraException(e);
    }
  }

  void _showDialog(context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(
            "Folder Name",
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: klasorAdicontroller,
            decoration: InputDecoration(),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Tamam"),
              onPressed: () {
                setState(() {
                  photoMainCategory.insert(
                      photoMainCategory.length - 1, klasorAdicontroller.text);
                });
                Navigator.of(context).pop();
                //Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  void _changeFolderName(context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(
            "Folder Name",
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: klasorAdicontroller,
            decoration: InputDecoration(),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Tamam"),
              onPressed: () {
                setState(() {
                  photoMainCategory[selectedIndex] = klasorAdicontroller.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  callFileMethod(fileName) async {
    String folderInAppDocDir =
        await AppUtil.createFolderInAppDocDir(fileName.toString());
  }
}

class AppUtil {
  static Future<String> createFolderInAppDocDir(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getExternalStorageDirectory();
    //App Document Directory + folder name
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$folderName/');
    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      return _appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      debugPrint(_appDocDirNewFolder.toString());
      return _appDocDirNewFolder.path;
    }
  }
}
