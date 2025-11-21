## 1. Implementation
- [ ] 1.1 Normalize Shorts URLs and reuse the extractor so every YouTube link resolves its video ID before the controller initializes.
- [ ] 1.2 Update the player listener to respond only to `YoutubeError`, provide friendly error messaging, and trigger fallback only when an actual playback error occurs.

## 2. Validation
- [ ] 2.1 Verify that Shorts and regular YouTube links load without immediately showing “Video not available” and that error messaging only appears for genuine failures.
- [ ] 2.2 Run an analyzer/lint pass to confirm there are no regression warnings in the touched files.

