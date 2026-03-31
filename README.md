# flint

Flutter 안티패턴을 잡아주는 린트 규칙 모음. 설정 없이, 추가만 하면 바로 동작합니다.

## 설치

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.6.4
  flint:
    git:
      url: https://github.com/suojae/flint.git
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

## 규칙 목록

| 규칙 | 설명 |
|------|------|
| `avoid_image_opacity` | Image를 Opacity로 감싸지 마세요. `color` + `colorBlendMode`를 사용하세요. |
| `avoid_hardcoded_color` | build 메서드에서 `Color(0xFF...)` 하드코딩 금지. `colorScheme`을 사용하세요. |
| `avoid_controller_in_build` | `build()` 안에서 `TextEditingController`/`ScrollController`/`FocusNode` 등을 생성하지 마세요. |
| `avoid_raw_go_router_navigation` | `context.go('/x')`, `router.pushNamed('foo')` 같은 raw `go_router` 호출 대신 typed route API를 사용하세요. |
| `avoid_side_effect_in_build` | `build()` 안에서 `Navigator.push`, `showDialog`, `bloc.add()` 같은 side effect를 직접 실행하지 마세요. |
| `avoid_visibility_widget` | `Visibility`/`Offstage`로 위젯을 숨기지 마세요. 조건부 렌더링을 사용하세요. |
| `avoid_shrink_wrap_in_list` | `ListView`/`GridView`에서 `shrinkWrap: true` 금지. Sliver를 사용하세요. |
| `enforce_dispose_owned_fields` | `State`가 직접 만든 controller/node는 `dispose()`에서 반드시 정리하세요. |

## 사용법

설치 후 IDE에서 자동으로 경고가 표시됩니다. CLI로도 실행 가능합니다:

```bash
dart run custom_lint
```

### 특정 규칙 끄기

```yaml
# analysis_options.yaml
custom_lint:
  rules:
    - avoid_hardcoded_color: false
```

## 라이선스

MIT
