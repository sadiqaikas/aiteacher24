import 'dart:convert';
import 'package:http/http.dart' as http;

class AiCall {
  static const String _openai_key =
      "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";
  static const String _openai_url =
      "https://api.openai.com/v1/chat/completions";

  Future<MathSolution?> solveMathProblem(String problem) async {
    print("i was called");
    final uri = Uri.parse(_openai_url);
    try {
      final response = await http.post(uri,
          body: jsonEncode(
            {
              "model": "gpt-4o-mini",
              "messages": [
                {
                  "role": "system",
                  "content":
                      "You are a helpful assistant designed to solve math and education problems. When provided with a math question, solve it step by step. Divide your response into JSON objects, where each object represents a page of content that fits a mobile screen. Each page should include a description and calculations in plain text, as well as a separate LaTeX formatted math expression. If the problem involves geometry, provide an SVG representation of the diagram. If the problem involves a graph, provide graph data points or functions. Here's an example format:\n\n{\n  \"pages\": [\n    {\n      \"page\": 1,\n      \"explanation\": \"Step 1: Description and calculations for the first step.\",\n      \"math\": \"LaTeX formatted math expression\",\n      \"geometry\": \"Optional SVG data for geometry problems\",\n      \"graph\": {\"type\": \"line\", \"data\": [{\"x\": 1, \"y\": 2}, {\"x\": 2, \"y\": 3}, ...]}\n    },\n    ...,\n    {\n      \"page\": n,\n      \"explanation\": \"Final Solution: The final answer with explanation.\",\n      \"math\": \"LaTeX formatted final answer\",\n      \"geometry\": \"Optional SVG data for geometry problems\",\n      \"graph\": {\"type\": \"line\", \"data\": [{\"x\": 1, \"y\": 2}, {\"x\": 2, \"y\": 3}, ...]}\n    }\n  ]\n}\n"
                },
                {
                  "role": "user",
                  "content":
                      "Solve the following math and education problem and format the response as described above.\n\nMath Problem: $problem"
                }
              ],
              "response_format": {"type": "json_object"},
              "max_tokens": 1000,
              "temperature": 0.7,
              "top_p": 1.0,
              "n": 1,
              "stream": false,
              "logprobs": null,
              "stop": ["\n\n"]
            },
          ),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_openai_key"
          });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        ChatComplete chatComplete = ChatComplete.fromJson(data);
        String content = chatComplete.choices[0].message.content;
        Map<String, dynamic> mathJson = json.decode(content);
        print("before");
        print(mathJson);
        print("after");
        return MathSolution.fromJson(mathJson);
      } else {
        print("failed");
        return null;
      }
    } catch (e) {
      print("i errored");
      print(e);
      return null;
    }
  }
}

class ChatComplete {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<Choice> choices;
  final Usage usage;

  ChatComplete({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory ChatComplete.fromJson(Map<String, dynamic> json) {
    return ChatComplete(
      id: json['id'],
      object: json['object'],
      created: json['created'],
      model: json['model'],
      choices:
          (json['choices'] as List).map((i) => Choice.fromJson(i)).toList(),
      usage: Usage.fromJson(json['usage']),
    );
  }
}

class Choice {
  final int index;
  final Message message;
  final String finishReason;

  Choice({
    required this.index,
    required this.message,
    required this.finishReason,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      index: json['index'],
      message: Message.fromJson(json['message']),
      finishReason: json['finish_reason'],
    );
  }
}

class Message {
  final String role;
  final String content;

  Message({
    required this.role,
    required this.content,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
    );
  }
}

class Usage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: json['prompt_tokens'],
      completionTokens: json['completion_tokens'],
      totalTokens: json['total_tokens'],
    );
  }
}

class MathSolution {
  List<Page> pages;
  MathSolution({required this.pages});
  factory MathSolution.fromJson(Map<String, dynamic> json) {
    var pageList = json['pages'] as List;
    List<Page> pages = pageList.map((i) => Page.fromJson(i)).toList();
    return MathSolution(
      pages: pages,
    );
  }
}

class Page {
  final int page;
  final String explanation;
  final String math;
  final String? geometry;
  final Graph? graph;

  Page({
    required this.page,
    required this.explanation,
    required this.math,
    this.geometry,
    this.graph,
  });
  factory Page.fromJson(Map<String, dynamic> json) {
    return Page(
      page: json['page'],
      explanation: json['explanation'],
      math: json['math'],
      geometry: json['geometry'] != null ? json['geometry'] : null,
      graph: json['graph'] != null ? Graph.fromJson(json["graph"]) : null,
    );
  }
}

class Graph {
  final List<AxisGraph>? data;
  final String? type;
  Graph({this.data, this.type});

  factory Graph.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Graph();
    var dataList = json['data'] as List?;
    List<AxisGraph>? data =
        dataList?.map((i) => AxisGraph.fromJson(i)).toList();
    return Graph(data: data, type: json['type']);
  }
}

class AxisGraph {
  final double? x;
  final double? y;
  AxisGraph({this.x, this.y});

  factory AxisGraph.fromJson(Map<String, dynamic> json) {
    return AxisGraph(
      x: json['x'] != null ? (json['x'] as num).toDouble() : null,
      y: json['y'] != null ? (json['y'] as num).toDouble() : null,
    );
  }
}
