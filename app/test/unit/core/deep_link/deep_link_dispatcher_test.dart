import 'dart:async';

import 'package:app/core/deep_link/deep_link.dart';
import 'package:app/core/deep_link/deep_link_dispatcher.dart';
import 'package:app/core/deep_link/deep_link_receiver.dart';
import 'package:app/core/logger/app_log_level.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingReceiver implements DeepLinkReceiver {
  final received = <DeepLink>[];

  @override
  void receive(DeepLink link) => received.add(link);
}

class _ThrowingReceiver implements DeepLinkReceiver {
  @override
  void receive(DeepLink link) => throw StateError('falha proposital');
}

void main() {
  final localCalls = <Map<String, dynamic>>[];

  setUp(() {
    localCalls.clear();
    AppLogger.debugMinimumLevelOverride = AppLogLevel.trace;
    AppLogger.debugLocalSinkOverride =
        (formatted, {required level, error, stackTrace}) {
          localCalls.add({'formatted': formatted, 'level': level});
        };
    AppLogger.debugCrashReportingSinkOverride =
        (level, message, {tag, userId, error, stackTrace}) async {};
  });

  tearDown(() {
    AppLogger.debugMinimumLevelOverride = null;
    AppLogger.debugLocalSinkOverride = null;
    AppLogger.debugCrashReportingSinkOverride = null;
  });

  test('distribui um DeepLink conhecido para todos os receptores', () async {
    final controller = StreamController<DeepLink>();
    final receiverA = _RecordingReceiver();
    final receiverB = _RecordingReceiver();
    final dispatcher = DeepLinkDispatcher(
      stream: controller.stream,
      receivers: [receiverA, receiverB],
    );
    addTearDown(dispatcher.dispose);
    addTearDown(controller.close);

    const link = GroupJoinDeepLink(inviteCode: 'ABCD');
    controller.add(link);
    await pumpEventQueue();

    expect(receiverA.received, [link]);
    expect(receiverB.received, [link]);
  });

  test(
    'exceção de um receiver não impede os demais de receber o mesmo link',
    () async {
      final controller = StreamController<DeepLink>();
      final before = _RecordingReceiver();
      final throwing = _ThrowingReceiver();
      final after = _RecordingReceiver();
      final dispatcher = DeepLinkDispatcher(
        stream: controller.stream,
        receivers: [before, throwing, after],
      );
      addTearDown(dispatcher.dispose);
      addTearDown(controller.close);

      const link = GroupJoinDeepLink(inviteCode: 'ABCD');
      controller.add(link);
      await pumpEventQueue();

      expect(before.received, [link]);
      expect(after.received, [link]);
      expect(
        localCalls.any(
          (c) => (c['formatted'] as String).contains('DeepLinkReceiver'),
        ),
        isTrue,
      );
    },
  );

  test(
    'UnknownDeepLink nunca é distribuído aos receptores, só logado',
    () async {
      final controller = StreamController<DeepLink>();
      final receiver = _RecordingReceiver();
      final dispatcher = DeepLinkDispatcher(
        stream: controller.stream,
        receivers: [receiver],
      );
      addTearDown(dispatcher.dispose);
      addTearDown(controller.close);

      controller.add(UnknownDeepLink(uri: Uri.parse('borah://x/y')));
      await pumpEventQueue();

      expect(receiver.received, isEmpty);
      expect(
        localCalls.any(
          (c) => (c['formatted'] as String).contains('borah://x/y'),
        ),
        isTrue,
      );
    },
  );

  test(
    'aceita Iterable (não só List) e copia para uma coleção imutável no construtor',
    () async {
      final receivers = [_RecordingReceiver(), _RecordingReceiver()];
      final controller = StreamController<DeepLink>();
      final dispatcher = DeepLinkDispatcher(
        stream: controller.stream,
        receivers: receivers.map((r) => r), // Iterable, não List
      );
      addTearDown(dispatcher.dispose);
      addTearDown(controller.close);

      // Adicionar um 3º receiver à lista original DEPOIS do dispatcher
      // já criado não deveria fazer esse 3º receber nada - a cópia
      // (List.unmodifiable) já aconteceu no construtor.
      final addedLate = _RecordingReceiver();
      receivers.add(addedLate);

      const link = GroupJoinDeepLink(inviteCode: 'ABCD');
      controller.add(link);
      await pumpEventQueue();

      expect(receivers[0].received, [link]);
      expect(receivers[1].received, [link]);
      expect(addedLate.received, isEmpty);
    },
  );
}
