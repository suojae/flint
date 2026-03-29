# Swint

`Swint`는 `swift + lint`를 줄인 이름입니다.

Swift 코드베이스에서 팀 컨벤션과 안티패턴을 잡기 위한 경량 린트 패키지입니다. `flint`가 Flutter 쪽에서 하던 역할을 Swift 생태계로 옮기는 것을 목표로 합니다.

## 목표

- 포매팅보다 **설계와 안티패턴**을 잡습니다.
- 팀 규칙을 **Swift Package**로 배포하고 재사용합니다.
- 작은 규칙 엔진과 CLI로 시작해서, 이후 `SwiftSyntax` 기반 AST 규칙으로 확장할 수 있게 설계합니다.

## 포함된 것

- `SwintCore`: 규칙 엔진, 진단 모델, 기본 룰셋
- `swint`: 디렉토리/파일을 순회하며 `.swift` 파일을 검사하는 CLI

## 현재 기본 규칙

- `avoid_force_unwrap`
  `!` 기반 force unwrap / implicitly unwrapped optional 패턴을 경고합니다.

## 사용법

```bash
cd packages/swint
swift run swint lint Sources
```

여러 경로를 한 번에 검사할 수도 있습니다.

```bash
swift run swint lint Sources Tests
```

## 출력 예시

```text
Sources/App/LoginViewController.swift:18:24 warning: [avoid_force_unwrap] Avoid force unwrapping and implicitly unwrapped optionals. Use guard/if let or a non-optional type instead.
```

## 로드맵

- `SwiftSyntax` 기반 AST 규칙 엔진
- 설정 파일 지원
- `Xcode Build Tool Plugin`
- iOS 아키텍처/생명주기 전용 규칙

## 라이선스

MIT
