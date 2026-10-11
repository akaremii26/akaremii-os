# KWin Patches

This directory contains the reproducible KWin overlay used by the image.

## Base Source

The patch is pinned to KWin commit:

```text
ab7df7ccb7c6af20f4b279cd6220f7cd3d2267d7
```

That commit is the KWin `v6.7.5` tag (`effect/offscreenquickview: fix the
render time query`). It is the same commit that `files/scripts/build-kwin.sh`
fetches.

## Patches

### discrete-swipes.patch

Touchpad and touchscreen swipes become discrete: the bound command commits
synchronously once the initial direction is recognized (16 logical units of
movement), instead of tracking realtime progress and deciding at finger lift.

- Desktop switching runs the ordinary `Switch One Desktop Up/Down/Left/Right`
  actions at direction recognition. The old release-time threshold
  (`GESTURE_SWITCH_THRESHOLD`) and the realtime `currentChanging` offset
  tracking are gone; `gestureReleasedX/Y`, `currentChanging`, and
  `currentChangingCancelled` are kept only for SDK compatibility and are no
  longer emitted by swipes. Further motion, axis changes, or lifting the
  fingers cannot undo or repeat a committed switch.
- Effect gestures (overview, grid, ...) are registered through a new
  `EffectTogglableGesture::addSwipeGesture()` that hands `SwipeGesture`
  objects directly to the input layer; `RealtimeFeedbackSwipeShortcut`
  becomes `SwipeShortcut` and no longer carries a progress callback.
- The overview effect drops its realtime desktop-offset tracking
  (`desktopOffsetForScreen`, `m_screenDesktopOffsets`, and the QML
  `deltaX`/`deltaY` overrides).
- The QML scripting API loses `SwipeGestureHandler.progress` and
  `cancelled`; `activated` fires once on direction recognition.
- Ships with regression tests (`autotests/integration/discrete_swipes_test.cpp`
  plus updates to the existing gesture, touch, and virtual-desktop tests).
  They are not built by the image (`-DBUILD_TESTING=OFF`).

Touchpad vertical swipes (3 fingers) switch desktops, so overview/grid stay on
four-finger swipes; touchscreen vertical three-finger gestures are unchanged.

Upstream: <https://raw.githubusercontent.com/chiezkeik/nwin-wm/kwin-6.7.5-1.3/packaging/discrete-swipes.patch>

## Apply

```bash
git clone https://invent.kde.org/plasma/kwin.git
cd kwin
git checkout --detach ab7df7ccb7c6af20f4b279cd6220f7cd3d2267d7

git apply --check /path/to/laptop-bluefin/patches/kwin/discrete-swipes.patch
git apply /path/to/laptop-bluefin/patches/kwin/discrete-swipes.patch
```

The BlueBuild recipe builds KWin from source in a `containerfile` module, applies this patch, and installs the resulting files into the image.
