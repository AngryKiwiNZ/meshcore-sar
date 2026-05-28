import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_client/src/meshcore_constants.dart';
import 'package:meshcore_client/src/protocol/frame_builder.dart';

void main() {
  group('FrameBuilder', () {
    test('terminates app start payload with null byte', () {
      final frame = FrameBuilder.buildAppStart(appName: 'MeshCore SAR');

      expect(frame.last, 0);
    });

    test('terminates direct text messages with null byte', () {
      final frame = FrameBuilder.buildSendTxtMsg(
        contactPublicKey: Uint8List.fromList(List<int>.filled(32, 0xAB)),
        text: 'status',
      );

      expect(frame.last, 0);
    });

    test('terminates channel text messages with null byte', () {
      final frame = FrameBuilder.buildSendChannelTxtMsg(
        channelIdx: 0,
        text: 'public update',
      );

      expect(frame.last, 0);
    });

    test('terminates login payload with null byte', () {
      final frame = FrameBuilder.buildSendLogin(
        roomPublicKey: Uint8List.fromList(List<int>.filled(32, 0xCD)),
        password: 'secret',
      );

      expect(frame.last, 0);
    });

    test('builds channel datagram frames with type and channel metadata', () {
      final frame = FrameBuilder.buildSendChannelData(
        channelIdx: 3,
        dataType: MeshCoreConstants.dataTypeDev,
        payload: Uint8List.fromList([0x47, 0x01, 0x02]),
      );

      expect(
        frame,
        orderedEquals([
          MeshCoreConstants.cmdSendChannelData,
          0xFF,
          0xFF,
          0x03,
          0x47,
          0x01,
          0x02,
        ]),
      );
    });

    test('builds radio params with 32-bit frequency and bandwidth', () {
      final frame = FrameBuilder.buildSetRadioParams(
        frequency: 917375,
        bandwidth: 62500,
        spreadingFactor: 7,
        codingRate: 5,
      );

      expect(
        frame,
        orderedEquals([
          MeshCoreConstants.cmdSetRadioParams,
          0x7F,
          0xFF,
          0x0D,
          0x00,
          0x24,
          0xF4,
          0x00,
          0x00,
          0x07,
          0x05,
        ]),
      );
    });
  });
}
