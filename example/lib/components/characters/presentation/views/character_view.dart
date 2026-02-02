import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:flutter/material.dart';
import 'package:example/components/characters/presentation/events/character_event.dart';
import 'package:example/components/characters/presentation/states/character_state.dart';
import 'package:example/components/characters/presentation/viewmodel/character_bloc.dart';

part 'character_view.view.dart';

@DragonflyView(
  bloc: CharacterBloc,
  event: CharacterEvent,
  state: CharacterState,
)
class CharacterView extends StatelessWidget with _$CharacterViewMixin {
  const CharacterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Character'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                dispatch(context, const CharacterEvent.fetch(characterId: 1)),
          ),
        ],
      ),
      body: buildStateWidget(
        context,
        onInitial: () => _InitialView(
          onFetch: () =>
              dispatch(context, const CharacterEvent.fetch(characterId: 1)),
        ),
        onLoading: () => const _LoadingView(),
        onLoaded: (character) => _CharacterDetailView(
          character: character,
          onDelete: () =>
              dispatch(context, CharacterEvent.delete(character: character)),
          onRefresh: () =>
              dispatch(context, const CharacterEvent.fetch(characterId: 1)),
        ),
        onCharacterList: (characters) =>
            _CharacterListView(characters: characters),
        onError: (message) => _ErrorView(
          message: message,
          onRetry: () =>
              dispatch(context, const CharacterEvent.fetch(characterId: 1)),
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
          const Icon(Icons.person_outline, size: 64),
          const SizedBox(height: 16),
          const Text('Tap to load a character'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onFetch,
            child: const Text('Load Character'),
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
    return const Center(child: CircularProgressIndicator());
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
            child: CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(character.image),
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
            ),
          ),
          const SizedBox(height: 24),
          _FieldRow(label: 'ID', value: character.id.toString()),
          _FieldRow(label: 'Name', value: character.name),
          _FieldRow(label: 'Status', value: character.status),
          _FieldRow(label: 'Species', value: character.species),
          _FieldRow(
            label: 'Type',
            value: character.type.isEmpty ? '-' : character.type,
          ),
          _FieldRow(label: 'Gender', value: character.gender),
          _FieldRow(label: 'Origin', value: character.origin.name),
          _FieldRow(label: 'Location', value: character.location.name),
          _FieldRow(
            label: 'Episodes',
            value: '${character.episode.length} episodes',
          ),
          _FieldRow(label: 'URL', value: character.url),
          _FieldRow(label: 'Created', value: character.created),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              ElevatedButton.icon(
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

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
        ],
      ),
    );
  }
}

class _CharacterListView extends StatelessWidget {
  final List<Character> characters;

  const _CharacterListView({required this.characters});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(character.image)),
          title: Text(character.name),
          subtitle: Text('${character.species} - ${character.status}'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
