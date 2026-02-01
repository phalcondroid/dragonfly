import 'package:dragonfly/dragonfly.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:example/components/characters/data/models/character.dart';
import 'package:flutter/material.dart';
import 'package:example/components/characters/presentation/events/user_event.dart';
import 'package:example/components/characters/presentation/states/user_state.dart';
import 'package:example/components/characters/presentation/viewmodel/character_bloc.dart';

part 'character_view.view.dart';

/// View widget for displaying character/user information.
///
/// This view uses the generated mixin to provide state-aware widget builders.
///
/// Example usage:
/// ```dart
/// // Wrap with provider
/// DragonflyBlocProvider<CharacterBloc>(
///   create: (context) => CharacterBloc(repository),
///   child: const CharacterView(),
/// )
/// ```
@DragonflyViewAnnotation(
  bloc: CharacterBloc,
  event: UserEvent,
  state: UserState,
  generateListener: true,
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
                dispatch(context, const UserEvent.fetchUser(userId: 1)),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Using the generated buildStateWidget method
    return DragonflyBlocBuilder<CharacterBloc, UserState>(
      builder: (context, state) {
        return state.when(
          initial: () => _buildInitialState(context),
          loading: () => _buildLoadingState(),
          loaded: (user) => _buildLoadedState(context, user),
          userList: (users) => _buildUserListState(context, users),
          error: (message) => _buildErrorState(context, message),
        );
      },
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 64),
          const SizedBox(height: 16),
          const Text('Welcome! Tap to load a character.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                dispatch(context, const UserEvent.fetchUser(userId: 1)),
            child: const Text('Load Character'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
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

  Widget _buildLoadedState(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.image),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: Text(user.status),
              backgroundColor: user.status == 'Alive'
                  ? Colors.green
                  : Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard('Species', user.species),
          _buildInfoCard('Gender', user.gender),
          _buildInfoCard('Origin', user.origin.name),
          _buildInfoCard('Location', user.location.name),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    dispatch(context, UserEvent.deleteUser(user: user)),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    dispatch(context, const UserEvent.fetchUser(userId: 2)),
                icon: const Icon(Icons.navigate_next),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserListState(BuildContext context, List<dynamic> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(user.image)),
          title: Text(user.name),
          subtitle: Text('${user.species} - ${user.status}'),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                dispatch(context, const UserEvent.fetchUser(userId: 1)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      ),
    );
  }
}
