import 'package:flutter/material.dart';
import 'package:medias_picker/medias_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> mediaPaths;

  void _getImages() async {
    mediaPaths = await MediasPicker.pickImages(
      quantity: 7,
      maxWidth: 1024,
      maxHeight: 1024,
      quality: 85,
    );

    if (!mounted) return;
    setState(() {});
  }

  void _getVideos() async {
    mediaPaths = await MediasPicker.pickVideos(quantity: 7);

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FlatButton(
                child: Text('Get images'),
                onPressed: _getImages,
              ),
              FlatButton(
                child: Text('Get videos'),
                onPressed: _getVideos,
              ),
              if (mediaPaths != null) Text(mediaPaths.join('\n'))
            ],
          ),
        ),
      ),
    );
  }
}
