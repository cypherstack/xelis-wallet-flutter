import 'dart:async';

import '../../api/assets/xelis_wallet_asset.dart';
import '../../api/address_book/xelis_address_book.dart';
import '../../api/data/xelis_data_element.dart';
import '../../api/errors/xelis_wallet_exception.dart';
import '../../api/events/xelis_wallet_business_event_subscription.dart';
import '../../api/history/xelis_wallet_history_filter.dart';
import '../../api/models/xelis_network.dart';
import '../../api/multisig/xelis_wallet_multisig.dart';
import '../../api/precomputed/xelis_precomputed_table_type.dart';
import '../../api/runtime/xelis_daemon_info.dart';
import '../../api/runtime/xelis_wallet_runtime_event_subscription.dart';
import '../../api/seed/seed_language.dart';
import '../../api/transactions/xelis_wallet_prepared_transaction.dart';
import '../../api/transactions/xelis_wallet_transaction.dart';
import '../../api/wallet/xelis_wallet.dart';
import '../../api/xswd/xelis_xswd.dart';
import '../../generated/rust_bridge/api/error.dart' as generated_error;
import '../../generated/rust_bridge/api/models/address_book_v2.dart'
    as generated_address_book;
import '../../generated/rust_bridge/api/models/business_event_dtos.dart'
    as generated_business;
import '../../generated/rust_bridge/api/models/runtime_dtos.dart'
    as generated_runtime;
import '../../generated/rust_bridge/api/models/wallet_dtos.dart'
    as generated_wallet;
import '../../generated/rust_bridge/api/models/xswd_dtos.dart'
    as generated_xswd;
import '../../generated/rust_bridge/api/wallet.dart' as generated;
import 'seed_search_engine_adapter.dart';
import 'xelis_daemon_info_adapter.dart';
import 'xelis_error_adapter.dart';
import 'xelis_network_adapter.dart';
import 'xelis_precomputed_table_type_adapter.dart';
import 'xelis_runtime_utility_adapter.dart';
import 'xelis_wallet_business_event_adapter.dart';
import 'xelis_wallet_runtime_event_adapter.dart';
import 'xelis_xswd_adapter.dart';

part 'xelis_wallet_xswd_state.dart';

const _xswdObservationTimeout = Duration(seconds: 2);
const _xswdObservationInterval = Duration(milliseconds: 100);

generated_business.NativeWalletExtraDataDisclosure
_generatedExtraDataDisclosure(XelisWalletExtraDataDisclosure disclosure) =>
    switch (disclosure) {
      XelisWalletExtraDataDisclosure.redacted =>
        generated_business.NativeWalletExtraDataDisclosure.redacted,
      XelisWalletExtraDataDisclosure.metadata =>
        generated_business.NativeWalletExtraDataDisclosure.metadata,
      XelisWalletExtraDataDisclosure.detailed =>
        generated_business.NativeWalletExtraDataDisclosure.detailed,
    };

Future<XelisWallet> createNativeXelisWallet({
  required String walletPath,
  required String password,
  required XelisNetwork network,
  required XelisPrecomputedTableType precomputedTableType,
  required XelisWalletOperation operation,
  String? seed,
  String? privateKey,
  String? precomputedTablesPath,
}) async {
  if (seed != null && privateKey != null) {
    throw ArgumentError('Only one wallet recovery input may be provided.');
  }

  final delegate = await guardXelisFuture(
    () => generated.createXelisWallet(
      name: '',
      directory: walletPath,
      password: password,
      network: generatedNetworkFromXelis(network),
      seed: seed,
      privateKey: privateKey,
      precomputedTablesPath: precomputedTablesPath,
      precomputedTableType: generatedPrecomputedTableTypeFromXelis(
        precomputedTableType,
      ),
    ),
    boundary: XelisErrorBoundary(
      source: XelisWalletErrorSource.xelisWallet,
      operation: operation,
    ),
  );
  return NativeXelisWallet(delegate);
}

Future<XelisWallet> openNativeXelisWallet({
  required String walletPath,
  required String password,
  required XelisNetwork network,
  required XelisPrecomputedTableType precomputedTableType,
  String? precomputedTablesPath,
}) async {
  final delegate = await guardXelisFuture(
    () => generated.openXelisWallet(
      name: '',
      directory: walletPath,
      password: password,
      network: generatedNetworkFromXelis(network),
      precomputedTablesPath: precomputedTablesPath,
      precomputedTableType: generatedPrecomputedTableTypeFromXelis(
        precomputedTableType,
      ),
    ),
    boundary: const XelisErrorBoundary(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.walletOpen,
    ),
  );
  return NativeXelisWallet(delegate);
}

/// Private bridge implementation of the authored wallet handle.
///
/// The class is public only for package-internal tests and is not exported by
/// the supported root library.
final class NativeXelisWallet implements XelisWallet {
  NativeXelisWallet(this._delegate);

  final generated.XelisWallet _delegate;
  Future<void>? _closeFuture;
  var _terminal = false;
  var _closeInProgress = false;
  var _disposedByWrapper = false;
  final _runtimeEventSubscriptions =
      <NativeXelisWalletRuntimeEventSubscription>{};
  final _businessEventSubscriptions =
      <NativeXelisWalletBusinessEventSubscription>{};
  final _preparedCapabilities = Expando<_NativePreparedTransactionCapability>(
    'xelis-wallet-prepared-transaction',
  );
  XelisWalletPreparedTransaction? _activePreparedTransaction;
  final _multisigRequestCapabilities =
      Expando<_NativeMultisigRequestCapability>(
        'xelis-wallet-multisig-request',
      );
  final _multisigShareCapabilities = Expando<_NativeMultisigShareCapability>(
    'xelis-wallet-multisig-share',
  );
  final _xswdState = _NativeXswdState();
  final _xswdApplicationOperations = <String>{};
  var _xswdLifecycleOperationInProgress = false;
  XelisWalletMultisigSigningRequest? _activePendingMultisigRequest;

  @override
  bool get isDisposed => _disposedByWrapper || _delegate.isDisposed;

  @override
  String get address {
    _ensureActive();
    return guardXelisCall(
      _delegate.getAddressStr,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAddressRead,
      ),
    );
  }

  @override
  XelisNetwork get network {
    _ensureActive();
    final generatedNetwork = guardXelisCall(
      _delegate.getNetwork,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletNetworkRead,
      ),
    );
    return xelisNetworkFromGenerated(generatedNetwork);
  }

  @override
  Future<String> getSeed({SeedLanguage language = SeedLanguage.english}) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.getSeed(
        languageIndex: BigInt.from(rustSeedLanguageIndex(language)),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletSeedRead,
      ),
    );
  }

  @override
  Future<void> verifyPassword({required String password}) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.isValidPassword(password: password),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletPasswordVerify,
      ),
    );
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletPasswordChange,
      ),
    );
  }

  @override
  Future<void> setOnline({
    required String daemonAddress,
    XelisWalletConnectionOptions options = const XelisWalletConnectionOptions(),
  }) {
    _ensureActive();
    final timeoutMillis = options.timeout.inMilliseconds;
    if (options.timeout.inMicroseconds <= 0 || timeoutMillis <= 0) {
      throw xelisOperationPreconditionException(
        operation: XelisWalletOperation.walletNetworkConnect,
        code: XelisWalletErrorCode.invalidInput,
        nativeKind: 'NETWORK_TIMEOUT_INVALID',
        diagnosticMessage: 'The connection timeout must be positive and at least one millisecond.',
      );
    }
    final timeoutMillisBigInt = BigInt.from(timeoutMillis);
    if (timeoutMillisBigInt > _maxUnsigned64) {
      throw xelisOperationPreconditionException(
        operation: XelisWalletOperation.walletNetworkConnect,
        code: XelisWalletErrorCode.invalidInput,
        nativeKind: 'NETWORK_TIMEOUT_INVALID',
        diagnosticMessage: 'The connection timeout exceeds the u64 range.',
      );
    }
    return guardXelisFuture(
      () => _delegate.onlineMode(
        daemonAddress: daemonAddress,
        options: generated_runtime.NativeWalletConnectionOptions(
          timeoutMillis: timeoutMillisBigInt,
          reconnectPolicy: switch (options.reconnectPolicy) {
            XelisWalletReconnectPolicy.applicationManaged =>
              generated_runtime.NativeWalletReconnectPolicy.applicationManaged,
            XelisWalletReconnectPolicy.upstreamManagedExperimental =>
              generated_runtime
                  .NativeWalletReconnectPolicy
                  .upstreamManagedExperimental,
          },
        ),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletNetworkConnect,
      ),
    );
  }

  @override
  Future<void> setOffline() {
    _ensureActive();
    return guardXelisFuture(
      _delegate.offlineMode,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletNetworkDisconnect,
      ),
    );
  }

  @override
  Future<bool> isOnline() {
    _ensureActive();
    return guardXelisFuture(
      _delegate.isOnline,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletNetworkStatusRead,
      ),
    );
  }

  @override
  Future<bool> isSyncing() {
    _ensureActive();
    return guardXelisFuture(
      _delegate.isSyncing,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletSyncStatusRead,
      ),
    );
  }

  @override
  Future<void> startXswd({required XelisXswdCallbacks callbacks}) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletXswdStart;
    final generatedLimits = generatedXswdLimitsFromXelis(
      callbacks,
      operation: operation,
    );
    final generatedCallbacks = _xswdState.generatedCallbacks(
      callbacks,
      onDecisionCompleted: (request, outcome) =>
          _scheduleXswdStateObservation(callbacks, request, outcome),
    );
    await _runXswdLifecycleOperation(
      () => guardXelisFuture(
        () => _delegate.startXswd(
          projectionLimits: generatedLimits,
          cancelRequestDartCallback: generatedCallbacks.cancelRequest,
          requestApplicationDartCallback: generatedCallbacks.applicationRequest,
          requestPermissionDartCallback: generatedCallbacks.permissionRequest,
          requestPrefetchPermissionsDartCallback:
              generatedCallbacks.prefetchPermissionsRequest,
          appDisconnectDartCallback: generatedCallbacks.applicationDisconnect,
        ),
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: operation,
        ),
      ),
      operation: operation,
    );
  }

  @override
  Future<void> stopXswd() async {
    _ensureActive();
    const operation = XelisWalletOperation.walletXswdStop;
    await _runXswdLifecycleOperation(() async {
      await guardXelisFuture(
        _delegate.stopXswd,
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: operation,
        ),
      );
      _xswdState.invalidateAll();
    }, operation: operation);
  }

  @override
  Future<XelisXswdState> getXswdState() async {
    _ensureActive();
    return guardXelisFuture(
      () async {
        while (true) {
          final revision = _xswdState.revision;
          final isRunning = await _delegate.isXswdRunning();
          if (revision != _xswdState.revision) {
            continue;
          }
          if (!isRunning) {
            _xswdState.reconcile(const <generated_xswd.AppInfo>[]);
            return XelisXswdState(isRunning: false, applications: const []);
          }
          final applications = await _delegate.getApplicationPermissions();
          if (revision != _xswdState.revision) {
            continue;
          }
          final authoredApplications = applications
              .map(
                (application) => _xswdState.adaptApplication(
                  application,
                  observedInState: true,
                ),
              )
              .toList(growable: false);
          _xswdState.reconcile(applications);
          return XelisXswdState(
            isRunning: true,
            applications: authoredApplications,
          );
        }
      },
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletXswdStateRead,
      ),
    );
  }

  @override
  Future<void> addXswdRelayer({
    required XelisXswdRelayer relayer,
    required XelisXswdCallbacks callbacks,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletXswdRelayerAdd;
    final generatedRelayer = generatedXswdRelayerFromXelis(
      relayer,
      operation: operation,
    );
    final generatedLimits = generatedXswdLimitsFromXelis(
      callbacks,
      operation: operation,
    );
    final generatedCallbacks = _xswdState.generatedCallbacks(
      callbacks,
      onDecisionCompleted: (request, outcome) =>
          _scheduleXswdStateObservation(callbacks, request, outcome),
    );
    await _runXswdApplicationOperation(relayer.id, () async {
      await guardXelisFuture(
        () => _delegate.addXswdRelayer(
          appData: generatedRelayer,
          projectionLimits: generatedLimits,
          cancelRequestDartCallback: generatedCallbacks.cancelRequest,
          requestApplicationDartCallback: generatedCallbacks.applicationRequest,
          requestPermissionDartCallback: generatedCallbacks.permissionRequest,
          requestPrefetchPermissionsDartCallback:
              generatedCallbacks.prefetchPermissionsRequest,
          appDisconnectDartCallback: generatedCallbacks.applicationDisconnect,
        ),
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: operation,
        ),
      );
    }, operation: operation);
  }

  @override
  Future<void> closeXswdApplicationSession({
    required XelisXswdApplication application,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletXswdSessionClose;
    _xswdState.capability(application, operation: operation);
    await _runXswdApplicationOperation(application.id, () async {
      final capability = _xswdState.capability(
        application,
        operation: operation,
      );
      await guardXelisFuture(
        () => _delegate.closeApplicationSession(
          sessionRef: capability.sessionRef,
        ),
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: operation,
        ),
      );
      _xswdState.tombstone(capability);
    }, operation: operation);
  }

  @override
  Future<void> updateXswdApplicationPermissions({
    required XelisXswdApplication application,
    required Map<String, XelisXswdPermissionPolicy> permissions,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletXswdPermissionsUpdate;
    final capability = _xswdState.capability(application, operation: operation);
    await guardXelisFuture(
      () => _delegate.modifyApplicationPermissions(
        sessionRef: capability.sessionRef,
        permissions: generatedXswdPermissionsFromXelis(
          permissions,
          operation: operation,
        ),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
  }

  @override
  Future<XelisXswdApplication> updateXswdApplicationPermission({
    required XelisXswdApplication application,
    required String permission,
    required XelisXswdPermissionPolicy policy,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletXswdPermissionsUpdate;
    final generatedPolicy = generatedXswdPermissionsFromXelis({
      permission: policy,
    }, operation: operation)[permission]!;
    final capability = _xswdState.capability(application, operation: operation);
    final native = await guardXelisFuture(
      () => _delegate.modifyApplicationPermission(
        sessionRef: capability.sessionRef,
        permission: permission,
        policy: generatedPolicy,
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    final current = _xswdState.capability(application, operation: operation);
    if (!identical(current, capability) ||
        native.sessionRef != capability.sessionRef) {
      throw xelisOperationPreconditionException(
        operation: operation,
        code: XelisWalletErrorCode.conflict,
        nativeKind: 'XSWD_SESSION_REFERENCE_INVALID',
        diagnosticMessage:
            'The targeted XSWD permission update returned for a stale or '
            'different application session.',
      );
    }
    return _xswdState.adaptApplication(native, observedInState: true);
  }

  void _scheduleXswdStateObservation(
    XelisXswdCallbacks callbacks,
    XelisXswdRequest request,
    generated_xswd.XswdDecisionCallbackOutcome outcome,
  ) {
    final observer = callbacks.onApplicationStateObservation;
    if (observer == null) {
      return;
    }
    final expectation = _xswdObservationExpectation(request, outcome);
    if (expectation == null) {
      return;
    }
    final sequence = _xswdState.nextObservationSequence();
    final ticket = _xswdState.beginObservation(request.application, sequence);
    if (ticket == null) {
      unawaited(
        _notifyXswdObserver(
          observer,
          XelisXswdApplicationStateStale(request.application, sequence),
        ),
      );
      return;
    }
    unawaited(_observeXswdApplicationState(observer, expectation, ticket));
  }

  Future<void> _observeXswdApplicationState(
    XelisXswdApplicationStateObservationCallback observer,
    _NativeXswdObservationExpectation expectation,
    _NativeXswdObservationTicket ticket,
  ) async {
    final deadline = DateTime.now().add(_xswdObservationTimeout);
    await Future<void>.delayed(_xswdObservationInterval);
    while (true) {
      if (!_xswdState.isObservationCurrent(ticket)) {
        await _notifyXswdObserver(
          observer,
          XelisXswdApplicationStateStale(
            expectation.application,
            ticket.sequence,
          ),
        );
        return;
      }

      final List<generated_xswd.AppInfo> applications;
      try {
        applications = await guardXelisFuture(
          _delegate.getApplicationPermissions,
          boundary: const XelisErrorBoundary(
            source: XelisWalletErrorSource.xelisWallet,
            operation: XelisWalletOperation.walletXswdStateRead,
          ),
        );
      } catch (error) {
        final failure = error is XelisWalletException
            ? error
            : xelisBridgeContractException(
                operation: XelisWalletOperation.walletXswdStateRead,
                nativeKind: 'XSWD_STATE_OBSERVATION_FAILED',
                diagnosticMessage:
                    'The native XSWD state observation failed outside the '
                    'authored error contract.',
              );
        final observation = _xswdState.isObservationCurrent(ticket)
            ? XelisXswdApplicationStateFailed(
                expectation.application,
                ticket.sequence,
                failure,
              )
            : XelisXswdApplicationStateStale(
                expectation.application,
                ticket.sequence,
              );
        await _notifyXswdObserver(observer, observation);
        return;
      }

      if (!_xswdState.isObservationCurrent(ticket)) {
        await _notifyXswdObserver(
          observer,
          XelisXswdApplicationStateStale(
            expectation.application,
            ticket.sequence,
          ),
        );
        return;
      }
      generated_xswd.AppInfo? matching;
      for (final application in applications) {
        if (application.sessionRef == ticket.capability.sessionRef) {
          matching = application;
          break;
        }
      }
      if (matching != null && expectation.matches(matching)) {
        final observed = _xswdState.adaptObservedApplication(matching, ticket);
        if (observed != null) {
          await _notifyXswdObserver(
            observer,
            XelisXswdApplicationStateObserved(observed, ticket.sequence),
          );
          return;
        }
      }

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        await _notifyXswdObserver(
          observer,
          XelisXswdApplicationStateTimedOut(
            expectation.application,
            ticket.sequence,
          ),
        );
        return;
      }
      await Future<void>.delayed(
        remaining < _xswdObservationInterval
            ? remaining
            : _xswdObservationInterval,
      );
    }
  }

  Future<void> _notifyXswdObserver(
    XelisXswdApplicationStateObservationCallback observer,
    XelisXswdApplicationStateObservation observation,
  ) async {
    try {
      await Future<void>.sync(() => observer(observation))
          .timeout(_xswdObservationTimeout);
    } catch (_) {
      // Observation notifications are advisory and never affect XSWD state.
    }
  }

  @override
  Future<XelisWalletRuntimeEventSubscription> subscribeRuntimeEvents() async {
    _ensureActive();
    final delegate = await guardXelisFuture(
      _delegate.subscribeRuntimeEvents,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWalletFlutter,
        operation: XelisWalletOperation.walletEventsSubscribe,
      ),
    );

    late final NativeXelisWalletRuntimeEventSubscription subscription;
    try {
      subscription = NativeXelisWalletRuntimeEventSubscription(
        delegate,
        onTerminated: _runtimeEventSubscriptions.remove,
      );
    } catch (error, stackTrace) {
      // Construction performs one synchronous bridge read (`generation`). If
      // that read fails, no pump exists yet, so cancelling and disposing the
      // otherwise orphaned opaque handle is safe. Cleanup remains best-effort
      // so it never hides the original bridge failure.
      try {
        guardXelisCall(
          delegate.cancel,
          boundary: const XelisErrorBoundary(
            source: XelisWalletErrorSource.xelisWalletFlutter,
            operation: XelisWalletOperation.walletEventsCancel,
          ),
        );
      } catch (_) {}
      try {
        if (!delegate.isDisposed) {
          guardXelisCall(
            delegate.dispose,
            boundary: const XelisErrorBoundary(
              source: XelisWalletErrorSource.xelisWalletFlutter,
              operation: XelisWalletOperation.walletEventsCancel,
            ),
          );
        }
      } catch (_) {}
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (_terminal || isDisposed) {
      await subscription.cancel();
      throw StateError('The XELIS wallet handle is closed.');
    }
    _runtimeEventSubscriptions.add(subscription);
    return subscription;
  }

  @override
  Future<XelisWalletBusinessEventSubscription> subscribeBusinessEvents({
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.redacted,
  }) async {
    _ensureActive();
    final delegate = await guardXelisFuture(
      () => _delegate.subscribeBusinessEvents(
        extraDataDisclosure: _generatedExtraDataDisclosure(extraDataDisclosure),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWalletFlutter,
        operation: XelisWalletOperation.walletBusinessEventsSubscribe,
      ),
    );

    late final NativeXelisWalletBusinessEventSubscription subscription;
    try {
      subscription = NativeXelisWalletBusinessEventSubscription(
        delegate,
        extraDataDisclosure: extraDataDisclosure,
        onTerminated: _businessEventSubscriptions.remove,
      );
    } catch (error, stackTrace) {
      try {
        guardXelisCall(
          delegate.cancel,
          boundary: const XelisErrorBoundary(
            source: XelisWalletErrorSource.xelisWalletFlutter,
            operation: XelisWalletOperation.walletBusinessEventsCancel,
          ),
        );
      } catch (_) {}
      try {
        if (!delegate.isDisposed) {
          guardXelisCall(
            delegate.dispose,
            boundary: const XelisErrorBoundary(
              source: XelisWalletErrorSource.xelisWalletFlutter,
              operation: XelisWalletOperation.walletBusinessEventsCancel,
            ),
          );
        }
      } catch (_) {}
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (_terminal || isDisposed) {
      await subscription.cancel();
      throw StateError('The XELIS wallet handle is closed.');
    }
    _businessEventSubscriptions.add(subscription);
    return subscription;
  }

  @override
  Future<BigInt> getXelisBalance() {
    _ensureActive();
    return guardXelisFuture(
      _delegate.getXelisBalance,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletBalanceRead,
      ),
    );
  }

  @override
  Future<Map<String, BigInt>> getTrackedBalances() async {
    _ensureActive();
    final balances = await guardXelisFuture(
      _delegate.getTrackedBalances,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletTrackedBalancesRead,
      ),
    );
    return Map.unmodifiable(balances);
  }

  @override
  Future<Map<String, XelisWalletAssetMetadata>> getKnownAssets() async {
    _ensureActive();
    final assets = await guardXelisFuture(
      _delegate.getKnownAssets,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletKnownAssetsRead,
      ),
    );
    return Map.unmodifiable(
      assets.map(
        (asset, metadata) =>
            MapEntry(asset, xelisWalletAssetMetadataFromGenerated(metadata)),
      ),
    );
  }

  @override
  Future<XelisWalletAssetMetadata> getAssetMetadata({
    required String asset,
  }) async {
    _ensureActive();
    final metadata = await guardXelisFuture(
      () => _delegate.getAssetMetadata(asset: asset),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAssetMetadataRead,
      ),
    );
    return xelisWalletAssetMetadataFromGenerated(metadata);
  }

  @override
  Future<bool> trackAsset({required String asset}) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.trackAsset(asset: asset),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAssetTrack,
      ),
    );
  }

  @override
  Future<bool> untrackAsset({required String asset}) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.untrackAsset(asset: asset),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAssetUntrack,
      ),
    );
  }

  @override
  Future<XelisAddressBookMigrationResult> migrateAddressBook() async {
    _ensureActive();
    final result = await guardXelisFuture(
      _delegate.migrateAddressBookV2,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAddressBookMigrate,
      ),
    );
    return XelisAddressBookMigrationResult(
      migratedEntries: result.migratedEntries,
      alreadyComplete: result.alreadyComplete,
    );
  }

  @override
  Future<XelisAddressBookPage> addressBookEntries({
    String? query,
    int skip = 0,
    int? take,
  }) async {
    _ensureActive();
    const maxUnsigned32 = 0xffffffff;
    if (skip < 0 ||
        skip > maxUnsigned32 ||
        (take != null && (take <= 0 || take > maxUnsigned32))) {
      throw xelisOperationPreconditionException(
        operation: XelisWalletOperation.walletAddressBookList,
        code: XelisWalletErrorCode.invalidInput,
        nativeKind: 'ADDRESS_BOOK_PAGINATION_INVALID',
        diagnosticMessage:
            'skip and take must fit the supported unsigned range.',
      );
    }
    final page = await guardXelisFuture(
      () => _delegate.listAddressBookEntriesV2(
        query: query,
        skip: skip,
        take: take,
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAddressBookList,
      ),
    );
    return XelisAddressBookPage(
      entries: page.entries
          .map(_addressBookEntryFromGenerated)
          .toList(growable: false),
      total: page.total,
      hasMore: page.hasMore,
    );
  }

  @override
  Future<XelisAddressBookEntry> upsertAddressBookEntry({
    required String address,
    required String displayName,
    String? destinationLabel,
    String? note,
  }) async {
    _ensureActive();
    final entry = await guardXelisFuture(
      () => _delegate.upsertAddressBookEntryV2(
        address: address,
        displayName: displayName,
        destinationLabel: destinationLabel,
        note: note,
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAddressBookUpsert,
      ),
    );
    return _addressBookEntryFromGenerated(entry);
  }

  @override
  Future<void> removeAddressBookEntry({required String entryId}) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.removeAddressBookEntryV2(entryId: entryId),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAddressBookRemove,
      ),
    );
  }

  @override
  Future<XelisAddressBookEntry> addressBookEntry({
    required String entryId,
  }) async {
    _ensureActive();
    final entry = await guardXelisFuture(
      () => _delegate.findAddressBookEntryV2(entryId: entryId),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAddressBookFind,
      ),
    );
    return _addressBookEntryFromGenerated(entry);
  }

  @override
  Future<XelisAddressBookMatch> matchAddressBookAddress({
    required String address,
  }) async {
    _ensureActive();
    final match = await guardXelisFuture(
      () => _delegate.matchAddressBookAddressV2(address: address),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAddressBookMatch,
      ),
    );
    return _addressBookMatchFromGenerated(match);
  }

  @override
  Future<XelisAddressBookMatch> matchAddressBookDestination({
    required String baseAddress,
    XelisDataElement? integratedData,
  }) async {
    _ensureActive();
    final match = await guardXelisFuture(
      () => _delegate.matchAddressBookDestinationV2(
        baseAddress: baseAddress,
        integratedData: integratedData == null
            ? null
            : generatedDataElementFromXelis(integratedData),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletAddressBookMatch,
      ),
    );
    return _addressBookMatchFromGenerated(match);
  }

  @override
  Future<BigInt> getHistoryCount() {
    _ensureActive();
    return guardXelisFuture(
      _delegate.getHistoryCount,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletHistoryCountRead,
      ),
    );
  }

  @override
  Future<List<XelisWalletTransactionEntry>> history({
    required XelisWalletHistoryFilter filter,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.metadata,
  }) async {
    _ensureActive();
    final transactions = await guardXelisFuture(
      () => _delegate.history(
        filter: _generatedHistoryFilter(filter),
        extraDataDisclosure: _generatedExtraDataDisclosure(extraDataDisclosure),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletHistoryRead,
      ),
    );
    return List.unmodifiable(
      transactions.map(
        (transaction) => xelisWalletTransactionFromGenerated(
          transaction,
          extraDataDisclosure: extraDataDisclosure,
        ),
      ),
    );
  }

  @override
  Future<String> convertTransactionsToCsv({
    required XelisWalletHistoryFilter filter,
  }) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.convertTransactionsToCsv(
        filter: _generatedHistoryFilter(filter),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWalletFlutter,
        operation: XelisWalletOperation.walletHistoryCsvConvert,
      ),
    );
  }

  @override
  Future<void> exportTransactionsToCsvFile({
    required String filePath,
    required XelisWalletHistoryFilter filter,
  }) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.exportTransactionsToCsvFile(
        filePath: filePath,
        filter: _generatedHistoryFilter(filter),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWalletFlutter,
        operation: XelisWalletOperation.walletHistoryCsvExport,
      ),
    );
  }

  @override
  Future<List<XelisWalletPendingTransaction>> pendingTransactions({
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.metadata,
  }) async {
    _ensureActive();
    final transactions = await guardXelisFuture(
      () => _delegate.getPendingTransactions(
        extraDataDisclosure: _generatedExtraDataDisclosure(extraDataDisclosure),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletPendingTransactionsRead,
      ),
    );
    return List.unmodifiable(
      transactions.map(
        (transaction) => xelisWalletPendingTransactionFromGenerated(
          transaction,
          extraDataDisclosure: extraDataDisclosure,
        ),
      ),
    );
  }

  @override
  Future<XelisWalletTransactionEntry> transactionByHash({
    required String hash,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.detailed,
  }) async {
    _ensureActive();
    final transaction = await guardXelisFuture(
      () => _delegate.getTransactionByHash(
        hash: hash,
        extraDataDisclosure: _generatedExtraDataDisclosure(extraDataDisclosure),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletHistoryTransactionRead,
      ),
    );
    return xelisWalletTransactionFromGenerated(
      transaction,
      extraDataDisclosure: extraDataDisclosure,
    );
  }

  @override
  Future<XelisWalletPendingTransaction> pendingTransactionByHash({
    required String hash,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.detailed,
  }) async {
    _ensureActive();
    final transaction = await guardXelisFuture(
      () => _delegate.getPendingTransactionByHash(
        hash: hash,
        extraDataDisclosure: _generatedExtraDataDisclosure(extraDataDisclosure),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletPendingTransactionRead,
      ),
    );
    return xelisWalletPendingTransactionFromGenerated(
      transaction,
      extraDataDisclosure: extraDataDisclosure,
    );
  }

  @override
  Future<XelisWalletMultisigState?> getMultisigState() async {
    _ensureActive();
    final native = await guardXelisFuture(
      _delegate.getMultisigState,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletMultisigStateRead,
      ),
    );
    return native == null ? null : _multisigStateFromGenerated(native);
  }

  @override
  Future<XelisWalletPreparedTransaction> prepareMultisigSetup({
    required int threshold,
    required List<String> participants,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    final native = await guardXelisFuture(
      () => _delegate.multisigSetup(
        threshold: threshold,
        participants: List.unmodifiable(participants),
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletMultisigSetupPrepare,
      ),
    );
    return _adaptAndRegisterPreparedTransaction(
      native,
      operation: XelisWalletOperation.walletMultisigSetupPrepare,
    );
  }

  @override
  bool isMultisigParticipantAddressValid({required String address}) {
    _ensureActive();
    return guardXelisCall(
      () => _delegate.isAddressValidForMultisig(address: address),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletMultisigParticipantValidate,
      ),
    );
  }

  @override
  Future<XelisWalletMultisigSigningRequest> prepareMultisigTransfers({
    required List<XelisWalletTransferRequest> transfers,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigTransfersPrepare;
    final native = await guardXelisFuture(
      () => _delegate.createMultisigTransfersTransaction(
        transfers: _generatedTransferRequests(transfers, operation: operation),
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    return _adaptAndRegisterPendingMultisigRequest(
      native,
      operation: operation,
    );
  }

  @override
  Future<XelisWalletMultisigSigningRequest> prepareMultisigTransferAll({
    required String destination,
    required String asset,
    String? extraData,
    bool encryptExtraData = true,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigTransferAllPrepare;
    final native = await guardXelisFuture(
      () => _delegate.createMultisigTransferAllTransaction(
        strAddress: destination,
        assetHash: asset,
        extraData: extraData,
        encryptExtraData: encryptExtraData,
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    return _adaptAndRegisterPendingMultisigRequest(
      native,
      operation: operation,
    );
  }

  @override
  Future<XelisWalletMultisigSigningRequest> prepareMultisigBurn({
    required String asset,
    required BigInt amountAtomic,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigBurnPrepare;
    _requirePositiveUnsigned64(
      amountAtomic,
      operation: operation,
      field: 'amountAtomic',
    );
    final native = await guardXelisFuture(
      () => _delegate.createMultisigBurnTransaction(
        amount: amountAtomic,
        assetHash: asset,
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    return _adaptAndRegisterPendingMultisigRequest(
      native,
      operation: operation,
    );
  }

  @override
  Future<XelisWalletMultisigSigningRequest> prepareMultisigBurnAll({
    required String asset,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigBurnAllPrepare;
    final native = await guardXelisFuture(
      () => _delegate.createMultisigBurnAllTransaction(
        assetHash: asset,
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    return _adaptAndRegisterPendingMultisigRequest(
      native,
      operation: operation,
    );
  }

  @override
  Future<XelisWalletMultisigSigningRequest> prepareMultisigDeletion({
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigDeletePrepare;
    final native = await guardXelisFuture(
      () => _delegate.initDeleteMultisig(
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    return _adaptAndRegisterPendingMultisigRequest(
      native,
      operation: operation,
    );
  }

  @override
  Future<XelisWalletMultisigSigningRequest> inspectMultisigSigningRequest({
    required String encoded,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigRequestInspect;
    final native = await guardXelisFuture(
      () => _delegate.inspectMultisigSigningRequest(encoded: encoded),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    final request = _multisigRequestFromGenerated(native, operation: operation);
    _multisigRequestCapabilities[request] =
        _NativeInspectedMultisigRequestCapability();
    return request;
  }

  @override
  Future<XelisWalletMultisigSignatureShare> signMultisigSigningRequest({
    required XelisWalletMultisigSigningRequest request,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigRequestSign;
    _inspectedMultisigRequestCapability(request, operation: operation);
    final native = await guardXelisFuture(
      () => _delegate.signMultisigSigningRequest(encoded: request.encoded),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    return _multisigSignatureShareFromGenerated(native);
  }

  @override
  Future<XelisWalletMultisigSignatureShare> inspectMultisigSignatureShare({
    required XelisWalletMultisigSigningRequest request,
    required String encoded,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigShareInspect;
    final capability = _pendingMultisigRequestCapability(
      request,
      operation: operation,
    );
    final native = await guardXelisFuture(
      () => _delegate.inspectMultisigSignatureShare(
        requestId: capability.requestId,
        signingHash: request.signingHash,
        encoded: encoded,
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: operation,
      ),
    );
    final share = _multisigSignatureShareFromGenerated(native);
    _multisigShareCapabilities[share] = _NativeMultisigShareCapability(request);
    return share;
  }

  @override
  Future<XelisWalletPreparedTransaction> finalizeMultisigTransaction({
    required XelisWalletMultisigSigningRequest request,
    required List<XelisWalletMultisigSignatureShare> shares,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigFinalize;
    final capability = _pendingMultisigRequestCapability(
      request,
      operation: operation,
    );
    for (final share in shares) {
      final shareCapability = _multisigShareCapabilities[share];
      if (shareCapability == null ||
          !shareCapability.active ||
          !identical(shareCapability.request, request)) {
        throw xelisOperationPreconditionException(
          operation: operation,
          code: XelisWalletErrorCode.conflict,
          nativeKind: 'MULTISIG_SIGNATURE_SHARE_CAPABILITY_INVALID',
          diagnosticMessage:
              'A signature share is reconstructed, stale, or belongs to '
              'another request or wallet handle.',
        );
      }
    }

    late final generated_wallet.NativePreparedTransaction native;
    try {
      native = await guardXelisFuture(
        () => _delegate.finalizeMultisigTransaction(
          requestId: capability.requestId,
          signingHash: request.signingHash,
          signatureShares: shares.map((share) => share.encoded).toList(),
        ),
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: operation,
        ),
      );
    } on XelisWalletException catch (error) {
      if (error.code == XelisWalletErrorCode.notFound) {
        _invalidatePendingMultisigRequest(request, capability);
      }
      rethrow;
    }
    _invalidatePendingMultisigRequest(request, capability);
    return _adaptAndRegisterPreparedTransaction(native, operation: operation);
  }

  @override
  Future<void> cancelMultisigSigningRequest({
    required XelisWalletMultisigSigningRequest request,
  }) async {
    _ensureActive();
    const operation = XelisWalletOperation.walletMultisigRequestCancel;
    final capability = _pendingMultisigRequestCapability(
      request,
      operation: operation,
    );
    try {
      guardXelisCall(
        () => _delegate.cancelPendingMultisigRequest(
          requestId: capability.requestId,
          signingHash: request.signingHash,
        ),
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: operation,
        ),
      );
    } on XelisWalletException catch (error) {
      if (error.code == XelisWalletErrorCode.notFound) {
        _invalidatePendingMultisigRequest(request, capability);
      }
      rethrow;
    }
    _invalidatePendingMultisigRequest(request, capability);
  }

  @override
  Future<BigInt> estimateTransferFees({
    required List<XelisWalletTransferRequest> transfers,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) {
    _ensureActive();
    final generatedTransfers = _generatedTransferRequests(
      transfers,
      operation: XelisWalletOperation.walletTransactionFeesEstimate,
    );
    return guardXelisFuture(
      () => _delegate.estimateTransferFeesAtomic(
        transfers: generatedTransfers,
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletTransactionFeesEstimate,
      ),
    );
  }

  @override
  Future<XelisWalletPreparedTransaction> prepareTransfers({
    required List<XelisWalletTransferRequest> transfers,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    final native = await guardXelisFuture(
      () => _delegate.prepareTransfersTransaction(
        transfers: _generatedTransferRequests(
          transfers,
          operation: XelisWalletOperation.walletTransactionTransfersPrepare,
        ),
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletTransactionTransfersPrepare,
      ),
    );
    return _adaptAndRegisterPreparedTransaction(
      native,
      operation: XelisWalletOperation.walletTransactionTransfersPrepare,
    );
  }

  @override
  Future<XelisWalletPreparedTransaction> prepareTransferAll({
    required String destination,
    required String asset,
    String? extraData,
    bool encryptExtraData = true,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    final native = await guardXelisFuture(
      () => _delegate.prepareTransferAllTransaction(
        destination: destination,
        asset: asset,
        extraData: extraData,
        encryptExtraData: encryptExtraData,
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletTransactionTransferAllPrepare,
      ),
    );
    return _adaptAndRegisterPreparedTransaction(
      native,
      operation: XelisWalletOperation.walletTransactionTransferAllPrepare,
    );
  }

  @override
  Future<XelisWalletPreparedTransferExtraData>
  inspectPreparedTransferExtraData({
    required XelisWalletPreparedTransaction transaction,
    required int transferIndex,
  }) async {
    _ensureActive();
    final capability = _preparedCapability(
      transaction,
      operation: XelisWalletOperation.walletTransactionPreparedInspect,
    );
    if (transferIndex < 0) {
      throw xelisOperationPreconditionException(
        operation: XelisWalletOperation.walletTransactionPreparedInspect,
        code: XelisWalletErrorCode.invalidInput,
        nativeKind: 'PREPARED_TRANSFER_INDEX_INVALID',
        diagnosticMessage: 'transferIndex must not be negative.',
      );
    }

    final native = await guardXelisFuture(
      () => _delegate.inspectPreparedTransferExtraData(
        preparationId: capability.preparationId,
        txHash: transaction.hash,
        transferIndex: transferIndex,
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletTransactionPreparedInspect,
      ),
    );
    return XelisWalletPreparedTransferExtraData(
      data: xelisDataElementFromGenerated(native.data),
      source: switch (native.source) {
        generated_wallet.NativePreparedExtraDataSource.integratedAddress =>
          XelisWalletPreparedExtraDataSource.integratedAddress,
        generated_wallet.NativePreparedExtraDataSource.explicit =>
          XelisWalletPreparedExtraDataSource.explicit,
      },
      encrypted: native.encrypted,
    );
  }

  @override
  Future<XelisWalletPreparedTransaction> prepareBurn({
    required String asset,
    required BigInt amountAtomic,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    _requirePositiveUnsigned64(
      amountAtomic,
      operation: XelisWalletOperation.walletTransactionBurnPrepare,
      field: 'amountAtomic',
    );
    final native = await guardXelisFuture(
      () => _delegate.prepareBurnTransaction(
        amount: amountAtomic,
        asset: asset,
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletTransactionBurnPrepare,
      ),
    );
    return _adaptAndRegisterPreparedTransaction(
      native,
      operation: XelisWalletOperation.walletTransactionBurnPrepare,
    );
  }

  @override
  Future<XelisWalletPreparedTransaction> prepareBurnAll({
    required String asset,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  }) async {
    _ensureActive();
    final native = await guardXelisFuture(
      () => _delegate.prepareBurnAllTransaction(
        asset: asset,
        feePolicy: _generatedFeePolicy(feePolicy),
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletTransactionBurnAllPrepare,
      ),
    );
    return _adaptAndRegisterPreparedTransaction(
      native,
      operation: XelisWalletOperation.walletTransactionBurnAllPrepare,
    );
  }

  @override
  Future<XelisWalletBroadcastResult> broadcastPreparedTransaction({
    required XelisWalletPreparedTransaction transaction,
  }) async {
    _ensureActive();
    final capability = _preparedCapability(
      transaction,
      operation: XelisWalletOperation.walletTransactionBroadcast,
    );

    late final generated_wallet.NativePreparedTransactionBroadcastOutcome
    native;
    try {
      native = await guardXelisFuture(
        () => _delegate.broadcastPreparedTransaction(
          preparationId: capability.preparationId,
          txHash: transaction.hash,
        ),
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: XelisWalletOperation.walletTransactionBroadcast,
        ),
      );
    } on XelisWalletException catch (error) {
      if (error.code == XelisWalletErrorCode.notFound) {
        _invalidatePreparedTransaction(transaction, capability);
      }
      rethrow;
    }

    final result = _adaptBroadcastOutcome(native);
    if (result is! XelisWalletBroadcastRetryable) {
      _invalidatePreparedTransaction(transaction, capability);
    }
    return result;
  }

  @override
  Future<void> discardPreparedTransaction({
    required XelisWalletPreparedTransaction transaction,
  }) async {
    _ensureActive();
    final capability = _preparedCapability(
      transaction,
      operation: XelisWalletOperation.walletTransactionPreparedCancel,
    );
    try {
      await guardXelisFuture(
        () => _delegate.cancelPreparedTransaction(
          preparationId: capability.preparationId,
          txHash: transaction.hash,
        ),
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: XelisWalletOperation.walletTransactionPreparedCancel,
        ),
      );
    } on XelisWalletException catch (error) {
      if (error.code == XelisWalletErrorCode.notFound) {
        _invalidatePreparedTransaction(transaction, capability);
      }
      rethrow;
    }
    _invalidatePreparedTransaction(transaction, capability);
  }

  @override
  Future<void> rescan({required BigInt topoheight}) {
    _ensureActive();
    return guardXelisFuture(
      () => _delegate.rescan(topoheight: topoheight),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletRescan,
      ),
    );
  }

  @override
  Future<XelisDaemonInfo> getDaemonInfo() async {
    _ensureActive();
    final info = await guardXelisFuture(
      _delegate.getDaemonInfo,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletDaemonInfoRead,
      ),
    );
    return xelisDaemonInfoFromGenerated(info);
  }

  @override
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) {
      return existing;
    }
    if (_terminal || isDisposed) {
      return Future<void>.value();
    }

    _terminal = true;
    _invalidateActivePreparedTransaction();
    _xswdState.invalidateAll();
    _closeInProgress = true;
    final future = _cancelSubscriptionsAndClose().whenComplete(
      () => _closeInProgress = false,
    );
    _closeFuture = future;
    return future;
  }

  Future<void> _cancelSubscriptionsAndClose() async {
    Object? firstError;
    StackTrace? firstStackTrace;
    final subscriptions = _runtimeEventSubscriptions.toList(growable: false);
    for (final subscription in subscriptions) {
      try {
        await subscription.cancel();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    final businessSubscriptions = _businessEventSubscriptions.toList(
      growable: false,
    );
    for (final subscription in businessSubscriptions) {
      try {
        await subscription.cancel();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    try {
      await guardXelisFuture(
        _delegate.close,
        boundary: const XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: XelisWalletOperation.walletClose,
        ),
      );
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    if (firstError case final error?) {
      Error.throwWithStackTrace(error, firstStackTrace!);
    }
  }

  @override
  void dispose() {
    if (_disposedByWrapper || _delegate.isDisposed) {
      _disposedByWrapper = true;
      _terminal = true;
      _xswdState.invalidateAll();
      return;
    }
    if (_closeFuture == null) {
      throw StateError(
        'Call and await wallet.close() before disposing the handle.',
      );
    }
    if (_closeInProgress) {
      throw StateError('Await wallet.close() before disposing the handle.');
    }

    _terminal = true;
    _disposedByWrapper = true;
    _xswdState.invalidateAll();
    guardXelisCall(
      _delegate.dispose,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletDispose,
      ),
    );
  }

  void _ensureActive() {
    if (_terminal || isDisposed) {
      throw StateError('The XELIS wallet handle is closed.');
    }
  }

  Future<T> _runXswdApplicationOperation<T>(
    String applicationId,
    Future<T> Function() action, {
    required XelisWalletOperation operation,
  }) async {
    if (_xswdLifecycleOperationInProgress ||
        !_xswdApplicationOperations.add(applicationId)) {
      throw _xswdOperationInProgress(operation);
    }
    try {
      _ensureActive();
      final result = await action();
      _ensureActive();
      return result;
    } finally {
      _xswdApplicationOperations.remove(applicationId);
    }
  }

  Future<T> _runXswdLifecycleOperation<T>(
    Future<T> Function() action, {
    required XelisWalletOperation operation,
  }) async {
    if (_xswdLifecycleOperationInProgress ||
        _xswdApplicationOperations.isNotEmpty) {
      throw _xswdOperationInProgress(operation);
    }
    _xswdLifecycleOperationInProgress = true;
    try {
      _ensureActive();
      final result = await action();
      _ensureActive();
      return result;
    } finally {
      _xswdLifecycleOperationInProgress = false;
    }
  }

  XelisWalletException _xswdOperationInProgress(
    XelisWalletOperation operation,
  ) => xelisOperationPreconditionException(
    operation: operation,
    code: XelisWalletErrorCode.conflict,
    nativeKind: 'XSWD_APPLICATION_OPERATION_IN_PROGRESS',
    diagnosticMessage:
        'Another conflicting XSWD lifecycle operation is already active.',
  );

  XelisWalletPreparedTransaction _adaptAndRegisterPreparedTransaction(
    generated_wallet.NativePreparedTransaction native, {
    required XelisWalletOperation operation,
  }) {
    _invalidateActivePreparedTransaction();

    try {
      final transaction = _preparedTransactionFromGenerated(native);
      final capability = _NativePreparedTransactionCapability(
        native.preparationId,
      );
      _preparedCapabilities[transaction] = capability;
      _activePreparedTransaction = transaction;
      return transaction;
    } catch (error, stackTrace) {
      // Rust has already replaced the native slot. Best-effort cleanup keeps a
      // malformed private bridge projection from leaving an unreviewable value
      // prepared. Never hide the original contract error with cleanup failure.
      guardXelisFuture(
        () => _delegate.cancelPreparedTransaction(
          preparationId: native.preparationId,
          txHash: native.hash,
        ),
        boundary: XelisErrorBoundary(
          source: XelisWalletErrorSource.xelisWallet,
          operation: operation,
        ),
      ).ignore();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  _NativePreparedTransactionCapability _preparedCapability(
    XelisWalletPreparedTransaction transaction, {
    required XelisWalletOperation operation,
  }) {
    final capability = _preparedCapabilities[transaction];
    if (capability == null ||
        !capability.active ||
        !identical(_activePreparedTransaction, transaction)) {
      throw xelisOperationPreconditionException(
        operation: operation,
        code: XelisWalletErrorCode.conflict,
        nativeKind: 'PREPARED_TRANSACTION_CAPABILITY_INVALID',
        diagnosticMessage:
            'The prepared transaction is stale, reconstructed, consumed, or '
            'owned by another wallet handle.',
      );
    }
    return capability;
  }

  void _invalidatePreparedTransaction(
    XelisWalletPreparedTransaction transaction,
    _NativePreparedTransactionCapability capability,
  ) {
    capability.active = false;
    if (identical(_activePreparedTransaction, transaction)) {
      _activePreparedTransaction = null;
    }
  }

  void _invalidateActivePreparedTransaction() {
    final transaction = _activePreparedTransaction;
    if (transaction != null) {
      final capability = _preparedCapabilities[transaction];
      if (capability != null) {
        capability.active = false;
      }
      _activePreparedTransaction = null;
    }
  }

  XelisWalletMultisigSigningRequest _adaptAndRegisterPendingMultisigRequest(
    generated_wallet.NativeMultisigSigningRequest native, {
    required XelisWalletOperation operation,
  }) {
    final requestId = native.requestId;
    if (requestId == null) {
      throw xelisOperationPreconditionException(
        operation: operation,
        code: XelisWalletErrorCode.internal,
        nativeKind: 'MULTISIG_PENDING_REQUEST_ID_MISSING',
        diagnosticMessage:
            'The private bridge omitted the pending multisig request ID.',
      );
    }

    try {
      final request = _multisigRequestFromGenerated(
        native,
        operation: operation,
      );
      final previous = _activePendingMultisigRequest;
      if (previous != null) {
        final previousCapability = _multisigRequestCapabilities[previous];
        if (previousCapability != null) {
          previousCapability.active = false;
        }
      }
      final capability = _NativePendingMultisigRequestCapability(requestId);
      _multisigRequestCapabilities[request] = capability;
      _activePendingMultisigRequest = request;
      return request;
    } catch (error, stackTrace) {
      try {
        _delegate.cancelPendingMultisigRequest(
          requestId: requestId,
          signingHash: native.signingHash,
        );
      } catch (_) {
        // Preserve the original private-projection failure.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  _NativePendingMultisigRequestCapability _pendingMultisigRequestCapability(
    XelisWalletMultisigSigningRequest request, {
    required XelisWalletOperation operation,
  }) {
    final capability = _multisigRequestCapabilities[request];
    if (capability is! _NativePendingMultisigRequestCapability ||
        !capability.active ||
        !identical(_activePendingMultisigRequest, request)) {
      throw xelisOperationPreconditionException(
        operation: operation,
        code: XelisWalletErrorCode.conflict,
        nativeKind: 'MULTISIG_REQUEST_CAPABILITY_INVALID',
        diagnosticMessage:
            'The multisig request is stale, reconstructed, consumed, or '
            'owned by another wallet handle.',
      );
    }
    return capability;
  }

  void _inspectedMultisigRequestCapability(
    XelisWalletMultisigSigningRequest request, {
    required XelisWalletOperation operation,
  }) {
    final capability = _multisigRequestCapabilities[request];
    if (capability is! _NativeInspectedMultisigRequestCapability ||
        !capability.active) {
      throw xelisOperationPreconditionException(
        operation: operation,
        code: XelisWalletErrorCode.conflict,
        nativeKind: 'MULTISIG_INSPECTED_REQUEST_CAPABILITY_INVALID',
        diagnosticMessage:
            'The signing request was reconstructed, is stale, or belongs to '
            'another wallet handle.',
      );
    }
  }

  void _invalidatePendingMultisigRequest(
    XelisWalletMultisigSigningRequest request,
    _NativePendingMultisigRequestCapability capability,
  ) {
    capability.active = false;
    if (identical(_activePendingMultisigRequest, request)) {
      _activePendingMultisigRequest = null;
    }
  }
}

final class _NativePreparedTransactionCapability {
  _NativePreparedTransactionCapability(this.preparationId);

  final BigInt preparationId;
  var active = true;
}

sealed class _NativeMultisigRequestCapability {
  _NativeMultisigRequestCapability();

  var active = true;
}

final class _NativePendingMultisigRequestCapability
    extends _NativeMultisigRequestCapability {
  _NativePendingMultisigRequestCapability(this.requestId);

  final BigInt requestId;
}

final class _NativeInspectedMultisigRequestCapability
    extends _NativeMultisigRequestCapability {
  _NativeInspectedMultisigRequestCapability();
}

final class _NativeMultisigShareCapability {
  _NativeMultisigShareCapability(this.request);

  final XelisWalletMultisigSigningRequest request;
  var active = true;
}

XelisWalletMultisigParticipant _multisigParticipantFromGenerated(
  generated_wallet.NativeMultisigParticipant native,
) => XelisWalletMultisigParticipant(id: native.id, address: native.address);

XelisWalletMultisigState _multisigStateFromGenerated(
  generated_wallet.NativeMultisigState native,
) => XelisWalletMultisigState(
  threshold: native.threshold,
  participants: native.participants
      .map(_multisigParticipantFromGenerated)
      .toList(growable: false),
  topoheight: native.topoheight,
);

XelisWalletMultisigSigningRequest _multisigRequestFromGenerated(
  generated_wallet.NativeMultisigSigningRequest native, {
  required XelisWalletOperation operation,
}) => XelisWalletMultisigSigningRequest(
  encoded: native.encoded,
  signingHash: native.signingHash,
  source: native.source,
  network: switch (native.network) {
    'mainnet' => XelisNetwork.mainnet,
    'testnet' => XelisNetwork.testnet,
    'devnet' => XelisNetwork.devnet,
    'stagenet' => XelisNetwork.stagenet,
    final network => throw xelisOperationPreconditionException(
      operation: operation,
      code: XelisWalletErrorCode.internal,
      nativeKind: 'MULTISIG_REQUEST_NETWORK_INVALID',
      diagnosticMessage:
          'The private bridge returned an unsupported network: $network.',
    ),
  },
  feeAtomic: native.fee,
  feeLimitAtomic: native.feeLimit,
  nonce: native.nonce,
  referenceTopoheight: native.referenceTopoheight,
  threshold: native.threshold,
  participants: native.participants
      .map(_multisigParticipantFromGenerated)
      .toList(growable: false),
  participantId: native.signerId,
  transaction: _multisigTransactionFromGenerated(native.transaction),
);

XelisWalletMultisigSigningTransaction _multisigTransactionFromGenerated(
  generated_wallet.NativeMultisigSigningTransaction native,
) => switch (native) {
  generated_wallet.NativeMultisigSigningTransaction_Transfers(
    :final transfers,
  ) =>
    XelisWalletMultisigTransfers(
      transfers: transfers
          .map(
            (transfer) => XelisWalletMultisigSigningTransfer(
              destination: transfer.destination,
              asset: transfer.asset,
              amountAtomic: transfer.amount,
              hasExtraData: transfer.hasExtraData,
            ),
          )
          .toList(growable: false),
    ),
  generated_wallet.NativeMultisigSigningTransaction_Burn(
    :final asset,
    :final amount,
  ) =>
    XelisWalletMultisigBurn(asset: asset, amountAtomic: amount),
  generated_wallet.NativeMultisigSigningTransaction_DeleteMultisig() =>
    const XelisWalletMultisigDelete(),
};

XelisWalletMultisigSignatureShare _multisigSignatureShareFromGenerated(
  generated_wallet.NativeMultisigSignatureShare native,
) => XelisWalletMultisigSignatureShare(
  encoded: native.encoded,
  signingHash: native.signingHash,
  participantId: native.signerId,
  signature: native.signature,
);

final _maxUnsigned64 = BigInt.parse('18446744073709551615');

void _requirePositiveUnsigned64(
  BigInt value, {
  required XelisWalletOperation operation,
  required String field,
}) {
  if (value <= BigInt.zero || value > _maxUnsigned64) {
    throw xelisOperationPreconditionException(
      operation: operation,
      code: XelisWalletErrorCode.invalidInput,
      nativeKind: 'TRANSACTION_AMOUNT_INVALID',
      diagnosticMessage:
          '$field must be between 1 and $_maxUnsigned64 atomic units; '
          'received $value.',
    );
  }
}

generated_wallet.NativeTransactionFeePolicy _generatedFeePolicy(
  XelisWalletFeePolicy policy,
) => switch (policy) {
  XelisWalletAutomaticFeePolicy() =>
    const generated_wallet.NativeTransactionFeePolicy.automatic(),
  XelisWalletFixedFeePolicy(:final feeAtomic) =>
    generated_wallet.NativeTransactionFeePolicy.fixed(feeAtomic),
  XelisWalletTipFeePolicy(:final tipAtomic) =>
    generated_wallet.NativeTransactionFeePolicy.tip(tipAtomic),
  XelisWalletMultiplierFeePolicy(:final basisPoints) =>
    generated_wallet.NativeTransactionFeePolicy.multiplier(basisPoints),
};

List<generated_wallet.NativeTransactionTransferRequest>
_generatedTransferRequests(
  List<XelisWalletTransferRequest> transfers, {
  required XelisWalletOperation operation,
}) => List.unmodifiable(
  transfers.indexed.map((entry) {
    final (index, transfer) = entry;
    _requirePositiveUnsigned64(
      transfer.amountAtomic,
      operation: operation,
      field: 'transfers[$index].amountAtomic',
    );
    return generated_wallet.NativeTransactionTransferRequest(
      amount: transfer.amountAtomic,
      destination: transfer.destination,
      asset: transfer.asset,
      extraData: transfer.extraData,
      encryptExtraData: transfer.encryptExtraData,
    );
  }),
);

XelisWalletPreparedTransaction _preparedTransactionFromGenerated(
  generated_wallet.NativePreparedTransaction native,
) => XelisWalletPreparedTransaction(
  hash: native.hash,
  feeAtomic: native.fee,
  details: switch (native.transaction) {
    generated_wallet.NativePreparedTransactionKind_Transfers(
      :final transfers,
    ) =>
      XelisWalletPreparedTransfers(
        transfers: transfers
            .map(
              (transfer) => XelisWalletPreparedTransfer(
                destination: transfer.destination,
                asset: transfer.asset,
                amountAtomic: transfer.amount,
                hasExtraData: transfer.hasExtraData,
                extraDataEncrypted: transfer.encryptExtraData,
              ),
            )
            .toList(growable: false),
      ),
    generated_wallet.NativePreparedTransactionKind_Burn(
      :final asset,
      :final amount,
    ) =>
      XelisWalletPreparedBurn(asset: asset, amountAtomic: amount),
    generated_wallet.NativePreparedTransactionKind_MultisigSetup(
      :final threshold,
      :final participants,
    ) =>
      XelisWalletPreparedMultisigSetup(
        threshold: threshold,
        participants: participants
            .map(_multisigParticipantFromGenerated)
            .toList(growable: false),
      ),
    generated_wallet.NativePreparedTransactionKind_MultisigFinalized(
      :final transaction,
    ) =>
      XelisWalletPreparedMultisigTransaction(
        transaction: _multisigTransactionFromGenerated(transaction),
      ),
  },
);

XelisWalletBroadcastResult _adaptBroadcastOutcome(
  generated_wallet.NativePreparedTransactionBroadcastOutcome outcome,
) => switch (outcome) {
  generated_wallet.NativePreparedTransactionBroadcastOutcome_Submitted() =>
    const XelisWalletBroadcastSubmitted(),
  generated_wallet.NativePreparedTransactionBroadcastOutcome_Retryable(
    :final failure,
  ) =>
    XelisWalletBroadcastRetryable(failure: _adaptBroadcastFailure(failure)),
  generated_wallet.NativePreparedTransactionBroadcastOutcome_Rejected(
    :final failure,
  ) =>
    XelisWalletBroadcastRejected(failure: _adaptBroadcastFailure(failure)),
  generated_wallet.NativePreparedTransactionBroadcastOutcome_LocalFailure(
    :final failure,
  ) =>
    XelisWalletBroadcastLocalFailure(failure: _adaptBroadcastFailure(failure)),
  generated_wallet.NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync(
    :final failure,
  ) =>
    XelisWalletBroadcastSubmittedNeedsResync(
      failure: _adaptBroadcastFailure(failure),
    ),
};

XelisWalletException _adaptBroadcastFailure(
  generated_error.NativeXelisError failure,
) => adaptXelisError(
  failure,
  boundary: const XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWallet,
    operation: XelisWalletOperation.walletTransactionBroadcast,
  ),
) as XelisWalletException;

generated_wallet.HistoryPageFilter _generatedHistoryFilter(
  XelisWalletHistoryFilter filter,
) => generated_wallet.HistoryPageFilter(
  page: filter.page,
  limit: filter.limit,
  assetHash: filter.assetHash,
  address: filter.encodedAddress,
  minTopoheight: filter.minTopoheight,
  maxTopoheight: filter.maxTopoheight,
  acceptIncoming: filter.acceptIncoming,
  acceptOutgoing: filter.acceptOutgoing,
  acceptCoinbase: filter.acceptCoinbase,
  acceptBurn: filter.acceptBurn,
  acceptBlob: filter.acceptBlob,
  minTimestamp: filter.minTimestampMillis,
  maxTimestamp: filter.maxTimestampMillis,
);

XelisAddressBookEntry _addressBookEntryFromGenerated(
  generated_address_book.NativeAddressBookEntry entry,
) => XelisAddressBookEntry(
  id: entry.id,
  displayName: entry.displayName,
  destinationLabel: entry.destinationLabel,
  note: entry.note,
  destination: XelisSavedDestination(
    address: entry.destination.address,
    baseAddress: entry.destination.baseAddress,
    kind: switch (entry.destination.kind) {
      generated_address_book.NativeSavedDestinationKind.standard =>
        XelisSavedDestinationKind.standard,
      generated_address_book.NativeSavedDestinationKind.integrated =>
        XelisSavedDestinationKind.integrated,
    },
    integratedDataKind: switch (entry.destination.integratedDataKind) {
      null => null,
      generated_address_book.NativeIntegratedDataKind.boolValue =>
        XelisIntegratedDataKind.boolValue,
      generated_address_book.NativeIntegratedDataKind.string =>
        XelisIntegratedDataKind.string,
      generated_address_book.NativeIntegratedDataKind.u8 =>
        XelisIntegratedDataKind.u8,
      generated_address_book.NativeIntegratedDataKind.u16 =>
        XelisIntegratedDataKind.u16,
      generated_address_book.NativeIntegratedDataKind.u32 =>
        XelisIntegratedDataKind.u32,
      generated_address_book.NativeIntegratedDataKind.u64 =>
        XelisIntegratedDataKind.u64,
      generated_address_book.NativeIntegratedDataKind.u128 =>
        XelisIntegratedDataKind.u128,
      generated_address_book.NativeIntegratedDataKind.hash =>
        XelisIntegratedDataKind.hash,
      generated_address_book.NativeIntegratedDataKind.blob =>
        XelisIntegratedDataKind.blob,
      generated_address_book.NativeIntegratedDataKind.array =>
        XelisIntegratedDataKind.array,
      generated_address_book.NativeIntegratedDataKind.fields =>
        XelisIntegratedDataKind.fields,
    },
  ),
);

XelisAddressBookMatch _addressBookMatchFromGenerated(
  generated_address_book.NativeAddressBookMatch match,
) {
  final entries = match.entries
      .map(_addressBookEntryFromGenerated)
      .toList(growable: false);
  return switch (match.kind) {
    generated_address_book.NativeAddressBookMatchKind.exact =>
      XelisAddressBookExactMatch(_singleAddressBookMatch(entries, 'exact')),
    generated_address_book.NativeAddressBookMatchKind.baseOnly =>
      XelisAddressBookBaseOnlyMatch(
        _singleAddressBookMatch(entries, 'baseOnly'),
      ),
    generated_address_book.NativeAddressBookMatchKind.ambiguous
        when entries.length >= 2 =>
      XelisAddressBookAmbiguousMatch(entries),
    generated_address_book.NativeAddressBookMatchKind.none
        when entries.isEmpty =>
      const XelisAddressBookNoMatch(),
    _ => throw xelisBridgeContractException(
      operation: XelisWalletOperation.walletAddressBookMatch,
      nativeKind: 'ADDRESS_BOOK_MATCH_PROJECTION_INVALID',
      diagnosticMessage:
          'The native address-book match violated its cardinality contract.',
    ),
  };
}

XelisAddressBookEntry _singleAddressBookMatch(
  List<XelisAddressBookEntry> entries,
  String kind,
) {
  if (entries.length != 1) {
    throw xelisBridgeContractException(
      operation: XelisWalletOperation.walletAddressBookMatch,
      nativeKind: 'ADDRESS_BOOK_MATCH_PROJECTION_INVALID',
      diagnosticMessage:
          'The native $kind address-book match violated its cardinality contract.',
    );
  }
  return entries.single;
}
