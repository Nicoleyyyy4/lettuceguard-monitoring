import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SensorCard extends StatefulWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color themeColor;
  final bool isError;
  final bool isWarning;
  final String? alertMessage;
  final String? targetRange;
  final double? normalizedProgress; // optional 0..1 bar indicator
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    this.unit = '',
    required this.icon,
    required this.themeColor,
    this.isError = false,
    this.isWarning = false,
    this.alertMessage,
    this.targetRange,
    this.normalizedProgress,
    this.onTap,
  });

  @override
  State<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = LettuceGuardColors.isDark(context);
    final surface = LettuceGuardColors.surface(context);
    final defaultBorder = LettuceGuardColors.border(context);

    Color cardBorderColor = _hovered
        ? widget.themeColor.withValues(alpha: 0.45)
        : defaultBorder;
    Color statusColor = LettuceGuardColors.statusOk;
    String statusText = 'Optimal';

    if (widget.isError) {
      cardBorderColor = LettuceGuardColors.statusError;
      statusColor = LettuceGuardColors.statusError;
      statusText = 'SENSOR ERROR';
    } else if (widget.isWarning) {
      cardBorderColor = LettuceGuardColors.statusWarning;
      statusColor = LettuceGuardColors.statusWarning;
      statusText = 'Out of Range';
    }

    final iconAccent = widget.isError
        ? LettuceGuardColors.statusError
        : widget.themeColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cardBorderColor,
            width: widget.isError || widget.isWarning ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isError
                  ? LettuceGuardColors.statusError.withValues(alpha: 0.14)
                  : widget.isWarning
                  ? LettuceGuardColors.statusWarning.withValues(alpha: 0.14)
                  : _hovered
                  ? widget.themeColor.withValues(alpha: isDark ? 0.18 : 0.12)
                  : LettuceGuardColors.shadow(context),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 6 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Icon & Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: iconAccent.withValues(
                            alpha: isDark ? 0.18 : 0.11,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(widget.icon, size: 20, color: iconAccent),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                              alpha: isDark ? 0.18 : 0.11,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  statusText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Metric Title + Live Reading
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: LettuceGuardColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              widget.isError ? 'ERR' : widget.value,
                              style: TextStyle(
                                fontSize: widget.isError ? 23 : 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: widget.isError
                                    ? LettuceGuardColors.statusError
                                    : (widget.isWarning
                                          ? LettuceGuardColors.statusWarning
                                          : LettuceGuardColors.textPrimary(
                                              context,
                                            )),
                              ),
                            ),
                            if (!widget.isError && widget.unit.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                widget.unit,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: LettuceGuardColors.textSecondary(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Subtle range progress bar + footer
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.normalizedProgress != null &&
                          !widget.isError) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: widget.normalizedProgress!.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: LettuceGuardColors.surfaceElevated(
                              context,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isWarning
                                  ? LettuceGuardColors.statusWarning
                                  : widget.themeColor,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      if (widget.isError && widget.alertMessage != null)
                        Text(
                          widget.alertMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: LettuceGuardColors.statusError,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (widget.targetRange != null)
                        Text(
                          'Optimal: ${widget.targetRange}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: LettuceGuardColors.textSecondary(context),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
