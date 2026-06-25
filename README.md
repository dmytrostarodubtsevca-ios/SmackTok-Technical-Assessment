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

Analysis of the provided `ArtworkListViewModel`.

_TODO — list each production bug, why it's problematic, and the fix._

## AI Usage

Tools used and what each was used for.

- _TODO_

All AI-generated code blocks are marked inline with `// AI-ASSISTED: …` comments.
