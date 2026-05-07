const STORAGE_KEYS = {
  task: "taskBubble.currentTask",
  queue: "taskBubble.queue",
  history: "taskBubble.history",
  corner: "taskBubble.corner",
  timer: "taskBubble.timer",
};

const CORNERS = ["top-left", "top-right", "bottom-left", "bottom-right"];
const EDGE_MARGIN = 12;
const MAX_HISTORY = 50;
const MAX_QUEUE = 50;
const MOVE_COOLDOWN_MS = 900;
const MOVE_DURATION_MS = 960;

const state = {
  currentTask: "",
  queue: [],
  history: [],
  activeCorner: CORNERS[1],
  isEditorOpen: false,
  isHistoryOpen: false,
  isMoving: false,
  lastMoveAt: 0,
  timerStartedAt: null,
  timerAccumulatedMs: 0,
  timerIsRunning: false,
  timerIntervalId: null,
};

const storage = {
  async get(keys) {
    return chrome.storage.local.get(keys);
  },
  async set(values) {
    return chrome.storage.local.set(values);
  },
};

const root = document.createElement("div");
root.id = "task-bubble-root";
document.documentElement.appendChild(root);

root.innerHTML = `
  <div class="task-bubble-shell" aria-live="polite">
    <div class="task-bubble-card">
      <div class="task-bubble-body">
        <div class="task-bubble-task-row">
          <span class="task-bubble-status-dot"></span>
          <div class="task-bubble-task"></div>
        </div>
        <div class="task-bubble-timer-row">
          <span class="task-bubble-timer"></span>
          <span class="task-bubble-queue-count"></span>
        </div>
      </div>
      <div class="task-bubble-panel task-bubble-editor-panel">
        <div class="task-bubble-panel-title">Add tasks</div>
        <textarea class="task-bubble-textarea task-bubble-queue-input" placeholder="One task per line"></textarea>
        <div class="task-bubble-shortcuts">
          Add: Ctrl/Cmd+Enter · History: Ctrl/Cmd+Shift+J · Done: Ctrl/Cmd+Shift+D · Pause timer: Ctrl/Cmd+Shift+P
        </div>
      </div>
      <div class="task-bubble-panel task-bubble-history-panel">
        <div class="task-bubble-history-section">
          <div class="task-bubble-panel-title">Up next</div>
          <div class="task-bubble-queue-list"></div>
        </div>
        <div class="task-bubble-history-section">
          <div class="task-bubble-panel-title">Completed</div>
          <div class="task-bubble-history-list"></div>
        </div>
      </div>
    </div>
  </div>
`;

const shell = root.querySelector(".task-bubble-shell");
const taskEl = root.querySelector(".task-bubble-task");
const statusDotEl = root.querySelector(".task-bubble-status-dot");
const timerEl = root.querySelector(".task-bubble-timer");
const queueCountEl = root.querySelector(".task-bubble-queue-count");
const editorPanel = root.querySelector(".task-bubble-editor-panel");
const historyPanel = root.querySelector(".task-bubble-history-panel");
const queueInput = root.querySelector(".task-bubble-queue-input");
const historyList = root.querySelector(".task-bubble-history-list");
const queueList = root.querySelector(".task-bubble-queue-list");

const nowIso = () => new Date().toISOString();

const formatDuration = (ms) => {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  }

  return `${minutes}:${String(seconds).padStart(2, "0")}`;
};

const getElapsedMs = () => {
  if (!state.timerIsRunning || !state.timerStartedAt) {
    return state.timerAccumulatedMs;
  }

  return state.timerAccumulatedMs + (Date.now() - state.timerStartedAt);
};

const persistTimer = async () => {
  await storage.set({
    [STORAGE_KEYS.timer]: {
      startedAt: state.timerStartedAt,
      accumulatedMs: state.timerAccumulatedMs,
      isRunning: state.timerIsRunning,
    },
  });
};

const renderTimer = () => {
  const hasTask = Boolean(state.currentTask.trim());
  const prefix = state.timerIsRunning ? "Working" : "Paused";
  timerEl.textContent = `${prefix} ${formatDuration(getElapsedMs())}`;

  statusDotEl.classList.toggle("is-active", hasTask && state.timerIsRunning);
  statusDotEl.classList.toggle("is-paused", hasTask && !state.timerIsRunning);
  statusDotEl.classList.toggle("is-idle", !hasTask);
};

const startTicker = () => {
  if (state.timerIntervalId) return;
  state.timerIntervalId = window.setInterval(renderTimer, 1000);
};

const stopTicker = () => {
  if (!state.timerIntervalId) return;
  window.clearInterval(state.timerIntervalId);
  state.timerIntervalId = null;
};

const startTimerForCurrentTask = async () => {
  state.timerAccumulatedMs = 0;
  state.timerStartedAt = Date.now();
  state.timerIsRunning = Boolean(state.currentTask.trim());
  renderTimer();
  if (state.timerIsRunning) {
    startTicker();
  } else {
    stopTicker();
  }
  await persistTimer();
};

const pauseResumeTimer = async () => {
  if (!state.currentTask.trim()) return;

  if (state.timerIsRunning && state.timerStartedAt) {
    state.timerAccumulatedMs = getElapsedMs();
    state.timerStartedAt = null;
    state.timerIsRunning = false;
    stopTicker();
  } else {
    state.timerStartedAt = Date.now();
    state.timerIsRunning = true;
    startTicker();
  }

  renderTimer();
  await persistTimer();
};

const renderTask = () => {
  if (!state.currentTask.trim()) {
    taskEl.textContent = "No task set";
    taskEl.classList.add("task-bubble-empty");
  } else {
    taskEl.textContent = state.currentTask;
    taskEl.classList.remove("task-bubble-empty");
  }

  queueCountEl.textContent = state.queue.length ? `${state.queue.length} queued` : "";
};

const saveHistoryEntry = async (entry) => {
  const nextHistory = [entry, ...state.history].slice(0, MAX_HISTORY);
  state.history = nextHistory;
  await storage.set({ [STORAGE_KEYS.history]: nextHistory });
};

const persistQueue = async () => {
  await storage.set({ [STORAGE_KEYS.queue]: state.queue.slice(0, MAX_QUEUE) });
};

const renderQueue = () => {
  queueList.innerHTML = "";

  if (!state.queue.length) {
    const empty = document.createElement("div");
    empty.className = "task-bubble-history-empty";
    empty.textContent = "Nothing queued.";
    queueList.appendChild(empty);
    return;
  }

  state.queue.forEach((task, index) => {
    const item = document.createElement("div");
    item.className = "task-bubble-list-item";
    item.draggable = true;
    item.dataset.index = String(index);

    item.addEventListener("dragstart", (event) => {
      item.classList.add("is-dragging");
      event.dataTransfer?.setData("text/plain", String(index));
      if (event.dataTransfer) {
        event.dataTransfer.effectAllowed = "move";
      }
    });

    item.addEventListener("dragend", () => {
      item.classList.remove("is-dragging");
      queueList.querySelectorAll(".is-drop-target").forEach((el) => el.classList.remove("is-drop-target"));
    });

    item.addEventListener("dragover", (event) => {
      event.preventDefault();
      if (event.dataTransfer) {
        event.dataTransfer.dropEffect = "move";
      }
      item.classList.add("is-drop-target");
    });

    item.addEventListener("dragleave", () => {
      item.classList.remove("is-drop-target");
    });

    item.addEventListener("drop", async (event) => {
      event.preventDefault();
      item.classList.remove("is-drop-target");
      const fromIndex = Number(event.dataTransfer?.getData("text/plain"));
      const toIndex = index;
      if (Number.isNaN(fromIndex) || fromIndex === toIndex || fromIndex < 0 || fromIndex >= state.queue.length) {
        return;
      }
      const [movedTask] = state.queue.splice(fromIndex, 1);
      state.queue.splice(toIndex, 0, movedTask);
      renderQueue();
      await persistQueue();
    });

    const dragHandle = document.createElement("div");
    dragHandle.className = "task-bubble-drag-handle";
    dragHandle.textContent = "☰";
    dragHandle.setAttribute("aria-label", "Drag to reorder task");
    dragHandle.title = "Drag to reorder";

    const text = document.createElement("button");
    text.type = "button";
    text.className = "task-bubble-history-entry";
    text.textContent = task;
    text.addEventListener("click", async () => {
      state.queue.splice(index, 1);
      if (state.currentTask.trim()) {
        state.queue.unshift(state.currentTask);
      }
      state.currentTask = task;
      renderTask();
      renderQueue();
      await persistQueue();
      await storage.set({ [STORAGE_KEYS.task]: state.currentTask });
      await startTimerForCurrentTask();
      closeHistory();
    });

    item.append(dragHandle, text);
    queueList.appendChild(item);
  });
};

const renderHistory = () => {
  historyList.innerHTML = "";

  if (!state.history.length) {
    const empty = document.createElement("div");
    empty.className = "task-bubble-history-empty";
    empty.textContent = "Nothing completed yet.";
    historyList.appendChild(empty);
    return;
  }

  state.history.forEach((entry, index) => {
    const item = document.createElement("div");
    item.className = "task-bubble-list-item";

    const content = document.createElement("div");
    content.className = "task-bubble-history-entry task-bubble-history-entry-block task-bubble-history-static";
    content.innerHTML = `
      <div class="task-bubble-completed-title">${entry.text}</div>
      <span class="task-bubble-history-meta">${formatDuration(entry.elapsedMs || 0)} · ${new Date(entry.savedAt).toLocaleString()}</span>
    `;

    const deleteButton = document.createElement("button");
    deleteButton.type = "button";
    deleteButton.className = "task-bubble-mini-button";
    deleteButton.textContent = "×";
    deleteButton.setAttribute("aria-label", "Delete completed task");
    deleteButton.addEventListener("click", async () => {
      state.history.splice(index, 1);
      renderHistory();
      await storage.set({ [STORAGE_KEYS.history]: state.history });
    });

    item.append(content, deleteButton);
    historyList.appendChild(item);
  });
};

const getCornerPosition = (corner) => {
  const rect = shell.getBoundingClientRect();
  const bubbleWidth = rect.width || 280;
  const bubbleHeight = rect.height || 120;
  const maxLeft = Math.max(EDGE_MARGIN, window.innerWidth - bubbleWidth - EDGE_MARGIN);
  const maxTop = Math.max(EDGE_MARGIN, window.innerHeight - bubbleHeight - EDGE_MARGIN);

  switch (corner) {
    case "top-left":
      return { top: EDGE_MARGIN, left: EDGE_MARGIN };
    case "top-right":
      return { top: EDGE_MARGIN, left: maxLeft };
    case "bottom-left":
      return { top: maxTop, left: EDGE_MARGIN };
    case "bottom-right":
    default:
      return { top: maxTop, left: maxLeft };
  }
};

const applyCorner = async (corner) => {
  const position = getCornerPosition(corner);
  shell.style.top = `${position.top}px`;
  shell.style.left = `${position.left}px`;
  state.activeCorner = corner;
  await storage.set({ [STORAGE_KEYS.corner]: corner });
};

const moveToRandomCorner = async () => {
  if (state.isMoving) return;

  state.isMoving = true;
  state.lastMoveAt = Date.now();
  shell.classList.add("is-gliding");

  const candidates = CORNERS.filter((corner) => corner !== state.activeCorner);
  const nextCorner = candidates[Math.floor(Math.random() * candidates.length)] || CORNERS[0];
  await applyCorner(nextCorner);

  window.setTimeout(() => {
    state.isMoving = false;
    shell.classList.remove("is-gliding");
  }, MOVE_DURATION_MS);
};

const ensurePanelVisible = async () => {
  const rect = shell.getBoundingClientRect();
  const overflowBottom = rect.bottom - window.innerHeight;
  const overflowTop = EDGE_MARGIN - rect.top;

  if (overflowBottom > 0) {
    shell.style.top = `${Math.max(EDGE_MARGIN, rect.top - overflowBottom - EDGE_MARGIN)}px`;
    shell.style.left = `${rect.left}px`;
  } else if (overflowTop > 0) {
    shell.style.top = `${EDGE_MARGIN}px`;
    shell.style.left = `${rect.left}px`;
  }
};

const openEditor = async () => {
  state.isEditorOpen = true;
  state.isHistoryOpen = false;
  editorPanel.classList.add("open");
  historyPanel.classList.remove("open");
  queueInput.value = "";
  await ensurePanelVisible();
  requestAnimationFrame(() => {
    queueInput.focus();
    queueInput.select();
  });
};

const closeEditor = () => {
  state.isEditorOpen = false;
  editorPanel.classList.remove("open");
};

const openHistory = async () => {
  state.isHistoryOpen = true;
  state.isEditorOpen = false;
  historyPanel.classList.add("open");
  editorPanel.classList.remove("open");
  renderQueue();
  renderHistory();
  await ensurePanelVisible();
};

const closeHistory = () => {
  state.isHistoryOpen = false;
  historyPanel.classList.remove("open");
};

const toggleHistory = async () => {
  if (state.isHistoryOpen) {
    closeHistory();
    return;
  }

  await openHistory();
};

const parseQueueInput = () =>
  queueInput.value
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);

const saveTask = async () => {
  const nextQueuedTasks = parseQueueInput();

  if (!nextQueuedTasks.length) {
    closeEditor();
    return;
  }

  if (!state.currentTask.trim()) {
    const [firstTask, ...remainingTasks] = nextQueuedTasks;
    state.currentTask = firstTask;
    state.queue = [...remainingTasks, ...state.queue].slice(0, MAX_QUEUE);
    await storage.set({ [STORAGE_KEYS.task]: state.currentTask });
    await persistQueue();
    await startTimerForCurrentTask();
  } else {
    state.queue = [...state.queue, ...nextQueuedTasks].slice(0, MAX_QUEUE);
    await persistQueue();
  }

  renderTask();
  renderQueue();
  closeEditor();
};

const completeCurrentTask = async () => {
  if (!state.currentTask.trim()) return;

  await saveHistoryEntry({
    text: state.currentTask,
    savedAt: nowIso(),
    elapsedMs: getElapsedMs(),
  });

  const nextTask = state.queue.shift() || "";
  state.currentTask = nextTask;
  renderTask();
  renderQueue();
  renderHistory();

  await Promise.all([
    storage.set({ [STORAGE_KEYS.task]: state.currentTask }),
    persistQueue(),
  ]);

  await startTimerForCurrentTask();
};

const initialize = async () => {
  const stored = await storage.get([
    STORAGE_KEYS.task,
    STORAGE_KEYS.queue,
    STORAGE_KEYS.history,
    STORAGE_KEYS.corner,
    STORAGE_KEYS.timer,
  ]);

  state.currentTask = stored[STORAGE_KEYS.task] || "";
  state.queue = stored[STORAGE_KEYS.queue] || [];
  state.history = stored[STORAGE_KEYS.history] || [];
  state.activeCorner = stored[STORAGE_KEYS.corner] || CORNERS[1];

  const timer = stored[STORAGE_KEYS.timer] || {};
  state.timerStartedAt = timer.startedAt ? new Date(timer.startedAt).getTime() : null;
  state.timerAccumulatedMs = timer.accumulatedMs || 0;
  state.timerIsRunning = Boolean(timer.isRunning && state.currentTask.trim());

  await applyCorner(state.activeCorner);
  renderTask();
  renderQueue();
  renderHistory();
  renderTimer();

  if (state.timerIsRunning) {
    startTicker();
  }
};

window.addEventListener("resize", () => {
  applyCorner(state.activeCorner);
});

window.addEventListener("mousemove", async (event) => {
  if (state.isEditorOpen || state.isHistoryOpen || state.isMoving) return;
  if (Date.now() - state.lastMoveAt < MOVE_COOLDOWN_MS) return;

  const rect = shell.getBoundingClientRect();
  const padding = 14;
  const insideX = event.clientX >= rect.left - padding && event.clientX <= rect.right + padding;
  const insideY = event.clientY >= rect.top - padding && event.clientY <= rect.bottom + padding;

  if (insideX && insideY) {
    await moveToRandomCorner();
  }
});

queueInput.addEventListener("keydown", async (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
    event.preventDefault();
    await saveTask();
    return;
  }

  if (event.key === "Escape") {
    closeEditor();
  }
});

chrome.runtime.onMessage.addListener((message) => {
  if (message?.type === "TASK_BUBBLE_OPEN_EDITOR") {
    openEditor();
  }

  if (message?.type === "TASK_BUBBLE_TOGGLE_HISTORY") {
    toggleHistory();
  }

  if (message?.type === "TASK_BUBBLE_COMPLETE_TASK") {
    completeCurrentTask();
  }

  if (message?.type === "TASK_BUBBLE_TOGGLE_TIMER") {
    pauseResumeTimer();
  }
});

initialize();
