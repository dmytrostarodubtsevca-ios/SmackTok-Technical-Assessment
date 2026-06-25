# Artwork Explorer

An iOS app for browsing and searching the [Art Institute of Chicago](https://api.artic.edu/docs/) public collection.

## Requirements

- Xcode 26.5 (build 17F42)
- iOS deployment target: 17.0
- Swift 6 (strict concurrency; default actor isolation left `nonisolated`)
- No third-party dependencies — everything uses the standard library, Foundation, SwiftUI, and Swift Testing.

## Build / Run / Test

```bash
# Open in Xcode
open Artwork.xcodeproj

# Run unit tests (offline — no network access required)
xcodebuild test \
  -project Artwork.xcodeproj \
  -scheme Artwork \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or just open the project and press ⌘R to run, ⌘U to test.

## Architecture

**MVVM with a protocol-abstracted data layer.** Dependencies point downward
through protocols only — View → ViewModel → Repository → Service — so every
layer is swappable and testable in isolation without a live network.

```
Models/       Pure value types: ArtworkModel (Codable), ArtworkPageModel
Networking/   ArtworkServiceProtocol + URLSession implementation, APIError, DTO
Repository/   ArtworkRepositoryProtocol — owns pagination + dedup state (@MainActor)
ViewModels/   ArtworkListViewModel (@MainActor, ViewState) + row/detail view models
Views/        SwiftUI screens, state views, CachedAsyncImage
Utilities/    ImageURLBuilder, ImageCache, Strings
```

| Layer | Owns | Knows about | Doesn't know |
|---|---|---|---|
| View | layout | the view model | URLs, page numbers, networking |
| ViewModel | presentation state (`ViewState`) | repository (protocol) | URLs, JSON, page math |
| Repository | pagination state, accumulated list | service (protocol) | URLs, decoding, SwiftUI |
| Service | nothing (stateless) | URLs + decoding | pagination, UI |

**Concurrency.** The stateful types (`ArtworkRepository`, `ArtworkListViewModel`)
are `@MainActor`, so their state is mutated on a single actor and data races are
structurally impossible. The `Service` is a stateless `Sendable` `struct` and
networking suspends off-main inside `await`, so the UI never blocks. Search is
debounced and cancellable via a retained `Task`.

**Testability.** `URLProtocolStub` lets the real `ArtworkService` be exercised
end-to-end (URL building → decoding → error mapping) with no network; the
repository and view models are tested against in-memory mocks. All tests run
offline.

### Pagination: infinite scroll vs. load more

Chose **infinite scroll**. For a browsing/exploration app it keeps a continuous
visual rhythm and lowers friction — the user keeps discovering without tapping.
The trade-off (less explicit user control, slightly trickier to test) is
mitigated by keeping all trigger logic in the repository/view model: the View
just reports "the last row appeared," and the repository's in-flight guard
absorbs the repeated `.onAppear` calls fast scrolling produces. The API reports
`total_pages`, so `canLoadMore` is exact and the footer spinner stops cleanly at
the end.

## Completed / Skipped / Next Steps

**Completed (core)**
- Paginated list with infinite scroll
- Search (debounced, cancellable)
- Explicit loading / empty / error states with retry
- Protocol-abstracted networking + repository
- Unit tests (service, repository, view models, cache) — all offline
- §4 code review (below)

**Completed (stretch)**
- Detail screen with IIIF image rendering (handles null `image_id`)
- Debounced search
- Accessibility — combined VoiceOver labels, Dynamic Type via semantic fonts
- Deliberate image caching (`NSCache` behind `ImageCaching`, `CachedAsyncImage`)

**Skipped (with reasoning)**
- **Rich detail via `/artworks/{id}`** — the detail screen reuses the data
  already in the list (no extra fetch). Fetching the fuller record (medium,
  dimensions, provenance, description) is a clear next step but adds a second
  endpoint, a stateful detail view model, and HTML handling — deferred to keep
  scope focused. See next steps.
- **Favorites + persistence** — needs a persistence decision (SwiftData vs.
  UserDefaults) and its own protocol/tests; more scope than signal here.
- **Full offline caching** — `NSCache` gives a warm in-memory image cache, but
  true offline (response cache + invalidation) is out of scope.

**Next steps**
- Add `fetchArtwork(id:)` + `ArtworkDetailModel` for a richer detail screen,
  with its own loading/error states and a sanitized `description`.
- Pull-to-refresh on the list.
- Favorites backed by SwiftData.
- Disk-backed image cache for cross-launch persistence.

## Assumptions

- `id` is the only guaranteed field; all descriptive fields are optional and
  render readable fallbacks ("Unknown artist", etc.).
- The IIIF base (`config.iiif_url`) is stable, so it's a verified constant rather
  than threaded through every layer.
- The API may re-list the same artwork across pages (its collection shifts during
  paging), so the repository dedupes by `id`.
- Page size of 20; widths 400 (thumbnail) / 843 (detail) for IIIF renditions.
- iOS 17 minimum (uses `ContentUnavailableView`, `NavigationStack`, `.searchable`).

## Code Review (§4)

The provided view model:

```swift
import SwiftUI
final class ArtworkListViewModel: ObservableObject {
    @Published private(set) var artworks: [Artwork] = []
    @Published private(set) var isLoading = false
    private let client: ArtworkClienting
    init(client: ArtworkClienting) {
        self.client = client
    }
    func search(_ query: String) {
        isLoading = true
        Task {
            let page = try! await client.search(query: query, page: 1)
            self.artworks = page.items
            self.isLoading = false
        }
    }
}
```

Issues, ordered worst-first (won't compile → crashes → races → logic).

> **AI disclosure:** when an LLM assisted with this review, it surfaced the
> concurrency and runtime bugs first and **initially missed the most obvious
> issue — `import SwiftUI` (#1)** — until a human reviewer pointed it out. It's
> listed first below because it's the first thing a careful reader notices, but
> it was the *last* thing the model flagged. A useful reminder that AI bias runs
> toward the "interesting" complex bugs and can walk right past a trivial one on
> line 1.

### Won't compile

1. **`import SwiftUI` on a view model.** The file uses zero SwiftUI types —
   `ObservableObject`/`@Published` come from **Combine**. Beyond the wrong
   import, it couples the business-logic layer to the UI framework, which breaks
   testability (test targets often don't link SwiftUI) and the point of MVVM
   layering. **Fix:** `import Combine`.

2. **Missing `any` on the existential.** `private let client: ArtworkClienting`
   uses a protocol as a type without `any`, a hard error since Swift 5.7
   (SE-0335). **Fix:** `private let client: any ArtworkClienting` (and the same
   in `init`).

3. **Non-`Sendable` `self` captured in `Task`.** `Task`'s closure is
   `@Sendable`; the class has no actor isolation, so capturing `self` to mutate
   it is a Swift 6 compile error. **Fix:** annotate the class `@MainActor`,
   which gives it isolation and satisfies the capture.

### Crashes / concurrency

4. **`try!` crashes on any failure.** A timeout, non-2xx response, or decode
   error force-unwraps and terminates the app. **Fix:** `do/catch` and surface
   an error state.

5. **Main-actor violation.** `@Published` properties are mutated inside a bare
   `Task` off the main thread; SwiftUI requires main-thread mutation.
   `@MainActor` on the class (see #3) fixes this too.

6. **`isLoading` never reset on failure.** Even with `try` instead of `try!`,
   `isLoading = false` sits *after* the throwing call, so on error it never
   runs and the spinner hangs forever. **Fix:** `defer { isLoading = false }`
   before the throwing call (or reset in `catch`).

7. **Race between concurrent searches.** Every keystroke spawns a new `Task`;
   the old one keeps running. A slower earlier request can resolve *after* a
   newer one and overwrite the correct results. **Fix:** retain the task and
   `cancel()` it before starting the next (plus debounce).

8. **Strong `self` capture / lifetime extension.** The `Task` retains `self`
   strongly, keeping the view model alive until the request finishes even after
   the view is gone. **Fix:** `[weak self]`.

### Logic

9. **Page hardcoded to `1`.** `search(query:query, page: 1)` ignores any
   pagination state, so "load more" is impossible. **Fix:** track and pass the
   current page.

10. **No empty-state distinction.** On no results, `artworks` is set to `[]` —
    identical to its initial value — so the UI can't tell "not loaded yet" from
    "loaded but empty." **Fix:** model state explicitly (e.g. a `ViewState`
    enum: `loading/loaded/empty/error`).

> This project's `ArtworkListViewModel` applies all ten fixes: `import Combine`,
> `@MainActor`, `any` existentials, `do/catch` with a `ViewState`, debounced and
> cancelled search via a retained `Task` with `[weak self]`, and pagination
> owned by the repository.

## AI Usage

An LLM coding assistant (Claude) was used throughout, with a human driving every
decision and reviewing all output. Specifically it was used for:

- **Planning** — turning the brief into a commit-by-commit plan (protocols →
  implementations → tests → view models → views → stretch).
- **Scaffolding code** — drafting models, protocols, the service/repository,
  view models, SwiftUI views, and the test suites, which were then reviewed,
  corrected, and adjusted by hand.
- **API exploration** — inspecting the live AIC responses to confirm the
  pagination shape, null `image_id`, and IIIF config.
- **The §4 review** — drafting the bug analysis.

Human review materially changed the result. Examples:

- The assistant **missed the `import SwiftUI` bug** in the §4 review until it was
  pointed out (see the disclosure note in [Code Review](#code-review-4)).
- Architecture decisions — dropping a redundant `refresh()` method in favour of a
  single `loadNextPage()`, fixing a spinner condition (`isLoadingNextPage` vs.
  `canLoadMore`), and resolving an actor-isolation mismatch — were human calls
  the assistant then implemented.

Rather than scatter per-line markers (nearly every file was AI-assisted, so
per-block tags would be noise), this section is the disclosure: the project was
built collaboratively with an LLM under human review and direction.
