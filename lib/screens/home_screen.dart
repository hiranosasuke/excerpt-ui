import 'package:flutter/material.dart';
import 'dart:math';
import '../toast.dart';

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

// Persistent active excerpts — 3 slots, survive navigation within session
List<int> activeExcerptIndices = [];
Set<int> retiredExcerptIndices = {};

// Daily check-in state
Map<String, Set<int>> dailyCheckIns = {};
Map<String, Map<int, String>> dailyCheckInNotes = {};

// Persistent check-in history: each entry is { 'date', 'promptIndex', 'notes' }
List<Map<String, dynamic>> checkInHistory = [];

String _getTodayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

void _initializeActiveExcerpts() {
  if (activeExcerptIndices.isNotEmpty) return;
  final pool = List.generate(prompts.length, (i) => i);
  pool.shuffle(Random());
  activeExcerptIndices = pool.take(3).toList();
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
  late Set<int> _completedToday;
  late AnimationController _pulseController;
  AnimationController? _confettiController;
  List<Map<String, dynamic>>? _confettiParticles;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _initializeActiveExcerpts();
    _completedToday = dailyCheckIns[_getTodayKey()] ?? {};
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
      dailyCheckIns[_getTodayKey()] = _completedToday;
    });

    checkInHistory.add({
      'date': _getTodayKey(),
      'promptIndex': activeExcerptIndices[index],
      'notes': _getNotesForSlot(index),
    });

    if (_allCompleted) {
      _triggerConfetti();
    } else if (index < activeExcerptIndices.length - 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
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
      dailyCheckIns[_getTodayKey()] = _completedToday;
    });

    checkInHistory.removeWhere((e) =>
        e['date'] == _getTodayKey() &&
        e['promptIndex'] == activeExcerptIndices[index]);
  }

  void _retireExcerpt(int slotIndex) {
    final retiredIndex = activeExcerptIndices[slotIndex];
    retiredExcerptIndices.add(retiredIndex);

    final currentActive = activeExcerptIndices.toSet();
    final pool = List.generate(prompts.length, (i) => i)
        .where((i) => !currentActive.contains(i) && !retiredExcerptIndices.contains(i))
        .toList();

    if (pool.isEmpty) {
      showToast(context, "All excerpts have been mastered!");
      return;
    }

    final replacement = pool[Random().nextInt(pool.length)];

    checkInHistory.removeWhere((e) =>
        e['date'] == _getTodayKey() && e['promptIndex'] == retiredIndex);

    setState(() {
      activeExcerptIndices[slotIndex] = replacement;
      _completedToday.remove(slotIndex);
      dailyCheckIns[_getTodayKey()] = _completedToday;
      dailyCheckInNotes[_getTodayKey()]?.remove(slotIndex);
    });

    showToast(context, "Excerpt replaced with a new one!");
  }

  Future<void> _confirmRetire(int slotIndex) async {
    final excerpt = prompts[activeExcerptIndices[slotIndex]];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Mark as mastered?"),
        content: Text(
          '"${excerpt['text']}" will be replaced with a new excerpt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.primary,
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      _retireExcerpt(slotIndex);
    }
  }

  String _getNotesForSlot(int slotIndex) {
    return dailyCheckInNotes[_getTodayKey()]?[slotIndex] ?? '';
  }

  void _saveNotesForSlot(int slotIndex, String notes) {
    setState(() {
      dailyCheckInNotes.putIfAbsent(_getTodayKey(), () => {})[slotIndex] = notes;
    });

    final idx = checkInHistory.indexWhere((e) =>
        e['date'] == _getTodayKey() &&
        e['promptIndex'] == activeExcerptIndices[slotIndex]);
    if (idx >= 0) {
      checkInHistory[idx]['notes'] = notes;
    }
  }

  void _openNotesSheet(int slotIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _CheckInNotesSheet(
          initialNotes: _getNotesForSlot(slotIndex),
          onSave: (notes) {
            _saveNotesForSlot(slotIndex, notes);
            Navigator.pop(sheetContext);
            showToast(context, 'Notes saved');
          },
          onDismiss: () => Navigator.pop(sheetContext),
        );
      },
    );
  }

  int get _completedCount => _completedToday.length;
  bool get _allCompleted => _completedCount == activeExcerptIndices.length;

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
                      // Title
                      Text(
                        _allCompleted ? "All checked in! 🎉" : "Daily Check-in",
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
                                ? "You've checked in for all excerpts"
                                : "$_completedCount of ${activeExcerptIndices.length} checked in today",
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
                              "$_completedCount/${activeExcerptIndices.length}",
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
                        children: List.generate(activeExcerptIndices.length, (index) {
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
                    itemCount: activeExcerptIndices.length,
                    itemBuilder: (context, index) {
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
                              child: _buildExcerptCard(context, index),
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

  Widget _buildExcerptCard(BuildContext context, int slotIndex) {
    final excerpt = prompts[activeExcerptIndices[slotIndex]];
    final isCheckedIn = _completedToday.contains(slotIndex);
    final hasNotes = _getNotesForSlot(slotIndex).isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        gradient: isCheckedIn
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              )
            : null,
        color: isCheckedIn
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isCheckedIn
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.2),
          width: isCheckedIn ? 2 : 1,
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
            // Checked-in indicator
            if (isCheckedIn)
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
                  color: isCheckedIn
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
            // 1. Check-in button (primary)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isCheckedIn
                    ? () => _markIncomplete(slotIndex)
                    : () => _markComplete(slotIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckedIn
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: isCheckedIn
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isCheckedIn ? 0 : 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCheckedIn ? Icons.undo : Icons.check_circle_outline,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isCheckedIn ? "Undo check-in" : "Check in for today",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 2. Notes button (outlined, secondary)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => _openNotesSheet(slotIndex),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: hasNotes
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasNotes ? Icons.notes : Icons.note_add_outlined,
                      size: 20,
                      color: hasNotes
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasNotes ? "Edit notes" : "Add notes",
                      style: TextStyle(
                        fontSize: 15,
                        color: hasNotes
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 3. Mark as mastered (text button, tertiary/muted)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: TextButton(
                onPressed: () => _confirmRetire(slotIndex),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_outline, size: 17),
                    SizedBox(width: 6),
                    Text(
                      "Mark as mastered",
                      style: TextStyle(fontSize: 14),
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

class _CheckInNotesSheet extends StatefulWidget {
  final String initialNotes;
  final Function(String) onSave;
  final VoidCallback onDismiss;

  const _CheckInNotesSheet({
    required this.initialNotes,
    required this.onSave,
    required this.onDismiss,
  });

  @override
  State<_CheckInNotesSheet> createState() => _CheckInNotesSheetState();
}

class _CheckInNotesSheetState extends State<_CheckInNotesSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Today's notes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: "How did this go today?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDismiss,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onSave(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
