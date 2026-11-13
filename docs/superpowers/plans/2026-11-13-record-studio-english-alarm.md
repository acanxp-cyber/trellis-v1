# Record Studio, Spoken Alarms, and English Reading Plan

## Goal

Make the creative tools discoverable from Records, make local audio reliably
replayable, finish the PencilKit/pixel/sticker editors, compress workout
warm-up and cool-down blocks, support spoken alarm titles, and add 100 bundled
English reading passages with local attempt recordings.

## Global Constraints

- All recordings, drawings, stickers, and reading attempts remain local.
- No health or practice media enters CloudKit.
- Spoken alarms use a locally generated short sound file at scheduling time.
- English passages are original app content, not copied news or textbook text.
- The Records screen exposes drawing, pixel art, stickers, and English reading
  without requiring horizontal scrolling.

## Task 1: Replayable Local Audio

- [ ] Add a shared local audio player with play, pause, resume, restart, and
  completion state.
- [ ] Add a state-machine regression test proving a finished clip restarts at
  zero.
- [ ] Reuse the player for voice records and English reading attempts.

## Task 2: Discoverable Creative Studio

- [ ] Replace the hidden horizontal-only creative actions with a visible grid.
- [ ] Add stable accessibility identifiers for every action.
- [ ] Keep photo, video, library, and voice capture available from the same
  section.

## Task 3: Complete Creative Editors

- [ ] PencilKit: clear, undo, redo, and PNG export.
- [ ] Pixel canvas: fixed 16x16 grid, palette, eraser, undo, clear, PNG export.
- [ ] Stickers: at least five categories and 40 system-owned vector stickers,
  multiple layers, selection, drag, pinch scale, rotate, delete, undo, and PNG
  export.

## Task 4: Compact Workout Timing

- [ ] Use one short warm-up item and one short cool-down item.
- [ ] Keep overhead at or below two minutes.
- [ ] Preserve the exact requested total duration.
- [ ] Skip redundant warm-up for mobility-only sessions.

## Task 5: Spoken Alarm Titles

- [ ] Generate a short local speech file from the task title.
- [ ] Use AlarmKit custom sound on iOS 26 and notification custom sound on
  earlier systems.
- [ ] Fall back to the default sound when speech generation fails.
- [ ] Remove obsolete speech files when reminders are cancelled.

## Task 6: English Reading Practice

- [ ] Bundle 100 original English passages with Chinese translations and IPA for
  selected advanced vocabulary.
- [ ] Add deterministic validation for count, uniqueness, length, translation,
  and IPA.
- [ ] Add random-next behavior without immediate repetition.
- [ ] Record and save local attempts linked to a passage and expose playback in
  Records.

## Task 7: Verification and TestFlight

- [ ] Build all targets.
- [ ] Run model, catalog, persistence, parser, and fitness tests.
- [ ] Archive and upload a signed build.
- [ ] Attach the build to the internal Debug TestFlight group.
