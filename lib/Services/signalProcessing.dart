import 'dart:math';

class SignalProcessor {
  // Generate Butterworth bandpass filter coefficients
  List<List<double>> butterBandpass(int order, double lowcut, double highcut, double fs) {
    double nyquist = 0.5 * fs;
    double low = lowcut / nyquist;
    double high = highcut / nyquist;

    // Pre-warp the frequencies
    double preW1 = tan(pi * low / 2);
    double preW2 = tan(pi * high / 2);

    // Calculate center frequency and bandwidth
    double w0 = sqrt(preW1 * preW2);
    double bw = preW2 - preW1;

    // Generate analog filter coefficients using bilinear transform
    List<double> a = List.filled(order + 1, 0.0);
    List<double> b = List.filled(order + 1, 0.0);

    // Calculate analog coefficients
    for (int i = 0; i <= order; i++) {
      a[i] = pow(-1, i).toDouble() * binomialCoeff(order, i).toDouble() * pow(w0, i).toDouble();
    }

    for (int i = 0; i <= order; i++) {
      b[i] = pow(w0, order - i).toDouble() * binomialCoeff(order, i).toDouble() * cos(pi * (2 * i + order - 1) / (2 * order)).toDouble();
    }

    // Normalize the coefficients
    double a0 = a.reduce((value, element) => value + element);
    for (int i = 0; i <= order; i++) {
      a[i] /= a0;
      b[i] /= a0;
    }

    return [b, a];
  }

  // Calculate binomial coefficient
  int binomialCoeff(int n, int k) {
    if (k > n - k) k = n - k;
    int c = 1;
    for (int i = 0; i < k; i++) {
      c = c * (n - i) ~/ (i + 1);
    }
    return c;
  }

  // Apply the Butterworth filter to the data
  List<double> bandpassFilter(List<double> data, int order, double lowcut, double highcut, double fs) {
    List<List<double>> coefficients = butterBandpass(order, lowcut, highcut, fs);
    List<double> b = coefficients[0];
    List<double> a = coefficients[1];

    List<double> y = List.filled(data.length, 0.0);

    for (int i = order; i < data.length; i++) {
      y[i] = b[0] * data[i];
      for (int j = 1; j <= order; j++) {
        y[i] += b[j] * data[i - j] - a[j] * y[i - j];
      }
    }

    return y;
  }

  // Normalize the data
  List<double> normalize(List<double> data) {
    double maxVal = data.reduce(max);
    double minVal = data.reduce(min);
    List<double> normalizedData = data.map((value) => (value - minVal) / (maxVal - minVal)).toList();
    return normalizedData;
  }
}
