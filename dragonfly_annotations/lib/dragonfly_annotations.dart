library;

// Injectable annotations
export 'annotations/injectable/injectable_annotations.dart'
    show
        Injectable,
        UseCase,
        InjectableUseCase, // Deprecated alias
        Singleton,
        LazySingleton,
        Named,
        Inject,
        InjectableInit,
        DragonflyInjectableInit, // Deprecated alias
        useCaseComponent,
        injectable,
        singleton,
        lazySingleton;
export 'annotations/injectable/inject.dart';

// Component annotations
export 'annotations/component/injector/injector_config.dart';

// Model annotations
export 'annotations/component/models/factory_model.dart' show FactoryModel;
export 'annotations/component/models/aggregate.dart'
    show Aggregate, ValueObject, DomainEvent;
export 'annotations/component/models/state_model.dart' show StateModel;
export 'annotations/component/models/field.dart'
    show Field, JsonIgnore, JsonKey;

// Repository annotations
export 'annotations/component/repository/repository.dart' show Repository;

// State management annotations
export 'annotations/component/presentation/state_manager.dart'
    show StateManager, Event, StateView;

// Router and Screen annotations (with Session/ACL support)
export 'annotations/navigation/router_config.dart'
    show RouterConfig, DragonflyRouterConfig; // DragonflyRouterConfig: deprecated alias
export 'annotations/session/session_annotations.dart'
    show
        Screen,
        DragonflyScreen, // Deprecated alias
        ScreenTransition,
        AccessLevel,
        SessionConfig,
        DragonflySessionConfig, // Deprecated alias
        Authenticated,
        PathParam,
        QueryParam;
// @Where removed — dead annotation

// Form validation annotations
export 'annotations/form/form_annotations.dart'
    show
        // Schema
        FormSchema,
        // Base
        FieldValidator,
        // String validators
        Required,
        Email,
        MinLength,
        MaxLength,
        Pattern,
        Url,
        Phone,
        Alphanumeric,
        Alpha,
        Numeric,
        // Number validators
        Min,
        Max,
        Range,
        Positive,
        Negative,
        // Comparison validators
        EqualTo,
        NotEqualTo,
        // Date validators
        PastDate,
        FutureDate,
        MinAge,
        // Collection validators
        MinItems,
        MaxItems,
        // Boolean validators
        MustBeTrue,
        MustBeFalse,
        // Custom validator
        Custom,
        // Conditional validators
        RequiredIf,
        RequiredUnless,
        // Credit card validators
        CreditCard,
        Cvv,
        ExpiryDate,
        // Password validators
        StrongPassword,
        // Field metadata
        FormField,
        FormKeyboardType,
        FormTextCapitalization;

// Network annotations
export 'annotations/network/get.dart' show Get;
export 'annotations/network/path.dart' show Path;
export 'annotations/network/query.dart' show Query;
export 'annotations/network/post.dart' show Post;
export 'annotations/network/patch.dart' show Patch;
export 'annotations/network/delete.dart' show Delete;
export 'annotations/network/put.dart' show Put;
export 'annotations/network/body.dart' show Body;
export 'annotations/network/header.dart' show Header;
export 'annotations/network/subscribe.dart' show Subscribe;
