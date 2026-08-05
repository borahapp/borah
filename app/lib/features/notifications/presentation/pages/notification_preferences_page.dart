import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/feedback/app_animated_switcher.dart';
import '../../../../design_system/components/feedback/error_state.dart';
import '../../../../design_system/components/feedback/loading_indicator.dart';
import '../../../../design_system/components/navigation/app_top_bar.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/notification_preferences_controller.dart';
import '../states/notification_preferences_status.dart';

/// Tela de Preferências (DV-09 §6/§11, estendida na RC-03 Sprint 0 - F48) -
/// toggles de notificações In-App para as categorias 'social' e 'groups';
/// sem opção de Push.
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

  void _toggle(String category) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref
        .read(notificationPreferencesControllerProvider.notifier)
        .toggle(userId, category);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(notificationPreferencesControllerProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Preferências'),
      body: AppAnimatedSwitcher(
        child: switch (status) {
          NotificationPreferencesInitial() ||
          NotificationPreferencesLoading() => const LoadingScreen(
            key: ValueKey('loading'),
          ),
          NotificationPreferencesError(:final message) => ErrorState(
            key: const ValueKey('error'),
            message: message,
            onRetry: () {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null) return;
              ref
                  .read(notificationPreferencesControllerProvider.notifier)
                  .load(userId);
            },
          ),
          NotificationPreferencesLoaded(
            :final socialEnabled,
            :final groupsEnabled,
          ) =>
            Column(
              key: const ValueKey('loaded'),
              children: [
                SwitchListTile(
                  title: const Text('Notificações sociais'),
                  subtitle: const Text(
                    'Novo seguidor, comentário e curtida nas suas avaliações.',
                  ),
                  value: socialEnabled,
                  onChanged: (_) =>
                      _toggle(NotificationPreferenceCategory.social),
                ),
                SwitchListTile(
                  title: const Text('Notificações de grupos'),
                  subtitle: const Text(
                    'Novo membro, novo rolê e resposta de presença.',
                  ),
                  value: groupsEnabled,
                  onChanged: (_) =>
                      _toggle(NotificationPreferenceCategory.groups),
                ),
              ],
            ),
        },
      ),
    );
  }
}
