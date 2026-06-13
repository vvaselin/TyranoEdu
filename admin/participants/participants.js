(function() {
  const { $, escapeHtml, setStatus } = window.AdminUI;
  const api = window.AdminAPI;
  const state = { profiles: [], selected: null, taskProgress: [] };

  function initPassword() {
    const input = $("admin-password");
    input.value = api.getPassword();
  }

  async function loadProfiles() {
    api.setPassword($("admin-password").value);
    if (!api.getPassword()) {
      setStatus("profile-status", "管理パスワードを入力してください", true);
      return;
    }
    setStatus("profile-status", "読み込み中...");
    try {
      const data = await api.fetchJSON("/api/admin/profiles");
      state.profiles = data.profiles || [];
      if (state.selected) {
        state.selected = state.profiles.find((p) => p.id === state.selected.id) || null;
      }
      renderProfiles();
      renderEditor();
      setStatus("profile-status", `${state.profiles.length}件`);
    } catch (error) {
      setStatus("profile-status", error.message, true);
    }
  }

  function renderProfiles() {
    $("profiles-body").innerHTML = state.profiles.map((p) => `
      <tr class="clickable ${state.selected && state.selected.id === p.id ? "selected" : ""}" data-user-id="${escapeHtml(p.id)}">
        <td title="${escapeHtml(p.participant_id || p.id)}">${escapeHtml(p.participant_id || "未完了")}</td>
        <td title="${escapeHtml(p.name)}">${escapeHtml(p.name)}</td>
        <td>${escapeHtml(p.role || "未割当")}</td>
        <td>${escapeHtml(p.love_level)}</td>
      </tr>
    `).join("");
    $("profiles-body").querySelectorAll("tr").forEach((row) => {
      row.addEventListener("click", () => {
        state.selected = state.profiles.find((p) => p.id === row.dataset.userId) || null;
        renderProfiles();
        loadTaskProgress();
      });
    });
  }

  async function loadTaskProgress() {
    if (!state.selected) return;
    setManageStatus("進捗読み込み中...");
    try {
      const params = new URLSearchParams();
      if (state.selected.participant_id) params.set("participant_id", state.selected.participant_id);
      else params.set("user_id", state.selected.id);
      const data = await api.fetchJSON(`/api/admin/task-progress?${params.toString()}`);
      state.taskProgress = data.task_progress || [];
      renderEditor();
      setManageStatus(`${state.taskProgress.length}件の進捗`);
    } catch (error) {
      state.taskProgress = [];
      renderEditor(error.message);
    }
  }

  function renderEditor(errorMessage) {
    const p = state.selected;
    if (!p) {
      $("editor-title").textContent = "参加者管理";
      $("editor-body").innerHTML = '<div class="empty">参加者を選択してください。</div>' + renderGlobalResetBlock();
      bindEditorEvents();
      return;
    }
    $("editor-title").textContent = `参加者管理: ${p.participant_id || "未完了"}`;
    const rows = state.taskProgress.map((row) => `
      <tr>
        <td title="${escapeHtml(row.task_id)}">${escapeHtml(row.task_id)}</td>
        <td><input class="tp-score" data-task="${escapeHtml(row.task_id)}" type="number" min="0" max="100" value="${escapeHtml(row.high_score)}"></td>
        <td><select class="tp-cleared" data-task="${escapeHtml(row.task_id)}"><option value="true" ${row.is_cleared ? "selected" : ""}>クリア</option><option value="false" ${!row.is_cleared ? "selected" : ""}>未クリア</option></select></td>
        <td><button class="secondary tp-save" data-task="${escapeHtml(row.task_id)}">保存</button></td>
      </tr>
    `).join("");
    $("editor-body").innerHTML = `
      ${errorMessage ? `<p class="error">${escapeHtml(errorMessage)}</p>` : ""}
      <div class="block">
        <h2>プロフィール</h2>
        <div class="kv">
          <div class="key">participant_id</div><div>${escapeHtml(p.participant_id || "未完了")}</div>
          <div class="key">user_id</div><div>${escapeHtml(p.id)}</div>
        </div>
        <div class="form-grid">
          <label for="manage-role">role</label>
          <select id="manage-role"><option value="experimental" ${p.role === "experimental" ? "selected" : ""}>experimental</option><option value="control" ${p.role === "control" ? "selected" : ""}>control</option></select>
          <label for="manage-name">name</label>
          <input id="manage-name" value="${escapeHtml(p.name)}">
          <label for="manage-love">love_level</label>
          <input id="manage-love" type="number" min="0" value="${escapeHtml(p.love_level)}">
        </div>
        <div class="actions"><button id="save-profile">プロフィールを保存</button></div>
      </div>
      <div class="block">
        <h3>task_progress</h3>
        <p class="note">既存行だけを編集します。行が無い課題は、参加者が採点した時に作成されます。</p>
        <div class="scroll task-progress-scroll">
          <table><thead><tr><th>task_id</th><th class="tp-score-col">high_score</th><th class="tp-state-col">状態</th><th class="tp-action-col"></th></tr></thead><tbody>${rows || '<tr><td colspan="4">進捗なし</td></tr>'}</tbody></table>
        </div>
      </div>
      <div class="block danger-zone">
        <h3>参加者削除</h3>
        <p class="note">関連データを削除します。未完了ユーザーは DELETE_INCOMPLETE と入力します。</p>
        <input id="delete-confirm" placeholder="${escapeHtml(p.participant_id || "DELETE_INCOMPLETE")} と入力" class="full-input">
        <div class="actions"><button class="danger" id="delete-user">この参加者を削除</button></div>
      </div>
      ${renderGlobalResetBlock()}
    `;
    bindEditorEvents();
  }

  function renderGlobalResetBlock() {
    return `
      <div class="block danger-zone">
        <h3>全体リセット</h3>
        <p class="note">実験前後のメンテナンス用です。実行前にCSV/JSONを保存してください。</p>
        <div class="form-grid">
          <label>進捗リセット</label><input id="reset-task-confirm" placeholder="RESET_TASK_PROGRESS">
          <label>ログリセット</label><input id="reset-events-confirm" placeholder="RESET_EXPERIMENT_EVENTS">
        </div>
        <div class="actions">
          <button class="warning" id="reset-task-progress">task_progress全リセット</button>
          <button class="danger" id="reset-events">experiment_events全リセット</button>
        </div>
      </div>`;
  }

  function bindEditorEvents() {
    const saveProfile = $("save-profile");
    if (saveProfile) saveProfile.addEventListener("click", saveSelectedProfile);
    document.querySelectorAll(".tp-save").forEach((btn) => btn.addEventListener("click", () => saveTaskProgress(btn.dataset.task)));
    const deleteUser = $("delete-user");
    if (deleteUser) deleteUser.addEventListener("click", deleteSelectedUser);
    const resetTask = $("reset-task-progress");
    if (resetTask) resetTask.addEventListener("click", resetTaskProgress);
    const resetEvents = $("reset-events");
    if (resetEvents) resetEvents.addEventListener("click", resetExperimentEvents);
  }

  async function saveSelectedProfile() {
    if (!state.selected) return;
    setManageStatus("保存中...");
    try {
      const loveLevel = parseInt($("manage-love").value, 10);
      await api.postJSON("/api/admin/profile/update", {
        user_id: state.selected.id,
        role: $("manage-role").value,
        name: $("manage-name").value.trim(),
        love_level: Number.isFinite(loveLevel) ? loveLevel : 0,
      });
      setManageStatus("保存完了");
      await loadProfiles();
    } catch (error) {
      setManageStatus(error.message, true);
    }
  }

  async function saveTaskProgress(taskId) {
    if (!state.selected) return;
    const score = parseInt(document.querySelector(`.tp-score[data-task="${CSS.escape(taskId)}"]`).value, 10);
    const cleared = document.querySelector(`.tp-cleared[data-task="${CSS.escape(taskId)}"]`).value === "true";
    setManageStatus("進捗保存中...");
    try {
      await api.postJSON("/api/admin/task-progress/update", {
        user_id: state.selected.id,
        task_id: taskId,
        high_score: Number.isFinite(score) ? score : 0,
        is_cleared: cleared,
      });
      setManageStatus("進捗保存完了");
      await loadTaskProgress();
    } catch (error) {
      setManageStatus(error.message, true);
    }
  }

  async function deleteSelectedUser() {
    if (!state.selected) return;
    setManageStatus("削除中...");
    try {
      await api.postJSON("/api/admin/user/delete", {
        user_id: state.selected.id,
        participant_id: state.selected.participant_id || "",
        confirm: $("delete-confirm").value.trim().toUpperCase(),
      });
      state.selected = null;
      state.taskProgress = [];
      await loadProfiles();
      setManageStatus("削除完了");
    } catch (error) {
      setManageStatus(error.message, true);
    }
  }

  async function resetTaskProgress() {
    setManageStatus("task_progressリセット中...");
    try {
      await api.postJSON("/api/admin/reset/task-progress", { confirm: $("reset-task-confirm").value.trim() });
      state.taskProgress = [];
      renderEditor();
      setManageStatus("task_progressリセット完了");
    } catch (error) {
      setManageStatus(error.message, true);
    }
  }

  async function resetExperimentEvents() {
    setManageStatus("experiment_eventsリセット中...");
    try {
      await api.postJSON("/api/admin/reset/experiment-events", { confirm: $("reset-events-confirm").value.trim() });
      setManageStatus("experiment_eventsリセット完了");
      await loadProfiles();
    } catch (error) {
      setManageStatus(error.message, true);
    }
  }

  function setManageStatus(text, isError) {
    setStatus("manage-status", text, isError);
  }

  function bindEvents() {
    $("load-profiles").addEventListener("click", loadProfiles);
    $("admin-password").addEventListener("keydown", (event) => {
      if (event.key === "Enter") loadProfiles();
    });
  }

  initPassword();
  bindEvents();
})();
