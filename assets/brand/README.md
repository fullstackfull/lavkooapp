# Brand assets

The full lockup, in colour and in white, as vector masters. Kept in the
repository so the marks that go on store listings, decks and print come from one
place — **not bundled into the app**: `pubspec.yaml` declares `assets/launch/`
only, and Launch Experience 3A uses the butterfly and the sparkle, never the
lockup.

Export a raster from these when a store or a print job asks for one, at whatever
size it asks for:

    rsvg-convert -w 2048 -b none lockup_color.svg -o lockup_color.png

The butterfly and the sparkle the launch sequence uses live in `assets/launch/`,
also as vectors, and the app draws them directly. The native splash screens
cannot draw a vector, so their PNGs are rendered per density by
`tool/generate_launch_assets.sh` — run it whenever a master changes.
