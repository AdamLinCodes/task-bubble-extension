# Task Bubble Chrome Extension

A small Chrome extension that keeps your current task visible in a translucent floating bubble on every page.

## Features

- Minimal floating task bubble on all pages
- Bubble glides away when your cursor bumps into it
- Keyboard shortcut to edit the current task
- Queue support for upcoming tasks
- Done shortcut that advances to the next queued task
- Built-in timer with pause/resume support
- Hidden queue and completed-task history panel
- Local persistence using extension storage

## Default shortcuts

- Edit task: `Ctrl+Shift+Y` (`Control+Shift+Y` on macOS)
- Toggle history and queue: `Ctrl+Shift+J` (`Control+Shift+J` on macOS)
- Mark current task done: `Ctrl+Shift+D` (`Control+Shift+D` on macOS)
- Pause or resume timer: `Ctrl+Shift+P` (`Control+Shift+P` on macOS)

You can change all shortcuts in Chrome at:

`chrome://extensions/shortcuts`

## Install locally

1. Open `chrome://extensions`
2. Enable **Developer mode**
3. Click **Load unpacked**
4. Select this folder

## Usage

- Click the extension icon or use the edit shortcut to update the current task
- Add future tasks in the queue box, one per line
- Use the done shortcut to mark the current task complete and pull in the next queued task
- Use the history shortcut to open the queue and completed-task history panel
- Click a completed task to reuse it
