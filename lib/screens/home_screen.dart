import 'package:flutter/material.dart';
import 'dart:math';

final prompts = [
  {
    "book": "Think and Grow Rich",
    "text": "Write your main goal and read it aloud twice today."
  },
  {
    "book": "Think and Grow Rich",
    "text": "Visualize your success for 5 minutes."
  },
  {
    "book": "How to Win Friends and Influence People",
    "text": "Give a genuine compliment."
  },
  {"book": "How to Win Friends", "text": "Listen more than you speak."},
  {"book": "Atomic Habits", "text": "Improve one tiny habit by 1% today."},
];

// Track completion status for each prompt
final Map<int, bool> promptCompletion = {};
final Map<int, String> promptNotes = {};

Map<String, String> getTodaysPrompt() {
  final now = DateTime.now();
  final seed = now.year + now.month + now.day;
  final rand = Random(seed);
  return prompts[rand.nextInt(prompts.length)];
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prompt = getTodaysPrompt();

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Practice")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(prompt["text"]!,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Text(prompt["book"]!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Marked as practiced!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Mark as Practiced"),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
