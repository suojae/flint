## Unreleased

- `avoid_controller_in_build` - `build()` 안에서 `TextEditingController`, `ScrollController`, `FocusNode` 같은 dispose 대상 객체 생성 금지
- `avoid_raw_go_router_navigation` - `context.go('/x')`, `router.pushNamed('foo')` 같은 raw `go_router` 네비게이션 API 사용 금지
- `avoid_side_effect_in_build` - `build()` 안에서 `Navigator.push`, `showDialog`, `bloc.add()` 같은 side effect 직접 실행 금지
- `prefer_specific_media_query_methods` - `MediaQuery.of(context).size`, `.padding`, `.devicePixelRatio` 대신 `sizeOf`, `paddingOf`, `devicePixelRatioOf` 같은 전용 접근자 사용 유도

## 0.1.0

- 최초 릴리즈
- `avoid_image_opacity` — Image에 Opacity 감싸기 금지 (오프스크린 버퍼 비효율)
- `avoid_hardcoded_color` — Color 하드코딩 금지 (다크모드 깨짐 방지)
- `avoid_visibility_widget` — Visibility/Offstage 사용 금지 (고스트 터치 방지)
- `avoid_shrink_wrap_in_list` — shrinkWrap: true 금지 (lazy rendering 무효화 방지)
