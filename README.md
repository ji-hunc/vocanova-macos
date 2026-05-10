# VocaNova (macOS)

어떤 앱에서든 영어 단어를 선택한 뒤 **⌘⇧F** 한 번이면 커서 옆에 사전 팝업이 뜨는 macOS 네이티브 단어장 앱입니다.
브라우저, IDE, 메신저, PDF — macOS의 모든 앱에서 곧바로 검색하고 단어장에 저장할 수 있습니다.

같은 Supabase 백엔드를 공유하는 [크롬 익스텐션(`voca-extension`)](../voca-extension) / [iOS 앱(`VocaNova`)](../VocaNova) 과 단어장이 자동으로 동기화됩니다.

## 실행화면

<table>
  <tr>
    <td><img width="400" alt="screenshot1" src="https://github.com/user-attachments/assets/c127ec14-8037-4946-ba14-160f01334c86" /></td>
    <td><img width="400" alt="screenshot2" src="https://github.com/user-attachments/assets/64bdad18-bfb1-4d6f-a077-d2242b8e2fc1" /></td>
    <td><img width="400" alt="screenshot3" src="https://github.com/user-attachments/assets/6758a4a2-3b24-45cf-89ae-03751b92a7d9" /></td>
  </tr>
</table>

## 주요 기능

- **시스템 전역 단축키** — ⌘⇧F (재바인딩 가능)로 어떤 앱에서든 즉시 호출
- **선택 텍스트 자동 인식** — macOS Accessibility API로 다른 앱의 선택 텍스트를 직접 읽어옴 (실패 시 클립보드 fallback)
- **플로팅 팝업** — 마우스 커서 근처에 사전 결과를 표시하는 NSPanel
- **네이버 영어 사전** — 발음(IPA + mp3 재생), 품사별 뜻, 예문
- **단어장 저장** — Google / Apple 로그인 후 한 번의 클릭으로 클라우드 단어장에 추가
- **메뉴바 전용** — Dock 아이콘 없이 메뉴바에 상주

## 배포

<!-- TODO: 배포 페이지 / DMG 다운로드 링크 추가 -->

## 기술 스택

- **언어**: Swift
- **UI**: SwiftUI + AppKit (NSPanel, NSStatusItem)
- **최소 OS**: macOS 14 (Sonoma)
- **단축키**: [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) (sindresorhus)
- **선택 텍스트 인식**: macOS Accessibility API (AX)
- **백엔드**: Supabase (Auth, PostgREST RPC)
- **인증**: Sign in with Apple, Google OAuth
- **프로젝트 생성**: XcodeGen (`project.yml`)
- **아키텍처 패턴**: MVVM

## 아키텍처

```
┌────────────────────────────────────┐
│  VocaNovaApp (macOS)               │
│  ┌──────────────────────────────┐  │
│  │ KeyboardShortcuts (⌘⇧F)      │  │
│  │ Accessibility API            │  │
│  │ Popup NSPanel (SwiftUI)      │  │
│  └──────────────┬───────────────┘  │
└─────────────────┼──────────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
┌──────────────┐    ┌──────────────────┐
│ Naver Dict   │    │   Supabase       │  ← voca-extension / VocaNova
│ (사전 검색)   │    │   Auth + DB      │     이 같은 백엔드를 공유
└──────────────┘    └──────────────────┘
```

- 전역 단축키가 눌리면 Accessibility API로 현재 포커스된 앱의 선택 텍스트를 읽어와 네이버 사전에 질의합니다.
- 사용자가 단어를 저장하면 Supabase의 `add_word_to_vocab` RPC가 호출되며, 이 데이터는 크롬 익스텐션 / iOS 앱에서도 그대로 보입니다.
- App Sandbox는 사용하지 않습니다 (Accessibility API 요건). 대신 Hardened Runtime + Notarization으로 배포합니다.
