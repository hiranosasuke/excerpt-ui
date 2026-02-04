import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'dart:ui';
import 'theme.dart';
import 'screens/sign_in_page.dart';
import 'screens/home_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/premium_screen.dart';
import 'toast.dart';

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

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Beliefs',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isSignedIn
          ? RootScreen(
              onSignOut: () => setState(() => isSignedIn = false),
              onThemeChanged: _onThemeChanged,
            )
          : SignInPage(onSignIn: () => setState(() => isSignedIn = true)),
    );
  }
}

class RootScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  final VoidCallback onThemeChanged;

  const RootScreen({
    super.key,
    required this.onSignOut,
    required this.onThemeChanged,
  });

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
      SettingsScreen(
        onSignOut: widget.onSignOut,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        onSettingsTapped: () {
          showCupertinoModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            topRadius: const Radius.circular(20),
            expand: true,
            builder: (context) => SettingsScreen(
              scrollController: ModalScrollController.of(context),
              onSignOut: () {
                Navigator.pop(context);
                widget.onSignOut();
              },
              onThemeChanged: widget.onThemeChanged,
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
      padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  width: 1,
                ),
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
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          items[i]['icon'] as IconData,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 28,
              ),
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
        padding: const EdgeInsets.fromLTRB(
            12, 12, 12, 112), // more bottom padding for tab bar
        itemBuilder: (context, i) {
          final p = prompts[i];
          final isCompleted = promptCompletion[i] ?? false;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              title: Text(
                p["text"]!,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(p["book"]!),
              leading: isCompleted
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
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
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback onSignOut;
  final VoidCallback? onThemeChanged;

  const SettingsScreen({
    super.key,
    this.scrollController,
    required this.onSignOut,
    this.onThemeChanged,
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

  void _toggleTheme() {
    setState(() {
      AppTheme.isDarkMode = !AppTheme.isDarkMode;
    });
    widget.onThemeChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
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
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.card_giftcard,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text("Upgrade to Premium"),
                        trailing: Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () {
                          showCupertinoModalBottomSheet(
                            context: context,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            topRadius: const Radius.circular(20),
                            builder: (context) => const PremiumScreen(),
                          );
                        },
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
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
                            onTap: () {
                              showCupertinoModalBottomSheet(
                                context: context,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                topRadius: const Radius.circular(20),
                                builder: (context) =>
                                    const DailyReminderScreen(),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              AppTheme.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                            ),
                            title: const Text("Dark Mode"),
                            trailing: Switch(
                              value: AppTheme.isDarkMode,
                              onChanged: (value) => _toggleTheme(),
                            ),
                            onTap: _toggleTheme,
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
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
            // Animated header - stacked blur layers for gradient effect
            if (_titleOpacity > 0) ...[
              // Layer 1 - strongest blur at very top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.3,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(height: 80, color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Layer 2
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.45,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(height: 80, color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Layer 3
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.6,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(height: 80, color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Layer 4
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.75,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(height: 80, color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Layer 5
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.88,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                      child: Container(height: 80, color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Layer 6 - barely any blur
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.97,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                      child: Container(height: 80, color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Gradient overlay for color blending
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 0.8, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Text layer
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Opacity(
                  opacity: _titleOpacity,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: const Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            // Excerpt text (match Today page)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Book source (match Today page)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.book,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
                  showToast(
                    context,
                    isCompleted
                        ? "Marked as incomplete"
                        : "Great job! Marked as completed!",
                  );
                  Navigator.pop(context);
                },
                icon: Icon(
                    isCompleted ? Icons.close_rounded : Icons.check_rounded),
                label: Text(
                    isCompleted ? "Mark as Incomplete" : "Mark as Completed"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? Colors.grey[700]
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
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
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showToast(context, "Notes saved!");
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

class DailyReminderScreen extends StatefulWidget {
  const DailyReminderScreen({super.key});

  @override
  State<DailyReminderScreen> createState() => _DailyReminderScreenState();
}

class _DailyReminderScreenState extends State<DailyReminderScreen> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isReminderEnabled = true;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  '⏰',
                  style: TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Daily Reminder',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'When would you like to practice?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Reminder toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enable Reminder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: _isReminderEnabled,
                        onChanged: (value) {
                          setState(() => _isReminderEnabled = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Time picker
                AnimatedOpacity(
                  opacity: _isReminderEnabled ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _isReminderEnabled
                        ? () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _reminderTime,
                            );
                            if (time != null) {
                              setState(() => _reminderTime = time);
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _reminderTime.format(context),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Save reminder settings
                      showToast(
                        context,
                        _isReminderEnabled
                            ? 'Reminder set for ${_reminderTime.format(context)}'
                            : 'Reminder disabled',
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
