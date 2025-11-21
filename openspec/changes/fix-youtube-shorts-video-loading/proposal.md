## Why
YouTube Shorts stop the ROM assessment video from loading and the UX shows “Video not available” even when the Shorts links are valid. The existing player logic misidentifies every Shorts playback event as an error and never normalizes the incoming Shorts URLs before parsing.

## What Changes
- Normalize Shorts URLs to regular watch URLs before extracting the video ID so the youtube_player_iframe controller can initialize reliably.
- Tighten error handling by reacting only to `YoutubeError` signals, adding friendly error messages, and triggering fallback behavior only when a real playback failure occurs.
- Document the change via the `media-capture` capability so the spec reflects the full Shorts URL coverage and the more accurate feedback.

## Impact
- Affected specs: `media-capture`
- Affected code: `lib/assessment/dynamic_video_player.dart`

