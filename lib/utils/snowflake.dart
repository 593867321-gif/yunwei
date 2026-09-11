/// 53 位雪花 ID 生成器
///
/// 与后端 `Snowflake53` / 设备端 `Snowflake.nextId()` 一致：
/// - 时间戳差 40 位 + workerId 5 位 + 序列 8 位 = 53 位（JS Safe Integer）
/// - 起始 epoch：2024-01-01 00:00:00 UTC
/// - 输出为十进制字符串，用作 MQTT User Property `msgId`
class Snowflake {
  Snowflake._();

  /// 起始时间戳：2024-01-01 00:00:00 UTC
  static const int _startTimestamp = 1704067200000;

  /// 序列号位数
  static const int _sequenceBits = 8;

  /// 工作节点位数
  static const int _workerIdBits = 5;

  /// 时间戳差位数
  static const int _timeDiffBits = 40;

  /// 序列最大值 255
  static const int _maxSequence = (1 << _sequenceBits) - 1;

  /// 工作节点最大值 31
  static const int _maxWorkerId = (1 << _workerIdBits) - 1;

  /// worker 左移量
  static const int _workerIdShift = _sequenceBits;

  /// 时间戳左移量
  static const int _timestampShift = _workerIdBits + _sequenceBits;

  static int _sequence = 0;
  static int _lastTimestamp = -1;

  /// 生成下一个 53 位雪花 ID（十进制字符串）
  ///
  /// [workerId] 工作节点，0–31，运维端默认 1。
  static String nextId({int workerId = 1}) {
    if (workerId < 0 || workerId > _maxWorkerId) {
      throw ArgumentError('Worker ID 必须在 0 到 $_maxWorkerId 之间');
    }

    var timestamp = DateTime.now().millisecondsSinceEpoch;

    if (timestamp < _lastTimestamp) {
      // 轻微回拨时等待追上；较大回拨直接抛错
      final back = _lastTimestamp - timestamp;
      if (back > 5) {
        throw StateError('时钟回拨 ${back}ms，拒绝生成 msgId');
      }
      while (timestamp < _lastTimestamp) {
        timestamp = DateTime.now().millisecondsSinceEpoch;
      }
    }

    if (timestamp == _lastTimestamp) {
      _sequence = (_sequence + 1) & _maxSequence;
      if (_sequence == 0) {
        while (timestamp <= _lastTimestamp) {
          timestamp = DateTime.now().millisecondsSinceEpoch;
        }
      }
    } else {
      _sequence = 0;
    }

    _lastTimestamp = timestamp;
    final timeDiff = timestamp - _startTimestamp;
    final maxTimeDiff = 1 << _timeDiffBits;
    if (timeDiff < 0 || timeDiff >= maxTimeDiff) {
      throw StateError('时间戳溢出 $_timeDiffBits 位');
    }

    final id =
        (timeDiff << _timestampShift) | (workerId << _workerIdShift) | _sequence;
    return id.toString();
  }
}
