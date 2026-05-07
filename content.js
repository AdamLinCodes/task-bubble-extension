const STORAGE_KEYS = {
  task: "taskBubble.currentTask",
  history: "taskBubble.history",
  corner: "taskBubble.corner",
};

const CORNERS = [
  "corner-top-left",
  "corner-top-right",
  "corner-bottom-left",
  "corner-bottom-right",
];

const MAX_HISTORY = 25;

const state = {
  currentTask: "",
  history: [],
  activeCorner: CORNERS[1],
  isEditorOpen: false,
  isHistoryOpen: false,
  isMoving: false,
  lastMoveAt: 0,
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
  <div class="task-bubble-shell ${state.activeCorner}">
    <div class="task-bubble-card">
      <div class="task-bubble-header">
        <div class="task-bubble-title">Current task</div>
        <div class="task-bubble-actions">
          <button class="task-bubble-button" data-action="edit">Edit</button>
          <button class="task-bubble-button" data-action="history">History</button>
        </div>
      </div>
      <div class="task-bubble-body">
        <div class="task-bubble-task"></div>
        <div class="task-bubble-tip">If your cursor bumps into it, it glides to another corner.</div>
      </div>
      <div class="task-bubble-panel task-bubble-editor-panel">
        <textarea class="task-bubble-textarea" placeholder="Finish finding jobs"></textarea>
        <div class="task-bubble-row">
          <button class="task-bubble-button task-bubble-cancel" data-action="cancel">Cancel</button>
          <button class="task-bubble-button task-bubble-save" data-action="save">Save</button>
        </div>
      </div>
      <div class="task-bubble-panel task-bubble-history-panel">
        <div class="task-bubble-history-list"></div>
      </div>
    </div>
  </div>
`;

const shell = root.querySelector(".task-bubble-shell");
const taskEl = root.querySelector(".task-bubble-task");
const editorPanel = root.querySelector(".task-bubble-editor-panel");
const historyPanel = root.querySelector(".task-bubble-history-panel");
const textarea = root.querySelector(".task-bubble-textarea");
const historyList = root.querySelector(".task-bubble-history-list");

const saveHistoryEntry = async (taskText) => {
  const trimmed = taskText.trim();
  if (!trimmed) return;

  const nextHistory = [
    {
      text: trimmed,
      savedAt: new Date().toISOString(),
    },
    ...state.history.filter((entry) => entry.text !== trimmed),
  ].slice(0, MAX_HISTORY);

  state.history = nextHistory;
  await storage.set({ [STORAGE_KEYS.history]: nextHistory });
};

const renderTask = () => {
  if (!state.currentTask.trim()) {
    taskEl.textContent = "No task yet. Use Edit or the keyboard shortcut.";
    taskEl.classList.add("task-bubble-empty");
    return;
  }

  taskEl.textContent = state.currentTask;
  taskEl.classList.remove("task-bubble-empty");
};

const renderHistory = () => {
  historyList.innerHTML = "";

  if (!state.history.length) {
    const empty = document.createElement("div");
    empty.className = "task-bubble-history-empty";
    empty.textContent = "No saved tasks yet.";
    historyList.appendChild(empty);
    return;
  }

  state.history.forEach((entry) => {
    const row = document.createElement("div");
    row.className = "task-bubble-history-item";

    const button = document.createElement("button");
    button.className = "task-bubble-history-entry";
    button.type = "button";
    button.innerHTML = `
      <div>${entry.text}</div>
      <span class="task-bubble-history-meta">${new Date(entry.savedAt).toLocaleString()}</span>
    `;
    button.addEventListener("click", async () => {
      state.currentTask = entry.text;
      renderTask();
      closeHistory();
      await storage.set({ [STORAGE_KEYS.task]: state.currentTask });
    });

    row.appendChild(button);
    historyList.appendChild(row);
  });
};

const applyCorner = async (corner) => {
  shell.classList.remove(...CORNERS);
  shell.classList.add(corner);
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
  }, 560);
};

const openEditor = () => {
  state.isEditorOpen = true;
  state.isHistoryOpen = false;
  editorPanel.classList.add("open");
  historyPanel.classList.remove("open");
  textarea.value = state.currentTask;
  requestAnimationFrame(() => {
    textarea.focus();
    textarea.select();
  });
};

const closeEditor = () => {
  state.isEditorOpen = false;
  editorPanel.classList.remove("open");
};

const openHistory = () => {
  state.isHistoryOpen = true;
  state.isEditorOpen = false;
  historyPanel.classList.add("open");
  editorPanel.classList.remove("open");
  renderHistory();
};

const closeHistory = () => {
  state.isHistoryOpen = false;
  historyPanel.classList.remove("open");
};

const toggleHistory = () => {
  if (state.isHistoryOpen) {
    closeHistory();
    return;
  }

  openHistory();
};

const saveTask = async () => {
  const nextTask = textarea.value.trim();
  state.currentTask = nextTask;
  renderTask();
  closeEditor();
  await storage.set({ [STORAGE_KEYS.task]: nextTask });
  await saveHistoryEntry(nextTask);
};

const initialize = async () => {
  const stored = await storage.get([STORAGE_KEYS.task, STORAGE_KEYS.history, STORAGE_KEYS.corner]);
  state.currentTask = stored[STORAGE_KEYS.task] || "";
  state.history = stored[STORAGE_KEYS.history] || [];
  state.activeCorner = stored[STORAGE_KEYS.corner] || CORNERS[1];
  await applyCorner(state.activeCorner);
  renderTask();
  renderHistory();
};

root.addEventListener("click", async (event) => {
  const button = event.target.closest("[data-action]");
  if (button) {
    const action = button.getAttribute("data-action");

    if (action === "edit") {
      openEditor();
      return;
    }

    if (action === "history") {
      toggleHistory();
      return;
    }

    if (action === "cancel") {
      closeEditor();
      return;
    }

    if (action === "save") {
      await saveTask();
      return;
    }
  }
});

window.addEventListener("mousemove", async (event) => {
  if (state.isEditorOpen || state.isHistoryOpen || state.isMoving) {
    return;
  }

  if (Date.now() - state.lastMoveAt < 900) {
    return;
  }

  const rect = shell.getBoundingClientRect();
  const padding = 14;
  const insideX = event.clientX >= rect.left - padding && event.clientX <= rect.right + padding;
  const insideY = event.clientY >= rect.top - padding && event.clientY <= rect.bottom + padding;

  if (insideX && insideY) {
    await moveToRandomCorner();
  }
});

textarea.addEventListener("keydown", async (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
    event.preventDefault();
    await saveTask();
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
});

initialize();
