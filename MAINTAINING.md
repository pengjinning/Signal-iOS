Apart from the general `BUILDING.md` there are certain things that have
to be done by Signal-iOS maintainers.

For transparency and bus factor, they are outlined here.

## Dependencies

Keeping cocoapods based dependencies is easy enough.

`pod update`

Similarly, Carthage dependencies can be updated like so:

`carthage update`

WebRTC updates are managed separately and manually based on
https://github.com/WhisperSystems/signal-webrtc-ios

## Translations

Read more about translations in [TRANSLATIONS.md](signal/translations/TRANSLATIONS.md)
