import 'package:flutter/material.dart';

class RoundedImage extends StatelessWidget{
  const RoundedImage({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 50,
      backgroundImage: AssetImage('images/image.png'),
    );
    
  }
}