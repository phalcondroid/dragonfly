/// Annotation for creating a BLoC (Business Logic Component) class.
///
/// This annotation generates event handlers and connects the BLoC
/// to its event and state models.
///
/// Example usage:
/// ```dart
/// @DragonflyBloc(
///   event: UserEvent,
///   state: UserState,
/// )
/// class UserBloc extends DragonflyBloc<UserEvent, UserState>
///     with _$UserBlocMixin {
///   UserBloc(this._userRepository) : super(const UserState.initial());
///
///   final UserRepository _userRepository;
///
///   @override
///   Future<void> onFetchUser(UserEventFetchUser event, Emitter<UserState> emit) async {
///     emit(const UserState.loading());
///     try {
///       final user = await _userRepository.getUser(event.userId);
///       emit(UserState.loaded(user: user));
///     } catch (e) {
///       emit(UserState.error(message: e.toString()));
///     }
///   }
/// }
/// ```
///
/// The generator creates a mixin with:
/// - Abstract handler methods for each event variant
/// - Automatic registration of handlers in constructor
class DragonflyBloc {
  /// The event type for this BLoC.
  final Type event;

  /// The state type for this BLoC.
  final Type state;

  /// Whether to generate logging for events and state changes.
  final bool enableLogging;

  /// Creates a DragonflyBloc.
  const DragonflyBloc({
    required this.event,
    required this.state,
    this.enableLogging = false,
  });
}
