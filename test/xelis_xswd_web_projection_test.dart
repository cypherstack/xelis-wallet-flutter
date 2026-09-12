import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_xswd_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/xswd_dtos.dart'
    as generated;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('XSWD projection preserves integers beyond JavaScript safety', () {
    const decimal = '9007199254740993';
    final request = generated.XswdRequestSummary(
      eventType: generated.XswdRequestType.permission(
        const generated.NativeXswdPayload(
          tokens: [
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.objectStart,
              length: 3,
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.objectKey,
              textValue: 'jsonrpc',
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.stringValue,
              textValue: '2.0',
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.objectKey,
              textValue: 'method',
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.stringValue,
              textValue: 'get_balance',
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.objectKey,
              textValue: 'params',
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.objectStart,
              length: 1,
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.objectKey,
              textValue: 'amount',
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.integer,
              textValue: decimal,
            ),
          ],
        ),
      ),
      applicationInfo: generated.AppInfo(
        sessionRef: BigInt.one,
        id: 'app',
        name: 'app',
        description: '',
        url: null,
        permissions: {},
        isRelayer: true,
      ),
    );

    final authored = xelisXswdRequestFromGenerated(request);
    final permission = authored.permissionRequest!;
    final parameters = permission.parameters! as XelisXswdObjectValue;
    final amount = parameters.fields['amount'] as XelisXswdIntegerValue;

    expect(identical(permission.source, authored), isTrue);
    expect(permission.method, 'get_balance');
    expect(amount.value, BigInt.parse(decimal));
    expect(amount.value.toString(), decimal);
    expect(authored.toString(), isNot(contains(decimal)));
    expect(permission.toString(), isNot(contains('get_balance')));
    expect(amount.toString(), isNot(contains(decimal)));
  });
}
