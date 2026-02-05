library;

export 'package:dragonfly/framework/config/dragonfly_app.dart'
    show DragonflyApp;
export 'package:dragonfly/framework/config/dragonfly_local_storage_config.dart'
    show DragonflyLocalStorageConfig;
export 'package:dragonfly/framework/config/dragonfly_network_config.dart'
    show DragonflyNetworkConfig;
export 'package:dragonfly/framework/functional/either.dart' show Either;
export 'package:dragonfly/framework/contracts/domain/use_case.dart'
    show UseCase;
export 'package:dragonfly/framework/exceptions/dragonfly_exception.dart'
    show DragonflyException;

// Navigation
export 'framework/navigation/router.dart';
export 'framework/navigation/navigation_extensions.dart';

// Exports all the main components of the framework
export 'framework/di/dragonfly_container.dart'
    show
        DragonflyContainer,
        FactoryFunc,
        FactoryFuncParam,
        FactoryFuncAsync,
        FactoryFuncParamAsync,
        DisposingFunc,
        ScopeDisposeFunc;
export 'package:dragonfly/framework/di/dragonfly_container_helper.dart'
    show DragonflyContainerHelper;
export 'package:dragonfly/framework/di/environment_filter.dart'
    show EnvironmentFilter;
export 'package:dragonfly/framework/network/adapter/dragonfly_network_http_adapter.dart'
    show DragonflyNetworkHttpAdapter;
export 'package:dragonfly/framework/types/enums/http_methods.dart'
    show HttpMethods;
export 'package:dragonfly/framework/mapper/json_datatype_mapper.dart'
    show JsonDatatypeMapper, JsonMappingException, DataTypeEnum;
export 'package:dragonfly/framework/contracts/models/factory_model_watcher.dart'
    show FactoryModelWatcher;
export 'package:dragonfly/framework/constructors/generic_builder_class.dart'
    show GenericBuilderClass;

// BLoC framework (legacy - consider using StateManager instead)
export 'package:dragonfly/framework/bloc/dragonfly_bloc.dart'
    show DragonflyBlocBase, EventHandler, Emitter, DragonflyBlocExtension;
export 'package:dragonfly/framework/bloc/dragonfly_bloc_provider.dart'
    show DragonflyBlocProvider, DragonflyBlocContextExtension;
export 'package:dragonfly/framework/bloc/dragonfly_bloc_builder.dart'
    show
        DragonflyBlocBuilder,
        DragonflyBlocListener,
        DragonflyBlocConsumer,
        DragonflyBlocWidgetBuilder,
        DragonflyBlocBuilderCondition;
export 'package:dragonfly/framework/bloc/dragonfly_bloc_selector.dart'
    show DragonflyBlocSelectorWidget, DragonflyBlocSelector;
export 'package:dragonfly/framework/bloc/dragonfly_multi_bloc_provider.dart'
    show DragonflyMultiBlocProvider, DragonflyMultiBlocListener, blocListener;

// StateManager framework (recommended)
export 'package:dragonfly/framework/feature/state_manager.dart'
    show
        StateManager,
        StateManagerSideEffect,
        NavigateTo,
        ShowSnackbar,
        ShowDialog,
        Pop,
        StateManagerStateListener,
        SideEffectCallback,
        StateManagerWidgetBuilder,
        StateManagerStateComparator,
        // Backwards compatibility
        Feature,
        FeatureSideEffect,
        FeatureStateListener,
        FeatureWidgetBuilder,
        FeatureStateComparator;
export 'package:dragonfly/framework/feature/state_manager_provider.dart'
    show
        StateManagerProvider,
        StateManagerContextExtension,
        // Backwards compatibility
        FeatureProvider,
        FeatureContextExtension;
export 'package:dragonfly/framework/feature/state_manager_builder.dart'
    show
        StateManagerBuilder,
        StateManagerListener,
        StateManagerSideEffectListener,
        StateManagerConsumer,
        StateManagerSelector,
        // Backwards compatibility
        FeatureBuilder,
        FeatureListener,
        FeatureSideEffectListener,
        FeatureConsumer,
        FeatureSelector;
export 'package:dragonfly/framework/feature/dragonfly_screen.dart'
    show
        DragonflyScreenBase,
        ScreenProvider,
        StateManagerNavigationExtension,
        DefaultSideEffectHandler,
        // Backwards compatibility
        FeatureNavigationExtension;

// Session management
// Note: AccessLevel is exported from dragonfly_annotations, not here to avoid ambiguity
export 'package:dragonfly/framework/session/session_storage.dart'
    show SessionStorage, InMemorySessionStorage, HiveSessionStorage;
export 'package:dragonfly/framework/session/dragonfly_session_manager.dart'
    show
        DragonflySessionManager,
        DragonflySessionConfiguration,
        SessionState,
        SessionStateCallback,
        AccessDeniedCallback,
        dragonflySession;
export 'package:dragonfly/framework/session/authenticated_network_adapter.dart'
    show AuthenticatedNetworkAdapter, AuthenticatedHttpException;

// Form validation framework
export 'package:dragonfly/framework/form/form_field_state.dart'
    show FormFieldState;
export 'package:dragonfly/framework/form/validators.dart'
    show Validators, Validator, CrossFieldValidator;
export 'package:dragonfly/framework/form/form_controller.dart'
    show FormController, FormControllerMixin;
export 'package:dragonfly/framework/form/validated_widgets.dart'
    show
        ValidatedTextField,
        ValidatedDropdown,
        ValidatedCheckbox,
        ValidatedSwitch,
        ValidatedDatePicker,
        ValidatedForm,
        ValidatedSubmitButton,
        FormStateAccessor;

// Logging framework
export 'package:dragonfly/framework/logging/dragonfly_log_level.dart'
    show DragonflyLogLevel;
export 'package:dragonfly/framework/logging/dragonfly_log_colors.dart'
    show DragonflyLogColors;
export 'package:dragonfly/framework/logging/dragonfly_log_entry.dart'
    show
        DragonflyLogEntry,
        DragonflyNetworkRequestLog,
        DragonflyNetworkResponseLog,
        DragonflyRepositoryLog;
export 'package:dragonfly/framework/logging/dragonfly_log_formatter.dart'
    show DragonflyLogFormatter;
export 'package:dragonfly/framework/logging/dragonfly_log_manager.dart'
    show DragonflyLogManager, DragonflyLogListener, dragonflyLog;
