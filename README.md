# VocaNovaApp

macOS 네이티브 영어 단어 학습 앱.
어떤 앱에서든 영어 단어를 선택하고 **⌘⇧F**를 누르면 즉시 사전 팝업이 뜬다.

크롬 익스텐션(`voca-extension`) / iOS RN 앱(`VocaNova`)과 같은 Supabase 백엔드를 공유한다.
이 앱에서 저장한 단어는 다른 클라이언트에서도 그대로 보인다.

## 핵심 기능

- 시스템 전역 단축키(⌘⇧F, 재바인딩 가능)
- macOS Accessibility API로 다른 앱의 선택 텍스트 읽기 (+ 클립보드 fallback)
- 마우스 커서 근처에 뜨는 플로팅 NSPanel
- 네이버 영어 사전 검색 — 발음(IPA + mp3), 뜻, 품사, 예문, 한국어 번역
- Google / Apple 로그인 후 단어장에 저장 (Supabase RPC `add_word_to_vocab`)
- 메뉴바 전용 (Dock 아이콘 없음)

## 디렉터리 구조

```
VocaNovaApp/
├── VocaNovaApp/
│   ├── App/              # 엔트리, AppDelegate, 환경, 설정
│   ├── Models/           # Codable 도메인 모델
│   ├── Services/         # 네트워킹, AX, 키체인, 단축키, 클립보드 등
│   ├── ViewModels/       # MVVM
│   ├── Windows/          # NSPanel 등 AppKit interop
│   ├── Views/            # SwiftUI (Popup / Settings / Onboarding / Shared)
│   ├── Util/             # 확장, 암호화 유틸
│   └── Resources/        # Info.plist, entitlements, Assets
├── VocaNovaAppTests/     # 단위 테스트 + JSON fixture
├── project.yml           # XcodeGen 설정 (.xcodeproj 재생성용)
└── README.md
```

총 ~50개 Swift 파일.

## 사전 준비물

- macOS 14.0+ (Sonoma 이상)
- Xcode 15+
- Apple Developer 계정 (Apple Sign-In 사용 시 무료 계정으로도 가능, 다만 배포 시 유료 필요)
- (선택) [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## 셋업

### 옵션 A: XcodeGen으로 .xcodeproj 자동 생성 (권장)

```bash
cd /Users/jason/workspace/voca/VocaNovaApp
xcodegen generate
open VocaNovaApp.xcodeproj
```

XcodeGen이 `project.yml`을 읽어 .xcodeproj를 만든다. `project.yml` 안에서:
- `DEVELOPMENT_TEAM`을 본인 팀 ID로 변경
- 필요 시 `PRODUCT_BUNDLE_IDENTIFIER` 변경

### 옵션 B: Xcode에서 새 프로젝트 만들고 소스 추가

1. Xcode → File → New → Project → macOS → App
   - Product Name: `VocaNovaApp`
   - Organization Identifier: `app.vocanova`
   - Interface: **SwiftUI**, Language: **Swift**
   - Storage: **None**, Tests: **Yes**
   - Min Deployment: macOS 14.0
2. 자동 생성된 `ContentView.swift` / 자동 생성 `Info.plist` 삭제
3. 이 저장소의 `VocaNovaApp/` 안 모든 폴더를 Xcode 프로젝트에 드래그 (Create groups + Copy items 체크 해제, Add to target=VocaNovaApp 체크)
4. `VocaNovaAppTests/`도 Test 타겟에 동일하게 추가
5. Project Settings:
   - **General** → Bundle Identifier `app.vocanova.macos`
   - **General** → Info.plist `VocaNovaApp/Resources/Info.plist`로 지정
   - **Signing & Capabilities** → Automatic Signing, 본인 팀 선택
   - **Signing & Capabilities** → `+ Capability` → "Sign in with Apple" 추가
   - **Signing & Capabilities** → "App Sandbox"는 추가하지 말 것 (또는 추가했다면 체크 해제)
   - **Build Settings** → Code Signing Entitlements: `VocaNovaApp/Resources/VocaNovaApp.entitlements`
   - **Build Settings** → Hardened Runtime: YES
6. **File → Add Package Dependencies…** → `https://github.com/sindresorhus/KeyboardShortcuts` (latest 2.x)
7. **Project → Info → URL Types** → `+`
   - Identifier: `app.vocanova.callback`
   - URL Schemes: `vocanova`

## 권한 / 엔타이틀먼트

| 권한 | 설명 | 어디서 |
|---|---|---|
| App Sandbox | **꺼짐** — Accessibility API는 비-샌드박스 필수 | `VocaNovaApp.entitlements` |
| Sign in with Apple | Apple 로그인 | Capabilities |
| Hardened Runtime | 코드 사인 + Notarization | Build Settings |
| Accessibility | 다른 앱의 선택 텍스트 읽기 | 앱 첫 실행 시 시스템 다이얼로그 → System Settings에서 토글 |

`Info.plist` 핵심 키:
- `LSUIElement = true` (메뉴바 전용)
- `LSMinimumSystemVersion = 14.0`
- `CFBundleURLTypes` (`vocanova` 스킴)

## OAuth provider 설정 (Supabase + Apple Developer)

Google 로그인은 Supabase 대시보드에서 토글만 켜면 동작하지만, Apple 로그인은 Apple Developer Console과 Supabase 양쪽에 추가 설정이 필요하다. 둘 다 켜야 macOS 앱에서 Apple 로그인이 성공한다.

### Apple Developer Console
1. **Identifiers → App IDs** → 앱 번들 ID(`app.vocanova.macos`)에 *Sign in with Apple* capability 활성화
2. **Identifiers → Services IDs** → 새 Service ID 생성 (예: `app.vocanova.signin`)
   - *Sign in with Apple* 활성화 → Configure → Primary App ID 지정
   - Domain: `sqhvrnlkjxebkodpghon.supabase.co`
   - Return URL: `https://sqhvrnlkjxebkodpghon.supabase.co/auth/v1/callback`
3. **Keys → +** → 새 Sign in with Apple 키 생성, `.p8` 파일 다운로드 (한 번만 가능). Key ID 메모.
4. **Membership** 페이지에서 Team ID 확인.

### Supabase Dashboard
1. Authentication → Providers → **Apple** → 활성화
2. 입력:
   - **Services ID**: 위에서 만든 ID (예: `app.vocanova.signin`)
   - **Team ID**
   - **Key ID**
   - **Secret Key (P8)**: `.p8` 파일 내용 전체 붙여넣기
3. Authorized Client IDs에 macOS 앱 번들 ID(`app.vocanova.macos`)도 추가 (네이티브 ID 토큰 흐름용)
4. Authentication → URL Configuration → Redirect URLs에 `vocanova://auth-callback` 추가 (Google과 공유)

### Xcode (macOS 앱)
- Signing & Capabilities → **+ Capability** → "Sign in with Apple"
- 자동으로 `com.apple.developer.applesignin = ["Default"]` 엔타이틀먼트가 들어감
- **Personal Team(무료) 빌드는 Sign in with Apple이 동작하지 않는다.** 유료 Apple Developer Program 팀 서명 필요.

### 디버깅
실패 시 Console.app에서 subsystem `app.vocanova.macos`, category `auth`로 필터링하면 두 가지 위치의 단서가 나온다:
- `Apple authorization failed — code=…` : Apple 측에서 발생한 에러. 1000(.failed)이면 capability/Service ID 문제일 가능성이 가장 큼.
- `Supabase id_token exchange failed (NNN): {body}` : Apple 토큰을 Supabase에 교환할 때 실패. 응답 본문에 `provider not enabled`, `invalid issuer`, `nonce mismatch` 같은 정확한 사유가 들어 있다.

## 첫 실행

1. Xcode에서 ▶︎ 또는 빌드된 앱 실행
2. 메뉴바에 책 아이콘이 생긴다
3. Onboarding 윈도우가 뜬다 → "시스템 설정에서 권한 부여" 클릭
4. macOS가 첫 실행 시 권한 다이얼로그를 한 번 띄우고, "시스템 설정 → 개인정보 보호 → 손쉬운 사용"으로 자동 이동
5. **VocaNova** 토글을 켠다
6. Onboarding이 자동으로 다음 단계로 진행 (단축키 설정 → 완료)

## 사용

1. Chrome / Safari / VSCode / Slack / 어디서든 영어 단어를 드래그
2. **⌘⇧F** (또는 본인 단축키) 누름
3. 커서 근처에 사전 팝업 표시
4. 발음 듣기 / 단어장에 저장 / ESC로 닫기

## 설정 창

메뉴바 아이콘 → **설정…** 또는 ⌘, 으로 열림.

| 탭 | 항목 |
|---|---|
| 일반 | 시작시 실행 (Launch at Login), 메뉴바 아이콘 표시, Accessibility 권한 상태, 버전 정보 |
| 단축키 | 단축키 사용 토글, ⌘⇧F 등 단축키 변경 (`KeyboardShortcuts.Recorder`) |
| 계정 | 로그인 정보, 로그아웃 / Google·Apple 로그인 |

**시작시 실행**은 `SMAppService.mainApp`을 사용한다. 작동 조건:
- macOS 13+ (우리는 14+ 타겟이므로 OK)
- **Developer ID로 사인된 빌드**여야 시스템에 정상 등록됨. dev 빌드(자동 사인)에서는 `register()`가 `.notFound`로 실패할 수 있음 — Release 빌드에서 최종 검증.
- 사용자가 거부하면 상태가 `.requiresApproval`로 남고, UI에서 "시스템 설정 → 일반 → 로그인 항목" 안내 버튼이 표시됨.

**메뉴바 아이콘 표시 OFF** 시 자동으로 Dock 아이콘으로 폴백 (`NSApp.setActivationPolicy(.regular)`). Dock 아이콘 클릭 시 설정창이 자동으로 다시 뜬다 (`applicationShouldHandleReopen`).

## 테스트

```bash
# XcodeGen 사용 시
xcodegen generate
xcodebuild test -project VocaNovaApp.xcodeproj \
  -scheme VocaNovaApp -destination 'platform=macOS'
```

테스트는 외부 네트워크 없이 실행된다 (Naver 응답 fixture 사용).

## 배포 (Notarization)

```bash
# 1. Archive
xcodebuild archive -project VocaNovaApp.xcodeproj \
  -scheme VocaNovaApp -configuration Release \
  -archivePath build/VocaNovaApp.xcarchive

# 2. Export with Developer ID
xcodebuild -exportArchive \
  -archivePath build/VocaNovaApp.xcarchive \
  -exportPath build/Export \
  -exportOptionsPlist ExportOptions.plist

# 3. ZIP & notarize
ditto -c -k --keepParent build/Export/VocaNovaApp.app build/VocaNovaApp.zip
xcrun notarytool submit build/VocaNovaApp.zip \
  --apple-id "<email>" --team-id "<team>" --password "<app-specific-pw>" \
  --wait

# 4. Staple
xcrun stapler staple build/Export/VocaNovaApp.app

# 5. (옵션) DMG 패키징
brew install create-dmg
create-dmg --volname "VocaNova" build/Export/VocaNovaApp.app build/
```

> **Mac App Store에는 출시할 수 없다.** App Sandbox가 필수인데 Accessibility API가 샌드박스에서 작동하지 않기 때문이다. 직접 배포(DMG) 또는 v3에서 XPC helper 분리로 해결.

## 자주 발생하는 문제

| 증상 | 해결 |
|---|---|
| Chrome / Slack에서 선택 텍스트가 비어있음 | `SelectionReader`가 자동으로 ⌘C 클립보드 fallback 사용 |
| 단축키가 안 먹음 | (1) Accessibility 권한 확인 (2) Karabiner / Raycast 충돌 확인 |
| 재빌드 후 "선택 텍스트 비어있음" 다시 발생 | 코드 사인 신원이 바뀌면 TCC 권한이 무효화됨. 한 인증서 유지하거나 ad-hoc 사인: `codesign --force --sign - VocaNovaApp.app` |
| Naver가 빈 응답 | Referer 헤더 누락. `Config.naverReferer` 확인 |
| Supabase 401 | 토큰 만료. `VocabService`가 자동 refresh 후 재시도 |
| 풀스크린 앱 위에 팝업이 안 뜸 | `PopupPanel.level`을 `.statusBar + 1`로 상승 |
| 발음 mp3가 안 들림 | `AudioPlayer` 인스턴스가 GC되었을 가능성 — 싱글톤 강한 참조 확인 |

## v1 / v2 / v3 단계

- **v1 (현재)**: 단축키, AX, 사전 팝업, Google + Apple 로그인, 단어 저장
- **v2**: mp3 캐시, 검색 히스토리, "클립보드 단어 검색" 메뉴, Sparkle 자동 업데이트
- **v3**: 저장 단어 브라우저 + SRS 복습, MAS용 XPC helper 분리

## 참고 자료

이 앱은 다음 기존 자산을 재사용한다:

- 네이버 사전 API + 파서: [voca-extension/parser.js](../voca-extension/parser.js)
- Naver 응답 스키마 문서: [voca-extension/docs/naver-api-response.md](../voca-extension/docs/naver-api-response.md)
- Supabase auth/RPC 패턴: [voca-extension/auth.js](../voca-extension/auth.js), [voca-extension/supabase.js](../voca-extension/supabase.js)
- Apple Sign-In 패턴: [VocaNova/src/lib/auth.ts](../VocaNova/src/lib/auth.ts)
- 모델 타입 (참고): [VocaNova/src/types/word.ts](../VocaNova/src/types/word.ts)
- 팝업 UI 디자인: [voca-extension/popup.css](../voca-extension/popup.css), [voca-extension/popup.js](../voca-extension/popup.js)
