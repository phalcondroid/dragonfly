import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/presentation/features/character_feature.dart';
import 'package:example/components/characters/presentation/states/character_state.dart';
import 'package:flutter/material.dart';

@DragonflyRoute(
  path: '/',
  initial: true,
  name: 'characters',
  provider: CharacterFeature,
)
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feature = context.feature<CharacterFeature>();

    return DefaultSideEffectHandler<CharacterFeature>(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Character (Feature)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: feature.refresh,
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: feature.fetchAllCharacters,
            ),
          ],
        ),
        body: FeatureBuilder<CharacterFeature, CharacterState>(
          builder: (context, state) {
            return state.when(
              initial: () =>
                  _InitialView(onFetch: () => feature.fetchCharacter(1)),
              loading: () => const _LoadingView(),
              loaded: (character) => _CharacterDetailView(
                character: character,
                onDelete: () => feature.deleteCharacter(character),
                onRefresh: feature.refresh,
              ),
              characterList: (characters) => _CharacterListView(
                characters: characters,
                onSelect: (character) => feature.fetchCharacter(character.id),
              ),
              error: (message) => _ErrorView(
                message: message,
                onRetry: () => feature.fetchCharacter(1),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  final VoidCallback onFetch;

  const _InitialView({required this.onFetch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Tap to load a character',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onFetch,
            icon: const Icon(Icons.download),
            label: const Text('Load Character'),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }
}

class _CharacterDetailView extends StatelessWidget {
  final Character character;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const _CharacterDetailView({
    required this.character,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Hero(
              tag: 'avatar-${character.id}',
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(character.image),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              character.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: Text(character.status),
              backgroundColor: character.status == 'Alive'
                  ? Colors.green
                  : Colors.red,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.tag,
                    label: 'ID',
                    value: '${character.id}',
                  ),
                  _InfoRow(
                    icon: Icons.category,
                    label: 'Species',
                    value: character.species,
                  ),
                  _InfoRow(
                    icon: Icons.type_specimen,
                    label: 'Type',
                    value: character.type.isEmpty ? 'N/A' : character.type,
                  ),
                  _InfoRow(
                    icon: Icons.person,
                    label: 'Gender',
                    value: character.gender,
                  ),
                  _InfoRow(
                    icon: Icons.home,
                    label: 'Origin',
                    value: character.origin.name,
                  ),
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: character.location.name,
                  ),
                  _InfoRow(
                    icon: Icons.movie,
                    label: 'Episodes',
                    value: '${character.episode.length} episodes',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonalIcon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(foregroundColor: Colors.red),
              ),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _CharacterListView extends StatelessWidget {
  final List<Character> characters;
  final void Function(Character) onSelect;

  const _CharacterListView({required this.characters, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        return ListTile(
          leading: Hero(
            tag: 'avatar-${character.id}',
            child: CircleAvatar(backgroundImage: NetworkImage(character.image)),
          ),
          title: Text(character.name),
          subtitle: Text('${character.species} - ${character.status}'),
          trailing: Icon(
            character.status == 'Alive'
                ? Icons.favorite
                : Icons.favorite_border,
            color: character.status == 'Alive' ? Colors.red : Colors.grey,
          ),
          onTap: () => onSelect(character),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
