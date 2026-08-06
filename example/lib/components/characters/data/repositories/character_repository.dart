import 'package:dragonfly/framework/types/enums/http_methods.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:dragonfly/dragonfly.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/data/models/info.dart';
import 'package:example/components/characters/data/models/service_response.dart';
import 'package:example/components/characters/data/models/service_response_double.dart';

part "character_repository.repository.dart";

@Repository(url: "character", realtimeConnection: "events")
abstract class CharacterRepository {
  factory CharacterRepository() = _CharacterRepository;

  /// `GET character?name=...` — @Query binds the parameter to the query string.
  @Get()
  Future<ServiceResponse<Character>> getAll(@Query('name') String name);

  /// `GET character/{id}` — @Path substitutes the `{id}` placeholder.
  @Get(path: '/{id}')
  Future<Character> getById(@Path('id') int id);

  @Get()
  Future<ServiceResponseDouble<Character, Info>> getAllDouble(
    @Query('name') String name,
    @Query('ids') List<String> params,
  );

  /// @Body serializes a @FactoryModel through its generated `toJson`, and
  /// @Authenticated routes the call through the session-aware adapter.
  /// (The demo API is read-only; this exists to exercise the generator.)
  @Post()
  @Authenticated()
  Future<Character> createCharacter(@Body() Character character);

  /// Realtime: one character per frame on the `character.created` channel.
  @Subscribe(channel: "character.created")
  Stream<Character> onCharacterCreated();

  /// Realtime: a batch of characters per frame. Channel defaults to the
  /// method name, so this subscribes to `onCharacterBatch`.
  @Subscribe()
  Stream<List<Character>> onCharacterBatch();
}
