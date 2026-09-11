// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remote_control_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
RemoteControlPayload _$RemoteControlPayloadFromJson(
  Map<String, dynamic> json
) {
        switch (json['cmd']) {
                  case 'acquireControl':
          return AcquireControl.fromJson(
            json
          );
                case 'releaseControl':
          return ReleaseControl.fromJson(
            json
          );
                case 'heartbeat':
          return Heartbeat.fromJson(
            json
          );
                case 'startStatusPush':
          return StartStatusPush.fromJson(
            json
          );
                case 'stopStatusPush':
          return StopStatusPush.fromJson(
            json
          );
                case 'relayToggle':
          return RelayToggle.fromJson(
            json
          );
                case 'robotAction':
          return RobotAction.fromJson(
            json
          );
                case 'coffeeAction':
          return CoffeeAction.fromJson(
            json
          );
                case 'doorControl':
          return DoorControl.fromJson(
            json
          );
                case 'cupDispense':
          return CupDispense.fromJson(
            json
          );
                case 'lidDispense':
          return LidDispense.fromJson(
            json
          );
                case 'iceDispense':
          return IceDispense.fromJson(
            json
          );
                case 'juiceDispense':
          return JuiceDispense.fromJson(
            json
          );
                case 'versionQuery':
          return VersionQuery.fromJson(
            json
          );
                case 'systemCommand':
          return SystemCommand.fromJson(
            json
          );
                case 'forceRelease':
          return ForceRelease.fromJson(
            json
          );
                case 'queryControl':
          return QueryControl.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'cmd',
  'RemoteControlPayload',
  'Invalid union type "${json['cmd']}"!'
);
        }
      
}

/// @nodoc
mixin _$RemoteControlPayload {



  /// Serializes this RemoteControlPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoteControlPayload);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload()';
}


}

/// @nodoc
class $RemoteControlPayloadCopyWith<$Res>  {
$RemoteControlPayloadCopyWith(RemoteControlPayload _, $Res Function(RemoteControlPayload) __);
}


/// Adds pattern-matching-related methods to [RemoteControlPayload].
extension RemoteControlPayloadPatterns on RemoteControlPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AcquireControl value)?  acquireControl,TResult Function( ReleaseControl value)?  releaseControl,TResult Function( Heartbeat value)?  heartbeat,TResult Function( StartStatusPush value)?  startStatusPush,TResult Function( StopStatusPush value)?  stopStatusPush,TResult Function( RelayToggle value)?  relayToggle,TResult Function( RobotAction value)?  robotAction,TResult Function( CoffeeAction value)?  coffeeAction,TResult Function( DoorControl value)?  doorControl,TResult Function( CupDispense value)?  cupDispense,TResult Function( LidDispense value)?  lidDispense,TResult Function( IceDispense value)?  iceDispense,TResult Function( JuiceDispense value)?  juiceDispense,TResult Function( VersionQuery value)?  versionQuery,TResult Function( SystemCommand value)?  systemCommand,TResult Function( ForceRelease value)?  forceRelease,TResult Function( QueryControl value)?  queryControl,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AcquireControl() when acquireControl != null:
return acquireControl(_that);case ReleaseControl() when releaseControl != null:
return releaseControl(_that);case Heartbeat() when heartbeat != null:
return heartbeat(_that);case StartStatusPush() when startStatusPush != null:
return startStatusPush(_that);case StopStatusPush() when stopStatusPush != null:
return stopStatusPush(_that);case RelayToggle() when relayToggle != null:
return relayToggle(_that);case RobotAction() when robotAction != null:
return robotAction(_that);case CoffeeAction() when coffeeAction != null:
return coffeeAction(_that);case DoorControl() when doorControl != null:
return doorControl(_that);case CupDispense() when cupDispense != null:
return cupDispense(_that);case LidDispense() when lidDispense != null:
return lidDispense(_that);case IceDispense() when iceDispense != null:
return iceDispense(_that);case JuiceDispense() when juiceDispense != null:
return juiceDispense(_that);case VersionQuery() when versionQuery != null:
return versionQuery(_that);case SystemCommand() when systemCommand != null:
return systemCommand(_that);case ForceRelease() when forceRelease != null:
return forceRelease(_that);case QueryControl() when queryControl != null:
return queryControl(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AcquireControl value)  acquireControl,required TResult Function( ReleaseControl value)  releaseControl,required TResult Function( Heartbeat value)  heartbeat,required TResult Function( StartStatusPush value)  startStatusPush,required TResult Function( StopStatusPush value)  stopStatusPush,required TResult Function( RelayToggle value)  relayToggle,required TResult Function( RobotAction value)  robotAction,required TResult Function( CoffeeAction value)  coffeeAction,required TResult Function( DoorControl value)  doorControl,required TResult Function( CupDispense value)  cupDispense,required TResult Function( LidDispense value)  lidDispense,required TResult Function( IceDispense value)  iceDispense,required TResult Function( JuiceDispense value)  juiceDispense,required TResult Function( VersionQuery value)  versionQuery,required TResult Function( SystemCommand value)  systemCommand,required TResult Function( ForceRelease value)  forceRelease,required TResult Function( QueryControl value)  queryControl,}){
final _that = this;
switch (_that) {
case AcquireControl():
return acquireControl(_that);case ReleaseControl():
return releaseControl(_that);case Heartbeat():
return heartbeat(_that);case StartStatusPush():
return startStatusPush(_that);case StopStatusPush():
return stopStatusPush(_that);case RelayToggle():
return relayToggle(_that);case RobotAction():
return robotAction(_that);case CoffeeAction():
return coffeeAction(_that);case DoorControl():
return doorControl(_that);case CupDispense():
return cupDispense(_that);case LidDispense():
return lidDispense(_that);case IceDispense():
return iceDispense(_that);case JuiceDispense():
return juiceDispense(_that);case VersionQuery():
return versionQuery(_that);case SystemCommand():
return systemCommand(_that);case ForceRelease():
return forceRelease(_that);case QueryControl():
return queryControl(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AcquireControl value)?  acquireControl,TResult? Function( ReleaseControl value)?  releaseControl,TResult? Function( Heartbeat value)?  heartbeat,TResult? Function( StartStatusPush value)?  startStatusPush,TResult? Function( StopStatusPush value)?  stopStatusPush,TResult? Function( RelayToggle value)?  relayToggle,TResult? Function( RobotAction value)?  robotAction,TResult? Function( CoffeeAction value)?  coffeeAction,TResult? Function( DoorControl value)?  doorControl,TResult? Function( CupDispense value)?  cupDispense,TResult? Function( LidDispense value)?  lidDispense,TResult? Function( IceDispense value)?  iceDispense,TResult? Function( JuiceDispense value)?  juiceDispense,TResult? Function( VersionQuery value)?  versionQuery,TResult? Function( SystemCommand value)?  systemCommand,TResult? Function( ForceRelease value)?  forceRelease,TResult? Function( QueryControl value)?  queryControl,}){
final _that = this;
switch (_that) {
case AcquireControl() when acquireControl != null:
return acquireControl(_that);case ReleaseControl() when releaseControl != null:
return releaseControl(_that);case Heartbeat() when heartbeat != null:
return heartbeat(_that);case StartStatusPush() when startStatusPush != null:
return startStatusPush(_that);case StopStatusPush() when stopStatusPush != null:
return stopStatusPush(_that);case RelayToggle() when relayToggle != null:
return relayToggle(_that);case RobotAction() when robotAction != null:
return robotAction(_that);case CoffeeAction() when coffeeAction != null:
return coffeeAction(_that);case DoorControl() when doorControl != null:
return doorControl(_that);case CupDispense() when cupDispense != null:
return cupDispense(_that);case LidDispense() when lidDispense != null:
return lidDispense(_that);case IceDispense() when iceDispense != null:
return iceDispense(_that);case JuiceDispense() when juiceDispense != null:
return juiceDispense(_that);case VersionQuery() when versionQuery != null:
return versionQuery(_that);case SystemCommand() when systemCommand != null:
return systemCommand(_that);case ForceRelease() when forceRelease != null:
return forceRelease(_that);case QueryControl() when queryControl != null:
return queryControl(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  acquireControl,TResult Function()?  releaseControl,TResult Function()?  heartbeat,TResult Function()?  startStatusPush,TResult Function()?  stopStatusPush,TResult Function( RelayToggleData data)?  relayToggle,TResult Function( RobotActionData data)?  robotAction,TResult Function( CoffeeActionData data)?  coffeeAction,TResult Function( DoorControlData data)?  doorControl,TResult Function( CupDispenseData data)?  cupDispense,TResult Function( LidDispenseData data)?  lidDispense,TResult Function( IceDispenseData data)?  iceDispense,TResult Function( JuiceDispenseData data)?  juiceDispense,TResult Function()?  versionQuery,TResult Function( SystemCommandData data)?  systemCommand,TResult Function()?  forceRelease,TResult Function()?  queryControl,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AcquireControl() when acquireControl != null:
return acquireControl();case ReleaseControl() when releaseControl != null:
return releaseControl();case Heartbeat() when heartbeat != null:
return heartbeat();case StartStatusPush() when startStatusPush != null:
return startStatusPush();case StopStatusPush() when stopStatusPush != null:
return stopStatusPush();case RelayToggle() when relayToggle != null:
return relayToggle(_that.data);case RobotAction() when robotAction != null:
return robotAction(_that.data);case CoffeeAction() when coffeeAction != null:
return coffeeAction(_that.data);case DoorControl() when doorControl != null:
return doorControl(_that.data);case CupDispense() when cupDispense != null:
return cupDispense(_that.data);case LidDispense() when lidDispense != null:
return lidDispense(_that.data);case IceDispense() when iceDispense != null:
return iceDispense(_that.data);case JuiceDispense() when juiceDispense != null:
return juiceDispense(_that.data);case VersionQuery() when versionQuery != null:
return versionQuery();case SystemCommand() when systemCommand != null:
return systemCommand(_that.data);case ForceRelease() when forceRelease != null:
return forceRelease();case QueryControl() when queryControl != null:
return queryControl();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  acquireControl,required TResult Function()  releaseControl,required TResult Function()  heartbeat,required TResult Function()  startStatusPush,required TResult Function()  stopStatusPush,required TResult Function( RelayToggleData data)  relayToggle,required TResult Function( RobotActionData data)  robotAction,required TResult Function( CoffeeActionData data)  coffeeAction,required TResult Function( DoorControlData data)  doorControl,required TResult Function( CupDispenseData data)  cupDispense,required TResult Function( LidDispenseData data)  lidDispense,required TResult Function( IceDispenseData data)  iceDispense,required TResult Function( JuiceDispenseData data)  juiceDispense,required TResult Function()  versionQuery,required TResult Function( SystemCommandData data)  systemCommand,required TResult Function()  forceRelease,required TResult Function()  queryControl,}) {final _that = this;
switch (_that) {
case AcquireControl():
return acquireControl();case ReleaseControl():
return releaseControl();case Heartbeat():
return heartbeat();case StartStatusPush():
return startStatusPush();case StopStatusPush():
return stopStatusPush();case RelayToggle():
return relayToggle(_that.data);case RobotAction():
return robotAction(_that.data);case CoffeeAction():
return coffeeAction(_that.data);case DoorControl():
return doorControl(_that.data);case CupDispense():
return cupDispense(_that.data);case LidDispense():
return lidDispense(_that.data);case IceDispense():
return iceDispense(_that.data);case JuiceDispense():
return juiceDispense(_that.data);case VersionQuery():
return versionQuery();case SystemCommand():
return systemCommand(_that.data);case ForceRelease():
return forceRelease();case QueryControl():
return queryControl();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  acquireControl,TResult? Function()?  releaseControl,TResult? Function()?  heartbeat,TResult? Function()?  startStatusPush,TResult? Function()?  stopStatusPush,TResult? Function( RelayToggleData data)?  relayToggle,TResult? Function( RobotActionData data)?  robotAction,TResult? Function( CoffeeActionData data)?  coffeeAction,TResult? Function( DoorControlData data)?  doorControl,TResult? Function( CupDispenseData data)?  cupDispense,TResult? Function( LidDispenseData data)?  lidDispense,TResult? Function( IceDispenseData data)?  iceDispense,TResult? Function( JuiceDispenseData data)?  juiceDispense,TResult? Function()?  versionQuery,TResult? Function( SystemCommandData data)?  systemCommand,TResult? Function()?  forceRelease,TResult? Function()?  queryControl,}) {final _that = this;
switch (_that) {
case AcquireControl() when acquireControl != null:
return acquireControl();case ReleaseControl() when releaseControl != null:
return releaseControl();case Heartbeat() when heartbeat != null:
return heartbeat();case StartStatusPush() when startStatusPush != null:
return startStatusPush();case StopStatusPush() when stopStatusPush != null:
return stopStatusPush();case RelayToggle() when relayToggle != null:
return relayToggle(_that.data);case RobotAction() when robotAction != null:
return robotAction(_that.data);case CoffeeAction() when coffeeAction != null:
return coffeeAction(_that.data);case DoorControl() when doorControl != null:
return doorControl(_that.data);case CupDispense() when cupDispense != null:
return cupDispense(_that.data);case LidDispense() when lidDispense != null:
return lidDispense(_that.data);case IceDispense() when iceDispense != null:
return iceDispense(_that.data);case JuiceDispense() when juiceDispense != null:
return juiceDispense(_that.data);case VersionQuery() when versionQuery != null:
return versionQuery();case SystemCommand() when systemCommand != null:
return systemCommand(_that.data);case ForceRelease() when forceRelease != null:
return forceRelease();case QueryControl() when queryControl != null:
return queryControl();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class AcquireControl implements RemoteControlPayload {
  const AcquireControl({final  String? $type}): $type = $type ?? 'acquireControl';
  factory AcquireControl.fromJson(Map<String, dynamic> json) => _$AcquireControlFromJson(json);



@JsonKey(name: 'cmd')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$AcquireControlToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcquireControl);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload.acquireControl()';
}


}




/// @nodoc
@JsonSerializable()

class ReleaseControl implements RemoteControlPayload {
  const ReleaseControl({final  String? $type}): $type = $type ?? 'releaseControl';
  factory ReleaseControl.fromJson(Map<String, dynamic> json) => _$ReleaseControlFromJson(json);



@JsonKey(name: 'cmd')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ReleaseControlToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseControl);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload.releaseControl()';
}


}




/// @nodoc
@JsonSerializable()

class Heartbeat implements RemoteControlPayload {
  const Heartbeat({final  String? $type}): $type = $type ?? 'heartbeat';
  factory Heartbeat.fromJson(Map<String, dynamic> json) => _$HeartbeatFromJson(json);



@JsonKey(name: 'cmd')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$HeartbeatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Heartbeat);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload.heartbeat()';
}


}




/// @nodoc
@JsonSerializable()

class StartStatusPush implements RemoteControlPayload {
  const StartStatusPush({final  String? $type}): $type = $type ?? 'startStatusPush';
  factory StartStatusPush.fromJson(Map<String, dynamic> json) => _$StartStatusPushFromJson(json);



@JsonKey(name: 'cmd')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$StartStatusPushToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartStatusPush);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload.startStatusPush()';
}


}




/// @nodoc
@JsonSerializable()

class StopStatusPush implements RemoteControlPayload {
  const StopStatusPush({final  String? $type}): $type = $type ?? 'stopStatusPush';
  factory StopStatusPush.fromJson(Map<String, dynamic> json) => _$StopStatusPushFromJson(json);



@JsonKey(name: 'cmd')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$StopStatusPushToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StopStatusPush);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload.stopStatusPush()';
}


}




/// @nodoc
@JsonSerializable()

class RelayToggle implements RemoteControlPayload {
  const RelayToggle({required this.data, final  String? $type}): $type = $type ?? 'relayToggle';
  factory RelayToggle.fromJson(Map<String, dynamic> json) => _$RelayToggleFromJson(json);

 final  RelayToggleData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelayToggleCopyWith<RelayToggle> get copyWith => _$RelayToggleCopyWithImpl<RelayToggle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RelayToggleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelayToggle&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.relayToggle(data: $data)';
}


}

/// @nodoc
abstract mixin class $RelayToggleCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $RelayToggleCopyWith(RelayToggle value, $Res Function(RelayToggle) _then) = _$RelayToggleCopyWithImpl;
@useResult
$Res call({
 RelayToggleData data
});




}
/// @nodoc
class _$RelayToggleCopyWithImpl<$Res>
    implements $RelayToggleCopyWith<$Res> {
  _$RelayToggleCopyWithImpl(this._self, this._then);

  final RelayToggle _self;
  final $Res Function(RelayToggle) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(RelayToggle(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RelayToggleData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RobotAction implements RemoteControlPayload {
  const RobotAction({required this.data, final  String? $type}): $type = $type ?? 'robotAction';
  factory RobotAction.fromJson(Map<String, dynamic> json) => _$RobotActionFromJson(json);

 final  RobotActionData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RobotActionCopyWith<RobotAction> get copyWith => _$RobotActionCopyWithImpl<RobotAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RobotActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RobotAction&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.robotAction(data: $data)';
}


}

/// @nodoc
abstract mixin class $RobotActionCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $RobotActionCopyWith(RobotAction value, $Res Function(RobotAction) _then) = _$RobotActionCopyWithImpl;
@useResult
$Res call({
 RobotActionData data
});




}
/// @nodoc
class _$RobotActionCopyWithImpl<$Res>
    implements $RobotActionCopyWith<$Res> {
  _$RobotActionCopyWithImpl(this._self, this._then);

  final RobotAction _self;
  final $Res Function(RobotAction) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(RobotAction(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RobotActionData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CoffeeAction implements RemoteControlPayload {
  const CoffeeAction({required this.data, final  String? $type}): $type = $type ?? 'coffeeAction';
  factory CoffeeAction.fromJson(Map<String, dynamic> json) => _$CoffeeActionFromJson(json);

 final  CoffeeActionData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoffeeActionCopyWith<CoffeeAction> get copyWith => _$CoffeeActionCopyWithImpl<CoffeeAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoffeeActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoffeeAction&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.coffeeAction(data: $data)';
}


}

/// @nodoc
abstract mixin class $CoffeeActionCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $CoffeeActionCopyWith(CoffeeAction value, $Res Function(CoffeeAction) _then) = _$CoffeeActionCopyWithImpl;
@useResult
$Res call({
 CoffeeActionData data
});




}
/// @nodoc
class _$CoffeeActionCopyWithImpl<$Res>
    implements $CoffeeActionCopyWith<$Res> {
  _$CoffeeActionCopyWithImpl(this._self, this._then);

  final CoffeeAction _self;
  final $Res Function(CoffeeAction) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(CoffeeAction(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as CoffeeActionData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class DoorControl implements RemoteControlPayload {
  const DoorControl({required this.data, final  String? $type}): $type = $type ?? 'doorControl';
  factory DoorControl.fromJson(Map<String, dynamic> json) => _$DoorControlFromJson(json);

 final  DoorControlData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DoorControlCopyWith<DoorControl> get copyWith => _$DoorControlCopyWithImpl<DoorControl>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DoorControlToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DoorControl&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.doorControl(data: $data)';
}


}

/// @nodoc
abstract mixin class $DoorControlCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $DoorControlCopyWith(DoorControl value, $Res Function(DoorControl) _then) = _$DoorControlCopyWithImpl;
@useResult
$Res call({
 DoorControlData data
});




}
/// @nodoc
class _$DoorControlCopyWithImpl<$Res>
    implements $DoorControlCopyWith<$Res> {
  _$DoorControlCopyWithImpl(this._self, this._then);

  final DoorControl _self;
  final $Res Function(DoorControl) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(DoorControl(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as DoorControlData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CupDispense implements RemoteControlPayload {
  const CupDispense({required this.data, final  String? $type}): $type = $type ?? 'cupDispense';
  factory CupDispense.fromJson(Map<String, dynamic> json) => _$CupDispenseFromJson(json);

 final  CupDispenseData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CupDispenseCopyWith<CupDispense> get copyWith => _$CupDispenseCopyWithImpl<CupDispense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CupDispenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CupDispense&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.cupDispense(data: $data)';
}


}

/// @nodoc
abstract mixin class $CupDispenseCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $CupDispenseCopyWith(CupDispense value, $Res Function(CupDispense) _then) = _$CupDispenseCopyWithImpl;
@useResult
$Res call({
 CupDispenseData data
});




}
/// @nodoc
class _$CupDispenseCopyWithImpl<$Res>
    implements $CupDispenseCopyWith<$Res> {
  _$CupDispenseCopyWithImpl(this._self, this._then);

  final CupDispense _self;
  final $Res Function(CupDispense) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(CupDispense(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as CupDispenseData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class LidDispense implements RemoteControlPayload {
  const LidDispense({required this.data, final  String? $type}): $type = $type ?? 'lidDispense';
  factory LidDispense.fromJson(Map<String, dynamic> json) => _$LidDispenseFromJson(json);

 final  LidDispenseData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LidDispenseCopyWith<LidDispense> get copyWith => _$LidDispenseCopyWithImpl<LidDispense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LidDispenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LidDispense&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.lidDispense(data: $data)';
}


}

/// @nodoc
abstract mixin class $LidDispenseCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $LidDispenseCopyWith(LidDispense value, $Res Function(LidDispense) _then) = _$LidDispenseCopyWithImpl;
@useResult
$Res call({
 LidDispenseData data
});




}
/// @nodoc
class _$LidDispenseCopyWithImpl<$Res>
    implements $LidDispenseCopyWith<$Res> {
  _$LidDispenseCopyWithImpl(this._self, this._then);

  final LidDispense _self;
  final $Res Function(LidDispense) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(LidDispense(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as LidDispenseData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class IceDispense implements RemoteControlPayload {
  const IceDispense({required this.data, final  String? $type}): $type = $type ?? 'iceDispense';
  factory IceDispense.fromJson(Map<String, dynamic> json) => _$IceDispenseFromJson(json);

 final  IceDispenseData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IceDispenseCopyWith<IceDispense> get copyWith => _$IceDispenseCopyWithImpl<IceDispense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IceDispenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IceDispense&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.iceDispense(data: $data)';
}


}

/// @nodoc
abstract mixin class $IceDispenseCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $IceDispenseCopyWith(IceDispense value, $Res Function(IceDispense) _then) = _$IceDispenseCopyWithImpl;
@useResult
$Res call({
 IceDispenseData data
});




}
/// @nodoc
class _$IceDispenseCopyWithImpl<$Res>
    implements $IceDispenseCopyWith<$Res> {
  _$IceDispenseCopyWithImpl(this._self, this._then);

  final IceDispense _self;
  final $Res Function(IceDispense) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(IceDispense(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as IceDispenseData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class JuiceDispense implements RemoteControlPayload {
  const JuiceDispense({required this.data, final  String? $type}): $type = $type ?? 'juiceDispense';
  factory JuiceDispense.fromJson(Map<String, dynamic> json) => _$JuiceDispenseFromJson(json);

 final  JuiceDispenseData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JuiceDispenseCopyWith<JuiceDispense> get copyWith => _$JuiceDispenseCopyWithImpl<JuiceDispense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JuiceDispenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JuiceDispense&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.juiceDispense(data: $data)';
}


}

/// @nodoc
abstract mixin class $JuiceDispenseCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $JuiceDispenseCopyWith(JuiceDispense value, $Res Function(JuiceDispense) _then) = _$JuiceDispenseCopyWithImpl;
@useResult
$Res call({
 JuiceDispenseData data
});




}
/// @nodoc
class _$JuiceDispenseCopyWithImpl<$Res>
    implements $JuiceDispenseCopyWith<$Res> {
  _$JuiceDispenseCopyWithImpl(this._self, this._then);

  final JuiceDispense _self;
  final $Res Function(JuiceDispense) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(JuiceDispense(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as JuiceDispenseData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class VersionQuery implements RemoteControlPayload {
  const VersionQuery({final  String? $type}): $type = $type ?? 'versionQuery';
  factory VersionQuery.fromJson(Map<String, dynamic> json) => _$VersionQueryFromJson(json);



@JsonKey(name: 'cmd')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$VersionQueryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VersionQuery);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload.versionQuery()';
}


}




/// @nodoc
@JsonSerializable()

class SystemCommand implements RemoteControlPayload {
  const SystemCommand({required this.data, final  String? $type}): $type = $type ?? 'systemCommand';
  factory SystemCommand.fromJson(Map<String, dynamic> json) => _$SystemCommandFromJson(json);

 final  SystemCommandData data;

@JsonKey(name: 'cmd')
final String $type;


/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemCommandCopyWith<SystemCommand> get copyWith => _$SystemCommandCopyWithImpl<SystemCommand>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SystemCommandToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemCommand&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'RemoteControlPayload.systemCommand(data: $data)';
}


}

/// @nodoc
abstract mixin class $SystemCommandCopyWith<$Res> implements $RemoteControlPayloadCopyWith<$Res> {
  factory $SystemCommandCopyWith(SystemCommand value, $Res Function(SystemCommand) _then) = _$SystemCommandCopyWithImpl;
@useResult
$Res call({
 SystemCommandData data
});




}
/// @nodoc
class _$SystemCommandCopyWithImpl<$Res>
    implements $SystemCommandCopyWith<$Res> {
  _$SystemCommandCopyWithImpl(this._self, this._then);

  final SystemCommand _self;
  final $Res Function(SystemCommand) _then;

/// Create a copy of RemoteControlPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(SystemCommand(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as SystemCommandData,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ForceRelease implements RemoteControlPayload {
  const ForceRelease({final  String? $type}): $type = $type ?? 'forceRelease';
  factory ForceRelease.fromJson(Map<String, dynamic> json) => _$ForceReleaseFromJson(json);



@JsonKey(name: 'cmd')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ForceReleaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForceRelease);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload.forceRelease()';
}


}




/// @nodoc
@JsonSerializable()

class QueryControl implements RemoteControlPayload {
  const QueryControl({final  String? $type}): $type = $type ?? 'queryControl';
  factory QueryControl.fromJson(Map<String, dynamic> json) => _$QueryControlFromJson(json);



@JsonKey(name: 'cmd')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$QueryControlToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueryControl);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RemoteControlPayload.queryControl()';
}


}




// dart format on
