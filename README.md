# Task Bubble Chrome Extension

A small Chrome extension that keeps your current task visible in a translucent floating bubble on every page.

## Features

- Minimal floating task bubble on all pages
- Bubble glides away when your cursor bumps into it
- One add-tasks field, with one task per line
- Done shortcut that advances to the next queued task
- Draggable queue reordering with a handle
- Built-in timer with pause/resume support
- Hidden queue and completed-task history panel
- Local persistence using extension storage

## Default shortcuts

- Add tasks: `Ctrl+Shift+Y` (`Control+Shift+Y` on macOS)
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

- Click the extension icon or use the add shortcut to add tasks
- If there is no current task, the first added task becomes the active one
- Additional tasks go into the queue
- Drag queued tasks with the handle to reorder them
- Use the done shortcut to mark the current task complete and pull in the next queued task
- Use the history shortcut to open the queue and completed-task history panel
