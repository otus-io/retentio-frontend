part of 'index.dart';

class Api {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  static const String decks = '/api/decks';
  static const String deck = '/api/decks/{id}';
  static const String profile = '/api/profile';

  static const String card = '/api/decks/{id}/card';
  static const String cards = '/api/decks/{id}/cards';
  static const String cardById = '/api/decks/{id}/cards/{cardId}';
  static const String reschedule = '/api/decks/{id}/reschedule';

  static const String facts = '/api/decks/{id}/facts';
  static const String factsWithOperation = '/api/decks/{id}/facts/{operation}';
  static const String fact = '/api/decks/{id}/facts/{factId}';
  static const String factCards = '/api/decks/{id}/facts/{factId}/cards';

  static const String media = '/api/media';
  static const String mediaById = '/api/media/{id}';
}
