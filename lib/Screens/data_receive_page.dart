import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

import 'data_plot.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({super.key, required this.server});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPageState extends State<ChatPage> {
  static final clientID = 0;
  double rate = 0.0;
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;
  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';
  bool startFlag = false;

  final TextEditingController textEditingController =
  TextEditingController();
  final ScrollController listScrollController = ScrollController();

  List<double> data = [];
  double maxVisibleXRange = 1000;

  @override
  void initState() {
    super.initState();
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      if (kDebugMode) {
        print('Connected to the device');
      }
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          if (kDebugMode) {
            print('Disconnecting locally!');
          }
        } else {
          if (kDebugMode) {
            print('Disconnected remotely!');
          }
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      if (kDebugMode) {
        print('Cannot connect, exception occurred');
        print(error);
      }
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: const Text('Receiving ECG data'))),
      body: Stack(
        children: [
          startFlag ?
          Positioned(
            left: 20,
            child:
            IconButton.outlined(
                icon:  Icon(Icons.pause, color: isConnected ? Colors.red : Colors.grey,),
                onPressed: () {
                  _sendMessage("0");
                  startFlag = false;
                  print(startFlag);
                }
                ),
          ) :
          Positioned(
            left: 20,
            child: IconButton.outlined(
                color: Colors.black,
                icon:  Icon(Icons.play_arrow,  color: isConnected ? Colors.green : Colors.grey,),
                onPressed: isConnected ? () => {
                  _sendMessage("1"),
                  startFlag = true,
                  print(startFlag),
                } : null),
          ),
          Center(child: Image.asset("assets/logo/heartbeat.gif", height: MediaQuery.of(context).size.height*.8)),
          Positioned(
            bottom: 60,
              left: MediaQuery.of(context).size.width*.47,
              child: Text('${rate.toString()} %', style: TextStyle(fontSize: 20),)),
        ],
      ),
    );
  }


  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      String messageText = backspacesCounter > 0
          ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString.substring(0, index);

      // Parse the message and add to plot
      _addDataPoint(messageText);

      setState(() {
        messages.add(
          _Message(1, messageText),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }


  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }


  void _addDataPoint(String message) {
    if (data.length < maxVisibleXRange) {
      try {
        // Convert the received message (string) to a double
        double yValue = double.parse(message.trim());

        setState(() {
          data.add(yValue / 4000);
          rate = data.length/10;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error converting message to double: $e');
        }
      }
    }
    else{
      dispose();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DataPlot(data)));
    }
  }
}