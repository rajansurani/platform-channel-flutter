import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Channel Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Platform Channel Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel channel =
      MethodChannel('live.videosdk.flutter.example/image_capture');

  String? base64Image;
  bool permissionGranted = false;
  @override
  void initState() {
    super.initState();
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'permissonGranted':
          setState(() {
            permissionGranted = true;
          });
          return;
        default:
          throw MissingPluginException();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
                "Camera Permission Status: ${permissionGranted ? "Granted" : "Not granted"}"),
            if (base64Image != null)
              Image.memory(
                  height: 400, const Base64Decoder().convert(base64Image!)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MaterialButton(
                  onPressed: () async {
                    await channel.invokeMethod('requestPermission');
                  },
                  child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4))),
                      child: const Text(
                        "Request Permission",
                        style: TextStyle(color: Colors.white),
                      )),
                ),
                MaterialButton(
                  onPressed: () async {
                    final String? image =
                        await channel.invokeMethod('captureImage');
                    print("image $image");
                    setState(() {
                      base64Image = image;
                    });
                  },
                  child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4))),
                      child: const Text(
                        "Capture Image",
                        style: TextStyle(color: Colors.white),
                      )),
                )
              ],
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
