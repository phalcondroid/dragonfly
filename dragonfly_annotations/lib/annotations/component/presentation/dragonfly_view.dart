/// Annotation for creating a view widget with state-aware builders.
///
/// This annotation generates widget builders that correspond to each
/// state variant, making it easy to build reactive UIs.
///
/// Example usage:
/// ```dart
/// @DragonflyView(
///   bloc: UserBloc,
///   event: UserEvent,
///   state: UserState,
/// )
/// class UserView extends StatelessWidget with _$UserViewMixin {
///   const UserView({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: buildStateWidget(
///         context,
///         onInitial: () => const WelcomeWidget(),
///         onLoading: () => const CircularProgressIndicator(),
///         onLoaded: (user) => UserDetailsWidget(user: user),
///         onError: (message) => ErrorWidget(message: message),
///       ),
///     );
///   }
/// }
/// ```
///
/// The generator creates a mixin with:
/// - `buildStateWidget` method with callbacks for each state variant
/// - `dispatchEvent` method to easily dispatch events
/// - Helper getters to access the bloc and current state
class DragonflyView {
  /// The BLoC type for this view.
  final Type bloc;

  /// The event type for this view.
  final Type event;

  /// The state type for this view.
  final Type state;

  /// Whether to automatically provide the BLoC.
  ///
  /// If true, the generated code will wrap the widget with a BlocProvider.
  final bool autoProvide;

  /// Whether to generate listener callbacks.
  final bool generateListener;

  /// Creates a DragonflyView annotation.
  const DragonflyView({
    required this.bloc,
    required this.event,
    required this.state,
    this.autoProvide = false,
    this.generateListener = true,
  });
}

/// Annotation for generating a standalone state builder widget.
///
/// This creates a widget that can be used independently of the view.
///
/// Example:
/// ```dart
/// @DragonflyStateBuilder(state: UserState)
/// class UserStateBuilder {}
/// ```
///
/// Generates:
/// ```dart
/// class UserStateBuilderWidget extends StatelessWidget {
///   const UserStateBuilderWidget({
///     super.key,
///     required this.state,
///     required this.onInitial,
///     required this.onLoading,
///     required this.onLoaded,
///     required this.onError,
///   });
///
///   final UserState state;
///   final Widget Function() onInitial;
///   final Widget Function() onLoading;
///   final Widget Function(User user) onLoaded;
///   final Widget Function(String message) onError;
///
///   @override
///   Widget build(BuildContext context) {
///     return state.when(
///       initial: onInitial,
///       loading: onLoading,
///       loaded: onLoaded,
///       error: onError,
///     );
///   }
/// }
/// ```
class DragonflyStateBuilder {
  /// The state type to build widgets for.
  final Type state;

  /// Creates a DragonflyStateBuilder.
  const DragonflyStateBuilder({required this.state});
}
