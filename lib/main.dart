import 'package:flutter/material.dart';
import 'dart:math';
import 'theme.dart';
import 'screens/sign_in_page.dart';

void main() {
  runApp(const DailyBeliefsApp());
}

class DailyBeliefsApp extends StatefulWidget {
  const DailyBeliefsApp({super.key});

  @override
  State<DailyBeliefsApp> createState() => _DailyBeliefsAppState();
}

class _DailyBeliefsAppState extends State<DailyBeliefsApp> {
  bool isSignedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Beliefs',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: isSignedIn
          ? RootScreen(onSignOut: () => setState(() => isSignedIn = false))
          : SignInPage(onSignIn: () => setState(() => isSignedIn = true)),
    );
  }
}

class RootScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const RootScreen({super.key, required this.onSignOut});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const LibraryScreen(),
      const StreakScreen(),
      SettingsScreen(onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
      ),
      extendBody: true,
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.today, 'label': 'Today'},
      {'icon': Icons.menu_book, 'label': 'Library'},
      {'icon': Icons.local_fire_department, 'label': 'Streak'},
      {'icon': Icons.settings, 'label': 'Settings'},
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (i) {
            final isSelected = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF3F51B5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white54,
                      size: 24,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

final prompts = [
  {
    "book": "Think and Grow Rich",
    "text": "Write your main goal and read it aloud twice today."
  },
  {
    "book": "Think and Grow Rich",
    "text": "Visualize your success for 5 minutes."
  },
  {"book": "How to Win Friends", "text": "Give a genuine compliment."},
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

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Library")),
      body: ListView.builder(
        itemCount: prompts.length,
        itemBuilder: (context, i) {
          final p = prompts[i];
          final isCompleted = promptCompletion[i] ?? false;
          return ListTile(
            title: Text(
              p["text"]!,
              style: TextStyle(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : Colors.white,
              ),
            ),
            subtitle: Text(p["book"]!),
            leading: isCompleted
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PromptDetailPage(
                    index: i,
                    book: p["book"]!,
                    text: p["text"]!,
                    onStatusChanged: () => setState(() {}),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Streak")),
      body: Center(
        child: Transform.translate(
          offset: const Offset(0, -60),
          child: const Text(
            "🔥 3 Day Streak\n(placeholder logic)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final VoidCallback onSignOut;

  const SettingsScreen({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PREMIUM Section
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 24, 0, 12),
                child: Text(
                  "PREMIUM",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: const Text("Upgrade to Premium"),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {},
                ),
              ),

              // PERSONALIZE Section
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 24, 0, 12),
                child: Text(
                  "PERSONALIZE",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.book),
                      title: const Text("Favorite Books"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text("Daily Reminder"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text("Theme"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text("Language"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // ABOUT Section
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 24, 0, 12),
                child: Text(
                  "ABOUT",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text("About Us"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text("Help & Support"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // ACCOUNT Section
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 24, 0, 12),
                child: Text(
                  "ACCOUNT",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Sign Out",
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.arrow_forward, color: Colors.red),
                  onTap: onSignOut,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class PromptDetailPage extends StatefulWidget {
  final int index;
  final String book;
  final String text;
  final VoidCallback onStatusChanged;

  const PromptDetailPage({
    super.key,
    required this.index,
    required this.book,
    required this.text,
    required this.onStatusChanged,
  });

  @override
  State<PromptDetailPage> createState() => _PromptDetailPageState();
}

class _PromptDetailPageState extends State<PromptDetailPage> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: promptNotes[widget.index] ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = promptCompletion[widget.index] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prompt Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.book,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    promptCompletion[widget.index] =
                        !(promptCompletion[widget.index] ?? false);
                  });
                  widget.onStatusChanged();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isCompleted
                          ? "Marked as incomplete"
                          : "Great job! Marked as completed!"),
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: Icon(
                    isCompleted ? Icons.close_rounded : Icons.check_rounded),
                label: Text(
                    isCompleted ? "Mark as Incomplete" : "Mark as Completed"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.orange : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "My Notes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _notesController,
                onChanged: (value) {
                  promptNotes[widget.index] = value;
                },
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "Write your notes here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notes saved!")),
                  );
                  Navigator.pop(context);
                },
                child: const Text("Save Notes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
