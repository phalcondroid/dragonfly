/// Marks a repository method as a realtime subscription.
///
/// The method must return a `Stream<T>` (or `Stream<List<T>>`). The generated
/// implementation resolves a `DragonflyRealtimeAdapter` by connection name and
/// maps each incoming JSON payload through `T.fromJson`.
///
/// ```dart
/// @Repository(url: 'character', realtimeConnection: 'events')
/// abstract class CharacterRepository {
///   factory CharacterRepository() = _CharacterRepository;
///
///   @Get()
///   Future<ServiceResponse<Character>> getAll();
///
///   @Subscribe(channel: 'character.created')
///   Stream<Character> onCharacterCreated();
///
///   @Subscribe(channel: 'character.batch')
///   Stream<List<Character>> onCharacterBatch();
/// }
/// ```
///
/// [channel] defaults to the method name when omitted, which keeps the common
/// case free of configuration.
class Subscribe {
  const Subscribe({
    this.channel = '',
    this.connection = '',
  });

  /// Channel or event name to subscribe to. Defaults to the method name.
  final String channel;

  /// Realtime connection name. Defaults to the enclosing `@Repository`'s
  /// `realtimeConnection`.
  final String connection;
}
