// import 'package:flutter/material.dart';

// var _currentBmsState = 0;

// Widget stateSelected() {
//     Widget abc = idleWidget();
//     var data;
//     var statevalue = data["BMS_state"];
//     if (statevalue is String) {
//       _currentBmsState = int.tryParse(statevalue) ?? 0;
//       print("${_currentBmsState} BMSstate");
//     } else if (statevalue is int) {
//       // ignore: cast_from_null_always_fails
//       _currentBmsState = statevalue as int;
//       print("${_currentBmsState} BMSstate");
//     } else {
//       _currentBmsState = 0;
//       print("${_currentBmsState} BMSstate");
//     }

//     switch (_currentBmsState) {
//       case 1:
//       case 2:
//       case 5:
//         abc = idleWidget();
//         break;

//       case 4:
//         abc = chargingWidget();
//         break;

//       case 3:
//         abc = dischargingWidget();
//         break;

//       default:
//         abc = idleWidget();
//         break;
//     }
//     return abc;
//   }
  
//   dischargingWidget() {
//   }
  
//   chargingWidget() {
//   }
  
//   idleWidget() {
//   }