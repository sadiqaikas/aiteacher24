import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smathmathai/service/ai.dart';

class BuildPage extends StatelessWidget {
  final MathSolution chatComplete;
  final int index;
  const BuildPage({super.key, required this.chatComplete, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${chatComplete.pages[index].page}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chatComplete.pages[index].explanation,
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      if (chatComplete.pages[index].math != 'N/A') ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Math.tex(
                            chatComplete.pages[index].math,
                            textStyle: const TextStyle(
                              fontSize: 24, // Larger font size
                            ),
                            onErrorFallback: (error) {
                              print(
                                  'LaTeX Error: ${error.toString()}'); // Log the error for debugging
                              return Text(
                                'LaTeX Error: ${error.toString()}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.red,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (chatComplete.pages[index].geometry != null &&
                          chatComplete.pages[index].geometry!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SvgPicture.string(
                          chatComplete.pages[index].geometry!,
                          width: 300,
                          height: 300,
                        ),
                      ],
                      if (chatComplete.pages[index].graph != null &&
                          chatComplete.pages[index].graph?.data != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: chatComplete.pages[index].graph!.data!
                                      .map<FlSpot>((point) => FlSpot(
                                          point.x!.toDouble(),
                                          point.y!.toDouble()))
                                      .toList(),
                                  isCurved: true,

                                  // colors: [Colors.blue],
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                ),
                              ],
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              gridData: const FlGridData(show: true),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
