const broadcastToActiveTab = async (message) => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab?.id) return;

  try {
    await chrome.tabs.sendMessage(tab.id, message);
  } catch (error) {
    console.debug("Task Bubble message failed", error);
  }
};

chrome.commands.onCommand.addListener(async (command) => {
  if (command === "edit-task-bubble") {
    await broadcastToActiveTab({ type: "TASK_BUBBLE_OPEN_EDITOR" });
  }

  if (command === "toggle-task-history") {
    await broadcastToActiveTab({ type: "TASK_BUBBLE_TOGGLE_HISTORY" });
  }
});

chrome.action.onClicked.addListener(async () => {
  await broadcastToActiveTab({ type: "TASK_BUBBLE_OPEN_EDITOR" });
});
