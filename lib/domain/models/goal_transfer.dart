/// A person's earning used to weight the monthly goal transfers.
class GoalEarning {
  const GoalEarning({
    required this.personId,
    required this.name,
    required this.earning,
  });

  final String personId;
  final String name;

  /// The person's income for the month, in euros.
  final double earning;
}

/// One goal's slice of a person's transfer.
class GoalTransferPart {
  const GoalTransferPart({
    required this.goalId,
    required this.name,
    required this.amount,
  });

  final String goalId;
  final String name;
  final double amount;
}

/// How much one person transfers towards the month's goals, and to which goals.
class GoalTransfer {
  const GoalTransfer({
    required this.personId,
    required this.name,
    required this.earning,
    required this.share,
    required this.amount,
    required this.parts,
  });

  final String personId;
  final String name;

  /// The person's income for the month, in euros.
  final double earning;

  /// The person's share of the total earning, as a 0..1 fraction.
  final double share;

  /// The amount the person transfers, in euros.
  final double amount;

  /// Where the transfer goes, goal by goal.
  final List<GoalTransferPart> parts;

  /// Distributes [reservedTotal] across [earnings] proportionally to each
  /// person's income, with the goals filled in order (a waterfall): the first
  /// person closes the goals one by one, the next covers what is left.
  ///
  /// All arithmetic is in cents so the displayed totals add up exactly. Returns
  /// an empty list when there is nothing to transfer or no income.
  static List<GoalTransfer> distribute({
    required double reservedTotal,
    required List<GoalEarning> earnings,
    required List<GoalTransferPart> goals,
  }) {
    if (reservedTotal <= 0 || earnings.isEmpty) {
      return const [];
    }
    final totalEarning = earnings.fold<double>(
      0,
      (sum, item) => sum + item.earning,
    );
    if (totalEarning <= 0) {
      return const [];
    }
    final shares = <double>[
      for (final item in earnings) item.earning / totalEarning,
    ];

    // Largest-remainder split of the reserved total across the shares.
    final totalCents = (reservedTotal * 100).round();
    final exact = <double>[for (final share in shares) totalCents * share];
    final floored = <int>[for (final value in exact) value.floor()];
    final fractions = <double>[
      for (var i = 0; i < exact.length; i++) exact[i] - floored[i],
    ];
    final leftover = totalCents - floored.fold<int>(0, (sum, v) => sum + v);
    final ranked = <int>[for (var i = 0; i < shares.length; i++) i]
      ..sort((a, b) => fractions[b].compareTo(fractions[a]));
    final gifted = ranked
        .take(leftover.clamp(0, ranked.length).toInt())
        .toSet();
    final amountCents = <int>[
      for (var i = 0; i < earnings.length; i++)
        floored[i] + (gifted.contains(i) ? 1 : 0),
    ];

    // Waterfall: fill each goal from the first person that still has quota.
    final remaining = <int>[...amountCents];
    final parts = <List<GoalTransferPart>>[
      for (final _ in earnings) <GoalTransferPart>[],
    ];
    for (final goal in goals) {
      var need = (goal.amount * 100).round();
      for (var index = 0; index < remaining.length && need > 0; index++) {
        if (remaining[index] <= 0) {
          continue;
        }
        final give = need < remaining[index] ? need : remaining[index];
        remaining[index] -= give;
        need -= give;
        if (give > 0) {
          parts[index].add(
            GoalTransferPart(
              goalId: goal.goalId,
              name: goal.name,
              amount: give / 100,
            ),
          );
        }
      }
      if (need > 0 && remaining.isNotEmpty) {
        final last = remaining.length - 1;
        remaining[last] -= need;
        parts[last].add(
          GoalTransferPart(
            goalId: goal.goalId,
            name: goal.name,
            amount: need / 100,
          ),
        );
      }
    }

    return <GoalTransfer>[
      for (var i = 0; i < earnings.length; i++)
        GoalTransfer(
          personId: earnings[i].personId,
          name: earnings[i].name,
          earning: earnings[i].earning,
          share: shares[i],
          amount: amountCents[i] / 100,
          parts: parts[i],
        ),
    ];
  }
}
