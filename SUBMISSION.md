# Submission — AI Story Buddy & Quiz (Peblo Challenge)

Everything here is ready to **copy‑paste** into the Google Form
(https://forms.gle/6re5JGsiUgyGBc5r7) and your repo. Replace the
`<<...>>` placeholders with your details/links.

---

## A. Form fields

- **Name:** `<<Your name>>`
- **Email / phone:** `<<...>>`
- **Framework chosen:** Flutter
- **GitHub repository:** `<<https://github.com/your-username/ai-story-buddy>>`
- **Screen recording link:** `<<Google Drive / Loom link>>`

---

## B. README answers (copy‑paste)

**Which framework you chose and why.**
Flutter. The primary audience is children in India on mid‑range Android (~3GB
RAM). Flutter compiles to a small, fast AOT binary and renders its own widgets,
so the joyful UI is identical and smooth across many cheap devices from one
codebase. 60fps animations (shake, confetti, reveal) are first‑class via
`AnimationController`s, and `flutter_tts` gives on‑device narration with no
network dependency.

**How you managed the transition between audio ending and the quiz appearing.**
A single `ChangeNotifier` (`StoryBuddyController`) models the narration lifecycle
`idle → preparing → reading → finished`. The TTS **completion callback** (not a
timer) sets `finished` and flips `quizRevealed = true`. The view watches that
flag and swaps `StoryView → QuizView` inside an `AnimatedSwitcher` (Fade + Size,
450ms), then auto‑scrolls to the question. So the quiz appears exactly when the
audio ends. A manual Stop uses the cancel callback and does not reveal.

**How you built the quiz to be data‑driven.**
`QuizQuestion.fromJson` parses `{question, options, answer}` and computes the
correct index via `options.indexOf(answer)`. The UI renders options with a
`for` loop over `options`, so 3/4/5 (or more) options work with no code change.
The payload is loaded from `assets/quiz.json` through a repository whose
`AssetBundle` is injectable (real bundle in prod, fake in tests, a network call
later). Unit tests cover 3/4/5‑option payloads and malformed JSON.

**Your caching approach (incl. remote audio).**
Quiz JSON is loaded once and kept in memory for the session; for offline‑first
I'd persist the last good payload to disk and read‑through on launch. Native TTS
synthesizes on‑device, so there's nothing to cache. With a remote TTS API
(ElevenLabs), I'd cache audio bytes in the app cache dir keyed by
`hash(text+voice+rate+pitch)` with an LRU size cap, check cache before calling
the API (`flutter_cache_manager`), and pre‑warm the next page's audio.

**How you handled audio loading and failure states.**
Loading = `preparing` state with a spinner and disabled button. Reading = a Stop
button. Failure = `TtsService.speak` catches `MissingPluginException` /
`PlatformException` and returns false; on a real failure the app quietly returns
to the **Read Me a Story** button to tap again (no alarming message), and the
"cancel" errors the browser fires when we stop to **seek** are recognised and
ignored. The app never hangs or crashes — covered by a widget test that forces a
failure then succeeds. A single, consistent on‑device voice is used throughout
(so its word‑boundary highlighting keeps working after a seek).

**Your performance profiling.**
Method: `flutter run --profile` on a physical mid‑range Android, DevTools →
Performance, record across read → reveal → option taps → confetti, watching for
frames over 16ms. Changes that helped: scoping rebuilds with
`context.select`/`Selector` (only the avatar rebuilds on mood change; only the
quiz subtree on quiz taps) and a `RepaintBoundary` around the spinning avatar so
its animation doesn't repaint the rest of the screen.
➜ Attach `docs/perf-before.png` and `docs/perf-after.png` captured on device.

**How you optimized to stay lightweight on mid‑range Android.**
No heavy image assets (Buddy is drawn with shapes) and **Poppins is bundled**
(no runtime font fetch) for a fast first paint. Scoped rebuilds via Provider
selectors, a `RepaintBoundary` around the animated avatar, `const` widgets
throughout, a single responsive screen with no route‑stack overhead, and
on‑device TTS so there's no network on the hot path.

**AI usage & judgment.**
Used GitHub Copilot CLI to scaffold the app, widgets, state and tests. One
suggestion I changed: it first built **two screens** (Story + Quiz with a manual
button) mirroring the two wireframes; I switched to a **single screen that
auto‑reveals the quiz on audio completion**, per the brief. What didn't work:
(1) a `const` quiz model with `assert(options.length…)` wouldn't compile — moved
validation into `fromJson` + tests; (2) widget tests hung — first on
`pumpAndSettle` waiting on the avatar's infinite animation (used fixed `pump`),
then on the shared `rootBundle` being poisoned across tests by GoogleFonts —
fixed by injecting a per‑test `AssetBundle`; (3) TTS completion didn't fire under
test — put TTS behind an interface and drove it with a fake.

---

## C. Screen‑recording shot list (record on a device/emulator)

1. App opens → story + Buddy (robot), everything fitted on one screen.
2. Tap **Read Me a Story** → **Preparing…** then it narrates; the **current word
   highlights** and the story auto‑scrolls along.
3. Drag the **progress bar** (above the button) to scrub — the narration and the
   highlight jump to that point.
4. Narration ends → quiz **reveals**.
5. Tap a **wrong** option → card **shakes** + (haptic on device) + "try again".
6. Tap **Blue** (correct) → **confetti** + Buddy smiles + Success + "Read it
   Again".

Keep it ~30–45s.

---

## D. Requirements → where it's implemented

| Requirement | Where |
| --- | --- |
| Kid‑friendly single screen | `lib/screens/story_buddy_screen.dart` |
| AI Buddy character (placeholder) | `lib/widgets/buddy_avatar.dart` |
| "Read Me a Story" button | `story_buddy_screen.dart` → `_ReadButton` |
| Story text card | `story_buddy_screen.dart` → `_StoryCard`, `data/story_content.dart` |
| TTS narration | `lib/services/tts_service.dart` (`flutter_tts`) |
| Loading / preparing state | `NarrationStatus.preparing` + `PrimaryButton(busy: true)` |
| Failure + retry | `tts_service.dart`, controller `_handleError`, `_ErrorBanner` |
| Auto‑reveal on completion | controller `_handleCompleted` + `AnimatedSwitcher` |
| Data‑driven quiz from JSON | `models/quiz_question.dart`, `assets/quiz.json` |
| Flexible 3–5 options | `_QuizView` option loop; tests in `quiz_question_test.dart` |
| Wrong → shake + haptic + retry | `widgets/option_card.dart`, screen `_nudge()` |
| Correct → confetti + smile + success | `_celebrate()`, `confetti`, `BuddyMood.happy` |
| State management | Provider + `state/story_buddy_controller.dart` |
| Performance / lightweight | `select`/`Selector`, `RepaintBoundary`, drawn art |

---

## E. Source data

**Story (narrated):**
> Once upon a time, a clever little robot named Pip lost his shiny blue gear in
> the Whispering Woods...

**Quiz (`assets/quiz.json`):**
```json
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
}
```
