part of 'xelis_wallet_adapter.dart';

/// Wallet-owned XSWD identities and admission state, kept out of the public API.
/// Transport calls and wallet lifecycle guards remain in [NativeXelisWallet].
final class _NativeXswdState {
  final _applicationCapabilities = Expando<_NativeXswdSessionCapability>(
    'xelis-xswd-session',
  );
  final _capabilities = <BigInt, _NativeXswdSessionCapability>{};
  var _revision = 0;

  int get revision => _revision;

  GeneratedXswdCallbacks generatedCallbacks(XelisXswdCallbacks callbacks) =>
      generatedXswdCallbacksFromXelis(
        callbacks,
        applicationAdapter: adaptApplication,
        onApplicationDecisionStarted: _startXswdApplicationDecision,
        onApplicationDecisionCompleted: _completeXswdApplicationDecision,
        onCancelRequestStarted: _startXswdRequestCancellation,
        onApplicationDisconnectStarted: _startXswdApplicationDisconnect,
      );

  XelisXswdApplication adaptApplication(
    generated_xswd.AppInfo native, {
    bool observedInState = false,
  }) {
    final capability = _capabilities.putIfAbsent(
      native.sessionRef,
      () => _NativeXswdSessionCapability(native.sessionRef),
    );
    if (observedInState) {
      capability.admitted = true;
      capability.pendingApplicationDecision = false;
    }
    final application = xelisXswdApplicationFromGenerated(
      native,
      sessionIdentity: capability.identity,
    );
    _applicationCapabilities[application] = capability;
    return application;
  }

  void _startXswdApplicationDecision(generated_xswd.AppInfo application) {
    final capability = _capabilityForNative(application);
    capability.pendingApplicationDecision = true;
  }

  void _completeXswdApplicationDecision(
    generated_xswd.AppInfo application,
    generated_xswd.XswdDecisionCallbackOutcome outcome,
  ) {
    final capability = _capabilities[application.sessionRef];
    if (capability == null || !capability.active) {
      return;
    }
    final accepted = switch (outcome) {
      generated_xswd.XswdDecisionCallbackOutcome_Accept() ||
      generated_xswd.XswdDecisionCallbackOutcome_AlwaysAccept() => true,
      _ => false,
    };
    if (accepted) {
      // Upstream inserts the application only after this callback returns.
      // Preserve its identity until a fresh state read confirms admission.
      capability.pendingApplicationDecision = true;
    } else {
      _invalidate(capability);
    }
  }

  void _startXswdRequestCancellation(
    generated_xswd.AppInfo application,
    bool cancelledApplicationAdmission,
  ) {
    if (cancelledApplicationAdmission) {
      tombstone(_capabilityForNative(application));
    }
  }

  void _startXswdApplicationDisconnect(generated_xswd.AppInfo application) {
    final capability = _capabilityForNative(application);
    // Preserve the exact opaque identity for the informational disconnect
    // projection without leaving an operable entry that a stale state read
    // could revive. This also fails closed when disconnect is the first event
    // observed for the native session.
    tombstone(capability);
  }

  _NativeXswdSessionCapability _capabilityForNative(
    generated_xswd.AppInfo application,
  ) => _capabilities.putIfAbsent(
    application.sessionRef,
    () => _NativeXswdSessionCapability(application.sessionRef),
  );

  _NativeXswdSessionCapability capability(
    XelisXswdApplication application, {
    required XelisWalletOperation operation,
  }) {
    final capability = _applicationCapabilities[application];
    if (capability == null ||
        !capability.active ||
        !capability.admitted ||
        !identical(_capabilities[capability.sessionRef], capability)) {
      throw xelisOperationPreconditionException(
        operation: operation,
        code: XelisWalletErrorCode.conflict,
        nativeKind: 'XSWD_SESSION_REFERENCE_INVALID',
        diagnosticMessage:
            'The XSWD session reference is stale, reconstructed, disconnected, '
            'or owned by another wallet handle.',
      );
    }
    return capability;
  }

  void reconcile(List<generated_xswd.AppInfo> applications) {
    final current = applications.map((application) => application.sessionRef);
    final currentReferences = current.toSet();
    final stale = _capabilities.entries
        .where(
          (entry) =>
              !currentReferences.contains(entry.key) &&
              !entry.value.pendingApplicationDecision,
        )
        .map((entry) => entry.value)
        .toList(growable: false);
    for (final capability in stale) {
      _invalidate(capability);
    }
  }

  void _invalidate(_NativeXswdSessionCapability capability) {
    if (!capability.active &&
        !identical(_capabilities[capability.sessionRef], capability)) {
      return;
    }
    capability.active = false;
    capability.pendingApplicationDecision = false;
    if (identical(_capabilities[capability.sessionRef], capability)) {
      _capabilities.remove(capability.sessionRef);
    }
    _revision++;
  }

  void tombstone(_NativeXswdSessionCapability capability) {
    if (!capability.active) {
      return;
    }
    capability.active = false;
    capability.pendingApplicationDecision = false;
    _revision++;
  }

  void invalidateAll() {
    for (final capability in _capabilities.values) {
      capability.active = false;
      capability.pendingApplicationDecision = false;
    }
    _capabilities.clear();
    _revision++;
  }
}

final class _NativeXswdSessionCapability {
  _NativeXswdSessionCapability(this.sessionRef);

  final BigInt sessionRef;
  final Object identity = Object();
  var active = true;
  var admitted = false;
  var pendingApplicationDecision = false;
}
