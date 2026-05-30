import 'package:flutter/foundation.dart';

import '../../models/contact.dart';

typedef RawPacketSender =
    Future<void> Function({
      required Uint8List contactPath,
      required int contactPathLen,
      required Uint8List payload,
    });

Future<bool> serveCachedSessionFragments<T>({
  required String providerLabel,
  required String sessionId,
  required Contact requester,
  required List<T> fragments,
  required int maxDirectPayloadHops,
  required int Function(T fragment) indexOf,
  required Uint8List Function(T fragment) encodeBinary,
  required RawPacketSender? sendRawPacket,
  Set<int>? requestedIndices,
  Duration interFragmentDelay = Duration.zero,
  int fragmentSendRounds = 1,
  int maxFragmentSendAttempts = 1,
  Duration interAttemptDelay = Duration.zero,
  Future<bool> Function(T fragment, int attempt)? waitForFragmentAck,
}) async {
  if (fragments.isEmpty) {
    debugPrint('[$providerLabel] No cached fragments for $sessionId');
    return false;
  }
  if (sendRawPacket == null) {
    debugPrint('[$providerLabel] sendRawPacketCallback not set');
    return false;
  }
  if (!requester.routeHasPath) {
    debugPrint('[$providerLabel] ${requester.advName} has no direct path');
    return false;
  }
  if (requester.routeHopCount > maxDirectPayloadHops) {
    debugPrint(
      '[$providerLabel] ${requester.advName} is too far: ${requester.routeHopCount} hops (max $maxDirectPayloadHops)',
    );
    return false;
  }
  if (requester.routeHopCount > 0 && requester.outPath.isEmpty) {
    debugPrint(
      '[$providerLabel] ${requester.advName} has empty outPath payload',
    );
    return false;
  }
  if (fragmentSendRounds < 1) {
    debugPrint(
      '[$providerLabel] Invalid fragmentSendRounds=$fragmentSendRounds for $sessionId',
    );
    return false;
  }
  if (maxFragmentSendAttempts < 1) {
    debugPrint(
      '[$providerLabel] Invalid maxFragmentSendAttempts=$maxFragmentSendAttempts for $sessionId',
    );
    return false;
  }

  final fragmentsToServe = <T>[];
  for (final fragment in fragments) {
    final index = indexOf(fragment);
    if (index < 0) {
      debugPrint('[$providerLabel] Invalid fragment index $index');
      continue;
    }
    if (requestedIndices != null && !requestedIndices.contains(index)) {
      continue;
    }
    fragmentsToServe.add(fragment);
  }

  if (fragmentsToServe.isEmpty) {
    debugPrint('[$providerLabel] No fragments matched request for $sessionId');
    return false;
  }

  for (var round = 0; round < fragmentSendRounds; round++) {
    for (final fragment in fragmentsToServe) {
      final index = indexOf(fragment);
      var delivered = false;
      for (var attempt = 0; attempt < maxFragmentSendAttempts; attempt++) {
        try {
          await sendRawPacket(
            contactPath: requester.outPath,
            contactPathLen: requester.routeEncodedPathLen,
            payload: encodeBinary(fragment),
          );
          if (interFragmentDelay > Duration.zero) {
            await Future<void>.delayed(interFragmentDelay);
          }
          delivered =
              await waitForFragmentAck?.call(fragment, attempt) ?? true;
          if (delivered) {
            break;
          }
          if (interAttemptDelay > Duration.zero &&
              attempt + 1 < maxFragmentSendAttempts) {
            await Future<void>.delayed(interAttemptDelay);
          }
        } catch (e, st) {
          debugPrint(
            '[$providerLabel] Serve error for $sessionId#$index (round ${round + 1}/$fragmentSendRounds, attempt ${attempt + 1}/$maxFragmentSendAttempts): $e\n$st',
          );
          return false;
        }
      }
      if (!delivered) {
        debugPrint(
          '[$providerLabel] Fragment ACK not received for $sessionId#$index after $maxFragmentSendAttempts attempt(s)',
        );
        return false;
      }
    }
  }

  debugPrint(
    '[$providerLabel] Served ${fragmentsToServe.length} fragment(s) for $sessionId across $fragmentSendRounds round(s)',
  );
  return true;
}
