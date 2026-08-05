library;

// Injectable annotations
export 'annotations/injectable/injectable_annotations.dart'
    show
        Injectable,
        InjectableUseCase,
        Singleton,
        LazySingleton,
        Named,
        Inject,
        DragonflyInjectableInit,
        useCaseComponent,
        injectable,
        singleton,
        lazySingleton;
export 'annotations/injectable/inyectar.dart';

// Component annotations
export 'annotations/component/injector/injector_config.dart';

// Model annotations
export 'annotations/component/models/factory_model.dart' show FactoryModel;
export 'annotations/component/models/event_model.dart' show EventModel;
export 'annotations/component/models/state_model.dart' show StateModel;
export 'annotations/component/models/field.dart'
    show Field, JsonIgnore, JsonKey;

// Repository annotations
export 'annotations/component/repositoriy/repository.dart' show Repository;

// Presentation annotations (BLoC)
export 'annotations/component/presentation/dragonfly_bloc.dart'
    show DragonflyBloc;
export 'annotations/component/presentation/dragonfly_view.dart'
    show DragonflyBlocView, DragonflyStateBuilder;

// State Manager annotations (Feature architecture)
export 'annotations/component/presentation/feature/dragonfly_feature.dart'
    show
        DragonflyStateManager,
        DragonflyView, // Deprecated alias
        DragonflyFeature, // Deprecated alias
        InitialState,
        StateAction,
        ViewAction, // Deprecated alias
        FeatureAction, // Deprecated alias
        SideEffect,
        Computed,
        StateSlot;

// Router and Screen annotations (with Session/ACL support)
export 'annotations/navigation/router_config.dart' show DragonflyRouterConfig;
export 'annotations/session/session_annotations.dart'
    show
        DragonflyScreen,
        ScreenTransition,
        AccessLevel,
        DragonflySessionConfig,
        Authenticated,
        PathParam,
        QueryParam;
export 'annotations/where.dart';

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
