# Third-party notices

PocketPane is an independent macOS front-end built on top of
[scrcpy](https://github.com/Genymobile/scrcpy) and Android Debug Bridge (ADB).
It is not affiliated with or endorsed by Google, Android, Genymobile, or the
scrcpy maintainers.

## scrcpy

- Project: [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy)
- Version bundled by the current build: 4.0
- Copyright: Genymobile and Romain Vimont
- License: [Apache License 2.0](https://github.com/Genymobile/scrcpy/blob/master/LICENSE)

The packaging script downloads the official macOS release from GitHub and
verifies its published SHA-256 checksum before embedding it. The upstream
license is included in the built app at
`Contents/Resources/Licenses/scrcpy-LICENSE.txt`.

The official scrcpy macOS archive also provides the ADB executable used by
PocketPane.

## Apple frameworks

PocketPane uses Swift, SwiftUI, AppKit, Foundation, and Uniform Type
Identifiers from the Apple SDK. Their use is governed by Apple's applicable
SDK and platform terms; they are not redistributed as third-party source code
in this repository.
