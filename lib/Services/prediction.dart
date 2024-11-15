import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


class Prediction {
  Future<List<List<double>>> loadEcgData(String fileLocation) async{
    List<List<double>> fetchData = [];
    for (int i = 0; i < 12; i++){
      List<double> data = await readCsv('assets/dataset/12_lead_ecg_test_${fileLocation}.csv',i+1);
      fetchData.add(data);
    }
    return fetchData;
  }

  Future<List<List<double>>>predict(String fileLocation) async {
    List<List<double>> predictionData = [];

    for (int i = 0; i < 12; i++) {
      List<double> data = await readCsv('assets/dataset/12_lead_ecg_test_${fileLocation}.csv',i+1);
      // data.removeAt(0);
      print(data);
      Interpreter interpreter = await Interpreter.fromAsset('assets/models/tflite_lead_${i+1}.tflite');
      if (data.length != 1000) {
        print('Error: Input data must have exactly 1000 elements.');
        return [];
      }

      var inputArray = data.map((e) => e.toDouble()).toList();
      var reshapedInput = inputArray.reshape([1, 1000, 1]);

      var output = List.filled(5, 0.0).reshape([1, 5]);

      try {
        interpreter.run(reshapedInput, output);

        predictionData.add(output[0]);

      } catch (e) {
        print('Error running model: $e');
      }
    }
    return predictionData;
  }


  Future<List<double>> readCsv(String filePath, int i) async {
    String csvContent = await rootBundle.loadString(filePath);
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvContent);
    List<double> data = [];
    for (int j = 0; j < csvTable[1].length; j++){
      if (csvTable[i][j].runtimeType == int){
        data.add(double.parse(csvTable[i][j].toString()));
      }
      else{
        data.add(csvTable[i][j]);
      }
    }
    return data;
  }

  List<List<String>> getClassLabels(List<List<double>> predictions) {
    List<String> classLabels = ['CD', 'HYP', 'MI', 'NORM', 'STTC'];
    List<List<String>> results = [];

    for (var prediction in predictions) {
      List<String> classifiedLabels = [];
      for (int i = 0; i < prediction.length; i++) {
        if (prediction[i] > 0.5) {
          classifiedLabels.add(classLabels[i]);
        }
      }
      if (classifiedLabels.isEmpty) {
        classifiedLabels.add('Unclassified');
      }
      results.add(classifiedLabels);
    }

    return results;
  }


}