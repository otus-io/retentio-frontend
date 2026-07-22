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

  static const String media = '/api/media';
  static const String mediaById = '/api/media/{id}';

  // Tags
  static const String tags = '/api/tags';
  static const String tag = '/api/tags/{tagId}';
  static const String tagFacts = '/api/tags/{tagId}/facts';

  // Deck <-> Tag
  static const String deckTags = '/api/decks/{id}/tags';
  static const String deckTag = '/api/decks/{id}/tags/{tagId}';

  // Fact <-> Tag
  static const String factTags = '/api/decks/{id}/facts/{factId}/tags';
  static const String factTag = '/api/decks/{id}/facts/{factId}/tags/{tagId}';

  // Deck sharing / catalog
  static const String deckCatalog = '/api/decks/catalog';
  static const String deckCatalogById = '/api/decks/catalog/{id}';
  static const String deckPublish = '/api/decks/{id}/publish';
  static const String deckImport = '/api/decks/import';
  static const String deckUpdates = '/api/decks/{id}/updates';
  static const String deckSync = '/api/decks/{id}/sync';

  // Import contributions (submit on import deck id)
  static const String deckFactReport =
      '/api/decks/{id}/contributions/facts/{factId}/report';
  static const String deckFactEditContribution =
      '/api/decks/{id}/contributions/facts/{factId}/edit';
  static const String deckFactAddContribution =
      '/api/decks/{id}/contributions/facts/{factId}/add';
  static const String deckFactTagsContribution =
      '/api/decks/{id}/contributions/facts/{factId}/tags';
  static const String deckTagsContribution =
      '/api/decks/{id}/contributions/deck-tags';
  static const String deckFieldRenameContribution =
      '/api/decks/{id}/contributions/fields/rename';
  static const String deckFactTemplateContribution =
      '/api/decks/{id}/contributions/facts/{factId}/templates';

  // Author contribution inbox (source deck id)
  static const String deckContributions = '/api/decks/{id}/contributions';
  static const String deckContribution =
      '/api/decks/{id}/contributions/{contributionId}';
  static const String deckContributionAccept =
      '/api/decks/{id}/contributions/{contributionId}/accept';
  static const String deckContributionMedia =
      '/api/decks/{id}/contributions/{contributionId}/media/{attachmentId}';
}
