import 'package:algosafe/utils/bnb_custom_painter.dart';
import 'package:flutter/material.dart';

class bottom_nav_bar extends StatefulWidget {
  const bottom_nav_bar({super.key});

  @override
  State<bottom_nav_bar> createState() => _bottom_nav_barState();
}

class _bottom_nav_barState extends State<bottom_nav_bar> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
            width: size.width,
            height: 80,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(size.width, 80),
                  painter: BNBCustomPainter(),
                ),
                //Center(
                //  heightFactor: 0.6,
                //  child: FloatingActionButton(onPressed: (){
                //  },
                //  backgroundColor: Colors.blue,
                //  child: Icon(Icons.scanner),elevation: 0.1,),
                //),
                Container(
                  width: size.width,
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(onPressed: (){}, icon: Icon(Icons.info)),
                      IconButton(onPressed: (){}, icon: Icon(Icons.settings)),
                      Container(width: size.width*0.20),
                      IconButton(onPressed: (){}, icon: Icon(Icons.light)),
                      IconButton(onPressed: (){}, icon: Icon(Icons.book))
                    ],
                  ),
                )
              ],
            ),
          );
  }
}




































