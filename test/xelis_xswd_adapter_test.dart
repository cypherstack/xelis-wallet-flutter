import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_xswd_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/error.dart'
    as generated_error;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/xswd_dtos.dart'
    as generated_models;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('authored XSWD facade', () {
    test('maps lifecycle state, sessions, permissions, and relayers', () async {
      final delegate = _FakeGeneratedXswdWallet(
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      final callbacks = _callbacks();

      await wallet.startXswd(callbacks: callbacks);
      await wallet.startXswd(callbacks: callbacks);
      expect(delegate.startCalls, 2);

      final state = await wallet.getXswdState();
      expect(state.isRunning, isTrue);
      expect(state.applications, hasLength(1));
      expect(state.applications.single.id, 'application-id');
      expect(
        state.applications.single.permissions['get_balance'],
        XelisXswdPermissionPolicy.ask,
      );
      expect(state.toString(), isNot(contains('application-id')));

      await wallet.updateXswdApplicationPermissions(
        application: state.applications.single,
        permissions: const {'get_balance': XelisXswdPermissionPolicy.accept},
      );
      expect(delegate.lastPermissions, {
        'get_balance': generated_models.PermissionPolicy.accept,
      });

      await wallet.closeXswdApplicationSession(
        application: state.applications.single,
      );
      expect(delegate.closedSessionRef, BigInt.one);

      final relayer = XelisXswdRelayer(
        id: 'relay-id',
        name: 'relay-name',
        description: 'relay-description',
        url: null,
        permissions: const ['get_balance'],
        relayer: 'wss://relay.example',
        encryption: XelisXswdEncryption(
          algorithm: XelisXswdEncryptionAlgorithm.aes,
          key: List.filled(32, 7),
        ),
      );
      await wallet.addXswdRelayer(relayer: relayer, callbacks: callbacks);
      expect(delegate.lastRelayer?.id, 'relay-id');
      expect(delegate.lastRelayer?.encryptionMode, isNotNull);
      expect(relayer.toString(), isNot(contains('relay-id')));
      expect(relayer.toString(), isNot(contains('wss://')));
      expect(relayer.encryption.toString(), isNot(contains('7')));

      await wallet.stopXswd();
      await wallet.stopXswd();
      expect(delegate.stopCalls, 2);
    });

    test(
      'uses exact stable capabilities across projections and wallet handles',
      () async {
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          applications: [
            _generatedApplication(),
            _generatedApplication(sessionRef: BigInt.two, isRelayer: true),
          ],
        );
        final wallet = NativeXelisWallet(delegate);
        final first = await wallet.getXswdState();
        final second = await wallet.getXswdState();

        expect(
          first.applications.first.sessionReference,
          second.applications.first.sessionReference,
        );
        expect(
          first.applications.first.sessionReference,
          isNot(first.applications.last.sessionReference),
        );
        expect(
          first.applications.first.sessionReference.toString(),
          'XelisXswdSessionReference(<opaque>)',
        );

        await wallet.updateXswdApplicationPermissions(
          application: first.applications.last,
          permissions: const {},
        );
        expect(delegate.lastPermissionsSessionRef, BigInt.two);

        final reconstructed = XelisXswdApplication(
          id: first.applications.first.id,
          name: first.applications.first.name,
          description: first.applications.first.description,
          url: first.applications.first.url,
          permissions: first.applications.first.permissions,
          isRelayer: first.applications.first.isRelayer,
        );
        await _expectInvalidXswdSession(
          wallet.closeXswdApplicationSession(application: reconstructed),
        );

        final otherWallet = NativeXelisWallet(
          _FakeGeneratedXswdWallet(
            running: true,
            applications: [_generatedApplication(sessionRef: BigInt.from(3))],
          ),
        );
        await _expectInvalidXswdSession(
          otherWallet.closeXswdApplicationSession(
            application: first.applications.first,
          ),
        );

        await wallet.closeXswdApplicationSession(
          application: first.applications.first,
        );
        await _expectInvalidXswdSession(
          wallet.updateXswdApplicationPermissions(
            application: second.applications.first,
            permissions: const {},
          ),
        );
      },
    );

    test(
      'targeted permission update returns a fresh same-session projection',
      () async {
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          applications: [
            _generatedApplication(
              permissions: const {
                'get_balance': generated_models.PermissionPolicy.ask,
                'build_transaction': generated_models.PermissionPolicy.reject,
              },
            ),
          ],
        );
        final wallet = NativeXelisWallet(delegate);
        final application = (await wallet.getXswdState()).applications.single;

        final updated = await wallet.updateXswdApplicationPermission(
          application: application,
          permission: 'get_balance',
          policy: XelisXswdPermissionPolicy.accept,
        );

        expect(updated.sessionReference, application.sessionReference);
        expect(updated.permissions, const {
          'get_balance': XelisXswdPermissionPolicy.accept,
          'build_transaction': XelisXswdPermissionPolicy.reject,
        });
        expect(delegate.lastPermission, 'get_balance');
        expect(
          delegate.lastPermissionPolicy,
          generated_models.PermissionPolicy.accept,
        );
      },
    );

    test(
      'observes retained decisions after returning the callback result',
      () async {
        final observation = Completer<XelisXswdApplicationStateObservation>();
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          applications: [_generatedApplication()],
        );
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(
          callbacks: _callbacks(
            onPermissionRequest: (_) => XelisXswdDecision.alwaysAccept,
            onApplicationStateObservation: observation.complete,
          ),
        );
        final admitted = (await wallet.getXswdState()).applications.single;

        expect(
          await delegate.permissionCallback!(
            _generatedRequest(
              generated_models.XswdRequestType.permission(
                _validPermissionPayload(),
              ),
            ),
          ),
          const generated_models.XswdDecisionCallbackOutcome.alwaysAccept(),
        );
        expect(observation.isCompleted, isFalse);
        delegate.applications = [
          _generatedApplication(
            permissions: const {
              'get_balance': generated_models.PermissionPolicy.accept,
            },
          ),
        ];

        final result = await observation.future.timeout(
          const Duration(seconds: 1),
        );
        expect(result, isA<XelisXswdApplicationStateObserved>());
        expect(result.sequence, greaterThan(0));
        expect(result.application.sessionReference, admitted.sessionReference);
        expect(
          result.application.permissions['get_balance'],
          XelisXswdPermissionPolicy.accept,
        );
      },
    );

    test('replaces an older observation for the same opaque session', () async {
      final observations = <XelisXswdApplicationStateObservation>[];
      final completed = Completer<void>();
      var decisions = 0;
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: _callbacks(
          onPermissionRequest: (_) => decisions++ == 0
              ? XelisXswdDecision.alwaysAccept
              : XelisXswdDecision.alwaysReject,
          onApplicationStateObservation: (observation) {
            observations.add(observation);
            if (observations.length == 2) completed.complete();
          },
        ),
      );
      await wallet.getXswdState();
      final request = _generatedRequest(
        generated_models.XswdRequestType.permission(_validPermissionPayload()),
      );

      await delegate.permissionCallback!(request);
      await delegate.permissionCallback!(request);
      delegate.applications = [
        _generatedApplication(
          permissions: const {
            'get_balance': generated_models.PermissionPolicy.reject,
          },
        ),
      ];
      await completed.future.timeout(const Duration(seconds: 1));

      final stale = observations
          .whereType<XelisXswdApplicationStateStale>()
          .single;
      final observed = observations
          .whereType<XelisXswdApplicationStateObserved>()
          .single;
      expect(
        stale.application.sessionReference,
        observed.application.sessionReference,
      );
      expect(stale.sequence, lessThan(observed.sequence));
    });

    test('observes only valid selective prefetch grants', () async {
      var decisionCalls = 0;
      final observation = Completer<XelisXswdApplicationStateObservation>();
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: _callbacks(
          onPrefetchPermissionsReview: (_) => decisionCalls++ == 0
              ? XelisXswdPrefetchDecision.grant(const ['not_requested'])
              : XelisXswdPrefetchDecision.grant(const ['get_balance']),
          onApplicationStateObservation: observation.complete,
        ),
      );
      await wallet.getXswdState();
      final readsBeforeDecision = delegate.stateReadCalls;

      expect(
        await delegate.prefetchCallback!(
          _generatedRequest(
            generated_models.XswdRequestType.prefetchPermissions(
              _validPrefetchPayload(),
            ),
          ),
        ),
        const generated_models.XswdDecisionCallbackOutcome.prefetchGrant(
          permissions: ['not_requested'],
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(observation.isCompleted, isFalse);
      expect(delegate.stateReadCalls, readsBeforeDecision);

      delegate.applications = [
        _generatedApplication(
          permissions: const {
            'get_balance': generated_models.PermissionPolicy.accept,
          },
        ),
      ];
      expect(
        await delegate.prefetchCallback!(
          _generatedRequest(
            generated_models.XswdRequestType.prefetchPermissions(
              _validPrefetchPayload(),
            ),
          ),
        ),
        const generated_models.XswdDecisionCallbackOutcome.prefetchGrant(
          permissions: ['get_balance'],
        ),
      );
      expect(
        await observation.future.timeout(const Duration(seconds: 1)),
        isA<XelisXswdApplicationStateObserved>(),
      );
    });

    test(
      'reports structured observation failure without changing the decision',
      () async {
        final observation = Completer<XelisXswdApplicationStateObservation>();
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          stateFailure: generated_error.NativeXelisError(
            version: 1,
            source: generated_error.NativeXelisErrorSource.xelisWallet,
            code: generated_error.NativeXelisErrorCode.operationFailed,
            diagnosticMessage: 'state read failed',
          ),
        );
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(
          callbacks: _callbacks(
            onApplicationRequest: (_) => XelisXswdDecision.accept,
            onApplicationStateObservation: observation.complete,
          ),
        );

        expect(
          await delegate.applicationCallback!(
            _generatedRequest(
              const generated_models.XswdRequestType.application(),
            ),
          ),
          const generated_models.XswdDecisionCallbackOutcome.accept(),
        );
        final result = await observation.future.timeout(
          const Duration(seconds: 1),
        );
        expect(result, isA<XelisXswdApplicationStateFailed>());
        final failure = (result as XelisXswdApplicationStateFailed).error;
        expect(failure.operation, XelisWalletOperation.walletXswdStateRead);
      },
    );

    test('stops polling after the bounded observation timeout', () async {
      final observation = Completer<XelisXswdApplicationStateObservation>();
      final delegate = _FakeGeneratedXswdWallet(running: true);
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: _callbacks(
          onApplicationRequest: (_) => XelisXswdDecision.accept,
          onApplicationStateObservation: observation.complete,
        ),
      );

      await delegate.applicationCallback!(
        _generatedRequest(const generated_models.XswdRequestType.application()),
      );
      final result = await observation.future.timeout(
        const Duration(seconds: 3),
      );
      expect(result, isA<XelisXswdApplicationStateTimedOut>());
      final readsAtTimeout = delegate.stateReadCalls;
      expect(readsAtTimeout, greaterThan(1));
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(delegate.stateReadCalls, readsAtTimeout);
    });

    test('keeps capability after native close failure', () async {
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
        sessionFailure: AnyhowException('first close failed'),
      );
      final wallet = NativeXelisWallet(delegate);
      final application = (await wallet.getXswdState()).applications.single;

      await expectLater(
        wallet.closeXswdApplicationSession(application: application),
        throwsA(isA<XelisWalletException>()),
      );
      delegate.sessionFailure = null;
      await wallet.closeXswdApplicationSession(application: application);
      expect(delegate.closedSessionRef, BigInt.one);
    });

    test('rejects same-id close while relayer admission is pending', () async {
      final relayerGate = Completer<void>();
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      )..relayerGate = relayerGate;
      final wallet = NativeXelisWallet(delegate);
      final application = (await wallet.getXswdState()).applications.single;
      final add = wallet.addXswdRelayer(
        relayer: XelisXswdRelayer(
          id: application.id,
          name: 'Replacement',
          description: '',
          url: null,
          permissions: const [],
          relayer: 'wss://relay.example',
        ),
        callbacks: _callbacks(),
      );
      await Future<void>.delayed(Duration.zero);
      await _expectXswdOperationInProgress(
        wallet.closeXswdApplicationSession(application: application),
        XelisWalletOperation.walletXswdSessionClose,
      );

      expect(delegate.closedSessionRef, isNull);
      relayerGate.complete();
      await add;
      await wallet.closeXswdApplicationSession(application: application);
      expect(delegate.operationOrder, [
        'add:start',
        'add:end',
        'close:start',
        'close:end',
      ]);
    });

    test('rejects same-id relayer admission while close is pending', () async {
      final closeGate = Completer<void>();
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      )..closeGate = closeGate;
      final wallet = NativeXelisWallet(delegate);
      final application = (await wallet.getXswdState()).applications.single;
      final close = wallet.closeXswdApplicationSession(
        application: application,
      );
      await Future<void>.delayed(Duration.zero);

      await _expectXswdOperationInProgress(
        wallet.addXswdRelayer(
          relayer: XelisXswdRelayer(
            id: application.id,
            name: 'Replacement',
            description: '',
            url: null,
            permissions: const [],
            relayer: 'wss://relay.example',
          ),
          callbacks: _callbacks(),
        ),
        XelisWalletOperation.walletXswdRelayerAdd,
      );
      expect(delegate.relayerCalls, 0);

      closeGate.complete();
      await close;
      await wallet.addXswdRelayer(
        relayer: XelisXswdRelayer(
          id: application.id,
          name: 'Replacement',
          description: '',
          url: null,
          permissions: const [],
          relayer: 'wss://relay.example',
        ),
        callbacks: _callbacks(),
      );
      expect(delegate.operationOrder, [
        'close:start',
        'close:end',
        'add:start',
        'add:end',
      ]);
    });

    test('rejects stop while an application operation is pending', () async {
      final relayerGate = Completer<void>();
      final delegate = _FakeGeneratedXswdWallet()..relayerGate = relayerGate;
      final wallet = NativeXelisWallet(delegate);
      final add = wallet.addXswdRelayer(
        relayer: XelisXswdRelayer(
          id: 'application-id',
          name: 'Relayer',
          description: '',
          url: null,
          permissions: const [],
          relayer: 'wss://relay.example',
        ),
        callbacks: _callbacks(),
      );
      await Future<void>.delayed(Duration.zero);

      await _expectXswdOperationInProgress(
        wallet.stopXswd(),
        XelisWalletOperation.walletXswdStop,
      );
      await _expectXswdOperationInProgress(
        wallet.startXswd(callbacks: _callbacks()),
        XelisWalletOperation.walletXswdStart,
      );
      expect(delegate.stopCalls, 0);
      relayerGate.complete();
      await add;
      await wallet.stopXswd();
      expect(delegate.stopCalls, 1);
    });

    test(
      'rejects relayer admission during stop and allows it after restart',
      () async {
        final stopGate = Completer<void>();
        final delegate = _FakeGeneratedXswdWallet(running: true)
          ..stopGate = stopGate;
        final wallet = NativeXelisWallet(delegate);
        final stop = wallet.stopXswd();
        await Future<void>.delayed(Duration.zero);

        await _expectXswdOperationInProgress(
          wallet.addXswdRelayer(
            relayer: XelisXswdRelayer(
              id: 'application-id',
              name: 'Relayer',
              description: '',
              url: null,
              permissions: const [],
              relayer: 'wss://relay.example',
            ),
            callbacks: _callbacks(),
          ),
          XelisWalletOperation.walletXswdRelayerAdd,
        );
        await _expectXswdOperationInProgress(
          wallet.startXswd(callbacks: _callbacks()),
          XelisWalletOperation.walletXswdStart,
        );
        expect(delegate.relayerCalls, 0);

        stopGate.complete();
        await stop;
        await wallet.startXswd(callbacks: _callbacks());
        await wallet.addXswdRelayer(
          relayer: XelisXswdRelayer(
            id: 'application-id',
            name: 'Relayer',
            description: '',
            url: null,
            permissions: const [],
            relayer: 'wss://relay.example',
          ),
          callbacks: _callbacks(),
        );
        expect(delegate.stopCalls, 1);
        expect(delegate.relayerCalls, 1);
      },
    );

    test('invalidates rejected callback session capabilities', () async {
      late XelisXswdApplication callbackApplication;
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: XelisXswdCallbacks(
          onCancelRequest: (_) async {},
          onApplicationRequest: (request) {
            callbackApplication = request.application;
            return XelisXswdDecision.reject;
          },
          onPermissionRequest: (_) async => XelisXswdDecision.accept,
          onPrefetchPermissionsRequest: (_) async => XelisXswdDecision.accept,
          onApplicationDisconnect: (_) async {},
        ),
      );

      final outcome = await delegate.applicationCallback!(
        _generatedRequest(const generated_models.XswdRequestType.application()),
      );
      expect(
        outcome,
        const generated_models.XswdDecisionCallbackOutcome.reject(),
      );
      await _expectInvalidXswdSession(
        wallet.closeXswdApplicationSession(application: callbackApplication),
      );
    });

    test('keeps admission identity stable but non-operable until state confirms it', () async {
      late XelisXswdApplication callbackApplication;
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: XelisXswdCallbacks(
          onCancelRequest: (_) async {},
          onApplicationRequest: (request) {
            callbackApplication = request.application;
            return XelisXswdDecision.accept;
          },
          onPermissionRequest: (_) async => XelisXswdDecision.accept,
          onPrefetchPermissionsRequest: (_) async => XelisXswdDecision.accept,
          onApplicationDisconnect: (_) async {},
        ),
      );

      expect(
        await delegate.applicationCallback!(
          _generatedRequest(
            const generated_models.XswdRequestType.application(),
          ),
        ),
        const generated_models.XswdDecisionCallbackOutcome.accept(),
      );
      await _expectInvalidXswdSession(
        wallet.closeXswdApplicationSession(application: callbackApplication),
      );
      expect(delegate.closedSessionRef, isNull);

      delegate.applications = const [];
      expect((await wallet.getXswdState()).applications, isEmpty);
      delegate.applications = [_generatedApplication()];
      final admitted = (await wallet.getXswdState()).applications.single;
      expect(admitted.sessionReference, callbackApplication.sessionReference);
      await wallet.updateXswdApplicationPermissions(
        application: admitted,
        permissions: const {},
      );
      expect(delegate.lastPermissionsSessionRef, BigInt.one);
    });

    test('does not revive a cancelled admission from a late decision or stale state', () async {
      late XelisXswdApplication callbackApplication;
      final decision = Completer<XelisXswdDecision>();
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: XelisXswdCallbacks(
          onCancelRequest: (_) async {},
          onApplicationRequest: (request) {
            callbackApplication = request.application;
            return decision.future;
          },
          onPermissionRequest: (_) async => XelisXswdDecision.accept,
          onPrefetchPermissionsRequest: (_) async => XelisXswdDecision.accept,
          onApplicationDisconnect: (_) async {},
        ),
      );

      final pendingDecision = delegate.applicationCallback!(
        _generatedRequest(const generated_models.XswdRequestType.application()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        await delegate.cancelCallback!(
          _generatedRequest(
            const generated_models.XswdRequestType.cancelRequest(),
          ),
          true,
        ),
        generated_models.XswdNotificationCallbackOutcome.completed,
      );

      await _expectInvalidXswdSession(
        wallet.closeXswdApplicationSession(application: callbackApplication),
      );
      decision.complete(XelisXswdDecision.accept);
      expect(
        await pendingDecision,
        const generated_models.XswdDecisionCallbackOutcome.accept(),
      );
      final staleApplication =
          (await wallet.getXswdState()).applications.single;
      await _expectInvalidXswdSession(
        wallet.updateXswdApplicationPermissions(
          application: staleApplication,
          permissions: const {},
        ),
      );
    });

    test('tombstones an accepted admission when cancellation wins before Rust consumes it', () async {
      late XelisXswdApplication callbackApplication;
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: _callbacks(
          onApplicationRequest: (request) {
            callbackApplication = request.application;
            return XelisXswdDecision.accept;
          },
        ),
      );

      expect(
        await delegate.applicationCallback!(
          _generatedRequest(
            const generated_models.XswdRequestType.application(),
          ),
        ),
        const generated_models.XswdDecisionCallbackOutcome.accept(),
      );
      expect(
        await delegate.cancelCallback!(
          _generatedRequest(
            const generated_models.XswdRequestType.cancelRequest(),
          ),
          true,
        ),
        generated_models.XswdNotificationCallbackOutcome.completed,
      );

      await _expectInvalidXswdSession(
        wallet.closeXswdApplicationSession(application: callbackApplication),
      );
      final staleProjection = (await wallet.getXswdState()).applications.single;
      await _expectInvalidXswdSession(
        wallet.updateXswdApplicationPermissions(
          application: staleProjection,
          permissions: const {},
        ),
      );
    });

    test(
      'keeps an admitted session live when Rust reports a later cancellation',
      () async {
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          applications: [_generatedApplication()],
        );
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(callbacks: _callbacks());

        expect(
          await delegate.applicationCallback!(
            _generatedRequest(
              const generated_models.XswdRequestType.application(),
            ),
          ),
          const generated_models.XswdDecisionCallbackOutcome.accept(),
        );
        expect(
          await delegate.cancelCallback!(
            _generatedRequest(
              const generated_models.XswdRequestType.cancelRequest(),
            ),
            false,
          ),
          generated_models.XswdNotificationCallbackOutcome.completed,
        );

        final admitted = (await wallet.getXswdState()).applications.single;
        await wallet.updateXswdApplicationPermissions(
          application: admitted,
          permissions: const {},
        );
        expect(delegate.lastPermissionsSessionRef, BigInt.one);
      },
    );

    test(
      'keeps an admitted session authoritative after a request cancellation',
      () async {
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          applications: [_generatedApplication()],
        );
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(callbacks: _callbacks());
        final application = (await wallet.getXswdState()).applications.single;

        expect(
          await delegate.cancelCallback!(
            _generatedRequest(
              const generated_models.XswdRequestType.cancelRequest(),
            ),
            false,
          ),
          generated_models.XswdNotificationCallbackOutcome.completed,
        );
        await wallet.updateXswdApplicationPermissions(
          application: application,
          permissions: const {},
        );

        expect(delegate.lastPermissionsSessionRef, BigInt.one);
      },
    );

    test(
      'keeps disconnect identity informative but permanently non-operable',
      () async {
        late XelisXswdApplication disconnectedApplication;
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          applications: [_generatedApplication()],
        );
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(
          callbacks: _callbacks(
            onApplicationDisconnect: (request) {
              disconnectedApplication = request.application;
            },
          ),
        );
        final admitted = (await wallet.getXswdState()).applications.single;

        expect(
          await delegate.disconnectCallback!(
            _generatedRequest(
              const generated_models.XswdRequestType.appDisconnect(),
            ),
          ),
          generated_models.XswdNotificationCallbackOutcome.completed,
        );
        expect(
          disconnectedApplication.sessionReference,
          admitted.sessionReference,
        );
        final staleProjection =
            (await wallet.getXswdState()).applications.single;
        expect(staleProjection.sessionReference, admitted.sessionReference);
        await _expectInvalidXswdSession(
          wallet.updateXswdApplicationPermissions(
            application: staleProjection,
            permissions: const {},
          ),
        );
      },
    );

    test(
      'tombstones disconnect identity even when it was not observed before',
      () async {
        late XelisXswdApplication disconnectedApplication;
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          applications: [_generatedApplication()],
        );
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(
          callbacks: _callbacks(
            onApplicationDisconnect: (request) {
              disconnectedApplication = request.application;
            },
          ),
        );

        expect(
          await delegate.disconnectCallback!(
            _generatedRequest(
              const generated_models.XswdRequestType.appDisconnect(),
            ),
          ),
          generated_models.XswdNotificationCallbackOutcome.completed,
        );
        final staleProjection =
            (await wallet.getXswdState()).applications.single;
        expect(
          staleProjection.sessionReference,
          disconnectedApplication.sessionReference,
        );
        await _expectInvalidXswdSession(
          wallet.closeXswdApplicationSession(application: staleProjection),
        );
      },
    );

    test('does not revive a session from a stale state read', () async {
      final staleApplications = [_generatedApplication()];
      final applicationsRead = Completer<List<generated_models.AppInfo>>();
      final disconnectRelease = Completer<void>();
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: staleApplications,
      );
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: XelisXswdCallbacks(
          onCancelRequest: (_) async {},
          onApplicationRequest: (_) async => XelisXswdDecision.accept,
          onPermissionRequest: (_) async => XelisXswdDecision.accept,
          onPrefetchPermissionsRequest: (_) async => XelisXswdDecision.accept,
          onApplicationDisconnect: (_) => disconnectRelease.future,
        ),
      );
      final application = (await wallet.getXswdState()).applications.single;

      delegate.applicationsFuture = applicationsRead.future;
      final staleRead = wallet.getXswdState();
      await Future<void>.delayed(Duration.zero);
      final disconnect = delegate.disconnectCallback!(
        _generatedRequest(
          const generated_models.XswdRequestType.appDisconnect(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await _expectInvalidXswdSession(
        wallet.closeXswdApplicationSession(application: application),
      );
      delegate
        ..applications = const []
        ..applicationsFuture = null;
      applicationsRead.complete(staleApplications);
      final refreshed = await staleRead;
      expect(refreshed.applications, isEmpty);

      disconnectRelease.complete();
      expect(
        await disconnect,
        generated_models.XswdNotificationCallbackOutcome.completed,
      );
    });

    test(
      'does not revive sessions from a state read overtaken by stop',
      () async {
        final staleApplications = [_generatedApplication()];
        final applicationsRead = Completer<List<generated_models.AppInfo>>();
        final delegate = _FakeGeneratedXswdWallet(
          running: true,
          applications: staleApplications,
        );
        final wallet = NativeXelisWallet(delegate);
        final application = (await wallet.getXswdState()).applications.single;

        delegate.applicationsFuture = applicationsRead.future;
        final staleRead = wallet.getXswdState();
        await Future<void>.delayed(Duration.zero);
        await wallet.stopXswd();
        delegate
          ..applications = const []
          ..applicationsFuture = null;
        applicationsRead.complete(staleApplications);

        final refreshed = await staleRead;
        expect(refreshed.isRunning, isFalse);
        expect(refreshed.applications, isEmpty);
        await _expectInvalidXswdSession(
          wallet.updateXswdApplicationPermissions(
            application: application,
            permissions: const {},
          ),
        );
      },
    );

    test('adapts generated callbacks and redacts request payloads', () async {
      late XelisXswdRequest received;
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);
      final callbacks = _callbacks(
        onPermissionRequest: (request) {
          received = request;
          return XelisXswdDecision.alwaysAccept;
        },
      );

      await wallet.startXswd(callbacks: callbacks);
      final generatedPayload = _generatedPayload([
        _objectStart(3),
        _objectKey('jsonrpc'),
        _string('2.0'),
        _objectKey('method'),
        _string('wallet.sign'),
        _objectKey('params'),
        _objectStart(6),
        _objectKey('secret'),
        _string('payload'),
        _objectKey('amount'),
        _integer('9007199254740993'),
        _objectKey('negative'),
        _integer('-9223372036854775808'),
        _objectKey('enabled'),
        _bool(true),
        _objectKey('ratio'),
        _float(1.5),
        _objectKey('items'),
        _arrayStart(2),
        _null(),
        _string('18446744073709551616'),
      ]);
      final decision = await delegate.permissionCallback!(
        _generatedRequest(
          generated_models.XswdRequestType.permission(generatedPayload),
        ),
      );

      expect(
        decision,
        const generated_models.XswdDecisionCallbackOutcome.alwaysAccept(),
      );
      expect(received.kind, XelisXswdRequestKind.permission);
      expect(received.application.id, 'application-id');
      final payload = received.payload as XelisXswdObjectValue;
      final permission = received.permissionRequest!;
      expect(identical(permission.source, received), isTrue);
      expect(permission.method, 'wallet.sign');
      final parameters = permission.parameters! as XelisXswdObjectValue;
      expect(
        (parameters.fields['amount'] as XelisXswdIntegerValue).value,
        BigInt.parse('9007199254740993'),
      );
      expect(
        (parameters.fields['negative'] as XelisXswdIntegerValue).value,
        BigInt.parse('-9223372036854775808'),
      );
      expect(
        (parameters.fields['enabled'] as XelisXswdBoolValue).value,
        isTrue,
      );
      expect((parameters.fields['ratio'] as XelisXswdFloatValue).value, 1.5);
      final items = parameters.fields['items'] as XelisXswdArrayValue;
      expect(items.values.first, isA<XelisXswdNullValue>());
      expect(
        (items.values.last as XelisXswdStringValue).value,
        '18446744073709551616',
      );
      expect(
        () => payload.fields['other'] = const XelisXswdNullValue(),
        throwsUnsupportedError,
      );
      expect(
        () => items.values.add(const XelisXswdNullValue()),
        throwsUnsupportedError,
      );
      expect(received.toString(), isNot(contains('wallet.sign')));
      expect(received.toString(), isNot(contains('payload')));
      expect(permission.toString(), isNot(contains('wallet.sign')));
      expect(payload.toString(), isNot(contains('method')));
      expect(payload.toString(), isNot(contains('wallet.sign')));
      expect(
        parameters.fields['secret'].toString(),
        isNot(contains('payload')),
      );
      expect(generatedPayload.toString(), isNot(contains('payload')));
      expect(generatedPayload.tokens[4].toString(), isNot(contains('payload')));
      expect(
        generated_models.XswdRequestType.permission(generatedPayload)
            .toString(),
        isNot(contains('payload')),
      );
    });

    test('projects a source-bound prefetch request', () async {
      late XelisXswdPrefetchPermissionsRequest received;
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: _callbacks(
          onPrefetchPermissionsRequest: (request) {
            received = request.prefetchPermissionsRequest!;
            return XelisXswdDecision.accept;
          },
        ),
      );

      final outcome = await delegate.prefetchCallback!(
        _generatedRequest(
          generated_models.XswdRequestType.prefetchPermissions(
            _validPrefetchPayload(),
          ),
        ),
      );

      expect(
        outcome,
        const generated_models.XswdDecisionCallbackOutcome.accept(),
      );
      expect(received.reason, 'Account overview');
      expect(received.permissions, ['get_balance', 'subscribe']);
      expect(received.source.prefetchPermissionsRequest, same(received));
      expect(received.toString(), isNot(contains('Account overview')));
      expect(received.toString(), isNot(contains('get_balance')));
      expect(
        () => received.permissions.add('get_asset'),
        throwsUnsupportedError,
      );
    });

    test(
      'selective prefetch callback takes priority over the legacy callback',
      () async {
        var legacyCalls = 0;
        late XelisXswdPrefetchPermissionsRequest received;
        final selectiveDecision = XelisXswdPrefetchDecision.grant(const [
          'subscribe',
        ]);
        final delegate = _FakeGeneratedXswdWallet();
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(
          callbacks: _callbacks(
            onPrefetchPermissionsRequest: (_) {
              legacyCalls++;
              return XelisXswdDecision.accept;
            },
            onPrefetchPermissionsReview: (request) {
              received = request;
              return selectiveDecision;
            },
          ),
        );

        final outcome = await delegate.prefetchCallback!(
          _generatedRequest(
            generated_models.XswdRequestType.prefetchPermissions(
              _validPrefetchPayload(),
            ),
          ),
        );

        expect(legacyCalls, 0);
        expect(received.permissions, ['get_balance', 'subscribe']);
        expect(
          outcome,
          const generated_models.XswdDecisionCallbackOutcome.prefetchGrant(
            permissions: ['subscribe'],
          ),
        );
        expect(selectiveDecision.toString(), isNot(contains('subscribe')));
      },
    );

    test('selective prefetch noChange has a distinct bridge outcome', () async {
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: _callbacks(
          onPrefetchPermissionsReview: (_) =>
              const XelisXswdPrefetchDecision.noChange(),
        ),
      );

      final outcome = await delegate.prefetchCallback!(
        _generatedRequest(
          generated_models.XswdRequestType.prefetchPermissions(
            _validPrefetchPayload(),
          ),
        ),
      );

      expect(
        outcome,
        const generated_models.XswdDecisionCallbackOutcome.prefetchNoChange(),
      );
    });

    test('preserves JSON null and positional permission parameters', () {
      final positional = xelisXswdRequestFromGenerated(
        _generatedRequest(
          generated_models.XswdRequestType.permission(
            _generatedPayload([
              _objectStart(3),
              _objectKey('jsonrpc'),
              _string('2.0'),
              _objectKey('method'),
              _string('get_balance'),
              _objectKey('params'),
              _arrayStart(1),
              _integer('9007199254740993'),
            ]),
          ),
        ),
      );
      final explicitNull = xelisXswdRequestFromGenerated(
        _generatedRequest(
          generated_models.XswdRequestType.prefetchPermissions(
            _generatedPayload([
              _objectStart(2),
              _objectKey('reason'),
              _null(),
              _objectKey('permissions'),
              _arrayStart(0),
            ]),
          ),
        ),
      );

      expect(
        positional.permissionRequest!.parameters,
        isA<XelisXswdArrayValue>(),
      );
      expect(explicitNull.prefetchPermissionsRequest!.reason, isNull);
    });

    test(
      'reports callback exceptions and timeouts as technical outcomes',
      () async {
        final delegate = _FakeGeneratedXswdWallet();
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(
          callbacks: _callbacks(
            timeout: const Duration(microseconds: 1),
            onCancelRequest: (_) => throw StateError('sensitive callback data'),
            onPermissionRequest: (_) => Completer<XelisXswdDecision>().future,
          ),
        );

        await expectLater(
          delegate.cancelCallback!(
            _generatedRequest(
              const generated_models.XswdRequestType.cancelRequest(),
            ),
            false,
          ),
          completion(
            generated_models.XswdNotificationCallbackOutcome.exception,
          ),
        );
        expect(
          await delegate.permissionCallback!(
            _generatedRequest(
              generated_models.XswdRequestType.permission(
                _validPermissionPayload(),
              ),
            ),
          ),
          const generated_models.XswdDecisionCallbackOutcome.timeout(),
        );
      },
    );

    test(
      'forwards configurable projection limits and validates ceilings',
      () async {
        final delegate = _FakeGeneratedXswdWallet();
        final wallet = NativeXelisWallet(delegate);
        const limits = XelisXswdProjectionLimits(
          maxDepth: 12,
          maxTokens: 1234,
          maxContainerMembers: 123,
          maxTextBytes: 456,
          maxTotalTextBytes: 789,
        );

        await wallet.startXswd(callbacks: _callbacks(limits: limits));
        expect(delegate.lastProjectionLimits?.maxDepth, 12);
        expect(delegate.lastProjectionLimits?.maxTokens, 1234);
        expect(delegate.lastProjectionLimits?.maxContainerMembers, 123);
        expect(delegate.lastProjectionLimits?.maxTextBytes, 456);
        expect(delegate.lastProjectionLimits?.maxTotalTextBytes, 789);

        final invalidCallbacks = [
          _callbacks(timeout: Duration.zero),
          _callbacks(limits: const XelisXswdProjectionLimits(maxDepth: 0)),
          _callbacks(
            limits: const XelisXswdProjectionLimits(
              maxDepth: XelisXswdProjectionLimits.technicalMaxDepth + 1,
            ),
          ),
          _callbacks(
            limits: const XelisXswdProjectionLimits(
              maxTextBytes: 1024,
              maxTotalTextBytes: 1023,
            ),
          ),
        ];
        for (final callbacks in invalidCallbacks) {
          await expectLater(
            wallet.startXswd(callbacks: callbacks),
            throwsA(
              isA<XelisWalletException>().having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.invalidInput,
              ),
            ),
          );
        }
      },
    );

    test(
      'rejects malformed private payloads before the consumer callback',
      () async {
        var callbackCalls = 0;
        final delegate = _FakeGeneratedXswdWallet();
        final wallet = NativeXelisWallet(delegate);
        await wallet.startXswd(
          callbacks: _callbacks(
            onPermissionRequest: (_) {
              callbackCalls++;
              return XelisXswdDecision.accept;
            },
          ),
        );

        final malformedPayloads = [
          _generatedPayload([_string('not-an-object')]),
          _generatedPayload([_objectStart(1), _objectKey('missing')]),
          _generatedPayload([
            _objectStart(1),
            _objectKey('integer'),
            _integer('01'),
          ]),
          _generatedPayload([
            _objectStart(2),
            _objectKey('duplicate'),
            _null(),
            _objectKey('duplicate'),
            _null(),
          ]),
          _generatedPayload([_objectStart(0), _null()]),
          _generatedPayload([
            const generated_models.NativeXswdPayloadToken(
              kind: generated_models.NativeXswdPayloadTokenKind.null_,
              textValue: 'unexpected',
            ),
          ]),
        ];

        for (final payload in malformedPayloads) {
          expect(
            await delegate.permissionCallback!(
              _generatedRequest(
                generated_models.XswdRequestType.permission(payload),
              ),
            ),
            const generated_models.XswdDecisionCallbackOutcome.invalidPayload(),
          );
        }
        expect(callbackCalls, 0);
      },
    );

    test('rejects malformed semantic envelopes before callbacks', () async {
      var permissionCalls = 0;
      var prefetchCalls = 0;
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: _callbacks(
          onPermissionRequest: (_) {
            permissionCalls++;
            return XelisXswdDecision.accept;
          },
          onPrefetchPermissionsRequest: (_) {
            prefetchCalls++;
            return XelisXswdDecision.accept;
          },
        ),
      );

      expect(
        await delegate.permissionCallback!(
          _generatedRequest(
            generated_models.XswdRequestType.permission(
              _generatedPayload([_objectStart(0)]),
            ),
          ),
        ),
        const generated_models.XswdDecisionCallbackOutcome.invalidPayload(),
      );
      expect(
        await delegate.prefetchCallback!(
          _generatedRequest(
            generated_models.XswdRequestType.prefetchPermissions(
              _generatedPayload([
                _objectStart(1),
                _objectKey('permissions'),
                _arrayStart(1),
                _integer('1'),
              ]),
            ),
          ),
        ),
        const generated_models.XswdDecisionCallbackOutcome.invalidPayload(),
      );
      expect(permissionCalls, 0);
      expect(prefetchCalls, 0);
    });

    test('rejects invalid relayer keys before the generated call', () async {
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);
      final relayer = XelisXswdRelayer(
        id: 'relay-id',
        name: 'relay-name',
        description: '',
        url: null,
        permissions: const [],
        relayer: 'wss://relay.example',
        encryption: XelisXswdEncryption(
          algorithm: XelisXswdEncryptionAlgorithm.aes,
          key: const [1, 2, 3],
        ),
      );

      await expectLater(
        wallet.addXswdRelayer(relayer: relayer, callbacks: _callbacks()),
        throwsA(
          isA<XelisWalletException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.walletXswdRelayerAdd,
              )
              .having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.invalidInput,
              ),
        ),
      );
      expect(delegate.relayerCalls, 0);
    });

    test('rejects prefixed permission names before generated calls', () async {
      final delegate = _FakeGeneratedXswdWallet(
        running: true,
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      final application = (await wallet.getXswdState()).applications.single;

      await expectLater(
        wallet.updateXswdApplicationPermissions(
          application: application,
          permissions: const {
            'wallet.get_balance': XelisXswdPermissionPolicy.accept,
          },
        ),
        throwsA(
          isA<XelisWalletException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.walletXswdPermissionsUpdate,
              )
              .having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.invalidInput,
              )
              .having(
                (error) => error.nativeKind,
                'nativeKind',
                'XSWD_PERMISSION_NAME_INVALID',
              ),
        ),
      );
      expect(delegate.lastPermissions, isNull);

      final relayer = XelisXswdRelayer(
        id: 'relay-id',
        name: 'relay-name',
        description: '',
        url: null,
        permissions: const ['wallet.get_balance'],
        relayer: 'wss://relay.example',
      );
      await expectLater(
        wallet.addXswdRelayer(relayer: relayer, callbacks: _callbacks()),
        throwsA(
          isA<XelisWalletException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.walletXswdRelayerAdd,
              )
              .having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.invalidInput,
              )
              .having(
                (error) => error.nativeKind,
                'nativeKind',
                'XSWD_PERMISSION_NAME_INVALID',
              ),
        ),
      );
      expect(delegate.relayerCalls, 0);
    });

    test('authors an exact operation for every generated failure', () async {
      final failure = AnyhowException('sensitive XSWD diagnostic payload');

      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(startFailure: failure),
        ),
        call: (wallet) => wallet.startXswd(callbacks: _callbacks()),
        operation: XelisWalletOperation.walletXswdStart,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(running: true, stopFailure: failure),
        ),
        call: (wallet) => wallet.stopXswd(),
        operation: XelisWalletOperation.walletXswdStop,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(running: true, stateFailure: failure),
        ),
        call: (wallet) async {
          await wallet.getXswdState();
        },
        operation: XelisWalletOperation.walletXswdStateRead,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(relayerFailure: failure),
        ),
        call: (wallet) => wallet.addXswdRelayer(
          relayer: XelisXswdRelayer(
            id: 'id',
            name: 'name',
            description: '',
            url: null,
            permissions: const [],
            relayer: 'wss://relay.example',
          ),
          callbacks: _callbacks(),
        ),
        operation: XelisWalletOperation.walletXswdRelayerAdd,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(
            running: true,
            applications: [_generatedApplication()],
            sessionFailure: failure,
          ),
        ),
        call: (wallet) async => wallet.closeXswdApplicationSession(
          application: (await wallet.getXswdState()).applications.single,
        ),
        operation: XelisWalletOperation.walletXswdSessionClose,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(
            running: true,
            applications: [_generatedApplication()],
            permissionsFailure: failure,
          ),
        ),
        call: (wallet) async => wallet.updateXswdApplicationPermissions(
          application: (await wallet.getXswdState()).applications.single,
          permissions: const {},
        ),
        operation: XelisWalletOperation.walletXswdPermissionsUpdate,
      );
    });
  });
}

Future<void> _expectXswdOperation({
  required NativeXelisWallet wallet,
  required Future<void> Function(NativeXelisWallet wallet) call,
  required XelisWalletOperation operation,
}) async {
  try {
    await call(wallet);
    fail('XSWD operation should throw');
  } on XelisWalletException catch (error) {
    expect(error.operation, operation);
    expect(error.code, XelisWalletErrorCode.operationFailed);
    expect(error.toString(), isNot(contains('sensitive')));
    expect(error.toString(), isNot(contains('payload')));
  }
}

Future<void> _expectInvalidXswdSession(Future<void> future) => expectLater(
  future,
  throwsA(
    isA<XelisWalletException>()
        .having((error) => error.code, 'code', XelisWalletErrorCode.conflict)
        .having(
          (error) => error.nativeKind,
          'nativeKind',
          'XSWD_SESSION_REFERENCE_INVALID',
        ),
  ),
);

Future<void> _expectXswdOperationInProgress(
  Future<void> future,
  XelisWalletOperation operation,
) => expectLater(
  future,
  throwsA(
    isA<XelisWalletException>()
        .having((error) => error.operation, 'operation', operation)
        .having((error) => error.code, 'code', XelisWalletErrorCode.conflict)
        .having(
          (error) => error.nativeKind,
          'nativeKind',
          'XSWD_APPLICATION_OPERATION_IN_PROGRESS',
        ),
  ),
);

XelisXswdCallbacks _callbacks({
  Duration timeout = const Duration(minutes: 1),
  XelisXswdProjectionLimits limits = const XelisXswdProjectionLimits(),
  XelisXswdNotificationCallback? onCancelRequest,
  XelisXswdDecisionCallback? onApplicationRequest,
  XelisXswdDecisionCallback? onPermissionRequest,
  XelisXswdDecisionCallback? onPrefetchPermissionsRequest,
  XelisXswdPrefetchDecisionCallback? onPrefetchPermissionsReview,
  XelisXswdNotificationCallback? onApplicationDisconnect,
  XelisXswdApplicationStateObservationCallback? onApplicationStateObservation,
}) => XelisXswdCallbacks(
  timeout: timeout,
  projectionLimits: limits,
  onCancelRequest: onCancelRequest ?? (_) async {},
  onApplicationRequest:
      onApplicationRequest ?? (_) async => XelisXswdDecision.accept,
  onPermissionRequest:
      onPermissionRequest ?? (_) async => XelisXswdDecision.accept,
  onPrefetchPermissionsRequest:
      onPrefetchPermissionsRequest ?? (_) async => XelisXswdDecision.accept,
  onPrefetchPermissionsReview: onPrefetchPermissionsReview,
  onApplicationDisconnect: onApplicationDisconnect ?? (_) async {},
  onApplicationStateObservation: onApplicationStateObservation,
);

generated_models.AppInfo _generatedApplication({
  BigInt? sessionRef,
  String id = 'application-id',
  bool isRelayer = false,
  Map<String, generated_models.PermissionPolicy>? permissions,
}) => generated_models.AppInfo(
  sessionRef: sessionRef ?? BigInt.one,
  id: id,
  name: 'application-name',
  description: 'application-description',
  url: 'https://application.example',
  permissions:
      permissions ?? {'get_balance': generated_models.PermissionPolicy.ask},
  isRelayer: isRelayer,
);

generated_models.XswdRequestSummary _generatedRequest(
  generated_models.XswdRequestType type,
) => generated_models.XswdRequestSummary(
  eventType: type,
  applicationInfo: _generatedApplication(),
);

generated_models.NativeXswdPayload _generatedPayload(
  List<generated_models.NativeXswdPayloadToken> tokens,
) => generated_models.NativeXswdPayload(tokens: tokens);

generated_models.NativeXswdPayload _validPermissionPayload() =>
    _generatedPayload([
      _objectStart(2),
      _objectKey('jsonrpc'),
      _string('2.0'),
      _objectKey('method'),
      _string('get_balance'),
    ]);

generated_models.NativeXswdPayload _validPrefetchPayload() =>
    _generatedPayload([
      _objectStart(2),
      _objectKey('reason'),
      _string('Account overview'),
      _objectKey('permissions'),
      _arrayStart(2),
      _string('get_balance'),
      _string('subscribe'),
    ]);

generated_models.NativeXswdPayloadToken _null() =>
    const generated_models.NativeXswdPayloadToken(
      kind: generated_models.NativeXswdPayloadTokenKind.null_,
    );

generated_models.NativeXswdPayloadToken _bool(bool value) =>
    generated_models.NativeXswdPayloadToken(
      kind: generated_models.NativeXswdPayloadTokenKind.bool,
      boolValue: value,
    );

generated_models.NativeXswdPayloadToken _string(String value) =>
    generated_models.NativeXswdPayloadToken(
      kind: generated_models.NativeXswdPayloadTokenKind.stringValue,
      textValue: value,
    );

generated_models.NativeXswdPayloadToken _integer(String value) =>
    generated_models.NativeXswdPayloadToken(
      kind: generated_models.NativeXswdPayloadTokenKind.integer,
      textValue: value,
    );

generated_models.NativeXswdPayloadToken _float(double value) =>
    generated_models.NativeXswdPayloadToken(
      kind: generated_models.NativeXswdPayloadTokenKind.float,
      floatValue: value,
    );

generated_models.NativeXswdPayloadToken _arrayStart(int length) =>
    generated_models.NativeXswdPayloadToken(
      kind: generated_models.NativeXswdPayloadTokenKind.arrayStart,
      length: length,
    );

generated_models.NativeXswdPayloadToken _objectStart(int length) =>
    generated_models.NativeXswdPayloadToken(
      kind: generated_models.NativeXswdPayloadTokenKind.objectStart,
      length: length,
    );

generated_models.NativeXswdPayloadToken _objectKey(String value) =>
    generated_models.NativeXswdPayloadToken(
      kind: generated_models.NativeXswdPayloadTokenKind.objectKey,
      textValue: value,
    );

final class _FakeGeneratedXswdWallet implements generated_wallet.XelisWallet {
  _FakeGeneratedXswdWallet({
    this.running = false,
    this.applications = const [],
    this.startFailure,
    this.stopFailure,
    this.stateFailure,
    this.relayerFailure,
    this.sessionFailure,
    this.permissionsFailure,
  });

  bool running;
  List<generated_models.AppInfo> applications;
  Future<List<generated_models.AppInfo>>? applicationsFuture;
  final Object? startFailure;
  final Object? stopFailure;
  final Object? stateFailure;
  final Object? relayerFailure;
  Object? sessionFailure;
  final Object? permissionsFailure;

  var startCalls = 0;
  var stopCalls = 0;
  var relayerCalls = 0;
  var stateReadCalls = 0;
  Completer<void>? relayerGate;
  Completer<void>? closeGate;
  Completer<void>? stopGate;
  final operationOrder = <String>[];
  BigInt? closedSessionRef;
  BigInt? lastPermissionsSessionRef;
  Map<String, generated_models.PermissionPolicy>? lastPermissions;
  String? lastPermission;
  generated_models.PermissionPolicy? lastPermissionPolicy;
  generated_models.ApplicationDataRelayer? lastRelayer;
  generated_models.NativeXswdProjectionLimits? lastProjectionLimits;
  FutureOr<generated_models.XswdNotificationCallbackOutcome> Function(
    generated_models.XswdRequestSummary,
    bool,
  )?
  cancelCallback;
  FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
    generated_models.XswdRequestSummary,
  )?
  permissionCallback;
  FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
    generated_models.XswdRequestSummary,
  )?
  applicationCallback;
  FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
    generated_models.XswdRequestSummary,
  )?
  prefetchCallback;
  FutureOr<generated_models.XswdNotificationCallbackOutcome> Function(
    generated_models.XswdRequestSummary,
  )?
  disconnectCallback;

  @override
  bool get isDisposed => false;

  @override
  Future<bool> isXswdRunning() async => running;

  @override
  Future<void> startXswd({
    required generated_models.NativeXswdProjectionLimits projectionLimits,
    required FutureOr<generated_models.XswdNotificationCallbackOutcome>
    Function(generated_models.XswdRequestSummary, bool)
    cancelRequestDartCallback,
    required FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
      generated_models.XswdRequestSummary,
    )
    requestApplicationDartCallback,
    required FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
      generated_models.XswdRequestSummary,
    )
    requestPermissionDartCallback,
    required FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
      generated_models.XswdRequestSummary,
    )
    requestPrefetchPermissionsDartCallback,
    required FutureOr<generated_models.XswdNotificationCallbackOutcome>
    Function(generated_models.XswdRequestSummary)
    appDisconnectDartCallback,
  }) async {
    startCalls++;
    if (startFailure case final error?) throw error;
    lastProjectionLimits = projectionLimits;
    cancelCallback = cancelRequestDartCallback;
    applicationCallback = requestApplicationDartCallback;
    permissionCallback = requestPermissionDartCallback;
    prefetchCallback = requestPrefetchPermissionsDartCallback;
    disconnectCallback = appDisconnectDartCallback;
    running = true;
  }

  @override
  Future<void> stopXswd() async {
    stopCalls++;
    await stopGate?.future;
    if (stopFailure case final error?) throw error;
    running = false;
  }

  @override
  Future<List<generated_models.AppInfo>> getApplicationPermissions() async {
    stateReadCalls++;
    if (stateFailure case final error?) throw error;
    if (applicationsFuture case final future?) return future;
    return applications;
  }

  @override
  Future<void> addXswdRelayer({
    required generated_models.ApplicationDataRelayer appData,
    required generated_models.NativeXswdProjectionLimits projectionLimits,
    required FutureOr<generated_models.XswdNotificationCallbackOutcome>
    Function(generated_models.XswdRequestSummary, bool)
    cancelRequestDartCallback,
    required FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
      generated_models.XswdRequestSummary,
    )
    requestApplicationDartCallback,
    required FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
      generated_models.XswdRequestSummary,
    )
    requestPermissionDartCallback,
    required FutureOr<generated_models.XswdDecisionCallbackOutcome> Function(
      generated_models.XswdRequestSummary,
    )
    requestPrefetchPermissionsDartCallback,
    required FutureOr<generated_models.XswdNotificationCallbackOutcome>
    Function(generated_models.XswdRequestSummary)
    appDisconnectDartCallback,
  }) async {
    relayerCalls++;
    operationOrder.add('add:start');
    await relayerGate?.future;
    if (relayerFailure case final error?) throw error;
    lastRelayer = appData;
    operationOrder.add('add:end');
  }

  @override
  Future<void> closeApplicationSession({required BigInt sessionRef}) async {
    if (sessionFailure case final error?) throw error;
    operationOrder.add('close:start');
    await closeGate?.future;
    closedSessionRef = sessionRef;
    operationOrder.add('close:end');
  }

  @override
  Future<void> modifyApplicationPermissions({
    required BigInt sessionRef,
    required Map<String, generated_models.PermissionPolicy> permissions,
  }) async {
    if (permissionsFailure case final error?) throw error;
    lastPermissionsSessionRef = sessionRef;
    lastPermissions = permissions;
  }

  @override
  Future<generated_models.AppInfo> modifyApplicationPermission({
    required BigInt sessionRef,
    required String permission,
    required generated_models.PermissionPolicy policy,
  }) async {
    if (permissionsFailure case final error?) throw error;
    lastPermissionsSessionRef = sessionRef;
    lastPermission = permission;
    lastPermissionPolicy = policy;
    final index = applications.indexWhere(
      (application) => application.sessionRef == sessionRef,
    );
    if (index < 0) throw StateError('Missing fake application');
    final current = applications[index];
    final updated = generated_models.AppInfo(
      sessionRef: current.sessionRef,
      id: current.id,
      name: current.name,
      description: current.description,
      url: current.url,
      permissions: {...current.permissions, permission: policy},
      isRelayer: current.isRelayer,
    );
    applications = [...applications]..[index] = updated;
    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
