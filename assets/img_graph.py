import numpy as np
from PIL import Image
import csv


class Axes:
    def __init__(self, px, py, dimensions, dp, labels):
        self._px = px
        self._py = py
        self._dimensions = dimensions
        self._dp = dp
        self.labels = labels

    def pixel_to_data(self, pxi, pyi, a_mat, c_vec, is_log_scale_x=False, is_log_scale_x_negative=False,
                      is_log_scale_y=False, is_log_scale_y_negative=False):
        xp = float(pxi)
        yp = float(pyi)

        # Apply the affine transformation
        dat_vec = np.dot(a_mat, [xp, yp])
        dat_vec[0] += c_vec[0]
        dat_vec[1] += c_vec[1]

        xf = dat_vec[0]
        yf = dat_vec[1]

        # If x-axis is log scale
        if is_log_scale_x:
            xf = -10 ** xf if is_log_scale_x_negative else 10 ** xf

        # If y-axis is log scale
        if is_log_scale_y:
            yf = -10 ** yf if is_log_scale_y_negative else 10 ** yf

        return [xf, -yf]

    def get_axes_labels(self):
        return self.labels


class DataSeries:
    def __init__(self, data_points):
        self._dataPoints = data_points

    def get_pixel(self, index):
        return self._dataPoints[index]

    def get_count(self):
        return len(self._dataPoints)


class AutoDetectionData:
    def __init__(self, fg_color=(128, 128, 0), bg_color=(255, 255, 255)):
        self.fg_color = fg_color
        self.bg_color = bg_color
        self.binary_data = set()
        self.image_width = 0
        self.image_height = 0
        self.color_distance = 0

    def generate_binary_data(self, image_path):
        image = Image.open(image_path).convert('RGBA')
        self.image_width, self.image_height = image.size
        data = np.array(image)
        for idx, pixel in enumerate(data.reshape(-1, 4)):
            r, g, b, a = pixel
            if a == 0:
                r, g, b = 255, 255, 255
            dist = np.linalg.norm(np.array([r, g, b]) - np.array(self.fg_color))
            if dist <= self.color_distance:
                self.binary_data.add(idx)
        return self.binary_data

    def get_general_axes_data(self, data_series, axes, a_mat, c_vec, is_log_scale_x=False,
                              is_log_scale_x_negative=False,
                              is_log_scale_y=False, is_log_scale_y_negative=False):
        raw_data = []

        # Process each data point
        for rowi in range(len(data_series)):
            pt = data_series[rowi]
            pt_data = axes.pixel_to_data(pt[0], pt[1], a_mat, c_vec, is_log_scale_x, is_log_scale_x_negative,
                                         is_log_scale_y, is_log_scale_y_negative)
            raw_data.append(pt_data)

        return raw_data

    @staticmethod
    def load_csv_data(file_path):
        data_points = []
        with open(file_path, newline='') as csvfile:
            reader = csv.reader(csvfile)
            for row in reader:
                x, y = map(float, row)
                data_points.append([x, y])
        return data_points

    @staticmethod
    def save_csv_data(file_path, data):
        with open(file_path, mode='w', newline='') as file:
            writer = csv.writer(file)
            for row in data:
                writer.writerow(row)


class AveragingWindowCore:
    def __init__(self, binary_data, image_width, image_height, x_step, y_step):
        self.binary_data = binary_data
        self.image_width = image_width
        self.image_height = image_height
        self.x_step = x_step
        self.y_step = y_step
        self.data_series = []

    def run(self):
        for col in range(self.image_width):
            blobs = []
            for row in range(self.image_height):
                if row * self.image_width + col in self.binary_data:
                    if not blobs or row > blobs[-1] + self.y_step:
                        blobs.append(row)
                    else:
                        blobs[-1] = (blobs[-1] + row) // 2
            for y in blobs:
                self.data_series.append((col + 0.5, self.image_height - (y + 0.5)))
        return self.data_series


def main():
    auto_data = AutoDetectionData()
    binary_data = auto_data.generate_binary_data("page_0.png")
    axes = Axes(
        px=[388.572, 3179.19, 388.572, 388.572],
        py=[1655.37, 1655.37, 1655.37, 235.19],
        dimensions=2,
        dp=["0", "-30", "250", "-30", "0", "-30", "250", "30"],
        labels=["X1", "X2", "Y1", "Y2"]
    )

    x1 = 388.57202291110343
    y1 = 1655.3711507293356
    x2 = 3179.1896272285253
    y2 = 1655.3711507293356
    x3 = 388.57202291110343
    y3 = 1655.3711507293356
    x4 = 388.57202291110343
    y4 = 235.1883296567205

    xmin = 0
    xmax = 250
    ymin = -30
    ymax = 30

    # Define the matrices and vectors
    dat_mat = np.array([[xmin - xmax, 0], [0, ymin - ymax]])
    pix_mat = np.array([[x1 - x2, x3 - x4], [y1 - y2, y3 - y4]])

    # Matrix multiplication and inversion
    a_mat = np.dot(dat_mat, np.linalg.inv(pix_mat))

    # Calculation of c_vec
    c_vec = np.zeros(2)
    c_vec[0] = xmin - a_mat[0, 0] * x1 - a_mat[0, 1] * y1
    c_vec[1] = ymin - a_mat[1, 0] * x3 - a_mat[1, 1] * y3

    averaging_algo = AveragingWindowCore(binary_data, auto_data.image_width, auto_data.image_height, 1, 1)
    data_series = averaging_algo.run()
    print(data_series)
    x, y = zip(*data_series)

    data_series_list = []
    for i in range(len(x)):
        data_series_list.append([x[i], y[i]])

    print(data_series_list)
    transformed_data = auto_data.get_general_axes_data(data_series_list, axes, a_mat, c_vec)

    # Output the transformed data to a new CSV file
    output_file_path = "transformed_data.csv"
    auto_data.save_csv_data(output_file_path, transformed_data)

    print(f"Transformed data saved to {output_file_path}")


if __name__ == "__main__":
    main()
