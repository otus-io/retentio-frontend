import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/services/index.dart';

void main() {
  group('Api', () {
    test('auth paths', () {
      expect(Api.login, '/auth/login');
      expect(Api.register, '/auth/register');
      expect(Api.logout, '/auth/logout');
      expect(Api.forgotPassword, '/auth/forgot-password');
      expect(Api.resetPassword, '/auth/reset-password');
    });

    test('decks path is correct', () {
      expect(Api.decks, '/api/decks');
    });

    test('deck and card paths', () {
      expect(Api.deck, '/api/decks/{id}');
      expect(Api.card, '/api/decks/{id}/card');
      expect(Api.cards, '/api/decks/{id}/cards');
      expect(Api.cardById, '/api/decks/{id}/cards/{cardId}');
      expect(Api.reschedule, '/api/decks/{id}/reschedule');
    });

    test('fact paths', () {
      expect(Api.facts, '/api/decks/{id}/facts');
      expect(Api.factsWithOperation, '/api/decks/{id}/facts/{operation}');
      expect(Api.fact, '/api/decks/{id}/facts/{factId}');
      expect(Api.factCards, '/api/decks/{id}/facts/{factId}/cards');
    });

    test('media paths', () {
      expect(Api.media, '/api/media');
      expect(Api.mediaById, '/api/media/{id}');
    });
  });
}
