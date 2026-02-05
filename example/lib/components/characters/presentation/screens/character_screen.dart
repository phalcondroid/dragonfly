import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:example/components/characters/presentation/features/character_feature.dart';
import 'package:example/components/characters/presentation/states/character_state.dart';
import 'package:flutter/material.dart';

@DragonflyScreen(
  path: '/',
  initial: true,
  name: 'characters',
  provider: CharacterFeature,
  access: AccessLevel.guest,
)
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the state manager using the new naming convention
    final stateManager = context.stateManager<CharacterFeature>();

    return DefaultSideEffectHandler<CharacterFeature>(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Character (StateManager)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: stateManager.refresh,
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: stateManager.fetchAllCharacters,
            ),
          ],
        ),
        // Using StateManagerBuilder with the traditional .when() approach
        body: StateManagerBuilder<CharacterFeature, CharacterState>(
          builder: (context, state) {
            return state.when(
              initial: () =>
                  _InitialView(onFetch: () => stateManager.fetchCharacter(1)),
              loading: () => const _LoadingView(),
              loaded: (character) => _CharacterDetailView(
                character: character,
                onDelete: () => stateManager.deleteCharacter(character),
                onRefresh: stateManager.refresh,
              ),
              characterList: (characters) => _CharacterListView(
                characters: characters,
                onSelect: (character) =>
                    stateManager.fetchCharacter(character.id),
              ),
              error: (message) => _ErrorView(
                message: message,
                onRetry: () => stateManager.fetchCharacter(1),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Alternative screen demonstrating individual state builder widgets.
///
/// This shows how to use the generated state-specific builders like
/// [CharacterLoaded], [CharacterLoading], etc.
@DragonflyScreen(
  path: '/character-alt',
  name: 'characters-alt',
  provider: CharacterFeature,
  access: AccessLevel.guest,
)
class CharacterScreenAlternative extends StatelessWidget {
  const CharacterScreenAlternative({super.key});

  @override
  Widget build(BuildContext context) {
    final stateManager = context.stateManager<CharacterFeature>();

    return DefaultSideEffectHandler<CharacterFeature>(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Character (State Builders)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: stateManager.refresh,
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: stateManager.fetchAllCharacters,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Each state builder only renders when its state is active

            // Initial state builder - no parameters
            CharacterInitial(
              builder: () =>
                  _InitialView(onFetch: () => stateManager.fetchCharacter(1)),
            ),

            // Loading state builder - no parameters
            CharacterLoading(builder: () => const _LoadingView()),

            // Loaded state builder - has Character parameter
            CharacterLoaded(
              builder: (character) => _CharacterDetailView(
                character: character,
                onDelete: () => stateManager.deleteCharacter(character),
                onRefresh: stateManager.refresh,
              ),
              // Optional: only rebuild when character name changes
              buildWhen: (prev, curr) {
                if (prev is CharacterStateLoaded &&
                    curr is CharacterStateLoaded) {
                  return prev.character.name != curr.character.name;
                }
                return true;
              },
            ),

            // Character list state builder - has List<Character> parameter
            CharacterCharacterList(
              builder: (characters) => _CharacterListView(
                characters: characters,
                onSelect: (character) =>
                    stateManager.fetchCharacter(character.id),
              ),
            ),

            // Error state builder - has String message parameter
            CharacterError(
              builder: (message) => _ErrorView(
                message: message,
                onRetry: () => stateManager.fetchCharacter(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Private View Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _InitialView extends StatelessWidget {
  const _InitialView({required this.onFetch});

  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Rick & Morty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to fetch a character',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onFetch,
            icon: const Icon(Icons.download),
            label: const Text('Fetch Character'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Loading...', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _CharacterDetailView extends StatelessWidget {
  const _CharacterDetailView({
    required this.character,
    required this.onDelete,
    required this.onRefresh,
  });

  final Character character;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                character.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            // Character Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          character.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      _StatusBadge(status: character.status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Species and Gender
                  Text(
                    '${character.species} • ${character.gender}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Cards
                  _InfoCard(
                    icon: Icons.place,
                    title: 'Origin',
                    value: character.origin.name,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.location_on,
                    title: 'Last known location',
                    value: character.location.name,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.tv,
                    title: 'First seen in',
                    value: '${character.episode.length} episodes',
                  ),
                  const SizedBox(height: 32),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Character'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status.toLowerCase()) {
      'alive' => (Colors.green, Icons.favorite),
      'dead' => (Colors.red, Icons.heart_broken),
      _ => (Colors.grey, Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterListView extends StatelessWidget {
  const _CharacterListView({required this.characters, required this.onSelect});

  final List<Character> characters;
  final void Function(Character) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelect(character),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.network(
                    character.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${character.species} • ${character.status}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          character.location.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
