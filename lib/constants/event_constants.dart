/// 活动相关常量
class EventConstants {
  EventConstants._(); // 私有构造函数，防止实例化

  /// 活动类型列表
  static const List<String> eventTypes = [
    '观影团',
    '影评征集',
    '线上观影',
    '电影节',
    '主题展映',
    '见面会',
    '口碑场',
    '其他',
  ];

  /// 活动类型 - 观影团
  static const String typeViewingGroup = '观影团';
  
  /// 活动类型 - 影评征集
  static const String typeReviewCollection = '影评征集';
  
  /// 活动类型 - 线上观影
  static const String typeOnlineViewing = '线上观影';
  
  /// 活动类型 - 电影节
  static const String typeFilmFestival = '电影节';
  
  /// 活动类型 - 主题展映
  static const String typeThemeScreening = '主题展映';
  
  /// 活动类型 - 见面会
  static const String typeMeetAndGreet = '见面会';
  
  /// 活动类型 - 口碑场
  static const String typeWordOfMouth = '口碑场';
  
  /// 活动类型 - 其他
  static const String typeOther = '其他';
}

