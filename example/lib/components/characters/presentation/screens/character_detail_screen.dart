import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/presentation/features/character_state_manager.dart';
import 'package:example/components/characters/presentation/states/character_state.dart';
import 'package:flutter/material.dart';

part 'character_detail_screen.view.dart';

/// Detail screen bound to `/character/:id`. The `id` path parameter is
/// extracted by the generated router and passed to the constructor.
///
/// Also demonstrates the mixin on a [StatefulWidget]'s [State] class —
/// `$CharacterStateManager` is not tied to stateless widgets.
@Screen(
  path: '/character/:id',
  name: 'character-detail',
  stateManager: CharacterStateManager,
  access: AccessLevel.guest,
)
class CharacterDetailScreen extends StatefulWidget {
  const CharacterDetailScreen({super.key, @PathParam('id') required this.id});

  final int id;

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen>
    with $CharacterStateManager {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchCharacter(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Character #${widget.id}')),
      body: when(
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (character) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 64,
                backgroundImage: NetworkImage(character.image),
              ),
              const SizedBox(height: 16),
              Text(
                character.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${character.species} • ${character.status}'),
            ],
          ),
        ),
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => fetchCharacter(widget.id),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
