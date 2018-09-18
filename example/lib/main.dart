import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medias_picker/medias_picker.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  List<dynamic> docPaths;
  @override
  initState() {
    super.initState();
  }
  
  pickImages() async {
    try {

      docPaths = await MediasPicker.pickImages(quantity: 7, maxWidth: 1024, maxHeight: 1024, quality: 85);
      
      String firstPath = docPaths[0] as String;

      List<dynamic> listCompressed = await MediasPicker.compressImages(imgPaths: [firstPath], maxWidth: 600, maxHeight: 600, quality: 100);
      print(listCompressed);

    } on PlatformException {

    }

    if (!mounted)
      return;

    setState(() {
      _platformVersion = docPaths.toString();
    });
  }

  pickVideos() async {
    try {
      docPaths = await MediasPicker.pickVideos(quantity: 7);
    } on PlatformException {

    }

    if (!mounted)
      return;

    setState(() {
      _platformVersion = docPaths.toString();
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: new Center(
          child: new Column(
            children: <Widget>[
              new Text('Running on: $_platformVersion\n'),
              new MaterialButton(
                child: new Text(
                  "Pick image",
                ),
                onPressed: () {
                  pickImages();
                },
              ),
              new MaterialButton(
                child: new Text(
                  "Pick videos",
                ),
                onPressed: () {
                  pickVideos();
                },
              ),
              new MaterialButton(
                child: new Text(
                  "Delete temp folder (automatic on ios)",
                ),
                onPressed: () async {
                  
                  if (await MediasPicker.deleteAllTempFiles()) {
                    setState(() {
                      _platformVersion = "deleted";             
                    });
                  } else {
                    setState(() {
                      _platformVersion = "not deleted";             
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
