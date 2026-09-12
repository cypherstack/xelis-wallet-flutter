import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../api/errors/xelis_wallet_exception.dart';
import '../../api/xswd/xelis_xswd.dart';
import '../../generated/rust_bridge/api/models/xswd_dtos.dart' as generated;
import 'xelis_error_adapter.dart';

XelisXswdApplication xelisXswdApplicationFromGenerated(
  generated.AppInfo application, {
  Object? sessionIdentity,
}) => sessionIdentity == null
    ? XelisXswdApplication(
        id: application.id,
        name: application.name,
        description: application.description,
        url: application.url,
        permissions: application.permissions.map(
          (name, policy) =>
              MapEntry(name, _permissionPolicyFromGenerated(policy)),
        ),
        isRelayer: application.isRelayer,
      )
    : xelisXswdApplicationWithSessionIdentity(
        sessionIdentity: sessionIdentity,
        id: application.id,
        name: application.name,
        description: application.description,
        url: application.url,
        permissions: application.permissions.map(
          (name, policy) =>
              MapEntry(name, _permissionPolicyFromGenerated(policy)),
        ),
        isRelayer: application.isRelayer,
      );

typedef GeneratedXswdApplicationAdapter = XelisXswdApplication Function(
  generated.AppInfo application,
);

XelisXswdRequest xelisXswdRequestFromGenerated(
  generated.XswdRequestSummary request, {
  XelisXswdProjectionLimits limits = const XelisXswdProjectionLimits(),
  GeneratedXswdApplicationAdapter applicationAdapter =
      xelisXswdApplicationFromGenerated,
}) {
  final (kind, payload) = switch (request.eventType) {
    generated.XswdRequestType_Application() => (
      XelisXswdRequestKind.application,
      null,
    ),
    generated.XswdRequestType_Permission(:final field0) => (
      XelisXswdRequestKind.permission,
      _xswdPayloadFromGenerated(field0, limits),
    ),
    generated.XswdRequestType_PrefetchPermissions(:final field0) => (
      XelisXswdRequestKind.prefetchPermissions,
      _xswdPayloadFromGenerated(field0, limits),
    ),
    generated.XswdRequestType_CancelRequest() => (
      XelisXswdRequestKind.cancel,
      null,
    ),
    generated.XswdRequestType_AppDisconnect() => (
      XelisXswdRequestKind.applicationDisconnect,
      null,
    ),
  };

  final authored = XelisXswdRequest(
    kind: kind,
    application: applicationAdapter(request.applicationInfo),
    payload: payload,
  );
  // Validate the semantic envelope before any untrusted request reaches the
  // consumer callback. Method-specific parameters remain uninterpreted.
  switch (kind) {
    case XelisXswdRequestKind.permission:
      authored.permissionRequest;
    case XelisXswdRequestKind.prefetchPermissions:
      authored.prefetchPermissionsRequest;
    case XelisXswdRequestKind.application ||
        XelisXswdRequestKind.cancel ||
        XelisXswdRequestKind.applicationDisconnect:
      break;
  }
  return authored;
}

XelisXswdObjectValue _xswdPayloadFromGenerated(
  generated.NativeXswdPayload payload,
  XelisXswdProjectionLimits limits,
) {
  final decoder = _XswdPayloadDecoder(payload.tokens, limits);
  final value = decoder.decode();
  if (value is! XelisXswdObjectValue) {
    throw StateError('Invalid XSWD payload root.');
  }
  return value;
}

final class _XswdPayloadDecoder {
  _XswdPayloadDecoder(this._tokens, this._limits);

  final List<generated.NativeXswdPayloadToken> _tokens;
  final XelisXswdProjectionLimits _limits;
  var _index = 0;
  var _totalTextBytes = 0;

  XelisXswdValue decode() {
    if (_tokens.isEmpty || _tokens.length > _limits.maxTokens) {
      throw StateError('Invalid XSWD payload token count.');
    }
    final value = _readValue(1);
    if (_index != _tokens.length) {
      throw StateError('Invalid trailing XSWD payload tokens.');
    }
    return value;
  }

  XelisXswdValue _readValue(int depth) {
    if (depth > _limits.maxDepth) {
      throw StateError('Invalid XSWD payload depth.');
    }

    final token = _take();
    return switch (token.kind) {
      generated.NativeXswdPayloadTokenKind.null_ => _readNull(token),
      generated.NativeXswdPayloadTokenKind.bool => _readBool(token),
      generated.NativeXswdPayloadTokenKind.stringValue => _readString(token),
      generated.NativeXswdPayloadTokenKind.integer => _readInteger(token),
      generated.NativeXswdPayloadTokenKind.float => _readFloat(token),
      generated.NativeXswdPayloadTokenKind.arrayStart => _readArray(
        _readLength(token),
        depth,
      ),
      generated.NativeXswdPayloadTokenKind.objectStart => _readObject(
        _readLength(token),
        depth,
      ),
      generated.NativeXswdPayloadTokenKind.objectKey => throw StateError(
        'Unexpected XSWD payload object key.',
      ),
    };
  }

  XelisXswdNullValue _readNull(generated.NativeXswdPayloadToken token) {
    _validateTokenFields(token);
    return const XelisXswdNullValue();
  }

  XelisXswdBoolValue _readBool(generated.NativeXswdPayloadToken token) {
    _validateTokenFields(token, hasBool: true);
    return XelisXswdBoolValue(token.boolValue!);
  }

  XelisXswdStringValue _readString(generated.NativeXswdPayloadToken token) {
    _validateTokenFields(token, hasText: true);
    _addText(token.textValue!);
    return XelisXswdStringValue(token.textValue!);
  }

  XelisXswdIntegerValue _readInteger(generated.NativeXswdPayloadToken token) {
    _validateTokenFields(token, hasText: true);
    return XelisXswdIntegerValue(_parseCanonicalInteger(token.textValue!));
  }

  XelisXswdFloatValue _readFloat(generated.NativeXswdPayloadToken token) {
    _validateTokenFields(token, hasFloat: true);
    return XelisXswdFloatValue(_validateFloat(token.floatValue!));
  }

  int _readLength(generated.NativeXswdPayloadToken token) {
    _validateTokenFields(token, hasLength: true);
    return token.length!;
  }

  XelisXswdArrayValue _readArray(int length, int depth) {
    _validateContainerLength(length);
    final values = <XelisXswdValue>[];
    for (var index = 0; index < length; index++) {
      values.add(_readValue(depth + 1));
    }
    return XelisXswdArrayValue(values);
  }

  XelisXswdObjectValue _readObject(int length, int depth) {
    _validateContainerLength(length);
    final fields = <String, XelisXswdValue>{};
    for (var index = 0; index < length; index++) {
      final keyToken = _take();
      if (keyToken.kind != generated.NativeXswdPayloadTokenKind.objectKey) {
        throw StateError('Missing XSWD payload object key.');
      }
      _validateTokenFields(keyToken, hasText: true);
      final key = keyToken.textValue!;
      _addText(key);
      if (fields.containsKey(key)) {
        throw StateError('Duplicate XSWD payload object key.');
      }
      fields[key] = _readValue(depth + 1);
    }
    return XelisXswdObjectValue(fields);
  }

  generated.NativeXswdPayloadToken _take() {
    if (_index >= _tokens.length) {
      throw StateError('Truncated XSWD payload token stream.');
    }
    return _tokens[_index++];
  }

  void _validateTokenFields(
    generated.NativeXswdPayloadToken token, {
    bool hasBool = false,
    bool hasText = false,
    bool hasFloat = false,
    bool hasLength = false,
  }) {
    if ((token.boolValue != null) != hasBool ||
        (token.textValue != null) != hasText ||
        (token.floatValue != null) != hasFloat ||
        (token.length != null) != hasLength) {
      throw StateError('Invalid XSWD payload token fields.');
    }
  }

  void _validateContainerLength(int length) {
    if (length < 0 || length > _limits.maxContainerMembers) {
      throw StateError('Invalid XSWD payload container length.');
    }
  }

  void _addText(String value) {
    final length = utf8.encode(value).length;
    if (length > _limits.maxTextBytes) {
      throw StateError('Invalid XSWD payload text length.');
    }
    _totalTextBytes += length;
    if (_totalTextBytes > _limits.maxTotalTextBytes) {
      throw StateError('Invalid XSWD payload total text length.');
    }
  }

  BigInt _parseCanonicalInteger(String decimalValue) {
    final BigInt value;
    try {
      value = BigInt.parse(decimalValue);
    } on FormatException {
      throw StateError('Invalid XSWD payload integer.');
    }
    if (value.toString() != decimalValue) {
      throw StateError('Non-canonical XSWD payload integer.');
    }
    return value;
  }

  double _validateFloat(double value) {
    if (!value.isFinite) {
      throw StateError('Invalid XSWD payload floating-point value.');
    }
    return value;
  }
}

Map<String, generated.PermissionPolicy> generatedXswdPermissionsFromXelis(
  Map<String, XelisXswdPermissionPolicy> permissions, {
  required XelisWalletOperation operation,
}) {
  _validateXswdPermissionNames(permissions.keys, operation: operation);
  return permissions.map(
    (name, policy) => MapEntry(name, _permissionPolicyToGenerated(policy)),
  );
}

generated.ApplicationDataRelayer generatedXswdRelayerFromXelis(
  XelisXswdRelayer relayer, {
  required XelisWalletOperation operation,
}) {
  _validateXswdPermissionNames(relayer.permissions, operation: operation);
  return generated.ApplicationDataRelayer(
    id: relayer.id,
    name: relayer.name,
    description: relayer.description,
    url: relayer.url,
    permissions: List.of(relayer.permissions),
    relayer: relayer.relayer,
    encryptionMode: _encryptionToGenerated(
      relayer.encryption,
      operation: operation,
    ),
  );
}

void _validateXswdPermissionNames(
  Iterable<String> permissions, {
  required XelisWalletOperation operation,
}) {
  if (permissions.any((name) => name.startsWith('wallet.'))) {
    throw xelisOperationPreconditionException(
      operation: operation,
      code: XelisWalletErrorCode.invalidInput,
      nativeKind: 'XSWD_PERMISSION_NAME_INVALID',
      diagnosticMessage:
          'XSWD permission names must use the unprefixed method form.',
    );
  }
}

/// Private generated callback bundle used only by bridge adapters.
final class GeneratedXswdCallbacks {
  const GeneratedXswdCallbacks({
    required this.cancelRequest,
    required this.applicationRequest,
    required this.permissionRequest,
    required this.prefetchPermissionsRequest,
    required this.applicationDisconnect,
  });

  final Future<generated.XswdNotificationCallbackOutcome> Function(
    generated.XswdRequestSummary,
    bool,
  )
  cancelRequest;
  final Future<generated.XswdDecisionCallbackOutcome> Function(
    generated.XswdRequestSummary,
  )
  applicationRequest;
  final Future<generated.XswdDecisionCallbackOutcome> Function(
    generated.XswdRequestSummary,
  )
  permissionRequest;
  final Future<generated.XswdDecisionCallbackOutcome> Function(
    generated.XswdRequestSummary,
  )
  prefetchPermissionsRequest;
  final Future<generated.XswdNotificationCallbackOutcome> Function(
    generated.XswdRequestSummary,
  )
  applicationDisconnect;
}

GeneratedXswdCallbacks generatedXswdCallbacksFromXelis(
  XelisXswdCallbacks callbacks, {
  required GeneratedXswdApplicationAdapter applicationAdapter,
  required void Function(generated.AppInfo application)
  onApplicationDecisionStarted,
  required void Function(
    generated.AppInfo application,
    generated.XswdDecisionCallbackOutcome outcome,
  )
  onApplicationDecisionCompleted,
  required void Function(
    generated.AppInfo application,
    bool cancelledApplicationAdmission,
  )
  onCancelRequestStarted,
  required void Function(generated.AppInfo application)
  onApplicationDisconnectStarted,
}) => GeneratedXswdCallbacks(
  cancelRequest: (request, cancelledApplicationAdmission) {
    onCancelRequestStarted(
      request.applicationInfo,
      cancelledApplicationAdmission,
    );
    return _runNotificationCallback(
      callbacks.onCancelRequest,
      request,
      timeout: callbacks.timeout,
      limits: callbacks.projectionLimits,
      applicationAdapter: applicationAdapter,
    );
  },
  applicationRequest: (request) => _runApplicationDecisionCallback(
    callbacks.onApplicationRequest,
    request,
    timeout: callbacks.timeout,
    limits: callbacks.projectionLimits,
    applicationAdapter: applicationAdapter,
    onStarted: onApplicationDecisionStarted,
    onCompleted: onApplicationDecisionCompleted,
  ),
  permissionRequest: (request) => _runDecisionCallback(
    callbacks.onPermissionRequest,
    request,
    timeout: callbacks.timeout,
    limits: callbacks.projectionLimits,
    applicationAdapter: applicationAdapter,
  ),
  prefetchPermissionsRequest: (request) {
    final selective = callbacks.onPrefetchPermissionsReview;
    if (selective != null) {
      return _runPrefetchDecisionCallback(
        selective,
        request,
        timeout: callbacks.timeout,
        limits: callbacks.projectionLimits,
        applicationAdapter: applicationAdapter,
      );
    }
    return _runDecisionCallback(
      callbacks.onPrefetchPermissionsRequest,
      request,
      timeout: callbacks.timeout,
      limits: callbacks.projectionLimits,
      applicationAdapter: applicationAdapter,
    );
  },
  applicationDisconnect: (request) {
    onApplicationDisconnectStarted(request.applicationInfo);
    return _runNotificationCallback(
      callbacks.onApplicationDisconnect,
      request,
      timeout: callbacks.timeout,
      limits: callbacks.projectionLimits,
      applicationAdapter: applicationAdapter,
    );
  },
);

Future<generated.XswdDecisionCallbackOutcome> _runApplicationDecisionCallback(
  XelisXswdDecisionCallback callback,
  generated.XswdRequestSummary request, {
  required Duration timeout,
  required XelisXswdProjectionLimits limits,
  required GeneratedXswdApplicationAdapter applicationAdapter,
  required void Function(generated.AppInfo application) onStarted,
  required void Function(
    generated.AppInfo application,
    generated.XswdDecisionCallbackOutcome outcome,
  )
  onCompleted,
}) async {
  onStarted(request.applicationInfo);
  final outcome = await _runDecisionCallback(
    callback,
    request,
    timeout: timeout,
    limits: limits,
    applicationAdapter: applicationAdapter,
  );
  onCompleted(request.applicationInfo, outcome);
  return outcome;
}

generated.NativeXswdProjectionLimits generatedXswdLimitsFromXelis(
  XelisXswdCallbacks callbacks, {
  required XelisWalletOperation operation,
}) {
  if (callbacks.timeout.inMicroseconds <= 0) {
    throw xelisOperationPreconditionException(
      operation: operation,
      code: XelisWalletErrorCode.invalidInput,
      nativeKind: 'XSWD_CALLBACK_TIMEOUT_INVALID',
      diagnosticMessage: 'The XSWD callback timeout must be positive.',
    );
  }

  final limits = callbacks.projectionLimits;
  final valid =
      limits.maxDepth > 0 &&
      limits.maxDepth <= XelisXswdProjectionLimits.technicalMaxDepth &&
      limits.maxTokens > 0 &&
      limits.maxTokens <= XelisXswdProjectionLimits.technicalMaxTokens &&
      limits.maxContainerMembers > 0 &&
      limits.maxContainerMembers <=
          XelisXswdProjectionLimits.technicalMaxContainerMembers &&
      limits.maxTextBytes > 0 &&
      limits.maxTextBytes <= XelisXswdProjectionLimits.technicalMaxTextBytes &&
      limits.maxTotalTextBytes >= limits.maxTextBytes &&
      limits.maxTotalTextBytes <=
          XelisXswdProjectionLimits.technicalMaxTotalTextBytes;
  if (!valid) {
    throw xelisOperationPreconditionException(
      operation: operation,
      code: XelisWalletErrorCode.invalidInput,
      nativeKind: 'XSWD_PROJECTION_LIMITS_INVALID',
      diagnosticMessage:
          'XSWD projection limits must be positive, internally consistent, '
          'and within the documented technical ceilings.',
    );
  }

  return generated.NativeXswdProjectionLimits(
    maxDepth: limits.maxDepth,
    maxTokens: limits.maxTokens,
    maxContainerMembers: limits.maxContainerMembers,
    maxTextBytes: limits.maxTextBytes,
    maxTotalTextBytes: limits.maxTotalTextBytes,
  );
}

Future<generated.XswdNotificationCallbackOutcome> _runNotificationCallback(
  XelisXswdNotificationCallback callback,
  generated.XswdRequestSummary request, {
  required Duration timeout,
  required XelisXswdProjectionLimits limits,
  required GeneratedXswdApplicationAdapter applicationAdapter,
}) async {
  final XelisXswdRequest authored;
  try {
    authored = xelisXswdRequestFromGenerated(
      request,
      limits: limits,
      applicationAdapter: applicationAdapter,
    );
  } catch (_) {
    return generated.XswdNotificationCallbackOutcome.invalidPayload;
  }
  try {
    await Future<void>.sync(() => callback(authored)).timeout(timeout);
    return generated.XswdNotificationCallbackOutcome.completed;
  } on TimeoutException {
    return generated.XswdNotificationCallbackOutcome.timeout;
  } catch (_) {
    return generated.XswdNotificationCallbackOutcome.exception;
  }
}

Future<generated.XswdDecisionCallbackOutcome> _runDecisionCallback(
  XelisXswdDecisionCallback callback,
  generated.XswdRequestSummary request, {
  required Duration timeout,
  required XelisXswdProjectionLimits limits,
  required GeneratedXswdApplicationAdapter applicationAdapter,
}) async {
  final XelisXswdRequest authored;
  try {
    authored = xelisXswdRequestFromGenerated(
      request,
      limits: limits,
      applicationAdapter: applicationAdapter,
    );
  } catch (_) {
    return const generated.XswdDecisionCallbackOutcome.invalidPayload();
  }
  try {
    final decision = await Future<XelisXswdDecision>.sync(
      () => callback(authored),
    ).timeout(timeout);
    return _decisionOutcomeToGenerated(decision);
  } on TimeoutException {
    return const generated.XswdDecisionCallbackOutcome.timeout();
  } catch (_) {
    return const generated.XswdDecisionCallbackOutcome.exception();
  }
}

Future<generated.XswdDecisionCallbackOutcome> _runPrefetchDecisionCallback(
  XelisXswdPrefetchDecisionCallback callback,
  generated.XswdRequestSummary request, {
  required Duration timeout,
  required XelisXswdProjectionLimits limits,
  required GeneratedXswdApplicationAdapter applicationAdapter,
}) async {
  final XelisXswdPrefetchPermissionsRequest authored;
  try {
    final source = xelisXswdRequestFromGenerated(
      request,
      limits: limits,
      applicationAdapter: applicationAdapter,
    );
    authored = source.prefetchPermissionsRequest!;
  } catch (_) {
    return const generated.XswdDecisionCallbackOutcome.invalidPayload();
  }
  try {
    final decision = await Future<XelisXswdPrefetchDecision>.sync(
      () => callback(authored),
    ).timeout(timeout);
    return switch (decision) {
      XelisXswdPrefetchNoChange() =>
        const generated.XswdDecisionCallbackOutcome.prefetchNoChange(),
      XelisXswdPrefetchGrant(:final permissions) =>
        generated.XswdDecisionCallbackOutcome.prefetchGrant(
          permissions: permissions,
        ),
    };
  } on TimeoutException {
    return const generated.XswdDecisionCallbackOutcome.timeout();
  } catch (_) {
    return const generated.XswdDecisionCallbackOutcome.exception();
  }
}

XelisXswdPermissionPolicy _permissionPolicyFromGenerated(
  generated.PermissionPolicy policy,
) => switch (policy) {
  generated.PermissionPolicy.ask => XelisXswdPermissionPolicy.ask,
  generated.PermissionPolicy.accept => XelisXswdPermissionPolicy.accept,
  generated.PermissionPolicy.reject => XelisXswdPermissionPolicy.reject,
};

generated.PermissionPolicy _permissionPolicyToGenerated(
  XelisXswdPermissionPolicy policy,
) => switch (policy) {
  XelisXswdPermissionPolicy.ask => generated.PermissionPolicy.ask,
  XelisXswdPermissionPolicy.accept => generated.PermissionPolicy.accept,
  XelisXswdPermissionPolicy.reject => generated.PermissionPolicy.reject,
};

generated.XswdDecisionCallbackOutcome _decisionOutcomeToGenerated(
  XelisXswdDecision decision,
) => switch (decision) {
  XelisXswdDecision.accept =>
    const generated.XswdDecisionCallbackOutcome.accept(),
  XelisXswdDecision.reject =>
    const generated.XswdDecisionCallbackOutcome.reject(),
  XelisXswdDecision.alwaysAccept =>
    const generated.XswdDecisionCallbackOutcome.alwaysAccept(),
  XelisXswdDecision.alwaysReject =>
    const generated.XswdDecisionCallbackOutcome.alwaysReject(),
};

generated.EncryptionMode? _encryptionToGenerated(
  XelisXswdEncryption? encryption, {
  required XelisWalletOperation operation,
}) {
  if (encryption == null) {
    return null;
  }
  if (encryption.key.length != 32 ||
      encryption.key.any((byte) => byte < 0 || byte > 255)) {
    throw xelisOperationPreconditionException(
      operation: operation,
      code: XelisWalletErrorCode.invalidInput,
      nativeKind: 'XSWD_ENCRYPTION_KEY_INVALID',
      diagnosticMessage: 'An XSWD encryption key must contain 32 bytes.',
    );
  }

  final key = Uint8List.fromList(encryption.key);
  return switch (encryption.algorithm) {
    XelisXswdEncryptionAlgorithm.aes => generated.EncryptionMode.aes(key: key),
    XelisXswdEncryptionAlgorithm.chacha20Poly1305 =>
      generated.EncryptionMode.chacha20Poly1305(key: key),
  };
}
