# Manual setup todo

Settings `setup.sh` cannot apply. Values are what the previous laptop used (captured 2026-09-21, macOS 26.6.2).

## Before leaving the old laptop

- [ ] Export a fresh Raycast config (Raycast → Settings → Advanced → Export) and replace the `.rayconfig` in this repo. The saved one is from 7 Sep.
- [ ] Note the wallpaper shuffle interval in System Settings → Wallpaper. It could not be read from the command line.
- [ ] Check Night Shift and True Tone in System Settings → Displays. They could not be read either.

## Setup Assistant (first boot)

- [ ] Language: English (Australia). Region: Australia.
- [ ] Keyboard layout: Australian.
- [ ] Siri: off.
- [ ] FileVault: on.
- [ ] Sign in to the same Apple ID so iCloud restores text replacements.

## System Settings

- [ ] **Control Centre → menu bar items**: set Sound, Focus, Now Playing and Spotlight to "Don't show in Menu Bar". Visible items are Wi-Fi, Battery, Control Centre and Clock.
- [ ] **Keyboard → Text Replacements**: `@@` → your email address. Skip if iCloud already restored it.
- [ ] **Wallpaper**: choose the folder `~/Downloads/Wallpaper` (a rotating folder, not a single image).
- [ ] **Lock Screen**: require password **immediately** after the screen saver begins or the display turns off. Scriptable with `sysadminctl -screenLock immediate -password -`, which prompts for your password. JumpCloud may enforce it anyway.
- [ ] **Keyboard → Keyboard Shortcuts**: confirm Spotlight ⌘Space and the input source shortcuts are unticked (the script disables them), and check Dictation's shortcut is off.
- [ ] **Touch ID**: enrol fingerprints.
- [ ] **Notifications** and **Focus** schedules: set per app by eye.

## Apps

- [ ] **Raycast**: import the `.rayconfig` from this repo, then confirm its hotkey is ⌘Space.
- [ ] **Launch at login**, switched on inside each app: Raycast, Notion Calendar, Superwhisper, Shottr.
- [ ] **Open Unix executables with Ghostty**: Finder → Get Info on any Unix executable → Open with → Ghostty → Change All.
- [ ] **Arc**: open it once before running `setup.sh`, otherwise macOS cannot make it the default browser. Confirm the "Use Arc" dialog. Arc also handles `mailto:` links.
- [ ] **Privacy & Security permissions**, granted when each app asks: Accessibility, Screen Recording and Microphone for Raycast, Shottr, Superwhisper and Ghostty.

## After the first run of `setup.sh`

- [ ] Log out and back in so key repeat, scroll direction and automatic appearance take effect.
- [ ] Check the Dock shows Arc, Slack, Notion Calendar, Ghostty, Spotify, on the right, auto-hidden.
