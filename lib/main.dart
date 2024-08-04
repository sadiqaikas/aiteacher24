import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Tutor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MathSolverScreen(),
    );
  }
}

class MathSolverScreen extends StatefulWidget {
  @override
  _MathSolverScreenState createState() => _MathSolverScreenState();
}

class _MathSolverScreenState extends State<MathSolverScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _pages = [];
  bool _isLoading = false;
  int _currentPageIndex = 0;
  FlutterTts _flutterTts = FlutterTts();
  final PageController _pageController = PageController();
  bool _showMathKeyboard = false;

  final String apiKey = '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'; // Replace with your actual API key

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showMathKeyboard = true;
        });
      }
    });
  }

  void _initializeTts() {
    _flutterTts.setStartHandler(() {
      print("TTS started");
    });

    _flutterTts.setCompletionHandler(() {
      print("Completed speaking text on page $_currentPageIndex");
      if (_currentPageIndex < _pages.length - 1) {
        setState(() {
          _currentPageIndex++;
        });
        _pageController.animateToPage(
          _currentPageIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
        _speakPageContent(_currentPageIndex);
      }
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
    });

    _flutterTts.awaitSpeakCompletion(true); // Ensures the completion handler works
  }

  Future<void> _solveMathProblem(String problem) async {
    setState(() {
      _isLoading = true;
      _pages = [];
      _currentPageIndex = 0;
    });

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "You are a helpful assistant designed to solve math and education problems. When provided with a math question, solve it step by step. Divide your response into JSON objects, where each object represents a page of content that fits a mobile screen. Each page should include a description and calculations in plain text, as well as a separate LaTeX formatted math expression. If the problem involves geometry, provide an SVG representation of the diagram. If the problem involves a graph, provide graph data points or functions. Here's an example format:\n\n{\n  \"pages\": [\n    {\n      \"page\": 1,\n      \"explanation\": \"Step 1: Description and calculations for the first step.\",\n      \"math\": \"LaTeX formatted math expression\",\n      \"geometry\": \"Optional SVG data for geometry problems\",\n      \"graph\": {\"type\": \"line\", \"data\": [{\"x\": 1, \"y\": 2}, {\"x\": 2, \"y\": 3}, ...]}\n    },\n    ...,\n    {\n      \"page\": n,\n      \"explanation\": \"Final Solution: The final answer with explanation.\",\n      \"math\": \"LaTeX formatted final answer\",\n      \"geometry\": \"Optional SVG data for geometry problems\",\n      \"graph\": {\"type\": \"line\", \"data\": [{\"x\": 1, \"y\": 2}, {\"x\": 2, \"y\": 3}, ...]}\n    }\n  ]\n}\n"
        },
        {
          "role": "user",
          "content": "Solve the following math and education problem and format the response as described above.\n\nMath Problem: $problem"
        }
      ],
       "response_format": {"type":"json_object"},
      "max_tokens": 1000,
      "temperature": 0.7,
      "top_p": 1.0,
      "n": 1,
      "stream": false,
      "logprobs": null,
      "stop": ["\n\n"]
    });

    try {
      print('Sending request to GPT API...');
      final response = await http.post(url, headers: headers, body: body);
      print('Received response with status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        final content = responseBody['choices'][0]['message']['content'].trim();
        print('Parsed content: $content');

        // Parse the JSON content from the GPT response
        final jsonResponse = jsonDecode(content);
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('pages')) {
          setState(() {
            _pages = List<Map<String, dynamic>>.from(jsonResponse['pages']);
            _isLoading = false;
          });
          _speakPageContent(0); // Start reading the first page
        } else {
          print('JSON response does not contain expected format.');
        }
      } else {
        print('Failed to load response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _speakPageContent(int index) async {
    if (index < _pages.length) {
      print('Speaking content of page $index: ${_pages[index]['explanation']}');
      await _flutterTts.stop(); // Ensure any previous speech is stopped
      await Future.delayed(Duration(milliseconds: 500)); // Allow some time for TTS to reset
      await _flutterTts.speak(_pages[index]['explanation']).then((result) {
        if (result == 1) {
          print('TTS playback started');
        } else {
          print('TTS playback failed to start');
        }
      });
    }
  }

  void _insertText(String text) {
    final textSelection = _controller.selection;
    final newText = _controller.text.replaceRange(textSelection.start, textSelection.end, text);
    final newSelection = textSelection.copyWith(
      baseOffset: textSelection.start + text.length,
      extentOffset: textSelection.start + text.length,
    );
    _controller.value = TextEditingValue(
      text: newText,
      selection: newSelection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _isLoading
                ? CircularProgressIndicator()
                : _pages.isNotEmpty
                    ? Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPageIndex = index;
                                  });
                                  _speakPageContent(index); // Speak the content of the new page
                                },
                                itemCount: _pages.length,
                                itemBuilder: (context, index) {
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
                                              'Step ${_pages[index]['page']}',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _pages[index]['explanation'],
                                                      style: TextStyle(fontSize: 18),
                                                    ),
                                                    SizedBox(height: 10),
                                                    if (_pages[index]['math'] != 'N/A') ...[
                                                      SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Math.tex(
                                                          _pages[index]['math'],
                                                          textStyle: TextStyle(
                                                            fontSize: 24, // Larger font size
                                                          ),
                                                          onErrorFallback: (error) {
                                                            print('LaTeX Error: ${error.toString()}'); // Log the error for debugging
                                                            return Text(
                                                              'LaTeX Error: ${error.toString()}',
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                color: Colors.red,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                    if (_pages[index]['geometry'] != null && _pages[index]['geometry'].isNotEmpty) ...[
                                                      SizedBox(height: 10),
                                                      SvgPicture.string(
                                                        _pages[index]['geometry'],
                                                        width: 300,
                                                        height: 300,
                                                      ),
                                                    ],
                                                    if (_pages[index]['graph'] != null && _pages[index]['graph']['data'] != null) ...[
                                                      SizedBox(height: 10),
                                                      Container(
                                                        height: 300,
                                                        child: LineChart(
                                                          LineChartData(
                                                            lineBarsData: [
                                                              LineChartBarData(
                                                                spots: _pages[index]['graph']['data']
                                                                    .map<FlSpot>((point) => FlSpot(point['x'].toDouble(), point['y'].toDouble()))
                                                                    .toList(),
                                                                isCurved: true,
                                                                
                                                                // colors: [Colors.blue],
                                                                barWidth: 4,
                                                                isStrokeCapRound: true,
                                                                dotData: FlDotData(show: false),
                                                              ),
                                                            ],
                                                            titlesData: FlTitlesData(
                                                              leftTitles: AxisTitles(
                                                                sideTitles: SideTitles(showTitles: true),
                                                              ),
                                                              bottomTitles: AxisTitles(
                                                                sideTitles: SideTitles(showTitles: true),
                                                              ),
                                                            ),
                                                            borderData: FlBorderData(show: true),
                                                            gridData: FlGridData(show: true),
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
                                },
                              ),
                            ),
                            LinearProgressIndicator(
                              value: _pages.isEmpty ? 0 : (_currentPageIndex + 1) / _pages.length,
                              minHeight: 5,
                              backgroundColor: Colors.grey[300],
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      )
                    : Container(),
            SizedBox(height: 10),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Math Problem or any question',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            if (_showMathKeyboard)
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () => _insertText('+'),
                    child: Text('+'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('-'),
                    child: Text('-'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('*'),
                    child: Text('*'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('/'),
                    child: Text('/'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('='),
                    child: Text('='),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('^'),
                    child: Text('^'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('sqrt('),
                    child: Text('√'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('∫'),
                    child: Text('∫'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('∂'),
                    child: Text('∂'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('['),
                    child: Text('['),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText(']'),
                    child: Text(']'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('('),
                    child: Text('('),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText(')'),
                    child: Text(')'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('sin('),
                    child: Text('sin'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('cos('),
                    child: Text('cos'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('tan('),
                    child: Text('tan'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('log('),
                    child: Text('log'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('ln('),
                    child: Text('ln'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('exp('),
                    child: Text('exp'),
                  ),
                  ElevatedButton(
                    onPressed: () => _insertText('matrix('),
                    child: Text('matrix'),
                  ),
                ],
              ),
            SizedBox(height: 10),
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       _showMathKeyboard = !_showMathKeyboard;
            //     });
            //     if (!_showMathKeyboard) {
            //       _focusNode.unfocus();
            //     }
            //   },
            //   child: Text(_showMathKeyboard ? 'Hide Math Keyboard' : 'Show Math Keyboard'),
            // ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showMathKeyboard = false;
                  _focusNode.unfocus();
                });
                if (_controller.text.isNotEmpty) {
                  _solveMathProblem(_controller.text);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Solve'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
