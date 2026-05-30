import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/helpers/raw_session_retransmit.dart';

class _Fragment {
  final int index;
  final Uint8List payload;

  _Fragment(this.index, this.payload);
}

Contact _buildContact({
  required int outPathLen,
  Uint8List? outPath,
}) {
  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i)),
    type: ContactType.chat,
    flags: 0,
    outPathLen: outPathLen,
    outPath:
        outPath ?? Uint8List.fromList(List<int>.generate(8, (i) => i + 1)),
    advName: 'Requester',
    lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    advLat: 0,
    advLon: 0,
    lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('serveCachedSessionFragments', () {
    test('returns false when sender callback is missing', () async {
      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: _buildContact(outPathLen: 1),
        fragments: [
          _Fragment(0, Uint8List.fromList([1])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket: null,
      );

      expect(ok, isFalse);
    });

    test('returns false when requester has no learned path', () async {
      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: _buildContact(outPathLen: -1),
        fragments: [
          _Fragment(0, Uint8List.fromList([1])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket:
            ({
              required contactPath,
              required contactPathLen,
              required payload,
            }) async {},
      );

      expect(ok, isFalse);
    });

    test('returns false when relayed requester path payload is empty', () async {
      final requester = Contact(
        publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i)),
        type: ContactType.chat,
        flags: 0,
        outPathLen: 1,
        outPath: Uint8List(0),
        advName: 'Requester',
        lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        advLat: 0,
        advLon: 0,
        lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: requester,
        fragments: [
          _Fragment(0, Uint8List.fromList([1])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket:
            ({
              required contactPath,
              required contactPathLen,
              required payload,
            }) async {},
      );

      expect(ok, isFalse);
    });

    test('sends zero-hop direct packets with an empty route payload', () async {
      final sentPathLens = <int>[];
      final sentPaths = <Uint8List>[];
      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: _buildContact(outPathLen: 0, outPath: Uint8List(0)),
        fragments: [
          _Fragment(0, Uint8List.fromList([10])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket:
            ({
              required contactPath,
              required contactPathLen,
              required payload,
            }) async {
              sentPathLens.add(contactPathLen);
              sentPaths.add(contactPath);
            },
      );

      expect(ok, isTrue);
      expect(sentPathLens, [0]);
      expect(sentPaths.single, isEmpty);
    });

    test('sends only requested indices', () async {
      final sent = <Uint8List>[];
      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: _buildContact(outPathLen: 1),
        fragments: [
          _Fragment(0, Uint8List.fromList([10])),
          _Fragment(1, Uint8List.fromList([20])),
          _Fragment(2, Uint8List.fromList([30])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket:
            ({
              required contactPath,
              required contactPathLen,
              required payload,
            }) async {
              sent.add(payload);
            },
        requestedIndices: {1, 2},
      );

      expect(ok, isTrue);
      expect(sent.length, equals(2));
      expect(sent[0], equals(Uint8List.fromList([20])));
      expect(sent[1], equals(Uint8List.fromList([30])));
    });

    test('fails when no requested index matches cached fragments', () async {
      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: _buildContact(outPathLen: 1),
        fragments: [
          _Fragment(0, Uint8List.fromList([1])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket:
            ({
              required contactPath,
              required contactPathLen,
              required payload,
            }) async {},
        requestedIndices: {99},
      );

      expect(ok, isFalse);
    });

    test('repeats requested fragments across multiple rounds', () async {
      final sent = <int>[];
      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: _buildContact(outPathLen: 2),
        fragments: [
          _Fragment(0, Uint8List.fromList([10])),
          _Fragment(1, Uint8List.fromList([20])),
          _Fragment(2, Uint8List.fromList([30])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket:
            ({
              required contactPath,
              required contactPathLen,
              required payload,
            }) async {
              sent.add(payload.single);
            },
        requestedIndices: {0, 2},
        fragmentSendRounds: 3,
      );

      expect(ok, isTrue);
      expect(sent, [10, 30, 10, 30, 10, 30]);
    });

    test('retries a fragment until its ack arrives', () async {
      final sent = <int>[];
      var ackAttempts = 0;

      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: _buildContact(outPathLen: 2),
        fragments: [
          _Fragment(0, Uint8List.fromList([10])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket:
            ({
              required contactPath,
              required contactPathLen,
              required payload,
            }) async {
              sent.add(payload.single);
            },
        maxFragmentSendAttempts: 3,
        waitForFragmentAck: (fragment, attempt) async {
          ackAttempts++;
          return attempt >= 1;
        },
      );

      expect(ok, isTrue);
      expect(sent, [10, 10]);
      expect(ackAttempts, equals(2));
    });

    test('fails when fragment ack never arrives', () async {
      var sendCount = 0;

      final ok = await serveCachedSessionFragments<_Fragment>(
        providerLabel: 'TestProvider',
        sessionId: 'deadbeef',
        requester: _buildContact(outPathLen: 2),
        fragments: [
          _Fragment(0, Uint8List.fromList([10])),
        ],
        maxDirectPayloadHops: 3,
        indexOf: (f) => f.index,
        encodeBinary: (f) => f.payload,
        sendRawPacket:
            ({
              required contactPath,
              required contactPathLen,
              required payload,
            }) async {
              sendCount++;
            },
        maxFragmentSendAttempts: 3,
        waitForFragmentAck: (fragment, attempt) async => false,
      );

      expect(ok, isFalse);
      expect(sendCount, equals(3));
    });
  });
}
