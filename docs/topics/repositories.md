# Repositories

`@Repository` generates the HTTP (and realtime) client. Binding annotations wire
method parameters into the network call:

```dart
part 'character_repository.repository.dart';

@Repository(url: "character", realtimeConnection: "events")
abstract class CharacterRepository {
  factory CharacterRepository() = _CharacterRepository;

  /// GET character?name=...         — @Query → query string
  @Get()
  Future<ServiceResponse<Character>> getAll(@Query('name') String name);

  /// GET character/{id}             — @Path → URL placeholder substitution
  @Get(path: '/{id}')
  Future<Character> getById(@Path('id') int id);

  /// POST character + auth header   — @Body → toJson, @Authenticated → session token
  @Post()
  @Authenticated()
  Future<Character> createCharacter(@Body() Character character);

  /// WebSocket subscription        — one Character per frame
  @Subscribe(channel: "character.created")
  Stream<Character> onCharacterCreated();

  /// Batch subscription            — channel defaults to the method name
  @Subscribe()
  Stream<List<Character>> onCharacterBatch();
}
```

| Annotation | Binds to | Runtime behaviour |
|-----------|----------|-------------------|
| `@Path('name')` | URL placeholder `{name}` | `${name}` substitution in the path |
| `@Query('name')` | Query parameter `?name=` | `name` appears in the query string |
| `@Body()` | Request body | Calls `toJson()` on the parameter |
| `@Header(item:)` | Request header | Static `{key: value}` merged into headers |
| `@Authenticated()` | Session token | Resolves `'<conn>:authenticated'` adapter |

Network adapters (`DragonflyBaseNetworkAdapter`) are registered per connection name
through `DragonflyHttpAdapterConfig` (HTTP) and `DragonflyWebSocketAdapterConfig`
(WebSocket), or custom `DragonflyAdapterConfig` subclasses.

> **Note:** For custom adapters (WebRTC, gRPC, GraphQL, MQTT, etc.), see
> [docs/topics/adapters.md](adapters.md).

---

[Back to README.md](../../README.md)
