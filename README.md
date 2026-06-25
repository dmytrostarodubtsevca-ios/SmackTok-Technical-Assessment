# Artwork Explorer

An iOS app for browsing and searching the [Art Institute of Chicago](https://api.artic.edu/docs/) public collection.

> **Status:** in progress — see [Completed / Skipped / Next Steps](#completed--skipped--next-steps).

## Requirements

- Xcode: _TODO (e.g. 16.x)_
- iOS deployment target: 17.0
- Swift: 6.0 (strict concurrency enabled)
- No third-party dependencies.

## Build / Run / Test

```bash
# Open in Xcode
open Artwork.xcodeproj

# Run unit tests (offline — no network access required)
xcodebuild test \
  -project Artwork.xcodeproj \
  -scheme Artwork \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture

_TODO — MVVM + protocol-abstracted data layer._

```
Domain/       Pure models (Artwork, ArtworkPage)
Networking/   ArtworkServiceProtocol + URLSession implementation
Repository/   ArtworkRepositoryProtocol — owns pagination state
ViewModels/   ArtworkListViewModel (@MainActor, ViewState)
Views/        SwiftUI screens + state views
Utilities/    Helpers (image cache, URLProtocol stub for tests)
```

Every layer depends only on protocols, never concrete types — so each is swappable and testable in isolation without a live network.

### Pagination: infinite scroll vs. load more

_TODO — justify the choice._

## Completed / Skipped / Next Steps

**Completed**
- _TODO_

**Skipped (with reasoning)**
- _TODO_

**Next steps**
- _TODO_

## Assumptions

- _TODO_

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

Tools used and what each was used for.

- _TODO_

All AI-generated code blocks are marked inline with `// AI-ASSISTED: …` comments.
