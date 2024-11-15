// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
// import 'package:fl_chart/fl_chart.dart'; // Add this for charting
//
// class ChatPage extends StatefulWidget {
//   final BluetoothDevice server;
//
//   const ChatPage({super.key, required this.server});
//
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }
//
// class _Message {
//   int whom;
//   String text;
//
//   _Message(this.whom, this.text);
// }
//
// class _ChatPageState extends State<ChatPage> {
//   static const clientID = 0;
//   BluetoothConnection? connection;
//   bool isConnecting = true;
//   bool get isConnected => (connection?.isConnected ?? false);
//   bool isDisconnecting = false;
//   List<_Message> messages = List<_Message>.empty(growable: true);
//   String _messageBuffer = '';
//
//   final TextEditingController textEditingController =
//   TextEditingController();
//   final ScrollController listScrollController = ScrollController();
//
//   List<FlSpot> dataPoints = []; // List to hold data points
//   double xValue = 0.0; // Initial x-axis value
//   double maxVisibleXRange = 50; // Number of visible points at any given time
//   double maxY = 100;
//   double minY = 0;
//   @override
//   void initState() {
//     super.initState();
//
//     BluetoothConnection.toAddress(widget.server.address).then((_connection) {
//       if (kDebugMode) {
//         print('Connected to the device');
//       }
//       connection = _connection;
//       setState(() {
//         isConnecting = false;
//         isDisconnecting = false;
//       });
//
//       connection!.input!.listen(_onDataReceived).onDone(() {
//         if (isDisconnecting) {
//           if (kDebugMode) {
//             print('Disconnecting locally!');
//           }
//         } else {
//           if (kDebugMode) {
//             print('Disconnected remotely!');
//           }
//         }
//         if (this.mounted) {
//           setState(() {});
//         }
//       });
//     }).catchError((error) {
//       if (kDebugMode) {
//         print('Cannot connect, exception occurred');
//         print(error);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     // Avoid memory leak (`setState` after dispose) and disconnect
//     if (isConnected) {
//       isDisconnecting = true;
//       connection?.dispose();
//       connection = null;
//     }
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Live Data Plot')),
//       body: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: LineChart(
//                 LineChartData(
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: dataPoints,
//                       isCurved: true,
//                       color: Colors.blue,
//                       barWidth: 2,
//                       isStrokeCapRound: true,
//                       dotData: const FlDotData(show: false),
//                     ),
//                   ],
//                   titlesData: const FlTitlesData(
//                     show: true,
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: false,
//                       )
//                     ),
//                       topTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: false,
//                       )
//                     ),
//                     rightTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: false,
//                       )
//                     )
//                   ),
//                   gridData: const FlGridData(show: true),
//                   borderData: FlBorderData(show: true),
//
//                   // Dynamically adjust the x-axis range to only show the last few points
//                   minX: dataPoints.isEmpty ? 0 : dataPoints.first.x,
//                   maxX: dataPoints.isEmpty ? 0 : dataPoints.last.x+1,
//
//
//                   // Set the y-axis range dynamically or fixed as per your data
//                   minY: minY - (maxY/4),
//                   maxY: maxY + (maxY/4),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   void _onDataReceived(Uint8List data) {
//     // Allocate buffer for parsed data
//     int backspacesCounter = 0;
//     data.forEach((byte) {
//       if (byte == 8 || byte == 127) {
//         backspacesCounter++;
//       }
//     });
//     Uint8List buffer = Uint8List(data.length - backspacesCounter);
//     int bufferIndex = buffer.length;
//
//     // Apply backspace control character
//     backspacesCounter = 0;
//     for (int i = data.length - 1; i >= 0; i--) {
//       if (data[i] == 8 || data[i] == 127) {
//         backspacesCounter++;
//       } else {
//         if (backspacesCounter > 0) {
//           backspacesCounter--;
//         } else {
//           buffer[--bufferIndex] = data[i];
//         }
//       }
//     }
//
//     // Create message if there is new line character
//     String dataString = String.fromCharCodes(buffer);
//     int index = buffer.indexOf(13);
//     if (~index != 0) {
//       String messageText = backspacesCounter > 0
//           ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
//           : _messageBuffer + dataString.substring(0, index);
//
//       // Parse the message and add to plot
//       _addDataPoint(messageText);
//
//       setState(() {
//         messages.add(
//           _Message(1, messageText),
//         );
//         _messageBuffer = dataString.substring(index);
//       });
//     } else {
//       _messageBuffer = (backspacesCounter > 0
//           ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
//           : _messageBuffer + dataString);
//     }
//   }
//
//
//   void _addDataPoint(String message) {
//     try {
//       // Convert the received message (string) to a double
//       double yValue = double.parse(message.trim());
//
//       setState(() {
//         dataPoints.add(FlSpot(xValue, yValue));
//         maxY = max(dataPoints.last.y as double,maxY);
//         minY = min(dataPoints.last.y as double,minY);
//         xValue += 1.0;
//
//         // Keep sliding the window: If xValue exceeds maxVisibleXRange, adjust the visible range
//         if (dataPoints.length > maxVisibleXRange) {
//           dataPoints.removeAt(0);
//         }
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error converting message to double: $e');
//       }
//     }
//   }
// }
