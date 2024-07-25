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
  OverlayEntry? overlayEntry;
  double _currentSliderV = 30;
  double _currentSliderH = 20;


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
  double scale =10;
  double speed = 20;
  double zoomH = 1;
  double zoomV = 1;
  double baselineX = 0;
  double baselineY = 0.0;
  FlSpot? initSpot;
  FlSpot? endSpot;
  ResetRulePointInitScreen(){
    setState(() {
      scale = 10;
      speed = 20;
      zoomH = 1;
      zoomV = 1;
      baselineX = 0.0;
      baselineY = 0.0;
      initSpot = null;
      endSpot = null;
      _currentSliderV = 10;
      _currentSliderH = 20;
    });
  }
  @override
  Widget build(BuildContext context) {

    final dataToDisplay = normalizedData;
    // final dataToDisplay = normalizedData.length > 4000
    //     ? normalizedData.sublist(normalizedData.length - 4000)
    //     : normalizedData;

    //List<double>? filterData = filteredData;

    // List<double> ecgShow = [];
    // for (int i = 0; i < ecgData!.length; i++) {
    //   ecgShow.add(ecgData![i] * scale!);
    // }
    // List<double> filterShow = [];
    // for (int i = 0; i < filterData!.length; i++) {
    //   filterShow.add(filterData![i] * scale!);
    // }

     initSpot = initSpot != null
        ? FlSpot(initSpot!.x * (0.004) * speed!,
        initSpot!.y * scale!)
        : null;
    endSpot = endSpot != null
        ? FlSpot(endSpot!.x * (0.004) * speed!,
        endSpot!.y * scale!)
        : null;


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
                             ((initSpot!.x) / speed!);
                             double end =
                             ((endSpot!.x) / speed!);
                             double initY =
                                 initSpot!.y / scale!;
                             double endY = endSpot!.y / scale!;
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
                     // maxY: 30 * zoomH! + baselineY!,
                     // minY: -30 * zoomH! + baselineY!,
                     // minX: (0) + baselineX!,
                     // maxX: ((80) * zoomH! + baselineX!),
                     maxY: 0.1 * zoomV! + baselineY!,
                     minY: 1 * zoomV! + baselineY!,
                     minX: (0) + baselineX,
                     maxX: ((80) * zoomH + baselineX),
                     clipData: FlClipData.all(),
                   ),
                 ),
               ),
             ],
           ),
         ),
         ),
     Align(
       alignment: Alignment.bottomCenter,
       child: Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Container(
             height: 40,
             width:500,
             padding: EdgeInsets.symmetric(horizontal: 35),
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(10),
               color:Colors.grey.withOpacity(.3)
             ),
               child:SizedBox(
                 width:400,
                 // child: Slider(
                 //   value: _currentSliderV,
                 //   max: 60,
                 //   min:0,
                 //   onChanged: (value) {
                 //     setState(() {
                 //       zoomH = value*.1;
                 //       _currentSliderV = value;
                 //     });
                 //   },
                 // ),
                 child: Slider(
                   value: _currentSliderV,
                   max: 50,
                   min:0,
                   onChanged: (value) {
                     setState(() {
                       baselineX = value*5;
                       _currentSliderV = value;
                     });
                   },
                 ),
               ),
               // Icon(Icons.keyboard_arrow_up_rounded, size: 30,)
           ),
           SizedBox(width: 10,),
           Row(
               children:[
                 Container(
                     decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(15),
                         color:Colors.grey.withOpacity(.3)
                     ),
                     child: TextButton(onPressed: (){
                       setState(() {
                         speed = speed > 120 ? 120 : speed + 5;
                         print(speed);
                       });
                     },
                       child: Text("+",style:TextStyle(fontSize: 25,fontWeight: FontWeight.w900)),)),
                 SizedBox(width: 5,),
                 Container(
                     decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(15),
                         color:Colors.grey.withOpacity(.3)
                     ),
                     child: TextButton(onPressed: (){
                       setState(() {
                         speed = speed < 10 ? 10 : speed - 5;
                         print(speed);
                       });
                     },
                       child: Text("—",style:TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),)),
                 SizedBox(width: 5,),
                 Container(
                     decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(15),
                         color:Colors.grey.withOpacity(.3)
                     ),
                     child: IconButton(onPressed: (){
                       ResetRulePointInitScreen();
                     }, icon: Icon(Icons.restart_alt_rounded,color: Colors.blue, size: 35,)),),
               ]
           )
         ],
       )
     ),
     Align(
         alignment: Alignment.centerRight,
         child: RotatedBox(
           quarterTurns: 3,
           child: Container(
             margin: EdgeInsets.symmetric(vertical: 3),
             height: 40,
             width:300,
             padding: EdgeInsets.symmetric(horizontal: 8),
             decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(10),
                 color:Colors.grey.withOpacity(.3)
             ),
             child:Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 SizedBox(
                   width:250,
                   child: Slider(
                     value: _currentSliderH,
                     max: 40,
                     min:0,
                     onChanged: (value) {
                       setState(() {
                         baselineY = value*.01;
                         _currentSliderH = value;
                       });
                     },
                   ),
                 ),
               ],
             ),
             // Icon(Icons.keyboard_arrow_up_rounded, size: 30,)
           ),
         )
     )
   ],
 );
  }
}