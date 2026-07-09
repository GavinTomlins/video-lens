#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title video-lens
# @raycast.mode silent
# @raycast.argument1 {"type": "text", "placeholder": "YouTube URL (leave blank to use clipboard)", "optional": true}
# @raycast.argument2 {"type": "text", "placeholder": "Model (haiku/sonnet/opus, default: sonnet)", "optional": true}

# Optional parameters:
# @raycast.icon 📺
# @raycast.packageName iTerm

# Documentation:
# @raycast.description Summarise a YouTube video — opens Claude in iTerm2 and launches the HTML report in the browser

ytURL="$1"
if [[ -z "$ytURL" ]]; then
  ytURL="$(pbpaste)"
fi

if [[ ! "$ytURL" =~ ^https?://(www\.)?(youtube\.com|youtu\.be)/ ]]; then
  osascript -e "display dialog \"Invalid YouTube URL: $ytURL\" buttons {\"OK\"} default button 1"
  exit 1
fi

ytURL="$(printf '%s' "$ytURL" | tr -dc 'A-Za-z0-9/:?=&._%-')"

# Model aliases resolve to the current model of each tier — no dated IDs to rot
case "$2" in
  haiku|opus) modelId="$2" ;;
  *)          modelId="sonnet" ;;
esac

# Detect iTerm2 from bash, and keep the iTerm2 tell-block in a script that is
# only compiled when iTerm2 exists: AppleScript resolves `tell application
# "iTerm2"` terminology at compile time, so a machine without iTerm2 would hit
# a "Where is iTerm2?" locate prompt even if the branch never runs.
if pgrep -xq iTerm2 \
   || [ -d "/Applications/iTerm.app" ] || [ -d "$HOME/Applications/iTerm.app" ]; then
  osascript - "$ytURL" "$HOME/Downloads" "$modelId" <<'EOF'
on run argv
  set ytURL to item 1 of argv
  set outputDir to item 2 of argv
  set modelId to item 3 of argv
  set cmd to "cd " & quoted form of outputDir & " && claude --dangerously-skip-permissions --allowedTools \"Bash,Read\" --model " & modelId & " \"/video-lens " & ytURL & "\""

  tell application "iTerm2"
    activate

    if (count of windows) = 0 then
      set newWindow to (create window with default profile)
      tell current session of newWindow
        write text cmd
      end tell
    else
      tell current window
        create tab with default profile
        tell current session
          write text cmd
        end tell
      end tell
    end if

  end tell
end run
EOF
else
  osascript - "$ytURL" "$HOME/Downloads" "$modelId" <<'EOF'
on run argv
  set ytURL to item 1 of argv
  set outputDir to item 2 of argv
  set modelId to item 3 of argv
  set cmd to "cd " & quoted form of outputDir & " && claude --dangerously-skip-permissions --allowedTools \"Bash,Read\" --model " & modelId & " \"/video-lens " & ytURL & "\""

  tell application "Terminal"
    activate
    do script cmd
  end tell
end run
EOF
fi
