import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/features/statistics/bloc/statistics_cubit.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/models/review_stats.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';

const _ranges = [7, 30, 90, 365];

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatisticsCubit(),
      child: const StatisticsView(),
    );
  }
}

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.statistics)),
      body: const _StatisticsBody(),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (context, state) {
        final loc = AppLocalizations.of(context)!;
        if (state.status == StatisticsStatus.loading && state.series == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == StatisticsStatus.error) {
          return _StatisticsError(
            message: state.error == null
                ? loc.statisticsLoadFailed
                : ApiErrorMessages.resolve(state.error!, loc),
          );
        }
        if (!state.hasDecks) {
          return _StatisticsEmpty(message: loc.statisticsNoDecks);
        }

        final series = state.series!;
        return RefreshIndicator(
          onRefresh: context.read<StatisticsCubit>().refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppThemeTokens.spaceLg,
              AppThemeTokens.spaceMd,
              AppThemeTokens.spaceLg,
              AppThemeTokens.spaceXl,
            ),
            children: [
              _Filters(state: state),
              const SizedBox(height: AppThemeTokens.spaceLg),
              if (state.isRefreshing)
                const SizedBox(
                  height: 240,
                  child: Center(
                    child: CupertinoActivityIndicator(
                      key: Key('statistics_content_loading'),
                      radius: 14,
                    ),
                  ),
                )
              else ...[
                if (state.refreshError != null) ...[
                  _RefreshWarning(
                    onRetry: context.read<StatisticsCubit>().retry,
                  ),
                  const SizedBox(height: AppThemeTokens.spaceLg),
                ],
                _MetricsGrid(series: series),
                const SizedBox(height: AppThemeTokens.spaceLg),
                if (series.totalReviews == 0)
                  _StatisticsEmpty(message: loc.statisticsNoActivity)
                else ...[
                  _DailyActivityChart(series: series),
                  const SizedBox(height: AppThemeTokens.spaceLg),
                  _WeekdayChart(series: series),
                ],
                const SizedBox(height: AppThemeTokens.spaceMd),
                Text(
                  loc.statisticsUtcNote,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final StatisticsState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cubit = context.read<StatisticsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DeckFilterButton(state: state, onSelected: cubit.selectDeck),
        const SizedBox(height: AppThemeTokens.spaceMd),
        Wrap(
          spacing: AppThemeTokens.spaceSm,
          runSpacing: AppThemeTokens.spaceSm,
          children: _ranges
              .map(
                (days) => ChoiceChip(
                  label: Text(loc.statisticsRangeDays(days)),
                  selected: state.rangeDays == days,
                  onSelected: state.isRefreshing
                      ? null
                      : (selected) {
                          if (selected) cubit.selectRange(days);
                        },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DeckFilterButton extends StatelessWidget {
  const _DeckFilterButton({required this.state, required this.onSelected});

  final StatisticsState state;
  final ValueChanged<String?> onSelected;

  Future<void> _showPicker(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final deckIds = <String?>[null, ...state.decks.map((deck) => deck.id)];
    final deckNames = <String>[
      loc.statisticsAllDecks,
      ...state.decks.map((deck) => deck.name),
    ];
    final selectedIndex = state.selectedDeckId == null
        ? 0
        : deckIds.indexOf(state.selectedDeckId).clamp(0, deckIds.length - 1);
    var pendingIndex = selectedIndex;
    final controller = FixedExtentScrollController(initialItem: selectedIndex);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (pickerContext) => CupertinoTheme(
        data: CupertinoThemeData(
          brightness: theme.brightness,
          primaryColor: scheme.primary,
          scaffoldBackgroundColor: scheme.surface,
          textTheme: CupertinoTextThemeData(
            pickerTextStyle: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        child: Material(
          color: scheme.surface,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 300,
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        CupertinoButton(
                          onPressed: () => Navigator.of(pickerContext).pop(),
                          child: Text(loc.cancel),
                        ),
                        Expanded(
                          child: Text(
                            loc.statisticsDeckFilter,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        CupertinoButton(
                          key: const Key('statistics_deck_picker_done'),
                          onPressed: () {
                            Navigator.of(pickerContext).pop();
                            onSelected(deckIds[pendingIndex]);
                          },
                          child: Text(loc.tagPickerDone),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  Expanded(
                    child: CupertinoPicker(
                      key: const Key('statistics_deck_picker'),
                      scrollController: controller,
                      itemExtent: 44,
                      useMagnifier: true,
                      magnification: 1.06,
                      onSelectedItemChanged: (index) => pendingIndex = index,
                      children: deckNames
                          .map(
                            (name) => Center(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedName = state.selectedDeckId == null
        ? loc.statisticsAllDecks
        : state.decks
                  .where((deck) => deck.id == state.selectedDeckId)
                  .map((deck) => deck.name)
                  .firstOrNull ??
              loc.statisticsAllDecks;
    return Material(
      key: const Key('statistics_deck_filter'),
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: AppThemeTokens.borderRadiusMd,
        side: BorderSide(
          color: scheme.outline,
          width: AppThemeTokens.borderWidthHairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: state.isRefreshing ? null : () => _showPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppThemeTokens.spaceLg,
            vertical: AppThemeTokens.spaceMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.statisticsDeckFilter,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppThemeTokens.spaceXs),
                    Text(
                      selectedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppThemeTokens.spaceSm),
              Icon(
                LucideIcons.chevronsUpDown,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.series});

  final ReviewStatsSeries series;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppThemeTokens.spaceMd) / 2;
        return Wrap(
          spacing: AppThemeTokens.spaceMd,
          runSpacing: AppThemeTokens.spaceMd,
          children: [
            _MetricCard(
              width: width,
              label: loc.statisticsPeriodReviews,
              value: '${series.totalReviews}',
            ),
            _MetricCard(
              width: width,
              label: loc.statisticsTodayReviews,
              value: '${series.todayReviews}',
            ),
            _MetricCard(
              width: width,
              label: loc.statisticsActiveDays,
              value: '${series.activeDays}',
            ),
            _MetricCard(
              width: width,
              label: loc.statisticsDailyAverage,
              value: series.dailyAverage.toStringAsFixed(1),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: AppThemeTokens.borderRadiusLg,
          side: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: AppThemeTokens.borderWidthHairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppThemeTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppThemeTokens.spaceXs),
              Text(value, style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyActivityChart extends StatelessWidget {
  const _DailyActivityChart({required this.series});

  final ReviewStatsSeries series;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.Md(locale);
    final details = series.days
        .map(
          (entry) =>
              '${dateFormat.format(entry.day)} ${loc.statisticsReviewsCount(entry.count)}',
        )
        .join(', ');
    return _ChartCard(
      title: loc.statisticsDailyActivity,
      child: Semantics(
        label: loc.statisticsDailyChartSemantics(details),
        child: ExcludeSemantics(
          child: SizedBox(
            height: 250,
            child: _BarChart(
              values: series.days.map((day) => day.count).toList(),
              bottomLabel: (index) {
                final step = switch (series.days.length) {
                  <= 7 => 1,
                  <= 30 => 5,
                  <= 90 => 15,
                  _ => 60,
                };
                if (index != 0 &&
                    index != series.days.length - 1 &&
                    index % step != 0) {
                  return '';
                }
                return dateFormat.format(series.days[index].day);
              },
              tooltip: (index) =>
                  '${dateFormat.format(series.days[index].day)}\n'
                  '${loc.statisticsReviewsCount(series.days[index].count)}',
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart({required this.series});

  final ReviewStatsSeries series;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekdayFormat = DateFormat.E(locale);
    // 2024-01-01 is a Monday, so index 0 matches weekdayTotals.
    final monday = DateTime.utc(2024, 1, 1);
    final labels = List.generate(
      7,
      (index) => weekdayFormat.format(monday.add(Duration(days: index))),
    );
    final values = series.weekdayTotals;
    final details = List.generate(
      7,
      (index) =>
          '${labels[index]} ${loc.statisticsReviewsCount(values[index])}',
    ).join(', ');
    return _ChartCard(
      title: loc.statisticsWeekdayDistribution,
      child: Semantics(
        label: loc.statisticsWeekdayChartSemantics(details),
        child: ExcludeSemantics(
          child: SizedBox(
            height: 220,
            child: _BarChart(
              values: values,
              bottomLabel: (index) => labels[index],
              tooltip: (index) =>
                  '${labels[index]}\n${loc.statisticsReviewsCount(values[index])}',
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: AppThemeTokens.borderRadiusLg,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: AppThemeTokens.borderWidthHairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppThemeTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppThemeTokens.spaceLg),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.bottomLabel,
    required this.tooltip,
  });

  final List<int> values;
  final String Function(int index) bottomLabel;
  final String Function(int index) tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final largest = values.fold<int>(0, math.max);
    final maxY = math.max(1.0, largest * 1.15);
    final rodWidth = switch (values.length) {
      <= 7 => 18.0,
      <= 30 => 7.0,
      <= 90 => 3.0,
      _ => 1.0,
    };
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: values.length > 90 ? 0 : 2,
        barGroups: List.generate(
          values.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index].toDouble(),
                width: rodWidth,
                color: scheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ],
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant,
            strokeWidth: AppThemeTokens.borderWidthHairline,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(value.toInt().toString(), style: labelStyle),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= values.length) {
                  return const SizedBox.shrink();
                }
                final label = bottomLabel(index);
                if (label.isEmpty) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(label, style: labelStyle),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
                  tooltip(group.x),
                  theme.textTheme.labelMedium!.copyWith(
                    color: scheme.onInverseSurface,
                  ),
                ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}

class _RefreshWarning extends StatelessWidget {
  const _RefreshWarning({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: AppThemeTokens.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeTokens.spaceMd,
          vertical: AppThemeTokens.spaceSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                loc.statisticsRefreshFailed,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            AppButton(
              label: loc.retry,
              onPressed: onRetry,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsError extends StatelessWidget {
  const _StatisticsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppThemeTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppThemeTokens.spaceMd),
            AppButton(
              label: loc.retry,
              onPressed: context.read<StatisticsCubit>().loadInitial,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsEmpty extends StatelessWidget {
  const _StatisticsEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
