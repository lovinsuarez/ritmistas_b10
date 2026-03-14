import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ritmistas_app/theme.dart';

/// Widgets compartilhados para manter consistência visual (padding, títulos, botões)
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 800 ? 32.0 : (width > 600 ? 24.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

// ============================================================
// PREMIUM WIDGETS — Design System Components
// ============================================================

/// Frosted glass card with blur and subtle gold border
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.lg,
    this.blurAmount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.borderGold,
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Card with gradient background and optional glow
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final bool showGlow;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.showGlow = false,
    this.borderRadius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: showGlow ? AppShadows.goldGlow : AppShadows.card,
      ),
      child: child,
    );
  }
}

/// Shimmer loading placeholder with gold accent
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppRadius.sm,
    this.isCircle = false,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.isCircle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Profile shimmer skeleton for loading states
class ProfileShimmerSkeleton extends StatelessWidget {
  const ProfileShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const ShimmerLoading(height: 100, isCircle: true),
          const SizedBox(height: AppSpacing.md),
          const ShimmerLoading(width: 150, height: 20),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerLoading(width: 100, height: 14),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (_) =>
              const ShimmerLoading(width: 80, height: 60, borderRadius: AppRadius.md),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(3, (_) =>
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: ShimmerLoading(height: 70, borderRadius: AppRadius.md),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated number counter that animates when value changes
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = AppAnimations.counter,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '${prefix ?? ''}$animatedValue${suffix ?? ''}',
          style: style ?? AppTypography.goldAccent,
        );
      },
    );
  }
}

/// Gold divider with fade edges
class GoldDivider extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;

  const GoldDivider({
    super.key,
    this.height = 0.5,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: AppSpacing.md),
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primaryGold,
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Wrapper that fades + slides children in on first build
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double slideOffset;
  final Axis axis;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = AppAnimations.medium,
    this.delay = Duration.zero,
    this.slideOffset = 20,
    this.axis = Axis.vertical,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.enter,
    );

    final beginOffset = widget.axis == Axis.vertical
        ? Offset(0, widget.slideOffset / 100)
        : Offset(widget.slideOffset / 100, 0);

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.enter,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Staggered list item wrapper for sequential entrance animations
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      delay: staggerDelay * index,
      child: child,
    );
  }
}

/// Icon with subtle pulsing glow animation (for CTAs)
class PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Duration duration;

  const PulseIcon({
    super.key,
    required this.icon,
    this.color = AppColors.primaryGold,
    this.size = 48,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowOpacity = 0.15 + (0.25 * _controller.value);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(glowOpacity),
                blurRadius: 20 + (10 * _controller.value),
                spreadRadius: 2 + (4 * _controller.value),
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        );
      },
    );
  }
}

/// Status/Role chip with gradient fill
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.primaryGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
