---
description: Build, run WhisperPad and capture logs for debugging (project)
argument-hint: <fix-description> [timeout-seconds]
allowed-tools: Bash(xcodebuild build:*), Bash(find:*), Bash(log stream:*), Bash(log show:*), Bash(mise run:*), Bash(pkill:*), Bash(killall:*), Bash(open:*), Bash(cat:*), Bash(tail:*), Bash(wc:*), Bash(sleep:*), Bash(rm:*), Bash(touch:*), Read, Glob, Grep, Edit, Write, EnterPlanMode, AskUserQuestion
---

# Debug Run: WhisperPad

## User Request

Fix: $1

## Configuration

- Timeout: $2 seconds (default: 60 if not specified)
- Project: WhisperPad/WhisperPad.xcodeproj
- Scheme: WhisperPad
- Build Configuration: Debug
- Log File: /tmp/whisperpad-debug-logs.txt
- Bundle ID: com.r0227n.WhisperPad

## Instructions

You are debugging the WhisperPad macOS menu bar application. Follow these steps carefully:

### Step 1: Build the Application

Run xcodebuild to build the app in Debug configuration:

```bash
xcodebuild build \
  -project WhisperPad/WhisperPad.xcodeproj \
  -scheme WhisperPad \
  -configuration Debug \
  2>&1
```

If the build fails, analyze the error and suggest fixes before proceeding.

### Step 2: Prepare Environment

Stop any running instances and prepare log file:

```bash
# Stop existing instances
pkill -f "WhisperPad.app" 2>/dev/null || true
sleep 1

# Prepare log file
rm -f /tmp/whisperpad-debug-logs.txt
touch /tmp/whisperpad-debug-logs.txt
```

### Step 3: Start Log Capture (Background)

Start capturing logs in background:

```bash
log stream \
  --predicate 'subsystem CONTAINS "whisperpad" OR subsystem CONTAINS "com.r0227n.WhisperPad"' \
  --style compact \
  --level debug \
  > /tmp/whisperpad-debug-logs.txt 2>&1 &
echo $!
```

Save the returned PID for later cleanup.

### Step 4: Launch Application

Find and open the built app directly:

```bash
open "$(find ~/Library/Developer/Xcode/DerivedData -path "*/Build/Products/Debug/WhisperPad.app" 2>/dev/null | head -1)"
```

### Step 5: Wait for User Testing

Use AskUserQuestion to prompt:

- "テストが完了したら「完了」を選択してください"
- Options: "完了" / "ログを確認しながら継続"

If user wants to check logs while testing, show latest logs:

```bash
tail -20 /tmp/whisperpad-debug-logs.txt
```

### Step 6: Cleanup

After user confirms or timeout:

```bash
# Stop log stream (replace <PID> with the PID from Step 3)
kill <PID> 2>/dev/null || true

# Stop the application
pkill -f "WhisperPad.app" 2>/dev/null || true
killall WhisperPad 2>/dev/null || true
sleep 1
```

### Step 7: Analyze Captured Logs

Show log summary and content:

```bash
wc -l < /tmp/whisperpad-debug-logs.txt
```

```bash
cat /tmp/whisperpad-debug-logs.txt
```

If no logs captured, try:

```bash
log show --predicate 'subsystem CONTAINS "whisperpad"' --last 5m --style compact
```

### Step 8: Enter Plan Mode for Fixes

IMPORTANT: Before making any code changes, you MUST enter plan mode using the EnterPlanMode tool.

Based on the user's fix request ("$1") and the captured logs:

1. Identify relevant error messages, warnings, or unexpected behavior
2. Use EnterPlanMode to design the fix approach
3. In plan mode, search the codebase for related code using Grep and Read tools
4. Propose a detailed fix plan for user approval

### Step 9: Implement Fixes (After Plan Approval)

After the user approves your plan:

1. Implement the fixes following project conventions
2. Run `mise run lint:swift` to check for linting issues
3. Run `mise run format:swift` to format code
4. Optionally suggest re-running this debug command to verify the fix

## Key Files for Debugging

### Logging Categories in the Project

The app uses `os.log` with these subsystems/categories:

- `com.whisperpad` / `RecordingFeature`
- `com.whisperpad` / `TranscriptionFeature`
- `com.whisperpad` / `AudioRecorderClient`
- `com.whisperpad` / `AudioRecorderClientLive`
- `com.whisperpad` / `AudioRecorder`
- `com.whisperpad` / `OutputClient`
- `com.whisperpad` / `OutputClientLive`
- `com.whisperpad` / `TranscriptionClient`
- `com.whisperpad` / `TranscriptionClientLive`
- `com.whisperpad` / `TranscriptionService`
- `com.whisperpad` / `UserDefaultsClient`
- `com.whisperpad` / `UserDefaultsClientLive`
- `com.r0227n.WhisperPad` / `AppDelegate`

### Architecture Reference

- TCA-based architecture (swift-composable-architecture v1.23.1)
- Key reducer: AppReducer at `WhisperPad/WhisperPad/App/AppReducer.swift`
- Features: Recording, Transcription, Settings

### Key Directories

- `WhisperPad/WhisperPad/App/` - App entry points
- `WhisperPad/WhisperPad/Features/` - TCA feature modules
- `WhisperPad/WhisperPad/Clients/` - Dependency implementations
- `WhisperPad/WhisperPad/Models/` - Data models
