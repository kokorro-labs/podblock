# podblock

macOS daemon that automatically switches your default audio input away from AirPods to your preferred microphone.

When AirPods connect, macOS silently switches the input source to the AirPods mic. This daemon detects that and immediately switches it back — no manual intervention needed.

## How it works

- CoreAudio property listener — truly event-driven, 0% CPU when idle
- No permissions, entitlements, or code signing required
- Runs as a LaunchAgent for persistence across restarts

## Install

```bash
make install
```

This compiles the binary to `~/bin/`, installs a LaunchAgent, and starts the daemon.

## Uninstall

```bash
make uninstall
```

## Configuration

Set your preferred microphone via environment variable:

```bash
PODBLOCK_PREFERRED_INPUT="Your Mic Name"
```

The value is matched case-insensitively as a substring against device names. Edit `LaunchAgent/com.local.podblock.plist` to change it permanently.

## Logs

```bash
tail -f /tmp/podblock.log
```
