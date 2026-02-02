import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
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
        onSettingsTapped: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              snap: true,
              builder: (context, scrollController) => ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A2E),
                  ),
                  child: SettingsScreen(
                    scrollController: scrollController,
                    onSignOut: () {
                      Navigator.pop(context); // Close modal
                      widget.onSignOut(); // Then sign out
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
      extendBody: true,
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onSettingsTapped;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onSettingsTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.today, 'label': 'Today'},
      {'icon': Icons.menu_book, 'label': 'Library'},
      {'icon': Icons.local_fire_department, 'label': 'Streak'},
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3F51B5)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          items[i]['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.white54,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSettingsTapped,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white54,
                size: 28,
              ),
            ),
          ),
        ],
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

class SettingsScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback onSignOut;

  const SettingsScreen({
    super.key,
    this.scrollController,
    required this.onSignOut,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ScrollController _scrollController;
  double _titleOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    // Start showing title when scrolled past 40px, fully visible at 80px
    const double startOffset = 40.0;
    const double endOffset = 80.0;

    double newOpacity = 0.0;
    if (_scrollController.offset > startOffset) {
      newOpacity =
          ((_scrollController.offset - startOffset) / (endOffset - startOffset))
              .clamp(0.0, 1.0);
    }

    if (newOpacity != _titleOpacity) {
      setState(() {
        _titleOpacity = newOpacity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                      trailing:
                          const Icon(Icons.arrow_forward, color: Colors.red),
                      onTap: widget.onSignOut,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Animated header that appears on scroll
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10 * _titleOpacity,
                  sigmaY: 10 * _titleOpacity,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.02 * _titleOpacity),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: _titleOpacity),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
