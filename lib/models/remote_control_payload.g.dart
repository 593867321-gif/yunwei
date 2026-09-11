// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_control_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelayToggleData _$RelayToggleDataFromJson(Map<String, dynamic> json) =>
    RelayToggleData(
      relayIndex: (json['relayIndex'] as num).toInt(),
      on: json['on'] as bool,
    );

Map<String, dynamic> _$RelayToggleDataToJson(RelayToggleData instance) =>
    <String, dynamic>{'relayIndex': instance.relayIndex, 'on': instance.on};

RobotActionData _$RobotActionDataFromJson(Map<String, dynamic> json) =>
    RobotActionData(
      arm: (json['arm'] as num).toInt(),
      action: (json['action'] as num).toInt(),
      dropTarget: (json['dropTarget'] as num).toInt(),
      cupOut: (json['cupOut'] as num).toInt(),
      cacheDiscard: (json['cacheDiscard'] as num).toInt(),
    );

Map<String, dynamic> _$RobotActionDataToJson(RobotActionData instance) =>
    <String, dynamic>{
      'arm': instance.arm,
      'action': instance.action,
      'dropTarget': instance.dropTarget,
      'cupOut': instance.cupOut,
      'cacheDiscard': instance.cacheDiscard,
    };

CoffeeActionData _$CoffeeActionDataFromJson(Map<String, dynamic> json) =>
    CoffeeActionData(
      function: (json['function'] as num).toInt(),
      value: (json['value'] as num).toInt(),
    );

Map<String, dynamic> _$CoffeeActionDataToJson(CoffeeActionData instance) =>
    <String, dynamic>{'function': instance.function, 'value': instance.value};

DoorControlData _$DoorControlDataFromJson(Map<String, dynamic> json) =>
    DoorControlData(
      doorIndex: (json['doorIndex'] as num).toInt(),
      cupMotor: (json['cupMotor'] as num?)?.toInt(),
      frontDoorMotor: (json['frontDoorMotor'] as num?)?.toInt(),
      linkControl: (json['linkControl'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DoorControlDataToJson(DoorControlData instance) =>
    <String, dynamic>{
      'doorIndex': instance.doorIndex,
      'cupMotor': ?instance.cupMotor,
      'frontDoorMotor': ?instance.frontDoorMotor,
      'linkControl': ?instance.linkControl,
    };

CupDispenseData _$CupDispenseDataFromJson(Map<String, dynamic> json) =>
    CupDispenseData(
      index: (json['index'] as num).toInt(),
      action: (json['action'] as num).toInt(),
    );

Map<String, dynamic> _$CupDispenseDataToJson(CupDispenseData instance) =>
    <String, dynamic>{'index': instance.index, 'action': instance.action};

LidDispenseData _$LidDispenseDataFromJson(Map<String, dynamic> json) =>
    LidDispenseData(
      index: (json['index'] as num).toInt(),
      action: (json['action'] as num).toInt(),
    );

Map<String, dynamic> _$LidDispenseDataToJson(LidDispenseData instance) =>
    <String, dynamic>{'index': instance.index, 'action': instance.action};

IceDispenseData _$IceDispenseDataFromJson(Map<String, dynamic> json) =>
    IceDispenseData(
      mode: (json['mode'] as num).toInt(),
      target: (json['target'] as num).toInt(),
    );

Map<String, dynamic> _$IceDispenseDataToJson(IceDispenseData instance) =>
    <String, dynamic>{'mode': instance.mode, 'target': instance.target};

JuiceDispenseData _$JuiceDispenseDataFromJson(Map<String, dynamic> json) =>
    JuiceDispenseData(
      pipe: (json['pipe'] as num).toInt(),
      grams: json['grams'] as num,
    );

Map<String, dynamic> _$JuiceDispenseDataToJson(JuiceDispenseData instance) =>
    <String, dynamic>{'pipe': instance.pipe, 'grams': instance.grams};

SystemCommandData _$SystemCommandDataFromJson(Map<String, dynamic> json) =>
    SystemCommandData(
      action: json['action'] as String,
      doorSelect: (json['doorSelect'] as num?)?.toInt(),
      cacheSelect: (json['cacheSelect'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SystemCommandDataToJson(SystemCommandData instance) =>
    <String, dynamic>{
      'action': instance.action,
      'doorSelect': ?instance.doorSelect,
      'cacheSelect': ?instance.cacheSelect,
    };

ReplyPayload _$ReplyPayloadFromJson(Map<String, dynamic> json) => ReplyPayload(
  cmd: json['cmd'] as String,
  status: json['status'] as String,
  reason: json['reason'] as String?,
  controller: json['controller'] as String?,
  data: json['data'] as String?,
  viewers: (json['viewers'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ReplyPayloadToJson(ReplyPayload instance) =>
    <String, dynamic>{
      'cmd': instance.cmd,
      'status': instance.status,
      'reason': instance.reason,
      'controller': instance.controller,
      'data': instance.data,
      'viewers': instance.viewers,
    };

AcquireControl _$AcquireControlFromJson(Map<String, dynamic> json) =>
    AcquireControl($type: json['cmd'] as String?);

Map<String, dynamic> _$AcquireControlToJson(AcquireControl instance) =>
    <String, dynamic>{'cmd': instance.$type};

ReleaseControl _$ReleaseControlFromJson(Map<String, dynamic> json) =>
    ReleaseControl($type: json['cmd'] as String?);

Map<String, dynamic> _$ReleaseControlToJson(ReleaseControl instance) =>
    <String, dynamic>{'cmd': instance.$type};

Heartbeat _$HeartbeatFromJson(Map<String, dynamic> json) =>
    Heartbeat($type: json['cmd'] as String?);

Map<String, dynamic> _$HeartbeatToJson(Heartbeat instance) => <String, dynamic>{
  'cmd': instance.$type,
};

StartStatusPush _$StartStatusPushFromJson(Map<String, dynamic> json) =>
    StartStatusPush($type: json['cmd'] as String?);

Map<String, dynamic> _$StartStatusPushToJson(StartStatusPush instance) =>
    <String, dynamic>{'cmd': instance.$type};

StopStatusPush _$StopStatusPushFromJson(Map<String, dynamic> json) =>
    StopStatusPush($type: json['cmd'] as String?);

Map<String, dynamic> _$StopStatusPushToJson(StopStatusPush instance) =>
    <String, dynamic>{'cmd': instance.$type};

RelayToggle _$RelayToggleFromJson(Map<String, dynamic> json) => RelayToggle(
  data: RelayToggleData.fromJson(json['data'] as Map<String, dynamic>),
  $type: json['cmd'] as String?,
);

Map<String, dynamic> _$RelayToggleToJson(RelayToggle instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

RobotAction _$RobotActionFromJson(Map<String, dynamic> json) => RobotAction(
  data: RobotActionData.fromJson(json['data'] as Map<String, dynamic>),
  $type: json['cmd'] as String?,
);

Map<String, dynamic> _$RobotActionToJson(RobotAction instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

CoffeeAction _$CoffeeActionFromJson(Map<String, dynamic> json) => CoffeeAction(
  data: CoffeeActionData.fromJson(json['data'] as Map<String, dynamic>),
  $type: json['cmd'] as String?,
);

Map<String, dynamic> _$CoffeeActionToJson(CoffeeAction instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

DoorControl _$DoorControlFromJson(Map<String, dynamic> json) => DoorControl(
  data: DoorControlData.fromJson(json['data'] as Map<String, dynamic>),
  $type: json['cmd'] as String?,
);

Map<String, dynamic> _$DoorControlToJson(DoorControl instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

CupDispense _$CupDispenseFromJson(Map<String, dynamic> json) => CupDispense(
  data: CupDispenseData.fromJson(json['data'] as Map<String, dynamic>),
  $type: json['cmd'] as String?,
);

Map<String, dynamic> _$CupDispenseToJson(CupDispense instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

LidDispense _$LidDispenseFromJson(Map<String, dynamic> json) => LidDispense(
  data: LidDispenseData.fromJson(json['data'] as Map<String, dynamic>),
  $type: json['cmd'] as String?,
);

Map<String, dynamic> _$LidDispenseToJson(LidDispense instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

IceDispense _$IceDispenseFromJson(Map<String, dynamic> json) => IceDispense(
  data: IceDispenseData.fromJson(json['data'] as Map<String, dynamic>),
  $type: json['cmd'] as String?,
);

Map<String, dynamic> _$IceDispenseToJson(IceDispense instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

JuiceDispense _$JuiceDispenseFromJson(Map<String, dynamic> json) =>
    JuiceDispense(
      data: JuiceDispenseData.fromJson(json['data'] as Map<String, dynamic>),
      $type: json['cmd'] as String?,
    );

Map<String, dynamic> _$JuiceDispenseToJson(JuiceDispense instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

VersionQuery _$VersionQueryFromJson(Map<String, dynamic> json) =>
    VersionQuery($type: json['cmd'] as String?);

Map<String, dynamic> _$VersionQueryToJson(VersionQuery instance) =>
    <String, dynamic>{'cmd': instance.$type};

SystemCommand _$SystemCommandFromJson(Map<String, dynamic> json) =>
    SystemCommand(
      data: SystemCommandData.fromJson(json['data'] as Map<String, dynamic>),
      $type: json['cmd'] as String?,
    );

Map<String, dynamic> _$SystemCommandToJson(SystemCommand instance) =>
    <String, dynamic>{'data': instance.data, 'cmd': instance.$type};

ForceRelease _$ForceReleaseFromJson(Map<String, dynamic> json) =>
    ForceRelease($type: json['cmd'] as String?);

Map<String, dynamic> _$ForceReleaseToJson(ForceRelease instance) =>
    <String, dynamic>{'cmd': instance.$type};

QueryControl _$QueryControlFromJson(Map<String, dynamic> json) =>
    QueryControl($type: json['cmd'] as String?);

Map<String, dynamic> _$QueryControlToJson(QueryControl instance) =>
    <String, dynamic>{'cmd': instance.$type};
