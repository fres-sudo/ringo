import 'package:ring_protocol/ring_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('ColmiFrame', () {
    test('encodes the documented battery request', () {
      final frame = ColmiFrame.request(commandId: 0x03);

      expect(frame.bytes, <int>[0x03, ...List<int>.filled(14, 0), 0x03]);
    });

    test('rejects a frame with a mismatched checksum', () {
      expect(
        () => ColmiFrame.parse(<int>[0x03, ...List<int>.filled(14, 0), 0x04]),
        throwsA(isA<ColmiFrameFormatException>()),
      );
    });

    test(
      'keeps modulo-255 validation available for captured firmware variants',
      () {
        final frame = ColmiFrame.request(
          commandId: 1,
          payload: const [254],
          checksum: ColmiChecksum.sumModulo255,
        );

        expect(frame.bytes.last, 0);
        expect(
          ColmiFrame.parse(frame.bytes, checksum: ColmiChecksum.sumModulo255),
          isA<ColmiFrame>(),
        );
      },
    );
  });

  group('COLMI commands', () {
    test('parses a battery response', () {
      final response = ColmiFrame.request(
        commandId: 0x03,
        payload: const [85, 1],
      );

      final battery = const ColmiBatteryRequest().parseResponse(response);

      expect(battery.percent, 85);
      expect(battery.isCharging, isTrue);
    });

    test('encodes a local clock value', () {
      final request = ColmiSetClockRequest(DateTime(2026, 8, 26, 1, 2, 3));

      expect(request.toFrame(checksum: ColmiChecksum.sumModulo256).bytes, <int>[
        1,
        26,
        8,
        26,
        1,
        2,
        3,
        ...List<int>.filled(8, 0),
        67,
      ]);
    });
  });

  group('COLMI profiles', () {
    test('selects R02 as the baseline profile', () {
      expect(
        ColmiDeviceProfiles.matchAdvertisementName('R02_341C'),
        same(ColmiDeviceProfiles.r02),
      );
    });

    test('selects R08+ model names as a candidate profile', () {
      final profile = ColmiDeviceProfiles.matchAdvertisementName('COLMI R10');

      expect(profile, same(ColmiDeviceProfiles.r08Plus));
      expect(profile!.support, RingProfileSupport.candidate);
    });
  });

  group('COLMI Big Data sleep history', () {
    test('builds the all-history sleep request', () {
      expect(ColmiBigData.sleepHistoryRequest(), <int>[
        0xbc,
        0x27,
        0x01,
        0x00,
        0xff,
        0x00,
        0xff,
      ]);
    });

    test('reassembles fragmented history notifications', () {
      final reassembler = ColmiBigDataReassembler();
      expect(reassembler.add(<int>[0xbc, 0x27, 0x03, 0x00]), isNull);
      final message = reassembler.add(<int>[0xff, 0xff, 10, 20, 30]);

      expect(message?.dataId, ColmiBigData.sleepDataId);
      expect(message?.usesCrcSentinel, isTrue);
      expect(message?.payload, <int>[10, 20, 30]);
    });

    test('decodes stage spans and drops padding nights', () {
      final history = parseColmiSleepHistory(<int>[
        2,
        ..._night(0, -30, 420, <List<int>>[
          <int>[2, 45],
          <int>[3, 90],
          <int>[4, 30],
          <int>[5, 10],
        ]),
        ..._night(1, 9000, 8000, const <List<int>>[]),
      ]);

      expect(history.nights, hasLength(1));
      final night = history.nights.single;
      expect(night.daysAgo, 0);
      expect(night.sleepStartMinute, -30);
      expect(night.sleepEndMinute, 420);
      expect(night.stages.map((stage) => stage.stage), <RingSleepStage>[
        RingSleepStage.light,
        RingSleepStage.deep,
        RingSleepStage.rem,
        RingSleepStage.awake,
      ]);
    });
  });
}

List<int> _night(
  int daysAgo,
  int startMinute,
  int endMinute,
  List<List<int>> stages,
) => <int>[
  daysAgo,
  4 + stages.length * 2,
  startMinute & 0xff,
  (startMinute >> 8) & 0xff,
  endMinute & 0xff,
  (endMinute >> 8) & 0xff,
  for (final stage in stages) ...stage,
];
