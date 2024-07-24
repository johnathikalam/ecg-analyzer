import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import '../Services/dataRead.dart';
import '../Services/signalProcessing.dart';
import '../Utils/I18n.dart';
import '../Utils/colors.dart';


class Ecgchart extends StatefulWidget {
  const Ecgchart({super.key});

  @override
  State<Ecgchart> createState() => _EcgchartState();
}

class _EcgchartState extends State<Ecgchart> {
  bool _isLoaded = false;
  //List<double>? ecgData;
  List<double>? normalizedData;


  @override
  void initState() {
    _isLoaded = true;
    super.initState();
    loadEcgData();
  }

  Future<void> loadEcgData() async {
    try {
      List<int> data = await readCsv('assets/CSV/rec_3.csv');
      List<double> data1 = data.map((int value) => value.toDouble()).toList();

      SignalProcessor processor = SignalProcessor();

      int order = 5;
      double fs = 500.0;
      double lowcut = 0.5;
      double highcut = 50.0;

      // Filter the data
      List<double> filteredData = processor.bandpassFilter(data1??[], order, lowcut, highcut, fs);

      // Normalize the data
      normalizedData = processor.normalize(filteredData);


      setState(() {
        _isLoaded = false;
      });
    } catch (e) {
      print('Error loading ecg data: $e');
    }
  }

  Future<List<int>> readCsv(String filePath) async {
    String csvContent = await rootBundle.loadString(filePath);
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvContent);
    List<int> data = [];
    for (var row in csvTable) {
      if (row.isNotEmpty) {
        data.add(row[0] as int);
      }
    }

    return data;
  }


  @override
  Widget build(BuildContext context) {

    final dataToDisplay = normalizedData;
    // final dataToDisplay = normalizedData.length > 4000
    //     ? normalizedData.sublist(normalizedData.length - 4000)
    //     : normalizedData;

    //List<double>? filterData = filteredData;
    double scale =10;
    double speed = 20;
    double zoom = 1;
    double baselineX = 0;
    double baselineY = 0;
    // List<double> ecgShow = [];
    // for (int i = 0; i < ecgData!.length; i++) {
    //   ecgShow.add(ecgData![i] * scale!);
    // }
    // List<double> filterShow = [];
    // for (int i = 0; i < filterData!.length; i++) {
    //   filterShow.add(filterData![i] * scale!);
    // }
    FlSpot? initSpot;
    FlSpot? endSpot;
     initSpot = initSpot != null
        ? FlSpot(initSpot.x * (0.004) * speed!,
        initSpot.y * scale!)
        : null;
    endSpot = endSpot != null
        ? FlSpot(endSpot.x * (0.004) * speed!,
        endSpot.y * scale!)
        : null;

    ResetRulePointInitScreen(){
      scale = 10;
      speed = 25;
      zoom = 1;
      baselineX = 0.0;
      baselineY = 0.0;
      initSpot;
      endSpot;
    }
 return _isLoaded ?
 Center(child: CircularProgressIndicator()):
 Stack(
   children: [
     Container(
       width: double.infinity,
       height: MediaQuery.of(context).size.height*0.99,
       color: Colors.white,
         padding: EdgeInsets.only(
           top: 12.dp,
           bottom: 10.dp,
           left: 10.dp,
           right: 10.dp,
         ),
         child: SingleChildScrollView(
           scrollDirection: Axis.horizontal,
           child: Row(
             children: [
               Container(
                   width: double.parse(normalizedData?.length.toString()??"")*0.08,
                 // width: MediaQuery.of(context).size.width*.04,
                 //width: 10000,
                 height: MediaQuery.of(context).size.height*0.99,
                 child: LineChart(
                   LineChartData(
                     lineTouchData: LineTouchData(
                       enabled: true,
                       mouseCursorResolver: (p0, p1) {
                         return SystemMouseCursors.precise;
                       },
                       touchSpotThreshold: 5,
                       distanceCalculator:
                           (touchPoint, spotPixelCoordinates) {
                         return (touchPoint -
                             spotPixelCoordinates)
                             .distance;
                       },
                       touchCallback: (event, response) {
                         if (event is FlTapUpEvent) {
                           if (response != null) {
                             if (response.lineBarSpots !=
                                 null) {
                               if (response
                                   .lineBarSpots!.isNotEmpty) {
                                 int x = (response
                                     .lineBarSpots![0]
                                     .x /
                                     speed! /
                                     0.004)
                                     .round()
                                     .toInt();
                                 double y =
                                 normalizedData![x.toInt()];

                                 // if (file && loaded) {
                                 //   BlocProvider.of<
                                 //       InitScreenBloc>(
                                 //       context)
                                 //       .add(SetRulePointInitScreen(
                                 //       spot: FlSpot(
                                 //           x.toDouble(),
                                 //           y)));
                                 // }
                                 //}
                               } else {

                                 ResetRulePointInitScreen();
                               }
                             } else {

                               ResetRulePointInitScreen();
                             }
                           }
                         };},
                       touchTooltipData: LineTouchTooltipData(
                         //maxContentWidth: 1,

                         fitInsideHorizontally: true,
                         fitInsideVertically: true,
                         maxContentWidth: 300.dp,
                         getTooltipItems: (touchedSpots) {
                           final textStyle = TextStyle(
                             color: Colors.white,
                             fontWeight: FontWeight.bold,
                             fontSize: 12.dp,
                           );
                           if (touchedSpots.length > 1 &&
                               initSpot != null &&
                               endSpot != null) {
                             double init =
                             ((initSpot.x) / speed!);
                             double end =
                             ((endSpot.x) / speed!);
                             double initY =
                                 initSpot.y / scale!;
                             double endY = endSpot.y / scale!;
                             return [
                               LineTooltipItem(
                                   '${I18n.translate("timeDifference")}: ${((end - init).abs()).toStringAsFixed(3)} s\n${I18n.translate("voltageDifference")}: ${((endY - initY).abs()).toStringAsFixed(2)} mV',
                                   textStyle),
                               LineTooltipItem(
                                   '${I18n.translate("time")}: ${(touchedSpots[1].x / speed!).toStringAsFixed(3)} s\n${I18n.translate("voltage")}: ${(touchedSpots[1].y / scale!).toStringAsFixed(2)} mV',
                                   textStyle),
                             ];
                           }
                           if (touchedSpots.length > 1) {
                             touchedSpots.removeAt(0);
                           }
                           return touchedSpots
                               .map((LineBarSpot touchedSpot) {
                             return LineTooltipItem(
                                 '${I18n.translate("time")}: ${(touchedSpot.x / speed!).toStringAsFixed(3)} s\n${I18n.translate("voltage")}: ${(touchedSpot.y / scale!).toStringAsFixed(2)} mV',
                                 textStyle);
                           }).toList();
                         },
                       ),
                       handleBuiltInTouches: true,
                       getTouchedSpotIndicator:
                           (barData, spotIndexes) {
                         return spotIndexes.map((spotIndex) {
                           final spot =
                           barData.spots[spotIndex];
                           if (spot.x == 0 || spot.x == 1) {
                             return null;
                           }
                           return TouchedSpotIndicatorData(
                             FlLine(
                               color: Colors.transparent,
                               strokeWidth: 4,
                             ),
                             FlDotData(
                               show: true,
                               getDotPainter: (spot, percent,
                                   barData, index) {
                                 return FlDotCirclePainter(
                                   radius: 4,
                                   color: MyColors.RedL,
                                   strokeWidth: 2,
                                   strokeColor: Colors.white,
                                 );
                               },
                             ),
                           );
                         }).toList();
                       },
                     ),

                     lineBarsData: [
                       LineChartBarData(
                         //show: filterShow.isNotEmpty,
                         // spots: dataToDisplay.asMap().entries.map((entry) {
                         //   return FlSpot(entry.key.toDouble(), double.parse(entry.value.toString()));
                         // }).toList(),
                         spots: dataToDisplay!
                             .asMap()
                             .entries
                             .map((e) => FlSpot(
                             e.key.toDouble() *
                                 0.00099*
                                 speed,
                             e.value))
                             .toList(),
                         isCurved: false,
                         preventCurveOverShooting: true,
                         curveSmoothness: 0.1,
                         isStrokeCapRound: false,
                         color: Colors.redAccent.withOpacity(.7),
                         barWidth: 2,
                         belowBarData: BarAreaData(
                           show: false,
                         ),
                         dotData: FlDotData(show: false),
                       ),

                       LineChartBarData(
                         show: (initSpot != null ||
                             endSpot != null)
                             ? true
                             : false,
                         color: MyColors.purpleL,
                         spots: [
                           initSpot ?? const FlSpot(0, 0),
                           endSpot ??
                               (initSpot ??
                                   const FlSpot(0, 0)),
                         ],
                       ),
                     ],
                     titlesData: FlTitlesData(
                       show: false,
                       leftTitles: AxisTitles(
                         axisNameWidget: Text(
                           'Voltage [mV]',
                           style: TextStyle(
                             color: Colors.black
                                 .withOpacity(0.5), // 0.2
                             fontWeight: FontWeight.bold,
                             fontSize: 12.dp,
                           ),
                         ),
                         sideTitles: SideTitles(
                           showTitles: true,
                           //getTitlesWidget: leftTitleWidgets,
                           reservedSize: 30.dp,
                         ),
                       ),
                       rightTitles: AxisTitles(
                         sideTitles:
                         SideTitles(showTitles: false),
                       ),
                       bottomTitles: AxisTitles(
                         axisNameWidget: Text(
                           'Time [s]',
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             color: Colors.black
                                 .withOpacity(0.5), // 0.2
                             fontWeight: FontWeight.bold,
                             fontSize: 12.dp,
                           ),
                         ),
                         sideTitles: SideTitles(
                           showTitles: true,
                           //getTitlesWidget: bottomTitleWidgets,
                           reservedSize: 26.dp,
                         ),
                       ),
                       topTitles: AxisTitles(
                         sideTitles:
                         SideTitles(showTitles: false),
                       ),
                     ),
                     gridData: FlGridData(
                       show: true,
                       drawHorizontalLine: true,
                       drawVerticalLine: true,
                       horizontalInterval:
                       1, // scale in mV (0.1 mV)
                       verticalInterval: 1, // scale to show
                       getDrawingHorizontalLine: (value) {
                         return value % 5 == 0
                             ? FlLine(
                           color: MyColors.BlueL, // 0.2
                           strokeWidth: 0.5,
                         )
                             : FlLine(
                           color: MyColors.BlueL, // 0.2
                           strokeWidth: 0.1,
                         );
                       },
                       getDrawingVerticalLine: (value) {
                         return value % 5 == 0
                             ? FlLine(
                           color: MyColors.BlueL, // 0.2
                           strokeWidth: 0.5,
                         )
                             : FlLine(
                           color: MyColors.BlueL, // 0.2
                           strokeWidth: 0.1,
                         );
                       },
                     ),
                     borderData: FlBorderData(
                       show: true,
                       border: Border.all(
                         color: MyColors.RedL,
                         width: 1,
                       ),
                     ),
                     // maxY: 30 * zoom! + baselineY!,
                     // minY: -30 * zoom! + baselineY!,
                     // minX: (0) + baselineX!,
                     // maxX: ((80) * zoom! + baselineX!),
                     maxY: 0.1,
                     minY: 1,
                     minX: (0) + baselineX!,
                     maxX: ((80) * zoom! + baselineX!),
                     clipData: FlClipData.all(),
                   ),
                 ),
               ),
             ],
           ),
         ),
             /*
             Positioned(
               top : 0,
               left: 0,
               right: 0,
               child: BlocBuilder<InitScreenBloc, InitScreenState>(
                 builder: (context, state) {
                   double maxvalue = 0;

                   if (state is InitScreenTools) {
                     speed = state.speed;
                     zoom = state.zoom;
                     scale = state.scale;
                     baselineX = state.baselineX;
                     maxvalue = state.silverMax;
                     file = state.file;
                     loaded = state.loaded;
                   }
                   baselineX ??= 0;
                   speed ??= 25;
                   zoom ??= 1;
                   if (file && loaded) {
                     return Tooltip(
                       message:
                       I18n.translate("horizontalAlignment"),
                       child: Slider(
                         onChanged: (value) {
                           BlocProvider.of<InitScreenBloc>(context)
                               .add(ChangeBaselineXInitScreen(
                               baselineX: (value)));
                         },
                         value: baselineX!,
                         min: 0,
                         max: maxvalue,
                       ),
                     );
                   }

                   return Container(
                     height: 0.0,
                   );
                 },
                 buildWhen: (previous, current) =>
                 current is InitScreenTools,
               ),
             ),
             Positioned(
               bottom: 0,
               left: 0,
               child: Container(
                 width: 20.w,
                 padding: EdgeInsets.only(
                   left: 2.dp,
                 ),
                 decoration: BoxDecoration(
                   color: MyColors.RedL,
                   borderRadius: BorderRadius.circular(5.dp),
                 ),
                 child:
                 BlocBuilder<InitScreenBloc, InitScreenState>(
                   builder: (context, state) {
                     if (state is InitScreenTools) {
                       file = state.file;
                       resultAr = state.result;
                     }

                     return Text(
                       resultAr != null
                           ? "${I18n.translate("project")}: ${resultAr!.nameFile}"
                           : "${I18n.translate("project")}: ${I18n.translate("noLoaded")}",
                       overflow: TextOverflow.ellipsis,
                       maxLines: 2,
                       style: TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 10.dp,
                       ),
                     );
                   },
                   buildWhen: (previous, current) =>
                   current is InitScreenTools,
                 ),
               ),
             ),
             Positioned(
               bottom: 0,
               right: 0,
               child: Container(
                 //padding: EdgeInsets.all(5.dp),
                 alignment: Alignment.bottomRight,
                 decoration: const BoxDecoration(
                   color: Colors.transparent,
                   //borderRadius: BorderRadius.circular(5.dp),
                 ),
                 child:
                 BlocBuilder<InitScreenBloc, InitScreenState>(
                   builder: (context, state) {
                     String scaleText = "";
                     String speedText = "";
                     if (state is InitScreenTools) {
                       scale = state.scale;
                       speed = state.speed;
                       file = state.file;
                       resultAr = state.result;
                     }
                     if (scale == 10.0) {
                       scaleText = '10';
                     } else if (scale == 20.0) {
                       scaleText = '20';
                     } else if (scale == 30.0) {
                       scaleText = '30';
                     } else if (scale == 2.0) {
                       scaleText = '2';
                     } else if (scale == 2.5) {
                       scaleText = '2.5';
                     } else if (scale == 5.0) {
                       scaleText = '5';
                     }

                     if (speed == 25.0) {
                       speedText = '25';
                     } else if (speed == 30.0) {
                       speedText = '30';
                     } else if (speed == 50.0) {
                       speedText = '50';
                     } else if (speed == 20.0) {
                       speedText = '20';
                     }

                     return Column(
                       children: [
                         Container(
                           padding: EdgeInsets.all(5.dp),
                           decoration: BoxDecoration(
                             color: MyColors.RedL,
                             borderRadius:
                             BorderRadius.circular(5.dp),
                           ),
                           child: Text(
                             '${I18n.translate("ecgSignal")} \t ${I18n.translate("scale")}: $scaleText div/mV \t ${I18n.translate("speed")}: $speedText div/s',
                             style: TextStyle(
                               color: Colors.white,
                               fontWeight: FontWeight.bold,
                               fontSize: 12.dp,
                             ),
                           ),
                         ),
                       ],
                     );
                   },
                   buildWhen: (previous, current) =>
                   current is InitScreenTools,
                 ),
               ),
             ),
             BlocBuilder<InitScreenBloc, InitScreenState>(
               builder: (context, state) {
                 double maxvalue = 0;
                 if (state is InitScreenTools) {
                   maxvalue = state.silverMax;
                   baselineX = state.baselineX;
                   resultAr = state.result;
                   loaded = state.loaded;
                 }
                 baselineX ??= 0;
                 if (baselineX! < maxvalue * 0.1 &&
                     resultAr != null &&
                     loaded) {
                   if (resultAr!.isStarted) {
                     return Positioned(
                       left: 0,
                       top: 60.dp,
                       child: Tooltip(
                         message: I18n.translate("previousSignal"),
                         waitDuration: const Duration(seconds: 1),
                         child: Container(
                           decoration: BoxDecoration(
                             color: MyColors.RedL,
                             borderRadius:
                             BorderRadius.circular(5.dp),
                           ),
                           padding: EdgeInsets.all(5.dp),
                           child: IconButton(
                             icon: Icon(
                               Icons.arrow_back_ios,
                               color: Colors.white,
                               size: 20.dp,
                             ),
                             onPressed: () {
                               BlocProvider.of<InitScreenBloc>(
                                   context)
                                   .add(
                                   PreviousECGDataInitScreen());
                             },
                           ),
                         ),
                       ),
                     );
                   } else {
                     return const SizedBox(
                       height: 0.0,
                       width: 0.0,
                     );
                   }
                 } else {
                   return const SizedBox(
                     height: 0.0,
                     width: 0.0,
                   );
                 }
               },
               buildWhen: (previous, current) =>
               current is InitScreenTools,
             ),
             BlocBuilder<InitScreenBloc, InitScreenState>(
               builder: (context, state) {
                 double maxvalue = 0;
                 if (state is InitScreenTools) {
                   maxvalue = state.silverMax;
                   baselineX = state.baselineX;
                   resultAr = state.result;
                   loaded = state.loaded;
                 }
                 baselineX ??= 0;
                 if (baselineX! > maxvalue * 0.9 &&
                     resultAr != null &&
                     loaded) {
                   if (!resultAr!.isFinished) {
                     return Positioned(
                       right: 0,
                       top: 60.dp,
                       child: Tooltip(
                         message: I18n.translate("nextSignal"),
                         waitDuration: const Duration(seconds: 1),
                         child: Container(
                           decoration: BoxDecoration(
                             color: MyColors.RedL,
                             borderRadius:
                             BorderRadius.circular(5.dp),
                           ),
                           padding: EdgeInsets.all(5.dp),
                           child: IconButton(
                             icon: Icon(
                               Icons.arrow_forward_ios,
                               color: Colors.white,
                               size: 20.dp,
                             ),
                             onPressed: () {
                               BlocProvider.of<InitScreenBloc>(
                                   context)
                                   .add(NextECGDataInitScreen());
                             },
                           ),
                         ),
                       ),
                     );
                   } else {
                     return const SizedBox(
                       height: 0.0,
                       width: 0.0,
                     );
                   }
                 } else {
                   return const SizedBox(
                     height: 0.0,
                     width: 0.0,
                   );
                 }
               },
               buildWhen: (previous, current) =>
               current is InitScreenTools,
             ),
             BlocBuilder<InitScreenBloc, InitScreenState>(
               builder: (context, state) {
                 if (state is InitScreenTools) {
                   file = state.file;
                   resultAr = state.result;
                 }
                 if (state
                 is DisconnectBluetoothDeviceInitScreenState) {
                   file = true;
                 }
                 if (file == false) {
                   return Positioned(
                     top: 5.dp,
                     right: 5.dp,
                     child: Tooltip(
                       message: I18n.translate("disconnect"),
                       waitDuration: const Duration(seconds: 1),
                       child: IconButton(
                         style: ButtonStyle(
                           backgroundColor:
                           MaterialStateProperty.all<Color>(
                               MyColors.RedL),
                           // set circular button shape
                           shape: MaterialStateProperty.all<
                               RoundedRectangleBorder>(
                               RoundedRectangleBorder(
                                 borderRadius:
                                 BorderRadius.circular(10.dp),
                               )),
                         ),
                         onPressed: () {
                           BlocProvider.of<InitScreenBloc>(context)
                               .add(
                               DisconnectBluetoothDeviceInitScreen());
                         },
                         icon: Icon(
                           Icons.bluetooth_connected,
                           color: MyColors.grayL,
                           size: 22.dp,
                         ),
                       ),
                     ),
                   );
                 }

                 return const SizedBox(
                   height: 0.0,
                   width: 0.0,
                 );
               },
               buildWhen: (previous, current) =>
               current is InitScreenTools ||
                   current
                   is DisconnectBluetoothDeviceInitScreenState,
             ),*/
         ),
     Align(
       alignment: Alignment.bottomCenter,
       child: IconButton(
           onPressed: (){},
           icon:Icon(Icons.keyboard_arrow_up_rounded,
             size: 30,
           )
       ),
     )
   ],
 );
  }

}



