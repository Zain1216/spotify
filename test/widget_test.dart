import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spotify_clone/main.dart';
import 'package:spotify_clone/providers/audio_player_provider.dart';

void main() {
  testWidgets('Spotify Clone smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AudioPlayerProvider(),
        child: const SpotifyCloneApp(),
      ),
    );

    // Verify that the SpotifyCloneApp widget is rendered.
    expect(find.byType(SpotifyCloneApp), findsOneWidget);
  });
}
