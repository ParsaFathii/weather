import 'package:flutter/material.dart';
import 'package:weather/screens/home.dart';

void main(){
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Application',
      theme: ThemeData.dark(),
      home: Home(),
    );
  }
}
