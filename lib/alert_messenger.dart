import 'package:flutter/material.dart';

const kAlertHeight = 80.0;

enum AlertPriority {
  error(2, 'Oops, ocorreu um erro. Pedimos desculpas.'),
  warning(1, 'Atenção! Você foi avisado.'),
  info(0, 'Este é um aplicativo escrito em Flutter.');

  const AlertPriority(this.value, this.description);
  final int value;
  final String description;
}

class Alert extends StatelessWidget {
  const Alert({
    super.key,
    required this.backgroundColor,
    required this.child,
    required this.leading,
    required this.priority,
  });

  final Color backgroundColor;
  final Widget child;
  final Widget leading;
  final AlertPriority priority;

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;
    return Material(
      child: Ink(
        color: backgroundColor,
        height: kAlertHeight + statusbarHeight,
        child: Column(
          children: [
            SizedBox(height: statusbarHeight),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 28.0),
                  IconTheme(
                    data: const IconThemeData(
                      color: Colors.white,
                      size: 36,
                    ),
                    child: leading,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28.0),
          ],
        ),
      ),
    );
  }
}

class AlertMessenger extends StatefulWidget {
  const AlertMessenger({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AlertMessenger> createState() => AlertMessengerState();

  static AlertMessengerState of(BuildContext context) {
    try {
      final scope = _AlertMessengerScope.of(context);
      return scope.state;
    } catch (error) {
      throw FlutterError.fromParts(
        [
          ErrorSummary('No AlertMessenger was found in the Element tree'),
          ErrorDescription(
              'AlertMessenger is required in order to show and hide alerts.'),
          ...context.describeMissingAncestor(
              expectedAncestorType: AlertMessenger),
        ],
      );
    }
  }
}

class AlertMessengerState extends State<AlertMessenger>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  Widget? alertWidget;
  final currentAlertPrioriry = ValueNotifier<AlertPriority?>(null);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alertHeight = MediaQuery.of(context).padding.top + kAlertHeight;
    animation = Tween<double>(begin: -alertHeight, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void showAlert({required Alert alert}) {
    if (currentAlertPrioriry.value == null ||
        alert.priority.value > currentAlertPrioriry.value!.value) {
      currentAlertPrioriry.value = alert.priority;
      setState(() => alertWidget = alert);
      controller.reverse().then((value) {
        controller.forward();
      });
    }
  }

  void hideAlert() {
    currentAlertPrioriry.value = null;
    controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final position = animation.value + kAlertHeight;
        return Stack(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          children: [
            Positioned.fill(
              top: position <= statusbarHeight ? 0 : position - statusbarHeight,
              child: _AlertMessengerScope(
                state: this,
                child: widget.child,
              ),
            ),
            Positioned(
              top: animation.value,
              left: 0,
              right: 0,
              child: alertWidget ?? const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _AlertMessengerScope extends InheritedWidget {
  const _AlertMessengerScope({
    required this.state,
    required super.child,
  });

  final AlertMessengerState state;

  @override
  bool updateShouldNotify(_AlertMessengerScope oldWidget) =>
      state != oldWidget.state;

  static _AlertMessengerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AlertMessengerScope>();
  }

  static _AlertMessengerScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No _AlertMessengerScope found in context');
    return scope!;
  }
}
