import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/presentation/features/character_search_state_manager.dart';
import 'package:dragonfly/dragonfly.dart';
import 'package:flutter/material.dart';

part 'character_search_screen.view.dart';

/// Easy-mode demo: the state class (`CharacterSearchStateManagerState`) is
/// generated entirely from the `@Event` methods — no `@StateModel` involved.
@Screen(path: '/search', name: 'search', stateManager: CharacterSearchStateManager, access: AccessLevel.guest)
class CharacterSearchScreen extends StatelessWidget
    with $CharacterSearchStateManager {
  const CharacterSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search (easy mode)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Character name',
                hintText: 'rick, morty, ...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              // Debounced by the generated controller (300ms).
              onChanged: search,
            ),
          ),
          Expanded(
            child: when(
              initial: () => const _HintView(),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              search: (characters) => _ResultsView(characters: characters),
              clear: () => const _HintView(),
              error: (message) => Center(child: Text(message)),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintView extends StatelessWidget {
  const _HintView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Type a name to search',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.characters});

  final List<Character> characters;

  @override
  Widget build(BuildContext context) {
    if (characters.isEmpty) {
      return const Center(child: Text('No results'));
    }
    return ListView.builder(
      itemCount: characters.length,
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(characters[index].image),
        ),
        title: Text(characters[index].name),
        subtitle: Text(characters[index].species),
      ),
    );
  }
}
