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
| `avoid_visibility_widget` | `Visibility`/`Offstage`로 위젯을 숨기지 마세요. 조건부 렌더링을 사용하세요. |
| `avoid_shrink_wrap_in_list` | `ListView`/`GridView`에서 `shrinkWrap: true` 금지. Sliver를 사용하세요. |

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

## 예시

### avoid_image_opacity

Opacity 위젯은 오프스크린 버퍼를 추가 할당합니다. Image 자체의 속성을 쓰면 중간 단계 없이 바로 투명도가 적용됩니다.

```dart
// 나쁜 예
Opacity(
  opacity: 0.5,
  child: Image.asset('photo.png'),
)

// 좋은 예
Image.asset(
  'photo.png',
  color: Color.fromRGBO(255, 255, 255, 0.5),
  colorBlendMode: BlendMode.modulate,
)
```

### avoid_hardcoded_color

하드코딩된 색상은 다크모드에서 텍스트/아이콘이 안 보이는 사고를 유발합니다.

```dart
// 나쁜 예
Container(color: Color(0xFF000000))

// 좋은 예
Container(color: Theme.of(context).colorScheme.surface)
```

### avoid_visibility_widget

숨겨진 위젯은 여전히 터치 이벤트를 가로채서 고스트 터치 버그를 유발합니다.

```dart
// 나쁜 예 — 보이지 않지만 터치는 가로챔
Visibility(
  visible: false,
  child: MyButton(),
)

// 좋은 예
if (isShown) MyButton()
```

### avoid_shrink_wrap_in_list

shrinkWrap: true는 lazy rendering을 무효화하여 모든 아이템을 한꺼번에 build합니다.

```dart
// 나쁜 예 — 1000개 아이템을 전부 한 번에 build
ListView.builder(
  shrinkWrap: true,
  itemCount: 1000,
  itemBuilder: (_, i) => Item(i),
)

// 좋은 예 — 화면에 보이는 것만 build
CustomScrollView(
  slivers: [
    SliverList.builder(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Item(i),
        childCount: 1000,
      ),
    ),
  ],
)
```

## 기여하기

PR 환영합니다! 새 규칙 추가 방법:

1. `lib/src/rules/`에 파일 생성
2. `DartLintRule` 상속
3. `lib/flint.dart`에 등록
4. 한국어 주석과 예시 추가

## 라이선스

MIT
