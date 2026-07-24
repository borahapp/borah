import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/notification_preferences_controller.dart';
import '../states/notification_preferences_status.dart';

/// Tela de Preferências (DV-09 §6/§11) - apenas o toggle de notificações
/// sociais In-App (decisão 3/5 do DV-09); sem opção de Push.
class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends ConsumerState<NotificationPreferencesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      ref.read(notificationPreferencesControllerProvider.notifier).load(userId);
    });
  }

  void _toggle() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref.read(notificationPreferencesControllerProvider.notifier).toggle(userId);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(notificationPreferencesControllerProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Preferências'),
      body: switch (status) {
        NotificationPreferencesInitial() ||
        NotificationPreferencesLoading() => const LoadingScreen(),
        NotificationPreferencesError(:final message) => Center(
          child: Text(message),
        ),
        NotificationPreferencesLoaded(:final inAppEnabled) => SwitchListTile(
          title: const Text('Notificações sociais'),
          subtitle: const Text(
            'Novo seguidor, comentário e curtida nas suas avaliações.',
          ),
          value: inAppEnabled,
          onChanged: (_) => _toggle(),
        ),
      },
    );
  }
}
