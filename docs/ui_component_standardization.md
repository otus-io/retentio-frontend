🌐 [English](ui_component_standardization.md) | [中文](ui_component_standardization_zh.md)

---

# UI Component Standardization Requirement (Buttons / Inputs / Icon Buttons)

## Background

The current Flutter frontend has inconsistent UI primitives across pages:

- Different button styles (`ElevatedButton`, `TextButton`, `FilledButton`) with repeated local style definitions.
- Input fields (`TextField`) have inconsistent height, spacing, border, and focus behavior.
- Icon button interactions (`IconButton`) are not unified in touch area, disabled behavior, and visual state.

This inconsistency increases maintenance cost and weakens UI coherence.

## Goal

Create exactly **3 shared UI components** and replace all existing usage in the app:

1. **AppButton**
2. **AppInput**
3. **AppIconButton**

After replacement, all pages should follow unified visual and interaction standards while preserving current product behavior.

## Scope

### In Scope

- Add 3 reusable components under shared widgets layer.
- Replace existing button/input/icon-button usages in all frontend pages.
- Keep existing logic and behavior intact (navigation, validation, callbacks, loading states).
- Update impacted tests and snapshots/assertions when needed.

### Out of Scope

- Global replacement of all display-only `Icon(...)` usages.
- Full design system/theming overhaul.
- New business features.

## Existing Usage Snapshot (for effort baseline)

- Button-class controls (`ElevatedButton` / `TextButton` / `FilledButton`...): around **12 files**.
- Input fields (`TextField`): around **5 files**.
- Icon buttons (`IconButton`): around **8 files**.

## Component Requirements

### 1) AppButton

Support unified APIs for:

- Variants: `primary`, `secondary`, `ghost`, `danger`.
- Sizes: `sm`, `md`, `lg`.
- States: enabled / disabled / loading.
- Optional icon slot (leading/trailing).
- Full-width option.

Behavioral requirements:

- Unified min-height and horizontal padding.
- Loading state prevents duplicate taps.
- Focus/pressed feedback consistent across pages.

### 2) AppInput

Support unified APIs for:

- Label / hint / helper / error text.
- Prefix and suffix widgets.
- Obscure text mode (password-like fields).
- Controlled/uncontrolled usage via controller/value callbacks.

Behavioral requirements:

- Unified height and content padding.
- Unified border radius and border color rules (default/focus/error/disabled).
- Keep compatibility with existing validation flows.

### 3) AppIconButton

Support unified APIs for:

- Icon data or custom icon widget.
- Variants: default / subtle / danger.
- Sizes with unified tappable target.
- Tooltip semantics when applicable.

Behavioral requirements:

- Unified hit area and disabled state.
- Avoid tiny touch targets on dense UI regions.

## Implementation Plan

1. Audit usage and map old widgets to new component variants.
2. Build 3 shared components with stable, minimal APIs.
3. Replace per module (login/register -> decks -> deck study -> profile -> shared widgets).
4. Run formatter/analyzer/tests and fix regressions.
5. Produce migration notes and follow-up cleanup suggestions.

## Acceptance Criteria

- No direct usage of `ElevatedButton`, `TextButton`, `FilledButton`, `TextField`, `IconButton` in app business pages (except justified framework edge cases).
- Key pages (login, register, deck list, deck study, profile) show consistent button/input/icon-button appearance.
- `flutter analyze` passes.
- `flutter test` passes.
- No major UX regression in core flows.

## Risks and Mitigation

- **Risk:** Visual regressions due to large replacement surface.
  - **Mitigation:** Replace by module and verify each module incrementally.
- **Risk:** Tests coupled to old widget types.
  - **Mitigation:** Update tests to assert behavior/semantics rather than concrete widget class where possible.
- **Risk:** Edge cases in deck/video pages with custom controls.
  - **Mitigation:** Keep exceptions explicit and document why an old widget is retained if needed.

## Estimated Effort (Implementation by AI pair-programming)

- Baseline scope (3 components + full replacement for button/input/icon-button): **9.5 ~ 13 hours**.
- Most likely effort: **~11 hours**.
- If expanding to all display icons (`Icon(...)`), add **4 ~ 8 hours**.

## Deliverables

- Shared component files for `AppButton`, `AppInput`, `AppIconButton`.
- Full-app replacement patch under current scope.
- Updated tests (if impacted).
- This requirement document (EN + ZH).
