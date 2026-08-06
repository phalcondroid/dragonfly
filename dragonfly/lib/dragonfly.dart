library;

export 'package:dragonfly/framework/config/dragonfly_app.dart'
    show DragonflyApp;
// App configuration. These were previously reachable only by importing
// framework/config/dragonfly_config.dart directly.
export 'package:dragonfly/framework/config/dragonfly_config.dart'
    show
        DragonflyConfig,
        DragonflyInjector,
        DragonflyHttpBaseOptions,
        DragonflyAdapterConfig,
        DragonflyHttpAdapterConfig,
        DragonflyWebSocketAdapterConfig,
        DragonflyInstanceConfig,
        DragonflyRealtimeInstanceConfig;
export 'package:dragonfly/framework/config/dragonfly_local_storage_config.dart'
    show DragonflyLocalStorageConfig;
export 'package:dragonfly/framework/config/dragonfly_network_config.dart'
    show DragonflyNetworkConfig;
export 'package:dragonfly/framework/functional/either.dart' show Either;
export 'package:dragonfly/framework/exceptions/dragonfly_exception.dart'
    show DragonflyException;

// Navigation
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
export 'package:dragonfly/framework/network/adapter/dragonfly_base_network_adapter.dart'
    show DragonflyBaseNetworkAdapter;
export 'package:dragonfly/framework/network/adapter/dragonfly_network_http_adapter.dart'
    show DragonflyNetworkHttpAdapter;
export 'package:dragonfly/framework/network/adapter/dragonfly_network_options.dart'
    show DragonflyNetworkOptions;

// Realtime / sockets. Generated Stream-returning repository methods resolve a
// DragonflyRealtimeAdapter from the container by connection name.
export 'package:dragonfly/framework/network/adapter/dragonfly_realtime_adapter.dart'
    show
        DragonflyRealtimeAdapter,
        DragonflyRealtimeState,
        DragonflyRealtimeException;
export 'package:dragonfly/framework/network/adapter/dragonfly_web_socket_adapter.dart'
    show DragonflyWebSocketAdapter, DragonflySocketConnection, WebSocketConnection;
export 'package:dragonfly/framework/network/config/dragonfly_realtime_config.dart'
    show DragonflyRealtimeConfig;
export 'package:dragonfly/framework/network/enums/dragonfly_network_names_constants.dart'
    show defaultHttpNetwork, defaultRealtimeNetwork;
export 'package:dragonfly/framework/types/enums/http_methods.dart'
    show HttpMethods;
export 'package:dragonfly/framework/mapper/json_datatype_mapper.dart'
    show JsonDatatypeMapper, JsonMappingException, DataTypeEnum;
export 'package:dragonfly/framework/contracts/models/factory_model_watcher.dart'
    show FactoryModelWatcher;
export 'package:dragonfly/framework/constructors/generic_builder_class.dart'
    show GenericBuilderClass;

// State management (v2).
// DragonflyController is the base for the generated `$XController` classes;
// DragonflyStateBuilder is the widget every generated view-mixin builder
// returns. ActionScheduler backs `@Event(debounce:/throttle:)`.
export 'package:dragonfly/framework/state/state_controller.dart'
    show DragonflyController;
export 'package:dragonfly/framework/state/state_builder.dart'
    show DragonflyStateBuilder;
// DDD
export 'package:dragonfly/framework/ddd/aggregate_root.dart'
    show AggregateRoot;
export 'package:dragonfly/framework/ddd/aggregate_repository.dart'
    show AggregateRepository;
export 'package:dragonfly/framework/ddd/domain_event.dart'
    show DomainEvent;
export 'package:dragonfly/framework/ddd/aggregate_exception.dart'
    show AggregateException;
export 'package:dragonfly/framework/state/action_scheduler.dart'
    show ActionScheduler;

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
    show
        DragonflyAuthenticatedAdapter,
        AuthenticatedNetworkAdapter;

// Form validation framework
export 'package:dragonfly/framework/form/form_field_state.dart'
    show DragonflyFormFieldState;
export 'package:dragonfly/framework/form/validators.dart'
    show Validators, Validator, CrossFieldValidator;
export 'package:dragonfly/framework/form/form_controller.dart'
    show FormController;
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

// Test helpers
export 'package:dragonfly/framework/testing/controller_test.dart'
    show controllerTest, ControllerResult, ControllerStates, pump;
