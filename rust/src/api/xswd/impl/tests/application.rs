use super::*;
use std::{
    sync::atomic::{AtomicUsize, Ordering},
    time::Duration,
};

#[tokio::test]
async fn app_permission_updates_remain_atomic_under_the_async_lock() {
    let app = app_state();
    let updates = HashMap::from([
        ("get_balance".to_owned(), PermissionPolicy::Accept),
        ("unknown".to_owned(), PermissionPolicy::Reject),
    ]);

    let error = modify_app_permissions(&app, &updates).await.unwrap_err();
    let permissions = app.get_permissions().lock().await;

    assert_eq!(error.to_string(), "XSWD permission not found");
    assert!(matches!(permissions["get_balance"], Permission::Ask));
    assert!(matches!(permissions["build_transaction"], Permission::Ask));
}

#[tokio::test]
async fn app_permission_updates_accept_unprefixed_method_names() {
    let app = app_state();

    modify_app_permissions(
        &app,
        &HashMap::from([("get_balance".to_owned(), PermissionPolicy::Accept)]),
    )
    .await
    .unwrap();
    modify_app_permissions(
        &app,
        &HashMap::from([("build_transaction".to_owned(), PermissionPolicy::Reject)]),
    )
    .await
    .unwrap();

    let permissions = app.get_permissions().lock().await;
    assert!(matches!(permissions["get_balance"], Permission::Allow));
    assert!(matches!(
        permissions["build_transaction"],
        Permission::Reject
    ));
}

#[tokio::test]
async fn app_permission_updates_reject_prefixed_names_atomically() {
    let app = app_state();
    let updates = HashMap::from([
        ("wallet.get_balance".to_owned(), PermissionPolicy::Accept),
        ("build_transaction".to_owned(), PermissionPolicy::Reject),
    ]);

    let error = modify_app_permissions(&app, &updates).await.unwrap_err();
    let permissions = app.get_permissions().lock().await;

    assert_eq!(
        error.to_string(),
        "Prefixed XSWD permission names are unsupported"
    );
    assert!(matches!(permissions["get_balance"], Permission::Ask));
    assert!(matches!(permissions["build_transaction"], Permission::Ask));
}

#[tokio::test]
async fn app_info_preserves_identity_metadata_and_permission_policies() {
    let app = app_state();
    {
        let mut permissions = app.get_permissions().lock().await;
        permissions.insert("get_balance".to_owned(), Permission::Allow);
        permissions.insert("build_transaction".to_owned(), Permission::Reject);
    }

    let registry = xelis_common::tokio::sync::Mutex::new(XswdSessionRegistry::default());
    let info = create_app_info(&registry, &app, false).await.unwrap();

    assert_eq!(info.id, "app-id");
    assert_eq!(info.name, "Test app");
    assert_eq!(info.description, "Test description");
    assert_eq!(info.url.as_deref(), Some("https://example.com"));
    assert!(!info.is_relayer);
    assert_ne!(info.session_ref, 0);
    assert!(matches!(
        info.permissions["get_balance"],
        PermissionPolicy::Accept
    ));
    assert!(matches!(
        info.permissions["build_transaction"],
        PermissionPolicy::Reject
    ));
}

#[tokio::test]
async fn targeted_permission_update_returns_fresh_projection_and_preserves_others() {
    let app = app_state();
    let info = modify_app_permission_and_project(
        &app,
        &HashMap::from([("get_balance".to_owned(), PermissionPolicy::Accept)]),
        true,
        42,
    )
    .await
    .unwrap();

    assert_eq!(info.session_ref, 42);
    assert!(info.is_relayer);
    assert!(matches!(
        info.permissions["get_balance"],
        PermissionPolicy::Accept
    ));
    assert!(matches!(
        info.permissions["build_transaction"],
        PermissionPolicy::Ask
    ));
}

#[tokio::test]
async fn closing_one_handler_does_not_invalidate_another_handlers_session() {
    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let first_app = app_state_with_id("first-handler");
    let second_app = app_state_with_id("second-handler");
    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let (second_sender, second_receiver) = mpsc::unbounded_channel();
    let second_handler = tokio::spawn(xswd_handler_with_registry(
        second_receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let (second_response_sender, second_response_receiver) = oneshot::channel();
    second_sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&second_app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            second_response_sender,
        ))
        .unwrap();
    assert!(matches!(
        second_response_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));
    let second_ref = registry.lock().await.register(&second_app).unwrap();

    let (first_started_sender, first_started_receiver) = oneshot::channel();
    let first_started_sender = Arc::new(Mutex::new(Some(first_started_sender)));
    let callback_started = Arc::clone(&first_started_sender);
    let (first_sender, first_receiver) = mpsc::unbounded_channel();
    let first_handler = tokio::spawn(xswd_handler_with_registry(
        first_receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        |_, _| Box::pin(async { XswdNotificationCallbackOutcome::Completed }),
        |_| Box::pin(async { XswdDecisionCallbackOutcome::Accept }),
        move |_| {
            callback_started
                .lock()
                .unwrap()
                .take()
                .unwrap()
                .send(())
                .unwrap();
            Box::pin(std::future::pending())
        },
        |_| Box::pin(async { XswdDecisionCallbackOutcome::Reject }),
        |_| Box::pin(async { XswdNotificationCallbackOutcome::Completed }),
    ));
    let (first_response_sender, first_response_receiver) = oneshot::channel();
    first_sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&first_app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            first_response_sender,
        ))
        .unwrap();
    first_started_receiver.await.unwrap();
    let first_ref = registry.lock().await.register(&first_app).unwrap();

    drop(first_sender);
    first_handler.await.unwrap();
    assert_eq!(
        first_response_receiver
            .await
            .unwrap()
            .unwrap_err()
            .to_string(),
        XSWD_HANDLER_CLOSED
    );
    {
        let mut registry = registry.lock().await;
        assert!(registry.resolve(first_ref).is_none());
        assert!(Arc::ptr_eq(
            &registry.resolve(second_ref).unwrap(),
            &second_app
        ));
    }

    drop(second_sender);
    second_handler.await.unwrap();
    assert!(registry.lock().await.resolve(second_ref).is_none());
}

#[tokio::test]
async fn cancellation_uses_the_exact_application_state_identity() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (decision_sender, decision_receiver) = oneshot::channel();
    let decision_receiver = Arc::new(Mutex::new(Some(decision_receiver)));

    let cancel_calls = Arc::new(AtomicUsize::new(0));
    let recorded_cancel_calls = Arc::clone(&cancel_calls);
    let cancel = move |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_cancel_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let active_app = app_state();
    let replacement_with_same_id = app_state();

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            active_app,
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(
            replacement_with_same_id,
            cancel_sender,
        ))
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), cancel_receiver)
        .await
        .unwrap()
        .unwrap()
        .unwrap();
    assert_eq!(
        cancel_calls.load(Ordering::SeqCst),
        0,
        "a stale cancellation must not clear the active review for another state instance"
    );

    decision_sender
        .send(XswdDecisionCallbackOutcome::Accept)
        .unwrap();
    assert!(matches!(
        permission_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn app_disconnect_preempts_the_exact_pending_permission() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));
    let (disconnect_seen_sender, disconnect_seen_receiver) = oneshot::channel();
    let disconnect_seen_sender = Arc::new(Mutex::new(Some(disconnect_seen_sender)));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&late_decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect_seen = Arc::clone(&disconnect_seen_sender);
    let disconnect = move |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        disconnect_seen
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    sender.send(XSWDEvent::AppDisconnect(app)).unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), disconnect_seen_receiver)
        .await
        .unwrap()
        .unwrap();

    let permission_error = permission_receiver.await.unwrap().unwrap_err();
    assert_eq!(permission_error.to_string(), "XSWD_REQUEST_CANCELLED");
    assert!(
        late_decision_sender
            .send(XswdDecisionCallbackOutcome::AlwaysAccept)
            .is_err(),
        "a late Dart decision must not authorize a disconnected application"
    );

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn cancelled_application_admission_cannot_remint_its_session_or_complete_late() {
    let (application_started_sender, application_started_receiver) = oneshot::channel();
    let application_started_sender = Arc::new(Mutex::new(Some(application_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));
    let (cancelled_admission_sender, cancelled_admission_receiver) = oneshot::channel();
    let cancelled_admission_sender = Arc::new(Mutex::new(Some(cancelled_admission_sender)));

    let recorded_cancelled_admission = Arc::clone(&cancelled_admission_sender);
    let cancel = move |_, cancelled_admission| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_cancelled_admission
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(cancelled_admission)
            .unwrap();
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let callback_started = Arc::clone(&application_started_sender);
    let callback_decision = Arc::clone(&late_decision_receiver);
    let application = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler_with_registry(
        receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (application_sender, mut application_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestApplication(
            Arc::clone(&app),
            application_sender,
        ))
        .unwrap();
    application_started_receiver.await.unwrap();
    let registered_reference = *registry.lock().await.sessions.keys().next().unwrap();

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(Arc::clone(&app), cancel_sender))
        .unwrap();
    cancel_receiver.await.unwrap().unwrap();
    assert!(cancelled_admission_receiver.await.unwrap());
    assert_eq!(
        application_receiver
            .try_recv()
            .unwrap()
            .unwrap_err()
            .to_string(),
        XSWD_REQUEST_CANCELLED
    );
    {
        let mut registry = registry.lock().await;
        assert!(registry.resolve(registered_reference).is_none());
        assert_eq!(
            registry.register(&app).unwrap_err().to_string(),
            XSWD_SESSION_REFERENCE_INVALID
        );
    }
    assert!(late_decision_sender
        .send(XswdDecisionCallbackOutcome::AlwaysAccept)
        .is_err());

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn disconnect_invalidates_native_authority_before_a_slow_notification_settles() {
    let (disconnect_started_sender, disconnect_started_receiver) = oneshot::channel();
    let disconnect_started_sender = Arc::new(Mutex::new(Some(disconnect_started_sender)));
    let (disconnect_release_sender, disconnect_release_receiver) = oneshot::channel();
    let disconnect_release_receiver = Arc::new(Mutex::new(Some(disconnect_release_receiver)));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let notification_started = Arc::clone(&disconnect_started_sender);
    let notification_release = Arc::clone(&disconnect_release_receiver);
    let disconnect = move |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        notification_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let release = notification_release.lock().unwrap().take().unwrap();
        Box::pin(async move {
            release.await.unwrap();
            XswdNotificationCallbackOutcome::Completed
        })
    };

    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let app = app_state();
    let session_ref = registry.lock().await.register(&app).unwrap();
    let permissions = app.get_permissions();
    let permissions_guard = permissions.lock().await;
    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler_with_registry(
        receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));

    sender
        .send(XSWDEvent::AppDisconnect(Arc::clone(&app)))
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), async {
        loop {
            if registry.lock().await.resolve(session_ref).is_none() {
                break;
            }
            xelis_common::tokio::task::yield_now().await;
        }
    })
    .await
    .unwrap();
    assert_eq!(
        registry
            .lock()
            .await
            .register(&app)
            .unwrap_err()
            .to_string(),
        XSWD_SESSION_REFERENCE_INVALID
    );

    drop(permissions_guard);
    disconnect_started_receiver.await.unwrap();

    drop(sender);
    xelis_common::tokio::time::timeout(Duration::from_secs(1), handler)
        .await
        .unwrap()
        .unwrap();
    assert!(disconnect_release_sender.send(()).is_err());
}
