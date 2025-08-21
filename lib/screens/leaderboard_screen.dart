// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/attendance_service.dart'; // Ensure this path is correct
import '../helpers/logger_helper.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      // Data now directly contains Score, PresentCount, LateCount, HalfDayCount
      // and is already sorted from the API
      final List<Map<String, dynamic>> data =
          await AttendanceService.getUserSummary();

      setState(() {
        leaderboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage =
            'Failed to load leaderboard: ${e.toString()}'; // Use e.toString() for better error message
        isLoading = false;
      });
      AppLogger.error('Leaderboard fetch error', e); // For debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Match your app's background
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
              : errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchLeaderboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : leaderboardData.isEmpty
              ? Center(
                child: Text(
                  'No attendance records yet to form a leaderboard.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              : RefreshIndicator(
                // Allow pull-to-refresh
                onRefresh: _fetchLeaderboard,
                color: colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: leaderboardData.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboardData[index];
                    final rank = index + 1;
                    Color rankColor = colorScheme.onSurface;
                    IconData? rankIcon;

                    // Use medal icons for top 3
                    if (rank == 1) {
                      rankColor = Colors.amber.shade700;
                      rankIcon = Icons.emoji_events; // Gold medal
                    } else if (rank == 2) {
                      rankColor = Colors.grey.shade500;
                      rankIcon = Icons.emoji_events; // Silver medal
                    } else if (rank == 3) {
                      rankColor = Colors.brown.shade400;
                      rankIcon = Icons.emoji_events; // Bronze medal
                    }

                    // Safely get counts and score
                    final int presentCount = entry['PresentCount'] ?? 0;
                    final int lateCount = entry['LateCount'] ?? 0;
                    final int halfDayCount = entry['HalfDayCount'] ?? 0;
                    final double score =
                        (entry['Score'] as num?)?.toDouble() ?? 0.0;
                    final int totalRecordedDays =
                        presentCount + lateCount + halfDayCount;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Rank/Medal display
                            CircleAvatar(
                              backgroundColor: rankColor.withOpacity(0.2),
                              child:
                                  rankIcon != null
                                      ? Icon(
                                        rankIcon,
                                        color: rankColor,
                                        size: 28,
                                      )
                                      : Text(
                                        '$rank',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: rankColor,
                                        ),
                                      ),
                            ),
                            const SizedBox(width: 16),
                            // Employee Name and Score
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry['EmployeeName'] ?? 'Unknown User',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Score: ${score.toStringAsFixed(2)}', // Display the calculated score
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Attendance Breakdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$totalRecordedDays',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Total Days',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                // Optional: Show breakdown
                                if (presentCount > 0 ||
                                    lateCount > 0 ||
                                    halfDayCount > 0)
                                  Text(
                                    'P:$presentCount L:$lateCount H:$halfDayCount',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
