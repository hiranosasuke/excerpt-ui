import 'package:flutter/material.dart';
import 'dart:math';

final prompts = [
  {
    "book": "Think and Grow Rich",
    "text": "Write your main goal and read it aloud twice today.",
    "category": "Mindset",
  },
  {
    "book": "Think and Grow Rich",
    "text": "Visualize your success for 5 minutes.",
    "category": "Visualization",
  },
  {
    "book": "How to Win Friends and Influence People",
    "text": "Give a genuine compliment to someone today.",
    "category": "Connection",
  },
  {
    "book": "How to Win Friends",
    "text": "Listen more than you speak in your next conversation.",
    "category": "Connection",
  },
  {
    "book": "Atomic Habits",
    "text": "Improve one tiny habit by 1% today.",
    "category": "Habits",
  },
  {
    "book": "The 7 Habits of Highly Effective People",
    "text": "Begin with the end in mind. Write down your ideal outcome.",
    "category": "Planning",
  },
  {
    "book": "Man's Search for Meaning",
    "text": "Find meaning in one challenge you're facing today.",
    "category": "Reflection",
  },
  {
    "book": "The Power of Now",
    "text": "Spend 3 minutes fully present, observing your breath.",
    "category": "Mindfulness",
  },
  {
    "book": "Deep Work",
    "text": "Block 30 minutes for focused, distraction-free work.",
    "category": "Focus",
  },
];

// Track completion status for each prompt
final Map<int, bool> promptCompletion = {};
final Map<int, String> promptNotes = {};

// Track daily journey completion (keyed by date string)
Map<String, Set<int>> dailyJourneyCompletion = {};

String _getTodayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

List<Map<String, String>> getTodaysJourney() {
  final now = DateTime.now();
  final seed = now.year * 1000 + now.month * 100 + now.day;
  final rand = Random(seed);

  // Shuffle and pick 3 distinct excerpts for today's journey
  final shuffled = List<Map<String, String>>.from(
    prompts.map((p) => Map<String, String>.from(p)),
  );
  shuffled.shuffle(rand);
  return shuffled.take(3).toList();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late List<Map<String, String>> _todaysJourney;
  late Set<int> _completedToday;
  late AnimationController _pulseController;
  AnimationController? _confettiController;
  List<Map<String, dynamic>>? _confettiParticles;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _todaysJourney = getTodaysJourney();
    _completedToday = dailyJourneyCompletion[_getTodayKey()] ?? {};
    _pageController = PageController(viewportFraction: 0.85);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _confettiController?.dispose();
    super.dispose();
  }

  void _markComplete(int index) {
    setState(() {
      _completedToday.add(index);
      dailyJourneyCompletion[_getTodayKey()] = _completedToday;
    });

    if (_allCompleted) {
      _triggerConfetti();
    } else if (index < _todaysJourney.length - 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  void _triggerConfetti() {
    _confettiController?.dispose();
    _confettiParticles = _generateConfettiParticles();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    setState(() => _showConfetti = true);
    _confettiController!.forward().whenComplete(() {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  List<Map<String, dynamic>> _generateConfettiParticles() {
    final rand = Random();
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFFDD835),
      const Color(0xFF8E24AA),
      const Color(0xFFFB8C00),
      const Color(0xFFD81B60),
      const Color(0xFF00ACC1),
    ];
    return List.generate(70, (_) => {
      'x': rand.nextDouble(),
      'delay': rand.nextDouble() * 0.4,
      'color': colors[rand.nextInt(colors.length)],
      'size': 6.0 + rand.nextDouble() * 10.0,
      'rotation': rand.nextDouble() * pi * 2,
      'driftX': (rand.nextDouble() - 0.5) * 0.3,
      'isCircle': rand.nextBool(),
    });
  }

  void _markIncomplete(int index) {
    setState(() {
      _completedToday.remove(index);
      dailyJourneyCompletion[_getTodayKey()] = _completedToday;
    });
  }

  int get _completedCount => _completedToday.length;
  bool get _allCompleted => _completedCount == _todaysJourney.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            const SizedBox(height: 20),
            // Header with progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Text(
                    _allCompleted ? "Journey Complete! 🎉" : "Today's Journey",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle with progress badge
                  Row(
                    children: [
                      Text(
                        _allCompleted
                            ? "You've completed all practices"
                            : "$_completedCount of ${_todaysJourney.length} practices complete",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      // Progress badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "$_completedCount/${_todaysJourney.length}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Step indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_todaysJourney.length, (index) {
                      final isCompleted = _completedToday.contains(index);
                      final isCurrent = index == _currentIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isCurrent ? 44 : 36,
                                height: isCurrent ? 44 : 36,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Theme.of(context).colorScheme.primary
                                      : isCurrent
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2)
                                          : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  border: isCurrent && !isCompleted
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 20)
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isCurrent
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.5),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isCurrent ? 24 : 0,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Card carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _todaysJourney.length,
                itemBuilder: (context, index) {
                  final excerpt = _todaysJourney[index];
                  final isCompleted = _completedToday.contains(index);

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                      }
                      return Center(
                        child: Transform.scale(
                          scale: value,
                          child: _buildExcerptCard(
                              context, excerpt, index, isCompleted),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 100), // Space for nav bar
          ],
        ),
          ),
          if (_showConfetti)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController!,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      _confettiParticles!,
                      _confettiController!.value,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExcerptCard(BuildContext context, Map<String, String> excerpt,
      int index, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              )
            : null,
        color: isCompleted
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isCompleted
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.2),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                excerpt["category"] ?? "Practice",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Completion indicator (small inline)
            if (isCompleted)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 36,
                ),
              ),
            // Excerpt text
            Flexible(
              child: Text(
                excerpt["text"] ?? "",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 12),
            // Book source
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
                    excerpt["book"] ?? "",
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
            const SizedBox(height: 12),
            // Action button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isCompleted
                    ? () => _markIncomplete(index)
                    : () => _markComplete(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: isCompleted
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isCompleted ? 0 : 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCompleted ? Icons.undo : Icons.play_circle_filled,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isCompleted ? "Undo" : "Mark as Done",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<Map<String, dynamic>> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final delay = p['delay'] as double;
      if (progress < delay) continue;

      final localProgress =
          ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);

      // Gravity-like easing: slow at top, accelerates downward
      final easedY = Curves.easeIn.transform(localProgress);

      // Gentle horizontal sine drift
      final driftX =
          (p['driftX'] as double) * sin(localProgress * pi * 2) * size.width;

      final x = size.width * (p['x'] as double) + driftX;
      final y = -30.0 + (size.height + 60.0) * easedY;

      // Fade out over the last 20% of this particle's life
      final opacity = localProgress > 0.8
          ? 1.0 - ((localProgress - 0.8) / 0.2).clamp(0.0, 1.0)
          : 1.0;

      final paint = Paint()
        ..color = (p['color'] as Color).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final particleSize = p['size'] as double;
      final rotation =
          (p['rotation'] as double) + localProgress * pi * 8;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (p['isCircle'] as bool) {
        canvas.drawCircle(Offset.zero, particleSize / 2.5, paint);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(
              -particleSize / 2, -particleSize * 0.3, particleSize,
              particleSize * 0.6),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
