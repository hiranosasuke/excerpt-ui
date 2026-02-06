import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'dart:ui';
import 'theme.dart';
import 'screens/sign_in_page.dart';
import 'screens/home_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/premium_screen.dart';
import 'toast.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const DailyBeliefsApp());
}

class DailyBeliefsApp extends StatefulWidget {
  const DailyBeliefsApp({super.key});

  @override
  State<DailyBeliefsApp> createState() => _DailyBeliefsAppState();
}

class _DailyBeliefsAppState extends State<DailyBeliefsApp> {
  bool _isLoading = true;
  bool _isSignedIn = false;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    // Listen for auth state changes
    AuthService.authStateChanges.listen((state) async {
      final isSignedIn = state.session != null;
      if (isSignedIn && !_isSignedIn) {
        // User just signed in, check if they need onboarding
        await _checkIfNeedsOnboarding();
      }
      setState(() {
        _isSignedIn = isSignedIn;
      });
    });
  }

  Future<void> _checkAuthState() async {
    final isSignedIn = AuthService.currentUser != null;
    if (isSignedIn) {
      await _checkIfNeedsOnboarding();
    }
    setState(() {
      _isSignedIn = isSignedIn;
      _isLoading = false;
    });
  }

  Future<void> _checkIfNeedsOnboarding() async {
    final userId = AuthService.userId;
    if (userId == null) return;

    try {
      // Create user if needed
      await ApiService.createUser(userId);
      // Check if user has active excerpts - if not, they need onboarding
      final activeExcerpts = await ApiService.getActiveExcerpts(userId);
      _needsOnboarding = activeExcerpts.isEmpty;
    } catch (e) {
      // If we can't check, assume they need onboarding
      _needsOnboarding = true;
    }
  }

  void _completeOnboarding() {
    setState(() {
      _needsOnboarding = false;
    });
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _handleSignOut() async {
    await AuthService.signOut();
    setState(() => _isSignedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppTheme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Daily Beliefs',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _isSignedIn
          ? (_needsOnboarding
              ? OnboardingFlow(onComplete: _completeOnboarding)
              : RootScreen(
                  onSignOut: _handleSignOut,
                  onThemeChanged: _onThemeChanged,
                ))
          : SignInPage(onSignIn: () => setState(() => _isSignedIn = true)),
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
      {'icon': Icons.history, 'label': 'History'},
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
  String _formatDateKey(String key) {
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (key == todayKey) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (key == yesterdayKey) return 'Yesterday';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $day, $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: _buildHistoryList(context),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    // Group entries by date using CheckIn objects from home_screen
    final grouped = <String, List<dynamic>>{};
    for (final entry in checkInHistory) {
      grouped.putIfAbsent(entry.checkInDate, () => []).add(entry);
    }
    // Sort dates newest first
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                "No check-ins yet",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Your check-in history will appear here",
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Flatten into date headers + entry cards
    final items = <Widget>[];
    for (final date in sortedDates) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
          child: Text(
            _formatDateKey(date),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      for (final entry in grouped[date]!) {
        final excerpt = entry.excerpt;
        final notes = entry.notes ?? '';
        items.add(
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              leading: Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(excerpt?.text ?? 'Unknown excerpt'),
              subtitle: notes.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(excerpt?.bookTitle ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          notes,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.55),
                          ),
                        ),
                      ],
                    )
                  : Text(excerpt?.bookTitle ?? ''),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 112),
      children: items,
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
                          Icons.subscriptions,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text("Manage Subscriptions"),
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
                            leading: const Icon(Icons.tag_outlined),
                            title: const Text("Interests"),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              showCupertinoModalBottomSheet(
                                context: context,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                topRadius: const Radius.circular(20),
                                builder: (context) => const InterestsScreen(),
                              );
                            },
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

class DailyReminderScreen extends StatefulWidget {
  const DailyReminderScreen({super.key});

  @override
  State<DailyReminderScreen> createState() => _DailyReminderScreenState();
}

class _DailyReminderScreenState extends State<DailyReminderScreen> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isReminderEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedReminder();
  }

  Future<void> _loadSavedReminder() async {
    final userId = AuthService.userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final settings = await ApiService.getSettings(userId);
      final hour = settings['reminder_hour'];
      final minute = settings['reminder_minute'];

      if (mounted) {
        setState(() {
          if (hour != null && minute != null) {
            _reminderTime = TimeOfDay(hour: hour, minute: minute);
            _isReminderEnabled = true;
          } else {
            _isReminderEnabled = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
                    onPressed: () async {
                      final userId = AuthService.userId;
                      if (userId != null) {
                        try {
                          if (_isReminderEnabled) {
                            await ApiService.setReminder(
                                userId, _reminderTime.hour, _reminderTime.minute);
                          } else {
                            await ApiService.clearReminder(userId);
                          }
                        } catch (e) {
                          // Silently fail - local settings still work
                        }
                      }
                      if (!context.mounted) return;
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

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  static final _options = <Map<String, String>>[
    {'icon': '🧠', 'label': 'Mindset'},
    {'icon': '🎨', 'label': 'Visualization'},
    {'icon': '🤝', 'label': 'Connection'},
    {'icon': '🔄', 'label': 'Habits'},
    {'icon': '📋', 'label': 'Planning'},
    {'icon': '🪞', 'label': 'Reflection'},
    {'icon': '💭', 'label': 'Mindfulness'},
    {'icon': '🎯', 'label': 'Focus'},
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  '✨',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pick your interests',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the categories you enjoy',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _options.map((option) {
                    final isSelected =
                        selectedInterests.contains(option['label']);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedInterests.remove(option['label']);
                          } else {
                            selectedInterests.add(option['label']!);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(option['icon']!,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              option['label']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId = AuthService.userId;
                      if (userId != null) {
                        try {
                          await ApiService.setInterests(
                              userId, selectedInterests.toList());
                        } catch (e) {
                          // Silently fail - local settings still work
                        }
                      }
                      if (!context.mounted) return;
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
                      'Done',
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
