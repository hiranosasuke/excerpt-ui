import 'package:flutter/material.dart';
import 'dart:math';
import '../toast.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/excerpt.dart';
import '../models/check_in.dart';

// User-selected interest categories (set during onboarding, editable in Settings)
Set<String> selectedInterests = {};

// Local cache of check-in history for LibraryScreen
List<CheckIn> checkInHistory = [];

String _getTodayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late AnimationController _pulseController;
  AnimationController? _confettiController;
  List<Map<String, dynamic>>? _confettiParticles;
  bool _showConfetti = false;

  // API data
  List<Excerpt> _activeExcerpts = [];
  Set<int> _completedSlots = {};
  Map<int, String> _slotCheckInIds = {}; // slot index -> check-in ID
  Map<int, String> _slotNotes = {}; // slot index -> notes
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = AuthService.userId;
    if (userId == null) {
      setState(() {
        _error = 'Not signed in';
        _isLoading = false;
      });
      return;
    }

    try {
      // Ensure user exists in backend
      await ApiService.createUser(userId);

      // Get active excerpts
      var excerpts = await ApiService.getActiveExcerpts(userId);

      // If no active excerpts, fetch random ones and set them
      if (excerpts.isEmpty) {
        final retiredIds = await ApiService.getRetiredExcerptIds(userId);
        final randomExcerpts = await ApiService.getRandomExcerpts(
          count: 3,
          exclude: retiredIds,
        );

        if (randomExcerpts.isNotEmpty) {
          final bulkData = randomExcerpts.asMap().entries.map((e) => {
            'slotIndex': e.key,
            'excerptId': e.value.id,
          }).toList();
          await ApiService.setActiveExcerptsBulk(userId, bulkData);
          excerpts = randomExcerpts;
        }
      }

      // Get today's check-ins to see which are already completed
      final completedSlots = <int>{};
      final slotCheckInIds = <int, String>{};
      final slotNotes = <int, String>{};

      try {
        final todayCheckIns = await ApiService.getCheckInsByDate(userId, _getTodayKey());

        for (var i = 0; i < excerpts.length; i++) {
          // Compare as strings to handle both int and UUID ids
          final excerptId = excerpts[i].id.toString();
          final checkIn = todayCheckIns.where((c) => c.excerptId.toString() == excerptId).firstOrNull;
          if (checkIn != null) {
            completedSlots.add(i);
            slotCheckInIds[i] = checkIn.id;
            if (checkIn.notes != null) {
              slotNotes[i] = checkIn.notes!;
            }
          }
        }
      } catch (e) {
        // If fetching today's check-ins fails, just show all as uncompleted
        print('Failed to fetch today check-ins: $e');
      }

      // Load full check-in history for library screen
      try {
        checkInHistory = await ApiService.getCheckIns(userId);
      } catch (e) {
        print('Failed to fetch check-in history: $e');
        // Keep existing history or empty list
      }

      if (!mounted) return;
      setState(() {
        _activeExcerpts = excerpts;
        _completedSlots = completedSlots;
        _slotCheckInIds = slotCheckInIds;
        _slotNotes = slotNotes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _confettiController?.dispose();
    super.dispose();
  }

  Future<void> _markComplete(int slotIndex) async {
    final userId = AuthService.userId;
    if (userId == null) return;

    final excerpt = _activeExcerpts[slotIndex];

    try {
      // Create check-in
      final checkIn = await ApiService.createCheckIn(
        userId,
        excerpt.id,
        _getTodayKey(),
        notes: _slotNotes[slotIndex],
      );

      // Record activity for streak
      await ApiService.recordActivity(userId, _getTodayKey());

      if (!mounted) return;
      setState(() {
        _completedSlots.add(slotIndex);
        _slotCheckInIds[slotIndex] = checkIn.id;
      });

      // Refresh check-in history
      checkInHistory = await ApiService.getCheckIns(userId);

      if (!mounted) return;
      if (_allCompleted) {
        _triggerConfetti();
      } else if (slotIndex < _activeExcerpts.length - 1) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed to check in: $e');
      }
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
    return List.generate(
        70,
        (_) => {
              'x': rand.nextDouble(),
              'delay': rand.nextDouble() * 0.4,
              'color': colors[rand.nextInt(colors.length)],
              'size': 6.0 + rand.nextDouble() * 10.0,
              'rotation': rand.nextDouble() * pi * 2,
              'driftX': (rand.nextDouble() - 0.5) * 0.3,
              'isCircle': rand.nextBool(),
            });
  }

  Future<void> _markIncomplete(int slotIndex) async {
    final checkInId = _slotCheckInIds[slotIndex];
    if (checkInId == null) return;

    try {
      await ApiService.deleteCheckIn(checkInId);

      setState(() {
        _completedSlots.remove(slotIndex);
        _slotCheckInIds.remove(slotIndex);
      });

      // Refresh check-in history
      final userId = AuthService.userId;
      if (userId != null) {
        checkInHistory = await ApiService.getCheckIns(userId);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed to undo: $e');
      }
    }
  }

  Future<void> _retireExcerpt(int slotIndex) async {
    final userId = AuthService.userId;
    if (userId == null) return;

    final excerpt = _activeExcerpts[slotIndex];

    try {
      // Retire the excerpt
      await ApiService.retireExcerpt(userId, excerpt.id);

      // Get a replacement
      final retiredIds = await ApiService.getRetiredExcerptIds(userId);
      final currentIds = _activeExcerpts.map((e) => e.id).toList();
      final excludeIds = [...retiredIds, ...currentIds];

      final replacements = await ApiService.getRandomExcerpts(
        count: 1,
        exclude: excludeIds,
      );

      if (replacements.isEmpty) {
        if (mounted) showToast(context, "All excerpts have been mastered!");
        return;
      }

      final replacement = replacements.first;
      await ApiService.setActiveExcerpt(userId, slotIndex, replacement.id);

      // Delete any check-in for this slot today
      final checkInId = _slotCheckInIds[slotIndex];
      if (checkInId != null) {
        await ApiService.deleteCheckIn(checkInId);
      }

      setState(() {
        _activeExcerpts[slotIndex] = replacement;
        _completedSlots.remove(slotIndex);
        _slotCheckInIds.remove(slotIndex);
        _slotNotes.remove(slotIndex);
      });

      // Refresh check-in history
      checkInHistory = await ApiService.getCheckIns(userId);

      if (mounted) showToast(context, "Excerpt replaced with a new one!");
    } catch (e) {
      if (mounted) showToast(context, 'Failed to retire: $e');
    }
  }

  Future<void> _confirmRetire(int slotIndex) async {
    final excerpt = _activeExcerpts[slotIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Mark as mastered?"),
        content: Text(
          '"${excerpt.text}" will be replaced with a new excerpt.',
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
    return _slotNotes[slotIndex] ?? '';
  }

  Future<void> _saveNotesForSlot(int slotIndex, String notes) async {
    setState(() {
      _slotNotes[slotIndex] = notes;
    });

    // If already checked in, update the check-in
    final checkInId = _slotCheckInIds[slotIndex];
    if (checkInId != null) {
      try {
        await ApiService.updateCheckInNotes(checkInId, notes);
        // Refresh check-in history
        final userId = AuthService.userId;
        if (userId != null) {
          checkInHistory = await ApiService.getCheckIns(userId);
        }
      } catch (e) {
        if (mounted) showToast(context, 'Failed to save notes: $e');
      }
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

  int get _completedCount => _completedSlots.length;
  bool get _allCompleted => _completedCount == _activeExcerpts.length && _activeExcerpts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeExcerpts.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No excerpts available')),
      );
    }

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
                        _allCompleted ? "All checked in!" : "Daily Check-in",
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
                                : "$_completedCount of ${_activeExcerpts.length} checked in today",
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
                              "$_completedCount/${_activeExcerpts.length}",
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
                        children:
                            List.generate(_activeExcerpts.length, (index) {
                          final isCompleted = _completedSlots.contains(index);
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
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemCount: _activeExcerpts.length,
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
    final excerpt = _activeExcerpts[slotIndex];
    final isCheckedIn = _completedSlots.contains(slotIndex);
    final hasNotes = _getNotesForSlot(slotIndex).isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                excerpt.category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Excerpt text
            Text(
              excerpt.text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: isCheckedIn
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                    : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
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
                    excerpt.bookTitle,
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
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
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
      final rotation = (p['rotation'] as double) + localProgress * pi * 8;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (p['isCircle'] as bool) {
        canvas.drawCircle(Offset.zero, particleSize / 2.5, paint);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(-particleSize / 2, -particleSize * 0.3, particleSize,
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
