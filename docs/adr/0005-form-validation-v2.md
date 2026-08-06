# ADR 0005 — Form validation integration with state management v2

**Date:** 2026-08-05
**Status:** Accepted
**Deciders:** Gap-fix pass (see `docs/ai/known-gaps.md` #3)

## Context

The form-validation subsystem had three independent causes of non-compilation:

1. **Missing imports** — generated `.form.dart` parts referenced framework types
   that the source file didn't import (a part file cannot import anything).
2. **Naming** — `LoginForm` generated `LoginFormFormState` (doubled `Form`).
3. **Flutter collision** — `FormFieldState<T>` collided with Flutter's own
   `FormFieldState<T>` in `package:flutter/material.dart`.

Additionally, the generated `<Name>FormController` mixin targeted
`on StateManager<S>`, which was deleted in the v2 clean break (ADR 0001).
The mixin was the integration point between forms and state managers — without
it, form updates could not be dispatched to the controller.

## Decision

**Make the generated form state self-sufficient** and remove the mixin.

### Form state class

The generated `LoginFormState extends FormController` now carries three
self-contained methods:

- `updateFieldValue(String fieldName, dynamic value)` — sets the value and
  validates when `validateOnChange` is on, returning the new state
- `touchField(String fieldName)` — marks touched and validates when
  `validateOnBlur` is on, returning the new state
- `validateAllFields()` — validates every field, marks all touched, and
  returns the error-annotated state (then read `isValid`)

The old `<Name>FormController` mixin (`on DragonflyController<S>`) was removed
from the generator. The `FormControllerMixin` runtime class was also deleted.

### Integration with v2 state managers

Form-carrying state models use a delegate `initialState` getter when the model's
`initial` variant has parameters:

```dart
@StateManager(state: LoginState)
class LoginStateManager {
  LoginFormState _form = LoginFormState.initial();
  LoginState get initialState => LoginState.initial(form: _form);

  @Event()
  LoginState emailChanged(String value) {
    _form = _form.updateFieldValue('email', value);
    return LoginState.editing(form: _form);
  }
}
```

The generated controller calls `delegate.initialState` instead of
`const LoginState.initial()` when the initial variant has parameters.

### Naming fix

Classes ending in `Form` append `State` rather than `FormState`:
`LoginForm` → `LoginFormState` (was `LoginFormFormState`).

### Flutter collision fix

Runtime class renamed `FormFieldState<T>` → `DragonflyFormFieldState<T>`.

## Consequences

- The form subsystem now compiles cleanly across `example/` (0 errors, 27 warnings
  in auth from unused-code noise)
- Form state objects are genuinely self-contained — no mixin, no controller
  dependency; they work with any `@StateManager` delegate
- Validated widgets simplified to a single generic parameter `<S>` (was
  `<C extends DragonflyController<S>, S>`)

## References

- `dragonfly_builder/lib/builder/generators/form_schema_generator.dart`
- `dragonfly/lib/framework/form/form_field_state.dart`
- `dragonfly/lib/framework/form/form_controller.dart`
