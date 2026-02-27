part of 'index.dart';

class Api {
  /// 登录页面的路由路径。
  static const String login = '/auth/login';

  /// 注册页面的路由路径。
  static const String register = '/auth/register';

  /// 获取卡牌组列表的API端点路径。
  static const String decks = '/api/decks';

  /// 获取卡牌组列表的API端点路径。
  static const String deck = '/api/decks/{id}';

  static const String profile = '/api/profile';

  /// Returns the most urgent card for a deck
  static const String card = '/api/decks/{id}/card';

  ///Returns card statistics including total count, hidden count, and hidden facts
  static const String cards = '/api/decks/{id}/cards';

  /// Returns a fact for the specified deck
  static const String fact = '/api/decks/{id}/facts/{factId}';

  ///Returns all facts for the specified deck
  static const String facts = '/api/decks/{id}/facts';
}
