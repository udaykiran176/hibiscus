// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApiSyncStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiSyncStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ApiSyncStatus()';
}


}

/// @nodoc
class $ApiSyncStatusCopyWith<$Res>  {
$ApiSyncStatusCopyWith(ApiSyncStatus _, $Res Function(ApiSyncStatus) __);
}


/// Adds pattern-matching-related methods to [ApiSyncStatus].
extension ApiSyncStatusPatterns on ApiSyncStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ApiSyncStatus_Success value)?  success,TResult Function( ApiSyncStatus_DecryptionFailed value)?  decryptionFailed,TResult Function( ApiSyncStatus_NeedNewKey value)?  needNewKey,TResult Function( ApiSyncStatus_NetworkError value)?  networkError,TResult Function( ApiSyncStatus_NotConfigured value)?  notConfigured,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ApiSyncStatus_Success() when success != null:
return success(_that);case ApiSyncStatus_DecryptionFailed() when decryptionFailed != null:
return decryptionFailed(_that);case ApiSyncStatus_NeedNewKey() when needNewKey != null:
return needNewKey(_that);case ApiSyncStatus_NetworkError() when networkError != null:
return networkError(_that);case ApiSyncStatus_NotConfigured() when notConfigured != null:
return notConfigured(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ApiSyncStatus_Success value)  success,required TResult Function( ApiSyncStatus_DecryptionFailed value)  decryptionFailed,required TResult Function( ApiSyncStatus_NeedNewKey value)  needNewKey,required TResult Function( ApiSyncStatus_NetworkError value)  networkError,required TResult Function( ApiSyncStatus_NotConfigured value)  notConfigured,}){
final _that = this;
switch (_that) {
case ApiSyncStatus_Success():
return success(_that);case ApiSyncStatus_DecryptionFailed():
return decryptionFailed(_that);case ApiSyncStatus_NeedNewKey():
return needNewKey(_that);case ApiSyncStatus_NetworkError():
return networkError(_that);case ApiSyncStatus_NotConfigured():
return notConfigured(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ApiSyncStatus_Success value)?  success,TResult? Function( ApiSyncStatus_DecryptionFailed value)?  decryptionFailed,TResult? Function( ApiSyncStatus_NeedNewKey value)?  needNewKey,TResult? Function( ApiSyncStatus_NetworkError value)?  networkError,TResult? Function( ApiSyncStatus_NotConfigured value)?  notConfigured,}){
final _that = this;
switch (_that) {
case ApiSyncStatus_Success() when success != null:
return success(_that);case ApiSyncStatus_DecryptionFailed() when decryptionFailed != null:
return decryptionFailed(_that);case ApiSyncStatus_NeedNewKey() when needNewKey != null:
return needNewKey(_that);case ApiSyncStatus_NetworkError() when networkError != null:
return networkError(_that);case ApiSyncStatus_NotConfigured() when notConfigured != null:
return notConfigured(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int mergedCount,  bool uploaded)?  success,TResult Function()?  decryptionFailed,TResult Function()?  needNewKey,TResult Function( String message)?  networkError,TResult Function()?  notConfigured,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ApiSyncStatus_Success() when success != null:
return success(_that.mergedCount,_that.uploaded);case ApiSyncStatus_DecryptionFailed() when decryptionFailed != null:
return decryptionFailed();case ApiSyncStatus_NeedNewKey() when needNewKey != null:
return needNewKey();case ApiSyncStatus_NetworkError() when networkError != null:
return networkError(_that.message);case ApiSyncStatus_NotConfigured() when notConfigured != null:
return notConfigured();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int mergedCount,  bool uploaded)  success,required TResult Function()  decryptionFailed,required TResult Function()  needNewKey,required TResult Function( String message)  networkError,required TResult Function()  notConfigured,}) {final _that = this;
switch (_that) {
case ApiSyncStatus_Success():
return success(_that.mergedCount,_that.uploaded);case ApiSyncStatus_DecryptionFailed():
return decryptionFailed();case ApiSyncStatus_NeedNewKey():
return needNewKey();case ApiSyncStatus_NetworkError():
return networkError(_that.message);case ApiSyncStatus_NotConfigured():
return notConfigured();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int mergedCount,  bool uploaded)?  success,TResult? Function()?  decryptionFailed,TResult? Function()?  needNewKey,TResult? Function( String message)?  networkError,TResult? Function()?  notConfigured,}) {final _that = this;
switch (_that) {
case ApiSyncStatus_Success() when success != null:
return success(_that.mergedCount,_that.uploaded);case ApiSyncStatus_DecryptionFailed() when decryptionFailed != null:
return decryptionFailed();case ApiSyncStatus_NeedNewKey() when needNewKey != null:
return needNewKey();case ApiSyncStatus_NetworkError() when networkError != null:
return networkError(_that.message);case ApiSyncStatus_NotConfigured() when notConfigured != null:
return notConfigured();case _:
  return null;

}
}

}

/// @nodoc


class ApiSyncStatus_Success extends ApiSyncStatus {
  const ApiSyncStatus_Success({required this.mergedCount, required this.uploaded}): super._();
  

 final  int mergedCount;
 final  bool uploaded;

/// Create a copy of ApiSyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiSyncStatus_SuccessCopyWith<ApiSyncStatus_Success> get copyWith => _$ApiSyncStatus_SuccessCopyWithImpl<ApiSyncStatus_Success>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiSyncStatus_Success&&(identical(other.mergedCount, mergedCount) || other.mergedCount == mergedCount)&&(identical(other.uploaded, uploaded) || other.uploaded == uploaded));
}


@override
int get hashCode => Object.hash(runtimeType,mergedCount,uploaded);

@override
String toString() {
  return 'ApiSyncStatus.success(mergedCount: $mergedCount, uploaded: $uploaded)';
}


}

/// @nodoc
abstract mixin class $ApiSyncStatus_SuccessCopyWith<$Res> implements $ApiSyncStatusCopyWith<$Res> {
  factory $ApiSyncStatus_SuccessCopyWith(ApiSyncStatus_Success value, $Res Function(ApiSyncStatus_Success) _then) = _$ApiSyncStatus_SuccessCopyWithImpl;
@useResult
$Res call({
 int mergedCount, bool uploaded
});




}
/// @nodoc
class _$ApiSyncStatus_SuccessCopyWithImpl<$Res>
    implements $ApiSyncStatus_SuccessCopyWith<$Res> {
  _$ApiSyncStatus_SuccessCopyWithImpl(this._self, this._then);

  final ApiSyncStatus_Success _self;
  final $Res Function(ApiSyncStatus_Success) _then;

/// Create a copy of ApiSyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mergedCount = null,Object? uploaded = null,}) {
  return _then(ApiSyncStatus_Success(
mergedCount: null == mergedCount ? _self.mergedCount : mergedCount // ignore: cast_nullable_to_non_nullable
as int,uploaded: null == uploaded ? _self.uploaded : uploaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ApiSyncStatus_DecryptionFailed extends ApiSyncStatus {
  const ApiSyncStatus_DecryptionFailed(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiSyncStatus_DecryptionFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ApiSyncStatus.decryptionFailed()';
}


}




/// @nodoc


class ApiSyncStatus_NeedNewKey extends ApiSyncStatus {
  const ApiSyncStatus_NeedNewKey(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiSyncStatus_NeedNewKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ApiSyncStatus.needNewKey()';
}


}




/// @nodoc


class ApiSyncStatus_NetworkError extends ApiSyncStatus {
  const ApiSyncStatus_NetworkError({required this.message}): super._();
  

 final  String message;

/// Create a copy of ApiSyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiSyncStatus_NetworkErrorCopyWith<ApiSyncStatus_NetworkError> get copyWith => _$ApiSyncStatus_NetworkErrorCopyWithImpl<ApiSyncStatus_NetworkError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiSyncStatus_NetworkError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiSyncStatus.networkError(message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiSyncStatus_NetworkErrorCopyWith<$Res> implements $ApiSyncStatusCopyWith<$Res> {
  factory $ApiSyncStatus_NetworkErrorCopyWith(ApiSyncStatus_NetworkError value, $Res Function(ApiSyncStatus_NetworkError) _then) = _$ApiSyncStatus_NetworkErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ApiSyncStatus_NetworkErrorCopyWithImpl<$Res>
    implements $ApiSyncStatus_NetworkErrorCopyWith<$Res> {
  _$ApiSyncStatus_NetworkErrorCopyWithImpl(this._self, this._then);

  final ApiSyncStatus_NetworkError _self;
  final $Res Function(ApiSyncStatus_NetworkError) _then;

/// Create a copy of ApiSyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ApiSyncStatus_NetworkError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApiSyncStatus_NotConfigured extends ApiSyncStatus {
  const ApiSyncStatus_NotConfigured(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiSyncStatus_NotConfigured);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ApiSyncStatus.notConfigured()';
}


}




/// @nodoc
mixin _$ApiWebDavSettings {

 String get url; String get username; String get password; String get encryptionKey; bool get autoSyncOnStart; int get autoSyncInterval;
/// Create a copy of ApiWebDavSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiWebDavSettingsCopyWith<ApiWebDavSettings> get copyWith => _$ApiWebDavSettingsCopyWithImpl<ApiWebDavSettings>(this as ApiWebDavSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiWebDavSettings&&(identical(other.url, url) || other.url == url)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.encryptionKey, encryptionKey) || other.encryptionKey == encryptionKey)&&(identical(other.autoSyncOnStart, autoSyncOnStart) || other.autoSyncOnStart == autoSyncOnStart)&&(identical(other.autoSyncInterval, autoSyncInterval) || other.autoSyncInterval == autoSyncInterval));
}


@override
int get hashCode => Object.hash(runtimeType,url,username,password,encryptionKey,autoSyncOnStart,autoSyncInterval);

@override
String toString() {
  return 'ApiWebDavSettings(url: $url, username: $username, password: $password, encryptionKey: $encryptionKey, autoSyncOnStart: $autoSyncOnStart, autoSyncInterval: $autoSyncInterval)';
}


}

/// @nodoc
abstract mixin class $ApiWebDavSettingsCopyWith<$Res>  {
  factory $ApiWebDavSettingsCopyWith(ApiWebDavSettings value, $Res Function(ApiWebDavSettings) _then) = _$ApiWebDavSettingsCopyWithImpl;
@useResult
$Res call({
 String url, String username, String password, String encryptionKey, bool autoSyncOnStart, int autoSyncInterval
});




}
/// @nodoc
class _$ApiWebDavSettingsCopyWithImpl<$Res>
    implements $ApiWebDavSettingsCopyWith<$Res> {
  _$ApiWebDavSettingsCopyWithImpl(this._self, this._then);

  final ApiWebDavSettings _self;
  final $Res Function(ApiWebDavSettings) _then;

/// Create a copy of ApiWebDavSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? username = null,Object? password = null,Object? encryptionKey = null,Object? autoSyncOnStart = null,Object? autoSyncInterval = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,encryptionKey: null == encryptionKey ? _self.encryptionKey : encryptionKey // ignore: cast_nullable_to_non_nullable
as String,autoSyncOnStart: null == autoSyncOnStart ? _self.autoSyncOnStart : autoSyncOnStart // ignore: cast_nullable_to_non_nullable
as bool,autoSyncInterval: null == autoSyncInterval ? _self.autoSyncInterval : autoSyncInterval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiWebDavSettings].
extension ApiWebDavSettingsPatterns on ApiWebDavSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiWebDavSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiWebDavSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiWebDavSettings value)  $default,){
final _that = this;
switch (_that) {
case _ApiWebDavSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiWebDavSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ApiWebDavSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String username,  String password,  String encryptionKey,  bool autoSyncOnStart,  int autoSyncInterval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiWebDavSettings() when $default != null:
return $default(_that.url,_that.username,_that.password,_that.encryptionKey,_that.autoSyncOnStart,_that.autoSyncInterval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String username,  String password,  String encryptionKey,  bool autoSyncOnStart,  int autoSyncInterval)  $default,) {final _that = this;
switch (_that) {
case _ApiWebDavSettings():
return $default(_that.url,_that.username,_that.password,_that.encryptionKey,_that.autoSyncOnStart,_that.autoSyncInterval);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String username,  String password,  String encryptionKey,  bool autoSyncOnStart,  int autoSyncInterval)?  $default,) {final _that = this;
switch (_that) {
case _ApiWebDavSettings() when $default != null:
return $default(_that.url,_that.username,_that.password,_that.encryptionKey,_that.autoSyncOnStart,_that.autoSyncInterval);case _:
  return null;

}
}

}

/// @nodoc


class _ApiWebDavSettings extends ApiWebDavSettings {
  const _ApiWebDavSettings({required this.url, required this.username, required this.password, required this.encryptionKey, required this.autoSyncOnStart, required this.autoSyncInterval}): super._();
  

@override final  String url;
@override final  String username;
@override final  String password;
@override final  String encryptionKey;
@override final  bool autoSyncOnStart;
@override final  int autoSyncInterval;

/// Create a copy of ApiWebDavSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiWebDavSettingsCopyWith<_ApiWebDavSettings> get copyWith => __$ApiWebDavSettingsCopyWithImpl<_ApiWebDavSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiWebDavSettings&&(identical(other.url, url) || other.url == url)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.encryptionKey, encryptionKey) || other.encryptionKey == encryptionKey)&&(identical(other.autoSyncOnStart, autoSyncOnStart) || other.autoSyncOnStart == autoSyncOnStart)&&(identical(other.autoSyncInterval, autoSyncInterval) || other.autoSyncInterval == autoSyncInterval));
}


@override
int get hashCode => Object.hash(runtimeType,url,username,password,encryptionKey,autoSyncOnStart,autoSyncInterval);

@override
String toString() {
  return 'ApiWebDavSettings(url: $url, username: $username, password: $password, encryptionKey: $encryptionKey, autoSyncOnStart: $autoSyncOnStart, autoSyncInterval: $autoSyncInterval)';
}


}

/// @nodoc
abstract mixin class _$ApiWebDavSettingsCopyWith<$Res> implements $ApiWebDavSettingsCopyWith<$Res> {
  factory _$ApiWebDavSettingsCopyWith(_ApiWebDavSettings value, $Res Function(_ApiWebDavSettings) _then) = __$ApiWebDavSettingsCopyWithImpl;
@override @useResult
$Res call({
 String url, String username, String password, String encryptionKey, bool autoSyncOnStart, int autoSyncInterval
});




}
/// @nodoc
class __$ApiWebDavSettingsCopyWithImpl<$Res>
    implements _$ApiWebDavSettingsCopyWith<$Res> {
  __$ApiWebDavSettingsCopyWithImpl(this._self, this._then);

  final _ApiWebDavSettings _self;
  final $Res Function(_ApiWebDavSettings) _then;

/// Create a copy of ApiWebDavSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? username = null,Object? password = null,Object? encryptionKey = null,Object? autoSyncOnStart = null,Object? autoSyncInterval = null,}) {
  return _then(_ApiWebDavSettings(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,encryptionKey: null == encryptionKey ? _self.encryptionKey : encryptionKey // ignore: cast_nullable_to_non_nullable
as String,autoSyncOnStart: null == autoSyncOnStart ? _self.autoSyncOnStart : autoSyncOnStart // ignore: cast_nullable_to_non_nullable
as bool,autoSyncInterval: null == autoSyncInterval ? _self.autoSyncInterval : autoSyncInterval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
