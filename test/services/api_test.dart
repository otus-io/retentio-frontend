import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/services/index.dart';

void main() {
  group('Api route constants', () {
    test('auth paths', () {
      expect(Api.login, '/auth/login');
      expect(Api.register, '/auth/register');
      expect(Api.logout, '/auth/logout');
      expect(Api.forgotPassword, '/auth/forgot-password');
      expect(Api.resetPassword, '/auth/reset-password');
    });

    test('deck and profile paths', () {
      expect(Api.decks, '/api/decks');
      expect(Api.deck, '/api/decks/{id}');
      expect(Api.profile, '/api/profile');
    });

    test('card paths', () {
      expect(Api.card, '/api/decks/{id}/card');
      expect(Api.cards, '/api/decks/{id}/cards');
      expect(Api.cardById, '/api/decks/{id}/cards/{cardId}');
      expect(Api.reschedule, '/api/decks/{id}/reschedule');
    });

    test('facts paths', () {
      expect(Api.facts, '/api/decks/{id}/facts');
      expect(Api.factsWithOperation, '/api/decks/{id}/facts/{operation}');
      expect(Api.fact, '/api/decks/{id}/facts/{factId}');
    });

    test('media paths', () {
      expect(Api.media, '/api/media');
      expect(Api.mediaById, '/api/media/{id}');
    });
  });
}
