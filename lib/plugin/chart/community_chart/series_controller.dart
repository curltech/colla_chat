import 'package:community_charts_flutter/community_charts_flutter.dart';

/// Series用于构造数据，内含一个范型化的数组数据，可以指定边框，填充颜色，填充样式
/// 一般Chart的输入数据是一个Series的数组
/// Chart的类型包括BarChart，TimeSeriesChart，LineChart，ScatterPlotChart，OrdinalComboChart，NumericComboChart
/// PieChart
/// BarChart的类型用参数barGroupingType来指示BarChart的类型: 包括stacked，grouped，groupedStacked
/// animate: 动画,vertical: 轴,
///
class SeriesController<T> {
  final List<Series<T, String>> data;
  final bool animate;

  SeriesController(this.data, this.animate);
}
