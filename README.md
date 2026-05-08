# Task Bubble Chrome Extension

I kept getting distracted and forgetting what I was doing so I vibe coded this Chrome extension to keep the task at hand visible.

## Features

- Minimal floating task bubble on all pages
- Bubble glides away when your cursor bumps into it
- One add-tasks field, with one task per line
- Separate queue and completed history panels
- Done shortcut that advances to the next queued task
- Draggable queue reordering with a handle
- Built-in timer with pause/resume support
- Gently pulsing active and paused status lights
- Local persistence using extension storage

## Default shortcuts

- Add tasks: `Ctrl+Shift+Y` (`Control+Shift+Y` on macOS)
- Toggle queue: `Ctrl+Shift+Q` (`Control+Shift+Q` on macOS)
- Toggle history: `Ctrl+Shift+H` (`Control+Shift+H` on macOS)
- Mark current task done: `Ctrl+Shift+D` (`Control+Shift+D` on macOS)
- Pause or resume timer: `Ctrl+Shift+P` (`Control+Shift+P` on macOS)

You can change all shortcuts in Chrome at:

`chrome://extensions/shortcuts`

## Setup and use right away

1. Open `chrome://extensions`
2. Enable **Developer mode**
3. Click **Load unpacked**
4. Select this folder

## Usage

- Click the extension icon or use the add shortcut to add tasks
- If there is no current task, the first added task becomes the active one
- Additional tasks go into the queue
- Use the queue shortcut to open the queued tasks panel
- Drag queued tasks with the handle to reorder them
- Use the history shortcut to open completed task history
- Use the done shortcut to mark the current task complete and pull in the next queued task
