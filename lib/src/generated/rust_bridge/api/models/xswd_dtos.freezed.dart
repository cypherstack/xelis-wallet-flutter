// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'xswd_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppInfo {

 BigInt get sessionRef; String get id; String get name; String get description; String? get url; Map<String, PermissionPolicy> get permissions; bool get isRelayer;
/// Create a copy of AppInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppInfoCopyWith<AppInfo> get copyWith => _$AppInfoCopyWithImpl<AppInfo>(this as AppInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppInfo&&(identical(other.sessionRef, _this.sessionRef) || other.sessionRef == _this.sessionRef)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.url, _this.url) || other.url == _this.url)&&const DeepCollectionEquality().equals(other.permissions, _this.permissions)&&(identical(other.isRelayer, _this.isRelayer) || other.isRelayer == _this.isRelayer));
}


@override
int get hashCode {
  final _this = this as AppInfo;
  return Object.hash(runtimeType,_this.sessionRef,_this.id,_this.name,_this.description,_this.url,const DeepCollectionEquality().hash(_this.permissions),_this.isRelayer);
}

@override
String toString() {
  final _this = this as AppInfo;
  return 'AppInfo(sessionRef: ${_this.sessionRef}, id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, url: ${_this.url}, permissions: ${_this.permissions}, isRelayer: ${_this.isRelayer})';
}


}

/// @nodoc
abstract mixin class $AppInfoCopyWith<$Res>  {
  factory $AppInfoCopyWith(AppInfo value, $Res Function(AppInfo) _then) = _$AppInfoCopyWithImpl;
@useResult
$Res call({
 BigInt sessionRef, String id, String name, String description, String? url, Map<String, PermissionPolicy> permissions, bool isRelayer
});




}
/// @nodoc
class _$AppInfoCopyWithImpl<$Res>
    implements $AppInfoCopyWith<$Res> {
  _$AppInfoCopyWithImpl(this._self, this._then);

  final AppInfo _self;
  final $Res Function(AppInfo) _then;

/// Create a copy of AppInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionRef = null,Object? id = null,Object? name = null,Object? description = null,Object? url = freezed,Object? permissions = null,Object? isRelayer = null,}) {
  return _then(AppInfo(
sessionRef: null == sessionRef ? _self.sessionRef : sessionRef // ignore: cast_nullable_to_non_nullable
as BigInt,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as Map<String, PermissionPolicy>,isRelayer: null == isRelayer ? _self.isRelayer : isRelayer // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppInfo].
extension AppInfoPatterns on AppInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppInfo value)  $default,){
final _that = this;
switch (_that) {
case _AppInfo():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AppInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BigInt sessionRef,  String id,  String name,  String description,  String? url,  Map<String, PermissionPolicy> permissions,  bool isRelayer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppInfo() when $default != null:
return $default(_that.sessionRef,_that.id,_that.name,_that.description,_that.url,_that.permissions,_that.isRelayer);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BigInt sessionRef,  String id,  String name,  String description,  String? url,  Map<String, PermissionPolicy> permissions,  bool isRelayer)  $default,) {final _that = this;
switch (_that) {
case _AppInfo():
return $default(_that.sessionRef,_that.id,_that.name,_that.description,_that.url,_that.permissions,_that.isRelayer);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BigInt sessionRef,  String id,  String name,  String description,  String? url,  Map<String, PermissionPolicy> permissions,  bool isRelayer)?  $default,) {final _that = this;
switch (_that) {
case _AppInfo() when $default != null:
return $default(_that.sessionRef,_that.id,_that.name,_that.description,_that.url,_that.permissions,_that.isRelayer);case _:
  return null;

}
}

}

/// @nodoc


class _AppInfo implements AppInfo {
  const _AppInfo({required this.sessionRef, required this.id, required this.name, required this.description, this.url, required  Map<String, PermissionPolicy> permissions, required this.isRelayer}): _permissions = permissions;
  

@override final  BigInt sessionRef;
@override final  String id;
@override final  String name;
@override final  String description;
@override final  String? url;
 final  Map<String, PermissionPolicy> _permissions;
@override Map<String, PermissionPolicy> get permissions {
  if (_permissions is EqualUnmodifiableMapView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_permissions);
}

@override final  bool isRelayer;

/// Create a copy of AppInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppInfoCopyWith<_AppInfo> get copyWith => __$AppInfoCopyWithImpl<_AppInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppInfo&&(identical(other.sessionRef, sessionRef) || other.sessionRef == sessionRef)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.permissions, _permissions)&&(identical(other.isRelayer, isRelayer) || other.isRelayer == isRelayer));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sessionRef,id,name,description,url,const DeepCollectionEquality().hash(_permissions),isRelayer);
}

@override
String toString() {
    return 'AppInfo(sessionRef: $sessionRef, id: $id, name: $name, description: $description, url: $url, permissions: $permissions, isRelayer: $isRelayer)';
}


}

/// @nodoc
abstract mixin class _$AppInfoCopyWith<$Res> implements $AppInfoCopyWith<$Res> {
  factory _$AppInfoCopyWith(_AppInfo value, $Res Function(_AppInfo) _then) = __$AppInfoCopyWithImpl;
@override @useResult
$Res call({
 BigInt sessionRef, String id, String name, String description, String? url, Map<String, PermissionPolicy> permissions, bool isRelayer
});




}
/// @nodoc
class __$AppInfoCopyWithImpl<$Res>
    implements _$AppInfoCopyWith<$Res> {
  __$AppInfoCopyWithImpl(this._self, this._then);

  final _AppInfo _self;
  final $Res Function(_AppInfo) _then;

/// Create a copy of AppInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionRef = null,Object? id = null,Object? name = null,Object? description = null,Object? url = freezed,Object? permissions = null,Object? isRelayer = null,}) {
  return _then(_AppInfo(
sessionRef: null == sessionRef ? _self.sessionRef : sessionRef // ignore: cast_nullable_to_non_nullable
as BigInt,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as Map<String, PermissionPolicy>,isRelayer: null == isRelayer ? _self.isRelayer : isRelayer // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ApplicationDataRelayer {

 String get id; String get name; String get description; String? get url; List<String> get permissions; String get relayer; EncryptionMode? get encryptionMode;
/// Create a copy of ApplicationDataRelayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplicationDataRelayerCopyWith<ApplicationDataRelayer> get copyWith => _$ApplicationDataRelayerCopyWithImpl<ApplicationDataRelayer>(this as ApplicationDataRelayer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ApplicationDataRelayer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplicationDataRelayer&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.url, _this.url) || other.url == _this.url)&&const DeepCollectionEquality().equals(other.permissions, _this.permissions)&&(identical(other.relayer, _this.relayer) || other.relayer == _this.relayer)&&(identical(other.encryptionMode, _this.encryptionMode) || other.encryptionMode == _this.encryptionMode));
}


@override
int get hashCode {
  final _this = this as ApplicationDataRelayer;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.url,const DeepCollectionEquality().hash(_this.permissions),_this.relayer,_this.encryptionMode);
}

@override
String toString() {
  final _this = this as ApplicationDataRelayer;
  return 'ApplicationDataRelayer(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, url: ${_this.url}, permissions: ${_this.permissions}, relayer: ${_this.relayer}, encryptionMode: ${_this.encryptionMode})';
}


}

/// @nodoc
abstract mixin class $ApplicationDataRelayerCopyWith<$Res>  {
  factory $ApplicationDataRelayerCopyWith(ApplicationDataRelayer value, $Res Function(ApplicationDataRelayer) _then) = _$ApplicationDataRelayerCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String? url, List<String> permissions, String relayer, EncryptionMode? encryptionMode
});


$EncryptionModeCopyWith<$Res>? get encryptionMode;

}
/// @nodoc
class _$ApplicationDataRelayerCopyWithImpl<$Res>
    implements $ApplicationDataRelayerCopyWith<$Res> {
  _$ApplicationDataRelayerCopyWithImpl(this._self, this._then);

  final ApplicationDataRelayer _self;
  final $Res Function(ApplicationDataRelayer) _then;

/// Create a copy of ApplicationDataRelayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? url = freezed,Object? permissions = null,Object? relayer = null,Object? encryptionMode = freezed,}) {
  return _then(ApplicationDataRelayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,relayer: null == relayer ? _self.relayer : relayer // ignore: cast_nullable_to_non_nullable
as String,encryptionMode: freezed == encryptionMode ? _self.encryptionMode : encryptionMode // ignore: cast_nullable_to_non_nullable
as EncryptionMode?,
  ));
}
/// Create a copy of ApplicationDataRelayer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EncryptionModeCopyWith<$Res>? get encryptionMode {
    if (_self.encryptionMode == null) {
    return null;
  }

  return $EncryptionModeCopyWith<$Res>(_self.encryptionMode!, (value) {
    return _then(_self.copyWith(encryptionMode: value));
  });
}
}


/// Adds pattern-matching-related methods to [ApplicationDataRelayer].
extension ApplicationDataRelayerPatterns on ApplicationDataRelayer {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApplicationDataRelayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApplicationDataRelayer() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApplicationDataRelayer value)  $default,){
final _that = this;
switch (_that) {
case _ApplicationDataRelayer():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApplicationDataRelayer value)?  $default,){
final _that = this;
switch (_that) {
case _ApplicationDataRelayer() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String? url,  List<String> permissions,  String relayer,  EncryptionMode? encryptionMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApplicationDataRelayer() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.url,_that.permissions,_that.relayer,_that.encryptionMode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String? url,  List<String> permissions,  String relayer,  EncryptionMode? encryptionMode)  $default,) {final _that = this;
switch (_that) {
case _ApplicationDataRelayer():
return $default(_that.id,_that.name,_that.description,_that.url,_that.permissions,_that.relayer,_that.encryptionMode);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  String? url,  List<String> permissions,  String relayer,  EncryptionMode? encryptionMode)?  $default,) {final _that = this;
switch (_that) {
case _ApplicationDataRelayer() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.url,_that.permissions,_that.relayer,_that.encryptionMode);case _:
  return null;

}
}

}

/// @nodoc


class _ApplicationDataRelayer implements ApplicationDataRelayer {
  const _ApplicationDataRelayer({required this.id, required this.name, required this.description, this.url, required  List<String> permissions, required this.relayer, this.encryptionMode}): _permissions = permissions;
  

@override final  String id;
@override final  String name;
@override final  String description;
@override final  String? url;
 final  List<String> _permissions;
@override List<String> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}

@override final  String relayer;
@override final  EncryptionMode? encryptionMode;

/// Create a copy of ApplicationDataRelayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplicationDataRelayerCopyWith<_ApplicationDataRelayer> get copyWith => __$ApplicationDataRelayerCopyWithImpl<_ApplicationDataRelayer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplicationDataRelayer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.permissions, _permissions)&&(identical(other.relayer, relayer) || other.relayer == relayer)&&(identical(other.encryptionMode, encryptionMode) || other.encryptionMode == encryptionMode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,url,const DeepCollectionEquality().hash(_permissions),relayer,encryptionMode);
}

@override
String toString() {
    return 'ApplicationDataRelayer(id: $id, name: $name, description: $description, url: $url, permissions: $permissions, relayer: $relayer, encryptionMode: $encryptionMode)';
}


}

/// @nodoc
abstract mixin class _$ApplicationDataRelayerCopyWith<$Res> implements $ApplicationDataRelayerCopyWith<$Res> {
  factory _$ApplicationDataRelayerCopyWith(_ApplicationDataRelayer value, $Res Function(_ApplicationDataRelayer) _then) = __$ApplicationDataRelayerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String? url, List<String> permissions, String relayer, EncryptionMode? encryptionMode
});


@override $EncryptionModeCopyWith<$Res>? get encryptionMode;

}
/// @nodoc
class __$ApplicationDataRelayerCopyWithImpl<$Res>
    implements _$ApplicationDataRelayerCopyWith<$Res> {
  __$ApplicationDataRelayerCopyWithImpl(this._self, this._then);

  final _ApplicationDataRelayer _self;
  final $Res Function(_ApplicationDataRelayer) _then;

/// Create a copy of ApplicationDataRelayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? url = freezed,Object? permissions = null,Object? relayer = null,Object? encryptionMode = freezed,}) {
  return _then(_ApplicationDataRelayer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,relayer: null == relayer ? _self.relayer : relayer // ignore: cast_nullable_to_non_nullable
as String,encryptionMode: freezed == encryptionMode ? _self.encryptionMode : encryptionMode // ignore: cast_nullable_to_non_nullable
as EncryptionMode?,
  ));
}

/// Create a copy of ApplicationDataRelayer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EncryptionModeCopyWith<$Res>? get encryptionMode {
    if (_self.encryptionMode == null) {
    return null;
  }

  return $EncryptionModeCopyWith<$Res>(_self.encryptionMode!, (value) {
    return _then(_self.copyWith(encryptionMode: value));
  });
}
}

/// @nodoc
mixin _$EncryptionMode {

 Uint8List get key;
/// Create a copy of EncryptionMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EncryptionModeCopyWith<EncryptionMode> get copyWith => _$EncryptionModeCopyWithImpl<EncryptionMode>(this as EncryptionMode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EncryptionMode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EncryptionMode&&const DeepCollectionEquality().equals(other.key, _this.key));
}


@override
int get hashCode {
  final _this = this as EncryptionMode;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.key));
}

@override
String toString() {
  final _this = this as EncryptionMode;
  return 'EncryptionMode(key: ${_this.key})';
}


}

/// @nodoc
abstract mixin class $EncryptionModeCopyWith<$Res>  {
  factory $EncryptionModeCopyWith(EncryptionMode value, $Res Function(EncryptionMode) _then) = _$EncryptionModeCopyWithImpl;
@useResult
$Res call({
 Uint8List key
});




}
/// @nodoc
class _$EncryptionModeCopyWithImpl<$Res>
    implements $EncryptionModeCopyWith<$Res> {
  _$EncryptionModeCopyWithImpl(this._self, this._then);

  final EncryptionMode _self;
  final $Res Function(EncryptionMode) _then;

/// Create a copy of EncryptionMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}

}


/// Adds pattern-matching-related methods to [EncryptionMode].
extension EncryptionModePatterns on EncryptionMode {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EncryptionMode_Aes value)?  aes,TResult Function( EncryptionMode_Chacha20Poly1305 value)?  chacha20Poly1305,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EncryptionMode_Aes() when aes != null:
return aes(_that);case EncryptionMode_Chacha20Poly1305() when chacha20Poly1305 != null:
return chacha20Poly1305(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EncryptionMode_Aes value)  aes,required TResult Function( EncryptionMode_Chacha20Poly1305 value)  chacha20Poly1305,}){
final _that = this;
switch (_that) {
case EncryptionMode_Aes():
return aes(_that);case EncryptionMode_Chacha20Poly1305():
return chacha20Poly1305(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EncryptionMode_Aes value)?  aes,TResult? Function( EncryptionMode_Chacha20Poly1305 value)?  chacha20Poly1305,}){
final _that = this;
switch (_that) {
case EncryptionMode_Aes() when aes != null:
return aes(_that);case EncryptionMode_Chacha20Poly1305() when chacha20Poly1305 != null:
return chacha20Poly1305(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Uint8List key)?  aes,TResult Function( Uint8List key)?  chacha20Poly1305,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EncryptionMode_Aes() when aes != null:
return aes(_that.key);case EncryptionMode_Chacha20Poly1305() when chacha20Poly1305 != null:
return chacha20Poly1305(_that.key);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Uint8List key)  aes,required TResult Function( Uint8List key)  chacha20Poly1305,}) {final _that = this;
switch (_that) {
case EncryptionMode_Aes():
return aes(_that.key);case EncryptionMode_Chacha20Poly1305():
return chacha20Poly1305(_that.key);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Uint8List key)?  aes,TResult? Function( Uint8List key)?  chacha20Poly1305,}) {final _that = this;
switch (_that) {
case EncryptionMode_Aes() when aes != null:
return aes(_that.key);case EncryptionMode_Chacha20Poly1305() when chacha20Poly1305 != null:
return chacha20Poly1305(_that.key);case _:
  return null;

}
}

}

/// @nodoc


class EncryptionMode_Aes extends EncryptionMode {
  const EncryptionMode_Aes({required this.key}): super._();
  

@override final  Uint8List key;

/// Create a copy of EncryptionMode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EncryptionMode_AesCopyWith<EncryptionMode_Aes> get copyWith => _$EncryptionMode_AesCopyWithImpl<EncryptionMode_Aes>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EncryptionMode_Aes&&const DeepCollectionEquality().equals(other.key, key));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(key));
}

@override
String toString() {
    return 'EncryptionMode.aes(key: $key)';
}


}

/// @nodoc
abstract mixin class $EncryptionMode_AesCopyWith<$Res> implements $EncryptionModeCopyWith<$Res> {
  factory $EncryptionMode_AesCopyWith(EncryptionMode_Aes value, $Res Function(EncryptionMode_Aes) _then) = _$EncryptionMode_AesCopyWithImpl;
@override @useResult
$Res call({
 Uint8List key
});




}
/// @nodoc
class _$EncryptionMode_AesCopyWithImpl<$Res>
    implements $EncryptionMode_AesCopyWith<$Res> {
  _$EncryptionMode_AesCopyWithImpl(this._self, this._then);

  final EncryptionMode_Aes _self;
  final $Res Function(EncryptionMode_Aes) _then;

/// Create a copy of EncryptionMode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,}) {
  return _then(EncryptionMode_Aes(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc


class EncryptionMode_Chacha20Poly1305 extends EncryptionMode {
  const EncryptionMode_Chacha20Poly1305({required this.key}): super._();
  

@override final  Uint8List key;

/// Create a copy of EncryptionMode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EncryptionMode_Chacha20Poly1305CopyWith<EncryptionMode_Chacha20Poly1305> get copyWith => _$EncryptionMode_Chacha20Poly1305CopyWithImpl<EncryptionMode_Chacha20Poly1305>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EncryptionMode_Chacha20Poly1305&&const DeepCollectionEquality().equals(other.key, key));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(key));
}

@override
String toString() {
    return 'EncryptionMode.chacha20Poly1305(key: $key)';
}


}

/// @nodoc
abstract mixin class $EncryptionMode_Chacha20Poly1305CopyWith<$Res> implements $EncryptionModeCopyWith<$Res> {
  factory $EncryptionMode_Chacha20Poly1305CopyWith(EncryptionMode_Chacha20Poly1305 value, $Res Function(EncryptionMode_Chacha20Poly1305) _then) = _$EncryptionMode_Chacha20Poly1305CopyWithImpl;
@override @useResult
$Res call({
 Uint8List key
});




}
/// @nodoc
class _$EncryptionMode_Chacha20Poly1305CopyWithImpl<$Res>
    implements $EncryptionMode_Chacha20Poly1305CopyWith<$Res> {
  _$EncryptionMode_Chacha20Poly1305CopyWithImpl(this._self, this._then);

  final EncryptionMode_Chacha20Poly1305 _self;
  final $Res Function(EncryptionMode_Chacha20Poly1305) _then;

/// Create a copy of EncryptionMode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,}) {
  return _then(EncryptionMode_Chacha20Poly1305(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc
mixin _$XswdDecisionCallbackOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome()';
}


}

/// @nodoc
class $XswdDecisionCallbackOutcomeCopyWith<$Res>  {
$XswdDecisionCallbackOutcomeCopyWith(XswdDecisionCallbackOutcome _, $Res Function(XswdDecisionCallbackOutcome) __);
}


/// Adds pattern-matching-related methods to [XswdDecisionCallbackOutcome].
extension XswdDecisionCallbackOutcomePatterns on XswdDecisionCallbackOutcome {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( XswdDecisionCallbackOutcome_Accept value)?  accept,TResult Function( XswdDecisionCallbackOutcome_Reject value)?  reject,TResult Function( XswdDecisionCallbackOutcome_AlwaysAccept value)?  alwaysAccept,TResult Function( XswdDecisionCallbackOutcome_AlwaysReject value)?  alwaysReject,TResult Function( XswdDecisionCallbackOutcome_PrefetchNoChange value)?  prefetchNoChange,TResult Function( XswdDecisionCallbackOutcome_PrefetchGrant value)?  prefetchGrant,TResult Function( XswdDecisionCallbackOutcome_InvalidPayload value)?  invalidPayload,TResult Function( XswdDecisionCallbackOutcome_Timeout value)?  timeout,TResult Function( XswdDecisionCallbackOutcome_Exception value)?  exception,required TResult orElse(),}){
final _that = this;
switch (_that) {
case XswdDecisionCallbackOutcome_Accept() when accept != null:
return accept(_that);case XswdDecisionCallbackOutcome_Reject() when reject != null:
return reject(_that);case XswdDecisionCallbackOutcome_AlwaysAccept() when alwaysAccept != null:
return alwaysAccept(_that);case XswdDecisionCallbackOutcome_AlwaysReject() when alwaysReject != null:
return alwaysReject(_that);case XswdDecisionCallbackOutcome_PrefetchNoChange() when prefetchNoChange != null:
return prefetchNoChange(_that);case XswdDecisionCallbackOutcome_PrefetchGrant() when prefetchGrant != null:
return prefetchGrant(_that);case XswdDecisionCallbackOutcome_InvalidPayload() when invalidPayload != null:
return invalidPayload(_that);case XswdDecisionCallbackOutcome_Timeout() when timeout != null:
return timeout(_that);case XswdDecisionCallbackOutcome_Exception() when exception != null:
return exception(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( XswdDecisionCallbackOutcome_Accept value)  accept,required TResult Function( XswdDecisionCallbackOutcome_Reject value)  reject,required TResult Function( XswdDecisionCallbackOutcome_AlwaysAccept value)  alwaysAccept,required TResult Function( XswdDecisionCallbackOutcome_AlwaysReject value)  alwaysReject,required TResult Function( XswdDecisionCallbackOutcome_PrefetchNoChange value)  prefetchNoChange,required TResult Function( XswdDecisionCallbackOutcome_PrefetchGrant value)  prefetchGrant,required TResult Function( XswdDecisionCallbackOutcome_InvalidPayload value)  invalidPayload,required TResult Function( XswdDecisionCallbackOutcome_Timeout value)  timeout,required TResult Function( XswdDecisionCallbackOutcome_Exception value)  exception,}){
final _that = this;
switch (_that) {
case XswdDecisionCallbackOutcome_Accept():
return accept(_that);case XswdDecisionCallbackOutcome_Reject():
return reject(_that);case XswdDecisionCallbackOutcome_AlwaysAccept():
return alwaysAccept(_that);case XswdDecisionCallbackOutcome_AlwaysReject():
return alwaysReject(_that);case XswdDecisionCallbackOutcome_PrefetchNoChange():
return prefetchNoChange(_that);case XswdDecisionCallbackOutcome_PrefetchGrant():
return prefetchGrant(_that);case XswdDecisionCallbackOutcome_InvalidPayload():
return invalidPayload(_that);case XswdDecisionCallbackOutcome_Timeout():
return timeout(_that);case XswdDecisionCallbackOutcome_Exception():
return exception(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( XswdDecisionCallbackOutcome_Accept value)?  accept,TResult? Function( XswdDecisionCallbackOutcome_Reject value)?  reject,TResult? Function( XswdDecisionCallbackOutcome_AlwaysAccept value)?  alwaysAccept,TResult? Function( XswdDecisionCallbackOutcome_AlwaysReject value)?  alwaysReject,TResult? Function( XswdDecisionCallbackOutcome_PrefetchNoChange value)?  prefetchNoChange,TResult? Function( XswdDecisionCallbackOutcome_PrefetchGrant value)?  prefetchGrant,TResult? Function( XswdDecisionCallbackOutcome_InvalidPayload value)?  invalidPayload,TResult? Function( XswdDecisionCallbackOutcome_Timeout value)?  timeout,TResult? Function( XswdDecisionCallbackOutcome_Exception value)?  exception,}){
final _that = this;
switch (_that) {
case XswdDecisionCallbackOutcome_Accept() when accept != null:
return accept(_that);case XswdDecisionCallbackOutcome_Reject() when reject != null:
return reject(_that);case XswdDecisionCallbackOutcome_AlwaysAccept() when alwaysAccept != null:
return alwaysAccept(_that);case XswdDecisionCallbackOutcome_AlwaysReject() when alwaysReject != null:
return alwaysReject(_that);case XswdDecisionCallbackOutcome_PrefetchNoChange() when prefetchNoChange != null:
return prefetchNoChange(_that);case XswdDecisionCallbackOutcome_PrefetchGrant() when prefetchGrant != null:
return prefetchGrant(_that);case XswdDecisionCallbackOutcome_InvalidPayload() when invalidPayload != null:
return invalidPayload(_that);case XswdDecisionCallbackOutcome_Timeout() when timeout != null:
return timeout(_that);case XswdDecisionCallbackOutcome_Exception() when exception != null:
return exception(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  accept,TResult Function()?  reject,TResult Function()?  alwaysAccept,TResult Function()?  alwaysReject,TResult Function()?  prefetchNoChange,TResult Function( List<String> permissions)?  prefetchGrant,TResult Function()?  invalidPayload,TResult Function()?  timeout,TResult Function()?  exception,required TResult orElse(),}) {final _that = this;
switch (_that) {
case XswdDecisionCallbackOutcome_Accept() when accept != null:
return accept();case XswdDecisionCallbackOutcome_Reject() when reject != null:
return reject();case XswdDecisionCallbackOutcome_AlwaysAccept() when alwaysAccept != null:
return alwaysAccept();case XswdDecisionCallbackOutcome_AlwaysReject() when alwaysReject != null:
return alwaysReject();case XswdDecisionCallbackOutcome_PrefetchNoChange() when prefetchNoChange != null:
return prefetchNoChange();case XswdDecisionCallbackOutcome_PrefetchGrant() when prefetchGrant != null:
return prefetchGrant(_that.permissions);case XswdDecisionCallbackOutcome_InvalidPayload() when invalidPayload != null:
return invalidPayload();case XswdDecisionCallbackOutcome_Timeout() when timeout != null:
return timeout();case XswdDecisionCallbackOutcome_Exception() when exception != null:
return exception();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  accept,required TResult Function()  reject,required TResult Function()  alwaysAccept,required TResult Function()  alwaysReject,required TResult Function()  prefetchNoChange,required TResult Function( List<String> permissions)  prefetchGrant,required TResult Function()  invalidPayload,required TResult Function()  timeout,required TResult Function()  exception,}) {final _that = this;
switch (_that) {
case XswdDecisionCallbackOutcome_Accept():
return accept();case XswdDecisionCallbackOutcome_Reject():
return reject();case XswdDecisionCallbackOutcome_AlwaysAccept():
return alwaysAccept();case XswdDecisionCallbackOutcome_AlwaysReject():
return alwaysReject();case XswdDecisionCallbackOutcome_PrefetchNoChange():
return prefetchNoChange();case XswdDecisionCallbackOutcome_PrefetchGrant():
return prefetchGrant(_that.permissions);case XswdDecisionCallbackOutcome_InvalidPayload():
return invalidPayload();case XswdDecisionCallbackOutcome_Timeout():
return timeout();case XswdDecisionCallbackOutcome_Exception():
return exception();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  accept,TResult? Function()?  reject,TResult? Function()?  alwaysAccept,TResult? Function()?  alwaysReject,TResult? Function()?  prefetchNoChange,TResult? Function( List<String> permissions)?  prefetchGrant,TResult? Function()?  invalidPayload,TResult? Function()?  timeout,TResult? Function()?  exception,}) {final _that = this;
switch (_that) {
case XswdDecisionCallbackOutcome_Accept() when accept != null:
return accept();case XswdDecisionCallbackOutcome_Reject() when reject != null:
return reject();case XswdDecisionCallbackOutcome_AlwaysAccept() when alwaysAccept != null:
return alwaysAccept();case XswdDecisionCallbackOutcome_AlwaysReject() when alwaysReject != null:
return alwaysReject();case XswdDecisionCallbackOutcome_PrefetchNoChange() when prefetchNoChange != null:
return prefetchNoChange();case XswdDecisionCallbackOutcome_PrefetchGrant() when prefetchGrant != null:
return prefetchGrant(_that.permissions);case XswdDecisionCallbackOutcome_InvalidPayload() when invalidPayload != null:
return invalidPayload();case XswdDecisionCallbackOutcome_Timeout() when timeout != null:
return timeout();case XswdDecisionCallbackOutcome_Exception() when exception != null:
return exception();case _:
  return null;

}
}

}

/// @nodoc


class XswdDecisionCallbackOutcome_Accept extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_Accept(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_Accept);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.accept()';
}


}




/// @nodoc


class XswdDecisionCallbackOutcome_Reject extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_Reject(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_Reject);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.reject()';
}


}




/// @nodoc


class XswdDecisionCallbackOutcome_AlwaysAccept extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_AlwaysAccept(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_AlwaysAccept);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.alwaysAccept()';
}


}




/// @nodoc


class XswdDecisionCallbackOutcome_AlwaysReject extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_AlwaysReject(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_AlwaysReject);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.alwaysReject()';
}


}




/// @nodoc


class XswdDecisionCallbackOutcome_PrefetchNoChange extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_PrefetchNoChange(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_PrefetchNoChange);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.prefetchNoChange()';
}


}




/// @nodoc


class XswdDecisionCallbackOutcome_PrefetchGrant extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_PrefetchGrant({required  List<String> permissions}): _permissions = permissions,super._();
  

 final  List<String> _permissions;
 List<String> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}


/// Create a copy of XswdDecisionCallbackOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XswdDecisionCallbackOutcome_PrefetchGrantCopyWith<XswdDecisionCallbackOutcome_PrefetchGrant> get copyWith => _$XswdDecisionCallbackOutcome_PrefetchGrantCopyWithImpl<XswdDecisionCallbackOutcome_PrefetchGrant>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_PrefetchGrant&&const DeepCollectionEquality().equals(other.permissions, _permissions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_permissions));
}

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.prefetchGrant(permissions: $permissions)';
}


}

/// @nodoc
abstract mixin class $XswdDecisionCallbackOutcome_PrefetchGrantCopyWith<$Res> implements $XswdDecisionCallbackOutcomeCopyWith<$Res> {
  factory $XswdDecisionCallbackOutcome_PrefetchGrantCopyWith(XswdDecisionCallbackOutcome_PrefetchGrant value, $Res Function(XswdDecisionCallbackOutcome_PrefetchGrant) _then) = _$XswdDecisionCallbackOutcome_PrefetchGrantCopyWithImpl;
@useResult
$Res call({
 List<String> permissions
});




}
/// @nodoc
class _$XswdDecisionCallbackOutcome_PrefetchGrantCopyWithImpl<$Res>
    implements $XswdDecisionCallbackOutcome_PrefetchGrantCopyWith<$Res> {
  _$XswdDecisionCallbackOutcome_PrefetchGrantCopyWithImpl(this._self, this._then);

  final XswdDecisionCallbackOutcome_PrefetchGrant _self;
  final $Res Function(XswdDecisionCallbackOutcome_PrefetchGrant) _then;

/// Create a copy of XswdDecisionCallbackOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? permissions = null,}) {
  return _then(XswdDecisionCallbackOutcome_PrefetchGrant(
permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class XswdDecisionCallbackOutcome_InvalidPayload extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_InvalidPayload(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_InvalidPayload);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.invalidPayload()';
}


}




/// @nodoc


class XswdDecisionCallbackOutcome_Timeout extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_Timeout(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_Timeout);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.timeout()';
}


}




/// @nodoc


class XswdDecisionCallbackOutcome_Exception extends XswdDecisionCallbackOutcome {
  const XswdDecisionCallbackOutcome_Exception(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdDecisionCallbackOutcome_Exception);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdDecisionCallbackOutcome.exception()';
}


}




/// @nodoc
mixin _$XswdRequestSummary {

 XswdRequestType get eventType; AppInfo get applicationInfo;
/// Create a copy of XswdRequestSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XswdRequestSummaryCopyWith<XswdRequestSummary> get copyWith => _$XswdRequestSummaryCopyWithImpl<XswdRequestSummary>(this as XswdRequestSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as XswdRequestSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdRequestSummary&&(identical(other.eventType, _this.eventType) || other.eventType == _this.eventType)&&(identical(other.applicationInfo, _this.applicationInfo) || other.applicationInfo == _this.applicationInfo));
}


@override
int get hashCode {
  final _this = this as XswdRequestSummary;
  return Object.hash(runtimeType,_this.eventType,_this.applicationInfo);
}

@override
String toString() {
  final _this = this as XswdRequestSummary;
  return 'XswdRequestSummary(eventType: ${_this.eventType}, applicationInfo: ${_this.applicationInfo})';
}


}

/// @nodoc
abstract mixin class $XswdRequestSummaryCopyWith<$Res>  {
  factory $XswdRequestSummaryCopyWith(XswdRequestSummary value, $Res Function(XswdRequestSummary) _then) = _$XswdRequestSummaryCopyWithImpl;
@useResult
$Res call({
 XswdRequestType eventType, AppInfo applicationInfo
});


$XswdRequestTypeCopyWith<$Res> get eventType;$AppInfoCopyWith<$Res> get applicationInfo;

}
/// @nodoc
class _$XswdRequestSummaryCopyWithImpl<$Res>
    implements $XswdRequestSummaryCopyWith<$Res> {
  _$XswdRequestSummaryCopyWithImpl(this._self, this._then);

  final XswdRequestSummary _self;
  final $Res Function(XswdRequestSummary) _then;

/// Create a copy of XswdRequestSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventType = null,Object? applicationInfo = null,}) {
  return _then(XswdRequestSummary(
eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as XswdRequestType,applicationInfo: null == applicationInfo ? _self.applicationInfo : applicationInfo // ignore: cast_nullable_to_non_nullable
as AppInfo,
  ));
}
/// Create a copy of XswdRequestSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XswdRequestTypeCopyWith<$Res> get eventType {
  
  return $XswdRequestTypeCopyWith<$Res>(_self.eventType, (value) {
    return _then(_self.copyWith(eventType: value));
  });
}/// Create a copy of XswdRequestSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppInfoCopyWith<$Res> get applicationInfo {
  
  return $AppInfoCopyWith<$Res>(_self.applicationInfo, (value) {
    return _then(_self.copyWith(applicationInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [XswdRequestSummary].
extension XswdRequestSummaryPatterns on XswdRequestSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XswdRequestSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XswdRequestSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XswdRequestSummary value)  $default,){
final _that = this;
switch (_that) {
case _XswdRequestSummary():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XswdRequestSummary value)?  $default,){
final _that = this;
switch (_that) {
case _XswdRequestSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( XswdRequestType eventType,  AppInfo applicationInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XswdRequestSummary() when $default != null:
return $default(_that.eventType,_that.applicationInfo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( XswdRequestType eventType,  AppInfo applicationInfo)  $default,) {final _that = this;
switch (_that) {
case _XswdRequestSummary():
return $default(_that.eventType,_that.applicationInfo);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( XswdRequestType eventType,  AppInfo applicationInfo)?  $default,) {final _that = this;
switch (_that) {
case _XswdRequestSummary() when $default != null:
return $default(_that.eventType,_that.applicationInfo);case _:
  return null;

}
}

}

/// @nodoc


class _XswdRequestSummary extends XswdRequestSummary {
  const _XswdRequestSummary({required this.eventType, required this.applicationInfo}): super._();
  

@override final  XswdRequestType eventType;
@override final  AppInfo applicationInfo;

/// Create a copy of XswdRequestSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XswdRequestSummaryCopyWith<_XswdRequestSummary> get copyWith => __$XswdRequestSummaryCopyWithImpl<_XswdRequestSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _XswdRequestSummary&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.applicationInfo, applicationInfo) || other.applicationInfo == applicationInfo));
}


@override
int get hashCode {
    return Object.hash(runtimeType,eventType,applicationInfo);
}

@override
String toString() {
    return 'XswdRequestSummary(eventType: $eventType, applicationInfo: $applicationInfo)';
}


}

/// @nodoc
abstract mixin class _$XswdRequestSummaryCopyWith<$Res> implements $XswdRequestSummaryCopyWith<$Res> {
  factory _$XswdRequestSummaryCopyWith(_XswdRequestSummary value, $Res Function(_XswdRequestSummary) _then) = __$XswdRequestSummaryCopyWithImpl;
@override @useResult
$Res call({
 XswdRequestType eventType, AppInfo applicationInfo
});


@override $XswdRequestTypeCopyWith<$Res> get eventType;@override $AppInfoCopyWith<$Res> get applicationInfo;

}
/// @nodoc
class __$XswdRequestSummaryCopyWithImpl<$Res>
    implements _$XswdRequestSummaryCopyWith<$Res> {
  __$XswdRequestSummaryCopyWithImpl(this._self, this._then);

  final _XswdRequestSummary _self;
  final $Res Function(_XswdRequestSummary) _then;

/// Create a copy of XswdRequestSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventType = null,Object? applicationInfo = null,}) {
  return _then(_XswdRequestSummary(
eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as XswdRequestType,applicationInfo: null == applicationInfo ? _self.applicationInfo : applicationInfo // ignore: cast_nullable_to_non_nullable
as AppInfo,
  ));
}

/// Create a copy of XswdRequestSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XswdRequestTypeCopyWith<$Res> get eventType {
  
  return $XswdRequestTypeCopyWith<$Res>(_self.eventType, (value) {
    return _then(_self.copyWith(eventType: value));
  });
}/// Create a copy of XswdRequestSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppInfoCopyWith<$Res> get applicationInfo {
  
  return $AppInfoCopyWith<$Res>(_self.applicationInfo, (value) {
    return _then(_self.copyWith(applicationInfo: value));
  });
}
}

/// @nodoc
mixin _$XswdRequestType {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdRequestType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdRequestType()';
}


}

/// @nodoc
class $XswdRequestTypeCopyWith<$Res>  {
$XswdRequestTypeCopyWith(XswdRequestType _, $Res Function(XswdRequestType) __);
}


/// Adds pattern-matching-related methods to [XswdRequestType].
extension XswdRequestTypePatterns on XswdRequestType {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( XswdRequestType_Application value)?  application,TResult Function( XswdRequestType_Permission value)?  permission,TResult Function( XswdRequestType_PrefetchPermissions value)?  prefetchPermissions,TResult Function( XswdRequestType_CancelRequest value)?  cancelRequest,TResult Function( XswdRequestType_AppDisconnect value)?  appDisconnect,required TResult orElse(),}){
final _that = this;
switch (_that) {
case XswdRequestType_Application() when application != null:
return application(_that);case XswdRequestType_Permission() when permission != null:
return permission(_that);case XswdRequestType_PrefetchPermissions() when prefetchPermissions != null:
return prefetchPermissions(_that);case XswdRequestType_CancelRequest() when cancelRequest != null:
return cancelRequest(_that);case XswdRequestType_AppDisconnect() when appDisconnect != null:
return appDisconnect(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( XswdRequestType_Application value)  application,required TResult Function( XswdRequestType_Permission value)  permission,required TResult Function( XswdRequestType_PrefetchPermissions value)  prefetchPermissions,required TResult Function( XswdRequestType_CancelRequest value)  cancelRequest,required TResult Function( XswdRequestType_AppDisconnect value)  appDisconnect,}){
final _that = this;
switch (_that) {
case XswdRequestType_Application():
return application(_that);case XswdRequestType_Permission():
return permission(_that);case XswdRequestType_PrefetchPermissions():
return prefetchPermissions(_that);case XswdRequestType_CancelRequest():
return cancelRequest(_that);case XswdRequestType_AppDisconnect():
return appDisconnect(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( XswdRequestType_Application value)?  application,TResult? Function( XswdRequestType_Permission value)?  permission,TResult? Function( XswdRequestType_PrefetchPermissions value)?  prefetchPermissions,TResult? Function( XswdRequestType_CancelRequest value)?  cancelRequest,TResult? Function( XswdRequestType_AppDisconnect value)?  appDisconnect,}){
final _that = this;
switch (_that) {
case XswdRequestType_Application() when application != null:
return application(_that);case XswdRequestType_Permission() when permission != null:
return permission(_that);case XswdRequestType_PrefetchPermissions() when prefetchPermissions != null:
return prefetchPermissions(_that);case XswdRequestType_CancelRequest() when cancelRequest != null:
return cancelRequest(_that);case XswdRequestType_AppDisconnect() when appDisconnect != null:
return appDisconnect(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  application,TResult Function( NativeXswdPayload field0)?  permission,TResult Function( NativeXswdPayload field0)?  prefetchPermissions,TResult Function()?  cancelRequest,TResult Function()?  appDisconnect,required TResult orElse(),}) {final _that = this;
switch (_that) {
case XswdRequestType_Application() when application != null:
return application();case XswdRequestType_Permission() when permission != null:
return permission(_that.field0);case XswdRequestType_PrefetchPermissions() when prefetchPermissions != null:
return prefetchPermissions(_that.field0);case XswdRequestType_CancelRequest() when cancelRequest != null:
return cancelRequest();case XswdRequestType_AppDisconnect() when appDisconnect != null:
return appDisconnect();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  application,required TResult Function( NativeXswdPayload field0)  permission,required TResult Function( NativeXswdPayload field0)  prefetchPermissions,required TResult Function()  cancelRequest,required TResult Function()  appDisconnect,}) {final _that = this;
switch (_that) {
case XswdRequestType_Application():
return application();case XswdRequestType_Permission():
return permission(_that.field0);case XswdRequestType_PrefetchPermissions():
return prefetchPermissions(_that.field0);case XswdRequestType_CancelRequest():
return cancelRequest();case XswdRequestType_AppDisconnect():
return appDisconnect();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  application,TResult? Function( NativeXswdPayload field0)?  permission,TResult? Function( NativeXswdPayload field0)?  prefetchPermissions,TResult? Function()?  cancelRequest,TResult? Function()?  appDisconnect,}) {final _that = this;
switch (_that) {
case XswdRequestType_Application() when application != null:
return application();case XswdRequestType_Permission() when permission != null:
return permission(_that.field0);case XswdRequestType_PrefetchPermissions() when prefetchPermissions != null:
return prefetchPermissions(_that.field0);case XswdRequestType_CancelRequest() when cancelRequest != null:
return cancelRequest();case XswdRequestType_AppDisconnect() when appDisconnect != null:
return appDisconnect();case _:
  return null;

}
}

}

/// @nodoc


class XswdRequestType_Application extends XswdRequestType {
  const XswdRequestType_Application(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdRequestType_Application);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdRequestType.application()';
}


}




/// @nodoc


class XswdRequestType_Permission extends XswdRequestType {
  const XswdRequestType_Permission(this.field0): super._();
  

 final  NativeXswdPayload field0;

/// Create a copy of XswdRequestType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XswdRequestType_PermissionCopyWith<XswdRequestType_Permission> get copyWith => _$XswdRequestType_PermissionCopyWithImpl<XswdRequestType_Permission>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdRequestType_Permission&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'XswdRequestType.permission(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $XswdRequestType_PermissionCopyWith<$Res> implements $XswdRequestTypeCopyWith<$Res> {
  factory $XswdRequestType_PermissionCopyWith(XswdRequestType_Permission value, $Res Function(XswdRequestType_Permission) _then) = _$XswdRequestType_PermissionCopyWithImpl;
@useResult
$Res call({
 NativeXswdPayload field0
});




}
/// @nodoc
class _$XswdRequestType_PermissionCopyWithImpl<$Res>
    implements $XswdRequestType_PermissionCopyWith<$Res> {
  _$XswdRequestType_PermissionCopyWithImpl(this._self, this._then);

  final XswdRequestType_Permission _self;
  final $Res Function(XswdRequestType_Permission) _then;

/// Create a copy of XswdRequestType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(XswdRequestType_Permission(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as NativeXswdPayload,
  ));
}


}

/// @nodoc


class XswdRequestType_PrefetchPermissions extends XswdRequestType {
  const XswdRequestType_PrefetchPermissions(this.field0): super._();
  

 final  NativeXswdPayload field0;

/// Create a copy of XswdRequestType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XswdRequestType_PrefetchPermissionsCopyWith<XswdRequestType_PrefetchPermissions> get copyWith => _$XswdRequestType_PrefetchPermissionsCopyWithImpl<XswdRequestType_PrefetchPermissions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdRequestType_PrefetchPermissions&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'XswdRequestType.prefetchPermissions(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $XswdRequestType_PrefetchPermissionsCopyWith<$Res> implements $XswdRequestTypeCopyWith<$Res> {
  factory $XswdRequestType_PrefetchPermissionsCopyWith(XswdRequestType_PrefetchPermissions value, $Res Function(XswdRequestType_PrefetchPermissions) _then) = _$XswdRequestType_PrefetchPermissionsCopyWithImpl;
@useResult
$Res call({
 NativeXswdPayload field0
});




}
/// @nodoc
class _$XswdRequestType_PrefetchPermissionsCopyWithImpl<$Res>
    implements $XswdRequestType_PrefetchPermissionsCopyWith<$Res> {
  _$XswdRequestType_PrefetchPermissionsCopyWithImpl(this._self, this._then);

  final XswdRequestType_PrefetchPermissions _self;
  final $Res Function(XswdRequestType_PrefetchPermissions) _then;

/// Create a copy of XswdRequestType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(XswdRequestType_PrefetchPermissions(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as NativeXswdPayload,
  ));
}


}

/// @nodoc


class XswdRequestType_CancelRequest extends XswdRequestType {
  const XswdRequestType_CancelRequest(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdRequestType_CancelRequest);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdRequestType.cancelRequest()';
}


}




/// @nodoc


class XswdRequestType_AppDisconnect extends XswdRequestType {
  const XswdRequestType_AppDisconnect(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is XswdRequestType_AppDisconnect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'XswdRequestType.appDisconnect()';
}


}




// dart format on
