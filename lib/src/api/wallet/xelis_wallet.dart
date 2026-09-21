import '../assets/xelis_wallet_asset.dart';
import '../address_book/xelis_address_book.dart';
import '../data/xelis_data_element.dart';
import '../history/xelis_wallet_history_filter.dart';
import '../models/xelis_network.dart';
import '../multisig/xelis_wallet_multisig.dart';
import '../events/xelis_wallet_business_event_subscription.dart';
import '../runtime/xelis_daemon_info.dart';
import '../runtime/xelis_wallet_runtime_event_subscription.dart';
import '../seed/seed_language.dart';
import '../transactions/xelis_wallet_prepared_transaction.dart';
import '../transactions/xelis_wallet_transaction.dart';
import '../xswd/xelis_xswd.dart';

enum XelisWalletReconnectPolicy {
  applicationManaged,
  upstreamManagedExperimental,
}

final class XelisWalletConnectionOptions {
  const XelisWalletConnectionOptions({
    this.timeout = const Duration(seconds: 20),
    this.reconnectPolicy = XelisWalletReconnectPolicy.applicationManaged,
  });

  final Duration timeout;
  final XelisWalletReconnectPolicy reconnectPolicy;
}

/// Stable Dart handle for one opened native XELIS wallet.
///
/// The underlying Flutter Rust Bridge opaque handle is deliberately private.
/// Passwords and returned seed material are never persisted or logged by this
/// contract. They necessarily exist in bridge memory while a call is running.
abstract interface class XelisWallet {
  /// Whether the local native handle has been released.
  bool get isDisposed;

  /// Address of this wallet on its configured [network].
  String get address;

  /// Network selected when this wallet was created or opened.
  XelisNetwork get network;

  /// Returns the wallet seed encoded using [language].
  ///
  /// The returned value is secret key material. Consumers must never log,
  /// retain unnecessarily, or expose it outside an explicit recovery flow.
  Future<String> getSeed({SeedLanguage language = SeedLanguage.english});

  /// Verifies [password] against this wallet.
  ///
  /// A failure is reported as a structured [XelisWalletException] by the
  /// implementation. The password itself is never retained or logged.
  Future<void> verifyPassword({required String password});

  /// Re-encrypts this wallet with [newPassword] after verifying [oldPassword].
  ///
  /// Both values are passed directly to the native wallet and are never
  /// retained or logged. Consumers remain responsible for synchronizing any
  /// separately persisted biometric credential after this call succeeds.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Connects this wallet to one daemon origin and starts synchronization.
  ///
  /// The address must use `http`, `https`, `ws`, or `wss`, include a host, and
  /// contain no credentials, path, query, or fragment. The native boundary
  /// verifies that the daemon network matches [network] before starting sync.
  Future<void> setOnline({
    required String daemonAddress,
    XelisWalletConnectionOptions options = const XelisWalletConnectionOptions(),
  });

  /// Stops this wallet's daemon connection.
  ///
  /// Calling this while the wallet is already offline succeeds.
  Future<void> setOffline();

  /// Whether the native wallet currently owns an online network handler.
  Future<bool> isOnline();

  /// Whether the native wallet storage is currently synchronizing.
  Future<bool> isSyncing();

  /// Starts the local XSWD server with authored consumer [callbacks].
  ///
  /// This operation is idempotent while XSWD is already running. Local-server
  /// availability remains platform and build dependent; relay mode is exposed
  /// separately through [addXswdRelayer].
  Future<void> startXswd({required XelisXswdCallbacks callbacks});

  /// Stops the local server and every relayed XSWD session.
  ///
  /// Calling this while XSWD is already stopped succeeds.
  Future<void> stopXswd();

  /// Reads the current XSWD lifecycle and connected applications.
  Future<XelisXswdState> getXswdState();

  /// Adds one untrusted, previously parsed relayer configuration.
  Future<void> addXswdRelayer({
    required XelisXswdRelayer relayer,
    required XelisXswdCallbacks callbacks,
  });

  /// Closes the exact live XSWD [application] session.
  ///
  /// Reconstructed, stale, and other-wallet projections are rejected.
  Future<void> closeXswdApplicationSession({
    required XelisXswdApplication application,
  });

  /// Updates the supplied retained permission policies for the exact live
  /// [application] session while preserving every other policy.
  ///
  /// Permission keys use unprefixed method identifiers such as `get_balance`.
  /// A prefixed identifier such as `wallet.get_balance` fails before the native
  /// call with `input.invalid / XSWD_PERMISSION_NAME_INVALID`.
  Future<void> updateXswdApplicationPermissions({
    required XelisXswdApplication application,
    required Map<String, XelisXswdPermissionPolicy> permissions,
  });

  /// Updates one retained permission of the exact live [application] session
  /// and returns a fresh native projection of that same session.
  ///
  /// Other permissions are preserved. Reconstructed, stale, and other-wallet
  /// projections are rejected.
  Future<XelisXswdApplication> updateXswdApplicationPermission({
    required XelisXswdApplication application,
    required String permission,
    required XelisXswdPermissionPolicy policy,
  });

  /// Opens a new pull-driven runtime and synchronization event subscription.
  ///
  /// The native receiver is installed before this future completes. Consumers
  /// should therefore create the subscription after [setOffline] and before
  /// [setOnline] when rotating a connection. The returned stream has one
  /// listener and must be cancelled and awaited before the next rotation.
  Future<XelisWalletRuntimeEventSubscription> subscribeRuntimeEvents();

  /// Opens the business-event subscription for this wallet session.
  ///
  /// Unlike [subscribeRuntimeEvents], this subscription remains active while
  /// the wallet is offline and across connection rotations. Consumers must
  /// cancel it only when replacing or closing the wallet session.
  Future<XelisWalletBusinessEventSubscription> subscribeBusinessEvents({
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.redacted,
  });

  /// Reads the native XELIS balance in atomic units.
  ///
  /// Returns zero only when no balance exists. Storage failures are reported
  /// as [XelisWalletException] and are never converted to a zero balance.
  Future<BigInt> getXelisBalance();

  /// Reads every tracked asset balance in atomic units, keyed by asset hash.
  Future<Map<String, BigInt>> getTrackedBalances();

  /// Reads all asset metadata known by the wallet, keyed by asset hash.
  Future<Map<String, XelisWalletAssetMetadata>> getKnownAssets();

  /// Resolves typed metadata for [asset].
  Future<XelisWalletAssetMetadata> getAssetMetadata({required String asset});

  /// Adds [asset] to the wallet's tracked set.
  Future<bool> trackAsset({required String asset});

  /// Removes [asset] from the wallet's tracked set.
  Future<bool> untrackAsset({required String asset});

  /// Copies legacy contacts into the package-owned v2 address book.
  ///
  /// The migration is idempotent and never modifies or deletes the legacy
  /// tree. Normal callers do not need to invoke it because every v2 operation
  /// ensures it has completed first.
  Future<XelisAddressBookMigrationResult> migrateAddressBook();

  /// Lists saved destinations after filtering and pagination.
  Future<XelisAddressBookPage> addressBookEntries({
    String? query,
    int skip = 0,
    int? take,
  });

  /// Creates or updates the entry identified by [address]'s complete canonical
  /// destination. Integrated addresses sharing one base remain distinct.
  Future<XelisAddressBookEntry> upsertAddressBookEntry({
    required String address,
    required String displayName,
    String? destinationLabel,
    String? note,
  });

  /// Removes the entry with the opaque package-owned [entryId].
  Future<void> removeAddressBookEntry({required String entryId});

  /// Reads one entry by its opaque package-owned [entryId].
  Future<XelisAddressBookEntry> addressBookEntry({required String entryId});

  /// Matches one complete canonical [address] against saved destinations.
  Future<XelisAddressBookMatch> matchAddressBookAddress({
    required String address,
  });

  /// Matches exact base address plus optional typed integrated data.
  ///
  /// This overload is intended for transaction history, where the stored
  /// transfer separates its base destination from decrypted extra data.
  Future<XelisAddressBookMatch> matchAddressBookDestination({
    required String baseAddress,
    XelisDataElement? integratedData,
  });

  /// Reads the number of confirmed transactions in wallet storage.
  Future<BigInt> getHistoryCount();

  /// Explicitly reads confirmed transactions matching [filter].
  ///
  /// List reads expose only extra-data metadata by default. Request
  /// [XelisWalletExtraDataDisclosure.detailed] only from an explicit detail or
  /// reveal flow because payloads can contain application data.
  Future<List<XelisWalletTransactionEntry>> history({
    required XelisWalletHistoryFilter filter,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.metadata,
  });

  /// Converts all confirmed transactions matching [filter] to UTF-8 CSV.
  ///
  /// This operation is available on native and Web targets. The returned text
  /// remains in memory; consumers own the explicit browser-download action.
  Future<String> convertTransactionsToCsv({
    required XelisWalletHistoryFilter filter,
  });

  /// Atomically exports all confirmed transactions matching [filter] to
  /// [filePath].
  ///
  /// Native targets write a temporary file in the destination directory, sync
  /// it, and replace the destination only after the export is complete. This
  /// operation is unsupported on Web; use [convertTransactionsToCsv] and a
  /// browser download instead. Path details are privileged diagnostics and
  /// never appear in an exception's safe [toString] representation.
  Future<void> exportTransactionsToCsvFile({
    required String filePath,
    required XelisWalletHistoryFilter filter,
  });

  /// Explicitly reads transactions currently pending in wallet storage.
  ///
  /// Extra-data follows the same progressive-disclosure policy as [history].
  Future<List<XelisWalletPendingTransaction>> pendingTransactions({
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.metadata,
  });

  /// Reads one confirmed transaction by [hash].
  ///
  /// This detail-oriented method includes the typed extra-data payload by
  /// default. Consumers must not log or persist that payload implicitly.
  Future<XelisWalletTransactionEntry> transactionByHash({
    required String hash,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.detailed,
  });

  /// Reads one pending transaction by [hash].
  ///
  /// This is the pending equivalent of [transactionByHash].
  Future<XelisWalletPendingTransaction> pendingTransactionByHash({
    required String hash,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.detailed,
  });

  /// Reads the active multisig configuration, or `null` when none is active.
  Future<XelisWalletMultisigState?> getMultisigState();

  /// Prepares setup of a new multisig configuration for exact review.
  Future<XelisWalletPreparedTransaction> prepareMultisigSetup({
    required int threshold,
    required List<String> participants,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Whether [address] can be added as an external multisig participant.
  bool isMultisigParticipantAddressValid({required String address});

  /// Creates one pending, source-attested multisig transfer request.
  Future<XelisWalletMultisigSigningRequest> prepareMultisigTransfers({
    required List<XelisWalletTransferRequest> transfers,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Creates a pending request transferring the full available asset balance.
  Future<XelisWalletMultisigSigningRequest> prepareMultisigTransferAll({
    required String destination,
    required String asset,
    String? extraData,
    bool encryptExtraData = true,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Creates a pending request burning an exact atomic amount.
  Future<XelisWalletMultisigSigningRequest> prepareMultisigBurn({
    required String asset,
    required BigInt amountAtomic,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Creates a pending request burning the full available asset balance.
  Future<XelisWalletMultisigSigningRequest> prepareMultisigBurnAll({
    required String asset,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Creates a pending request deleting the active configuration.
  Future<XelisWalletMultisigSigningRequest> prepareMultisigDeletion({
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Parses and verifies a request against the connected network and source.
  Future<XelisWalletMultisigSigningRequest> inspectMultisigSigningRequest({
    required String encoded,
  });

  /// Signs the exact inspected [request] with the opened participant wallet.
  Future<XelisWalletMultisigSignatureShare> signMultisigSigningRequest({
    required XelisWalletMultisigSigningRequest request,
  });

  /// Parses and verifies one share for the exact pending source [request].
  Future<XelisWalletMultisigSignatureShare> inspectMultisigSignatureShare({
    required XelisWalletMultisigSigningRequest request,
    required String encoded,
  });

  /// Finalizes the exact pending [request] with verified unordered [shares].
  Future<XelisWalletPreparedTransaction> finalizeMultisigTransaction({
    required XelisWalletMultisigSigningRequest request,
    required List<XelisWalletMultisigSignatureShare> shares,
  });

  /// Cancels the exact pending source [request].
  Future<void> cancelMultisigSigningRequest({
    required XelisWalletMultisigSigningRequest request,
  });

  /// Estimates the fee for [transfers] without occupying the prepared slot.
  ///
  /// The returned value is expressed in atomic XELIS units. It is advisory;
  /// user review must display the actual fee returned by [prepareTransfers].
  Future<BigInt> estimateTransferFees({
    required List<XelisWalletTransferRequest> transfers,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Prepares one exact transfer transaction for review and later submission.
  ///
  /// A successful call replaces any previous ready transaction owned by this
  /// wallet. It never replaces a transaction whose submission is in flight.
  Future<XelisWalletPreparedTransaction> prepareTransfers({
    required List<XelisWalletTransferRequest> transfers,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Prepares a transaction transferring the full available [asset] balance.
  Future<XelisWalletPreparedTransaction> prepareTransferAll({
    required String destination,
    required String asset,
    String? extraData,
    bool encryptExtraData = true,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Reveals the effective extra data of one transfer in [transaction].
  ///
  /// The original prepared object is an unforgeable Dart-side capability. The
  /// native implementation additionally verifies its preparation generation
  /// and hash before returning data. The result can contain sensitive
  /// application content and must only be requested by an explicit user flow.
  Future<XelisWalletPreparedTransferExtraData>
  inspectPreparedTransferExtraData({
    required XelisWalletPreparedTransaction transaction,
    required int transferIndex,
  });

  /// Prepares an exact asset burn for review and later submission.
  Future<XelisWalletPreparedTransaction> prepareBurn({
    required String asset,
    required BigInt amountAtomic,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Prepares a transaction burning the full available [asset] balance.
  Future<XelisWalletPreparedTransaction> prepareBurnAll({
    required String asset,
    XelisWalletFeePolicy feePolicy = XelisWalletFeePolicy.automatic,
  });

  /// Submits the exact [transaction] retained by this wallet.
  ///
  /// A retryable result retains that transaction unchanged. Submitted,
  /// rejected, local-failure, and submitted-needs-resync results consume it.
  /// Contract, ownership, or bridge failures are reported as
  /// [XelisWalletException] because no submission outcome can be asserted.
  Future<XelisWalletBroadcastResult> broadcastPreparedTransaction({
    required XelisWalletPreparedTransaction transaction,
  });

  /// Discards the exact [transaction] retained by this wallet.
  ///
  /// A stale, mismatched, or in-flight prepared transaction is rejected with a
  /// structured [XelisWalletException].
  Future<void> discardPreparedTransaction({
    required XelisWalletPreparedTransaction transaction,
  });

  /// Rescans wallet history from [topoheight].
  Future<void> rescan({required BigInt topoheight});

  /// Reads a lossless snapshot from the currently connected daemon.
  Future<XelisDaemonInfo> getDaemonInfo();

  /// Closes native wallet services and makes this handle terminal.
  ///
  /// Concurrent calls share the same close operation and later calls are
  /// idempotent. Call [dispose] after awaiting this future to release the local
  /// opaque handle.
  Future<void> close();

  /// Releases the local opaque handle.
  ///
  /// This is idempotent. Calling it before [close] has completed is a
  /// programming error. A completed close attempt permits disposal even when
  /// that attempt reported an error, so the local opaque handle can always be
  /// released.
  void dispose();
}
