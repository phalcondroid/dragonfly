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

  @Get()
  Future<ServiceResponse<Character>> getAll(
    @Path() String name,
    @Query() List<String> julian,
  );

  @Get()
  Future<ServiceResponseDouble<Character, Info>> getAllDouble(
    @Path() String name,
    @Query() List<String> julian,
  );

  /// Realtime: one character per frame on the `character.created` channel.
  @Subscribe(channel: "character.created")
  Stream<Character> onCharacterCreated();

  /// Realtime: a batch of characters per frame. Channel defaults to the
  /// method name, so this subscribes to `onCharacterBatch`.
  @Subscribe()
  Stream<List<Character>> onCharacterBatch();
}
