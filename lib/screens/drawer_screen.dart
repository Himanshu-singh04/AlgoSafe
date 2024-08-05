import 'package:algo_safe/utils/colors.dart';
import 'package:flutter/material.dart';

class drawer_screen extends StatefulWidget {
  const drawer_screen({super.key});

  @override
  State<drawer_screen> createState() => _drawer_screenState();
}

class _drawer_screenState extends State<drawer_screen> {
  // drawer screen activities
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: size.height * 0.01,
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Image.asset("assets/images/Algofet secondary subtext.png"),
            ),
            Container(
              width: size.width,
              height: size.height * 0.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30)),
                color: CustomColors.mainColor_1,
              ),
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.home,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Home",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Divider(),
                  ExpansionTile(
                    backgroundColor: CustomColors.mainColor_3,
                    leading: Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Products",
                      style: TextStyle(color: Colors.white),
                    ),
                    children: [
                      ListTile(
                        title: Text(
                          "AlgoDOCK",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          "AlgoBMS",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          "AlgoX",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          "AlgoPACK",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          "AlgoSAFE",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          "AlgoCOM",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.person_3,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Application",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.call,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Contact Us",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.work,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Company",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Divider(),
                  ExpansionTile(
                    backgroundColor: CustomColors.mainColor_3,
                    leading: Icon(
                      Icons.more,
                      color: Colors.white,
                    ),
                    title: Text(
                      "More",
                      style: TextStyle(color: Colors.white),
                    ),
                    children: [
                      ListTile(
                        title: Text(
                          "NEWS",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          "Partners",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          "FAQs",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  Divider()
                ],
              ),
            ),
        
            // stack to overlap the screens
            Stack(children: [
              Container(
                width: size.width,
                height: size.height * 0.14,
                decoration: BoxDecoration(
                  color: CustomColors.mainColor_1,
                ),
              ),
              Container(
                width: size.width,
                height: size.height * 0.14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                  ),
                  color: Colors.white,
                ),
                // child: Padding(
                //   padding: const EdgeInsets.all(12.0),
                //   child: Container(
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(30),
                //       color: CustomColors.mainColor_1,
                //     ),
                //   ),
                // ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
