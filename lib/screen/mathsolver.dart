import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_math_fork/flutter_math.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:smathmathai/service/ai.dart';
import 'package:smathmathai/service/tts_service.dart';
import 'package:smathmathai/widget/build_page.dart';

const List<Map<String, String>> symbols = [
  {"text": "+", "symbol": "+"},
  {"text": "-", "symbol": "-"},
  {"text": "*", "symbol": "*"},
  {"text": "/", "symbol": "/"},
  {"text": "=", "symbol": "="},
  {"text": "^", "symbol": "^"},
  {"text": "√", "symbol": "sqrt("},
  {"text": "∫", "symbol": "∫"},
  {"text": "∂", "symbol": "∂"},
  {"text": "[", "symbol": "["},
  {"text": "]", "symbol": "]"},
  {"text": "(", "symbol": "("},
  {"text": ")", "symbol": ")"},
  {"text": "sin", "symbol": "sin("},
  {"text": "cos", "symbol": "cos("},
  {"text": "tan", "symbol": "tan("},
  {"text": "log", "symbol": "log("},
  {"text": "ln", "symbol": "ln("},
  {"text": "exp", "symbol": "exp("},
  {"text": "matrix", "symbol": "matrix("}
];

class MathSolverScreen extends StatefulWidget {
  static const routeName = '/';
  const MathSolverScreen({super.key});

  @override
  _MathSolverScreenState createState() => _MathSolverScreenState();
}

class _MathSolverScreenState extends State<MathSolverScreen> {
  final TextEditingController _controller = TextEditingController();
  final AiCall _aiCall = AiCall();
  MathSolution? _chatComplete;
  final TtsService _flutterTts = TtsService();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  int _currentPageIndex = -1;
  final PageController _pageController = PageController();
  bool _showMathKeyboard = false;

  @override
  void initState() {
    super.initState();
    _flutterTts.setCompletionHandler(_onTTSComplete);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showMathKeyboard = true;
        });
      }
    });
  }

  Future<void> _solveMathProblem(String problem) async {
    print("api call worked");
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _aiCall.solveMathProblem(problem);

      if (response != null) {
        print("api call worked");

        setState(() {
          _chatComplete = response;

          _isLoading = false;
        });
        _onTTSComplete();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTTSComplete() {
    if (_currentPageIndex < _chatComplete!.pages.length - 1) {
      setState(() {
        _currentPageIndex++;
      });
      final page = _chatComplete!.pages[_currentPageIndex];
      _pageController.animateToPage(
        _currentPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      _speakPageContent(page.explanation);
    }
  }

  Future<void> _speakPageContent(String explanation) async {
    await _flutterTts.speak(explanation);
  }

  void _insertText(String text) {
    final textSelection = _controller.selection;
    final newText = _controller.text
        .replaceRange(textSelection.start, textSelection.end, text);
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
                ? const CircularProgressIndicator()
                : _chatComplete != null && _chatComplete!.pages.isNotEmpty
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
                                  _speakPageContent(_chatComplete!
                                      .pages[_currentPageIndex]
                                      .explanation); // Speak the content of the new page
                                },
                                itemCount: _chatComplete!.pages.length,
                                itemBuilder: (context, index) {
                                  return BuildPage(
                                      chatComplete: _chatComplete!,
                                      index: index);
                                },
                              ),
                            ),
                            LinearProgressIndicator(
                              value: _chatComplete!.pages.isEmpty
                                  ? 0
                                  : (_currentPageIndex + 1) /
                                      _chatComplete!.pages.length,
                              minHeight: 5,
                              backgroundColor: Colors.grey[300],
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      )
                    : Container(),
            const SizedBox(height: 10),
            Row(
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    labelText: 'Math Problem or any question',
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _chatComplete = null;
                      _currentPageIndex = -1;
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_showMathKeyboard)
              Wrap(
                  spacing: 10,
                  children: symbols
                      .map((item) => ElevatedButton(
                          onPressed: () =>
                              _insertText(item["symbol"] as String),
                          child: Text(item["text"] as String)))
                      .toList()),
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _showMathKeyboard = false;
                  _focusNode.unfocus();
                });
                if (_controller.text.isNotEmpty) {
                  await _solveMathProblem(_controller.text);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Solve'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
