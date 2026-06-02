# vbwd-ios-plugin-tarot

iOS port of the `taro` plugin from `vbwd-fe-user`. Tarot card reading with AI-powered interpretations.

## What this plugin does

| Feature | SDK seam used |
|---|---|
| "Tarot" item in side menu | `sdk.addMenuItem()` |
| Standalone `/tarot` screen | `sdk.addRoute(..., requiresAuth: true)` |
| English translations | `sdk.addTranslations("en", …)` |

## Backend endpoints consumed

All endpoints mirror `vbwd-fe-user/plugins/taro/src/stores/taro.ts`:

| Method | Endpoint | Purpose |
|---|---|---|
| `GET /taro/limits` | daily session quota |
| `POST /taro/session` | start a reading |
| `GET /taro/history` | past readings |
| `POST /taro/session/<id>/situation` | submit the question |
| `POST /taro/session/<id>/follow-up` | follow-up reading |
| `POST /taro/session/<id>/follow-up-question` | text follow-up |
| `POST /taro/session/<id>/card-explanation` | per-card explanation |

## Current scope (v0.1.0)

Functional MVP — matches the user's request "inject menu item → open tarot page":

- Menu item registered (order 50, top section).
- `/tarot` route opens `TarotScreen`.
- Screen calls `/taro/limits` on appear and shows the daily quota.
- "Start Reading" button → `POST /taro/session` → renders the drawn cards.

**Not yet ported** (web client has them, will land in follow-up iterations):
- Follow-up conversation flow (`OracleDialog`, `ConversationBox`)
- Reading history list
- Per-card detail modal
- Locale strings beyond English

## Plugin metadata

- `name = "taro"` — matches web client + backend so a single `plugins.json` entry controls both.
- `version = "0.1.0"` — minor version bumped as features port over.

## Activate

1. Add the package to Xcode (`File → Add Package Dependencies → Add Local → select this folder`).
2. Link `TarotPlugin` to the VBWD target.
3. Already wired in `VBWDApp.swift` + `plugins.json` (enabled by default).

## Requirements

- Swift 6.0+ / Xcode 16+
- iOS 16+ / macOS 13+
- `vbwd-ios-core` as a sibling package
- Backend with `taro` plugin enabled
