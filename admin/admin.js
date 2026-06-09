const state = {
  password: "",
  profiles: [],
  rawEvents: [],
  analysisEvents: [],
  taskProgress: [],
  selectedParticipantId: "",
  selectedEventId: "",
  selectedProfile: null,
};

const EVENT_META = {
  session: { label: "セッション開始", color: "#64748b" },
  lecture: { label: "エピソード", color: "#ea7a12" },
  chat: { label: "会話", color: "#2563eb" },
  execute: { label: "実行", color: "#0f9f6e" },
  grade: { label: "採点", color: "#7c3aed" },
  love: { label: "親密度変化", color: "#dc2626" },
  code: { label: "コード保存", color: "#6b7280" },
  screen: { label: "画面移動", color: "#94a3b8" },
  other: { label: "その他", color: "#475569" },
};

const RAW_LABELS = {
  session_start: "セッション開始",
  lecture_view: "エピソード閲覧",
  chat_user_payload: "会話送信",
  chat_ai_response: "AI応答",
  execute_start: "実行開始",
  execute_result: "実行結果",
  grade_start: "採点開始",
  grade_result: "採点結果",
  code_snapshot: "コード保存",
  love_change: "親密度変化",
  screen_transition: "画面移動",
};

const $ = (id) => document.getElementById(id);

function escapeHtml(value) {
  return String(value == null ? "" : value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function setStatus(id, text, isError) {
  const el = $(id);
  if (!el) return;
  el.textContent = text;
  el.classList.toggle("error", !!isError);
  el.classList.toggle("ok", !isError && /完了|成功/.test(text));
}

function authHeaders(extra) {
  return Object.assign({ "X-Admin-Password": state.password }, extra || {});
}

async function fetchJSON(url, options) {
  const res = await fetch(url, Object.assign({ headers: authHeaders() }, options || {}));
  const text = await res.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch (_) {
    data = {};
  }
  if (!res.ok) throw new Error(data.error || text || `HTTP ${res.status}`);
  return data;
}

async function postJSON(url, body) {
  return fetchJSON(url, {
    method: "POST",
    headers: authHeaders({ "Content-Type": "application/json" }),
    body: JSON.stringify(body || {}),
  });
}

function asTime(value) {
  const t = new Date(value).getTime();
  return Number.isFinite(t) ? t : 0;
}

function fmtTime(value) {
  if (!value) return "";
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? value : d.toLocaleString("ja-JP", { hour12: false });
}

function getData(e) {
  return e && e.event_data ? e.event_data : {};
}

function getRequestId(e) {
  const data = getData(e);
  return data.request_id || (data.payload && data.payload.request_id) || "";
}

function getEventLoveFromData(e) {
  const data = getData(e);
  if (e.event_type === "love_change" && data.after != null) return parseInt(data.after, 10);
  if (data.love_level != null) return parseInt(data.love_level, 10);
  if (data.payload && data.payload.love_level != null) return parseInt(data.payload.love_level, 10);
  return null;
}

function eventColor(type) {
  return (EVENT_META[type] || EVENT_META.other).color;
}

function eventLabel(type) {
  return (EVENT_META[type] || EVENT_META.other).label;
}

function rawLabel(type) {
  return RAW_LABELS[type] || type;
}

async function loadProfiles() {
  state.password = $("admin-password").value;
  if (!state.password) {
    setStatus("profile-status", "管理パスワードを入力してください", true);
    return;
  }

  setStatus("profile-status", "読み込み中...");
  try {
    const data = await fetchJSON("/api/admin/profiles");
    state.profiles = data.profiles || [];
    if (state.selectedParticipantId) {
      state.selectedProfile = state.profiles.find((p) => p.participant_id === state.selectedParticipantId) || null;
    }
    renderProfiles();
    renderManagePanel();
  } catch (error) {
    setStatus("profile-status", error.message, true);
  }
}

function renderProfiles() {
  $("profiles-body").innerHTML = state.profiles.map((p) => `
    <tr class="clickable ${p.participant_id === state.selectedParticipantId ? "selected" : ""}" data-pid="${escapeHtml(p.participant_id)}">
      <td title="${escapeHtml(p.participant_id)}">${escapeHtml(p.participant_id)}</td>
      <td title="${escapeHtml(p.name)}">${escapeHtml(p.name)}</td>
      <td>${escapeHtml(p.role)}</td>
      <td>${escapeHtml(p.love_level)}</td>
      <td>${escapeHtml(p.log_count)}</td>
    </tr>
  `).join("");

  $("profiles-body").querySelectorAll("tr").forEach((row) => {
    row.addEventListener("click", () => {
      state.selectedParticipantId = row.dataset.pid;
      state.selectedProfile = state.profiles.find((p) => p.participant_id === state.selectedParticipantId) || null;
      state.selectedEventId = "";
      renderProfiles();
      renderManagePanel();
      loadEvents();
      loadTaskProgress();
    });
  });

  $("download-profiles").disabled = state.profiles.length === 0;
  setStatus("profile-status", `${state.profiles.length}件`);
}

async function loadEvents() {
  if (!state.selectedParticipantId) return;

  $("load-events").disabled = false;
  $("download-events-csv").disabled = false;
  $("download-events-json").disabled = false;
  $("timeline-title").textContent = `親密度タイムライン: ${state.selectedParticipantId}`;
  setStatus("event-status", "読み込み中...");

  const params = new URLSearchParams({
    participant_id: state.selectedParticipantId,
    limit: $("filter-limit").value || "5000",
  });
  if ($("filter-session-id").value.trim()) params.set("session_id", $("filter-session-id").value.trim());
  if ($("filter-task-id").value.trim()) params.set("task_id", $("filter-task-id").value.trim());

  try {
    const data = await fetchJSON(`/api/admin/events?${params.toString()}`);
    state.rawEvents = data.events || [];
    buildAndRender();
  } catch (error) {
    setStatus("event-status", error.message, true);
  }
}

async function loadTaskProgress() {
  if (!state.selectedProfile) return;
  try {
    const params = new URLSearchParams({ participant_id: state.selectedProfile.participant_id });
    const data = await fetchJSON(`/api/admin/task-progress?${params.toString()}`);
    state.taskProgress = data.task_progress || [];
    renderManagePanel();
  } catch (error) {
    state.taskProgress = [];
    renderManagePanel(error.message);
  }
}

function buildAnalysisEvents(rawEvents) {
  const raw = rawEvents.slice().sort((a, b) => asTime(a.created_at) - asTime(b.created_at));
  const out = [];
  const chatByRequest = new Map();
  const pendingExecute = new Map();
  const pendingGrade = new Map();
  const keyFor = (e) => `${e.session_id || ""}|${e.task_id || ""}`;
  const add = (item) => {
    out.push(item);
    return item;
  };
  const base = (e, kind, data) => ({
    id: `${kind}-${e.id || out.length}-${out.length}`,
    kind,
    rawType: e.event_type,
    created_at: e.created_at,
    time: asTime(e.created_at),
    task_id: e.task_id || "",
    session_id: e.session_id || "",
    data: data || {},
    raw: [e],
    love: 0,
  });

  raw.forEach((e) => {
    const d = getData(e);
    if (e.event_type === "chat_user_payload" || e.event_type === "chat_ai_response") {
      const rid = getRequestId(e) || `${e.session_id || ""}-${e.created_at}`;
      let item = chatByRequest.get(rid);
      if (!item) {
        item = add(base(e, "chat", { request_id: rid }));
        chatByRequest.set(rid, item);
      }
      if (e.event_type === "chat_user_payload") item.data.user = d;
      else item.data.ai = d;
      item.raw.push(e);
      item.created_at = item.raw.map((r) => r.created_at).sort()[0];
      item.time = asTime(item.created_at);
      return;
    }
    if (e.event_type === "execute_start") {
      const item = base(e, "execute", { start: d });
      pendingExecute.set(keyFor(e), item);
      add(item);
      return;
    }
    if (e.event_type === "execute_result") {
      const key = keyFor(e);
      const item = pendingExecute.get(key) || add(base(e, "execute", {}));
      item.data.result = d;
      item.raw.push(e);
      pendingExecute.delete(key);
      return;
    }
    if (e.event_type === "grade_start") {
      const item = base(e, "grade", { start: d });
      pendingGrade.set(keyFor(e), item);
      add(item);
      return;
    }
    if (e.event_type === "grade_result") {
      const key = keyFor(e);
      const item = pendingGrade.get(key) || add(base(e, "grade", {}));
      item.data.result = d;
      item.raw.push(e);
      pendingGrade.delete(key);
      return;
    }
    if (e.event_type === "session_start") add(base(e, "session", d));
    else if (e.event_type === "lecture_view") add(base(e, "lecture", d));
    else if (e.event_type === "code_snapshot") add(base(e, "code", d));
    else if (e.event_type === "love_change") add(base(e, "love", d));
    else if (e.event_type === "screen_transition") add(base(e, "screen", d));
    else add(base(e, "other", d));
  });

  out.sort((a, b) => a.time - b.time);
  assignLoveValues(out);
  return out;
}

function assignLoveValues(events) {
  let current = state.selectedProfile ? parseInt(state.selectedProfile.love_level, 10) || 0 : 0;
  const start = events.find((e) => e.kind === "session" && e.data && e.data.love_level != null);
  if (start) current = parseInt(start.data.love_level, 10) || 0;

  events.forEach((item) => {
    const rawLove = item.raw.map(getEventLoveFromData).find((v) => Number.isFinite(v));
    if (Number.isFinite(rawLove)) current = rawLove;
    if (item.kind === "love" && item.data.after != null) current = parseInt(item.data.after, 10) || current;
    item.love = current;
  });
}

function filteredAnalysisEvents() {
  const showCode = $("show-code-snapshots").checked;
  const rawFilter = $("filter-event-type").value;
  return state.analysisEvents.filter((item) => {
    if (!showCode && item.kind === "code") return false;
    if (!rawFilter) return true;
    return item.raw.some((e) => e.event_type === rawFilter);
  });
}

function buildAndRender() {
  state.analysisEvents = buildAnalysisEvents(state.rawEvents);
  updateEventTypeOptions();
  renderChart();
  renderAnalysisList();
  setStatus("event-status", `${state.rawEvents.length}件の生ログ`);
}

function updateEventTypeOptions() {
  const select = $("filter-event-type");
  const current = select.value;
  const types = Array.from(new Set(state.rawEvents.map((e) => e.event_type).filter(Boolean))).sort();
  select.innerHTML = '<option value="">イベント全て</option>' + types.map((t) => `<option value="${escapeHtml(t)}">${escapeHtml(rawLabel(t))}</option>`).join("");
  select.value = types.includes(current) ? current : "";
}

function renderChart() {
  const svg = $("chart");
  const events = filteredAnalysisEvents();
  const width = 900;
  const height = 430;
  const pad = { left: 54, right: 22, top: 24, bottom: 44 };
  svg.innerHTML = "";

  if (events.length === 0) {
    svg.innerHTML = `<text x="${width / 2}" y="${height / 2}" text-anchor="middle" fill="#64748b">表示できるイベントがありません</text>`;
    return;
  }

  const minLove = Math.min(0, ...events.map((e) => e.love || 0));
  const maxLove = Math.max(100, ...events.map((e) => e.love || 0));
  const plotW = width - pad.left - pad.right;
  const plotH = height - pad.top - pad.bottom;
  const x = (index) => pad.left + (events.length <= 1 ? plotW / 2 : (index / (events.length - 1)) * plotW);
  const y = (v) => pad.top + plotH - ((v - minLove) / (maxLove - minLove || 1)) * plotH;

  for (let i = 0; i <= 5; i++) {
    const val = minLove + ((maxLove - minLove) / 5) * i;
    const yy = y(val);
    svg.insertAdjacentHTML("beforeend", `<line x1="${pad.left}" y1="${yy}" x2="${width - pad.right}" y2="${yy}" stroke="#e2e8f0"/><text x="${pad.left - 10}" y="${yy + 4}" text-anchor="end" fill="#64748b" font-size="12">${Math.round(val)}</text>`);
  }

  svg.insertAdjacentHTML("beforeend", `<polyline points="${events.map((e, index) => `${x(index)},${y(e.love || 0)}`).join(" ")}" fill="none" stroke="#334155" stroke-width="2" opacity=".65"/>`);

  events.forEach((item, index) => {
    const cx = x(index);
    const cy = y(item.love || 0);
    const selected = item.id === state.selectedEventId;
    svg.insertAdjacentHTML("beforeend", `<circle data-id="${escapeHtml(item.id)}" cx="${cx}" cy="${cy}" r="${selected ? 6 : 5}" fill="${eventColor(item.kind)}" stroke="${selected ? "#111827" : "white"}" stroke-width="2" style="cursor:pointer"><title>${escapeHtml(eventLabel(item.kind))} / ${escapeHtml(fmtTime(item.created_at))}</title></circle>`);
  });

  svg.querySelectorAll("[data-id]").forEach((node) => node.addEventListener("click", () => selectAnalysisEvent(node.dataset.id)));
}

function summarizeAnalysisEvent(item) {
  const d = item.data || {};
  if (item.kind === "chat") {
    const src = d.user && d.user.source === "system_trigger" ? "システム" : "ユーザー";
    const text = getChatUserText(d).replace(/\s+/g, " ").slice(0, 60);
    return `${src}: ${text || "送信内容なし"}`;
  }
  if (item.kind === "execute") {
    const result = d.result && d.result.result ? String(d.result.result) : "";
    return d.result ? (d.result.is_error ? "実行エラー" : result.replace(/\s+/g, " ").slice(0, 70)) : "実行開始";
  }
  if (item.kind === "grade") {
    const r = d.result || {};
    return r.score != null ? `${r.score}点 / 新記録:${r.is_new_record ? "はい" : "いいえ"} / ボーナス:${r.bonus_love || 0}` : "採点開始";
  }
  if (item.kind === "love") return `${d.delta > 0 ? "+" : ""}${d.delta || 0}: ${d.before ?? ""} -> ${d.after ?? ""}`;
  if (item.kind === "lecture") return `${d.lecture_label || ""} ${d.category || ""}`;
  if (item.kind === "code") return `length: ${d.length || 0}`;
  if (item.kind === "screen") return `${d.screen || ""} ${d.action || ""}`;
  return item.rawType || "";
}

function renderAnalysisList() {
  const events = filteredAnalysisEvents();
  $("analysis-status").textContent = `${events.length}件`;
  $("analysis-body").innerHTML = events.map((item) => `
    <tr class="clickable ${item.id === state.selectedEventId ? "selected" : ""}" data-id="${escapeHtml(item.id)}">
      <td title="${escapeHtml(fmtTime(item.created_at))}">${escapeHtml(fmtTime(item.created_at))}</td>
      <td><span class="pill" style="background:${eventColor(item.kind)}">${escapeHtml(eventLabel(item.kind))}</span></td>
      <td title="${escapeHtml(item.task_id)}">${escapeHtml(item.task_id)}</td>
      <td title="${escapeHtml(summarizeAnalysisEvent(item))}">${escapeHtml(summarizeAnalysisEvent(item))}</td>
      <td>${escapeHtml(item.love)}</td>
    </tr>
  `).join("");
  $("analysis-body").querySelectorAll("tr").forEach((row) => row.addEventListener("click", () => selectAnalysisEvent(row.dataset.id)));
}

function selectAnalysisEvent(id) {
  state.selectedEventId = id;
  const item = state.analysisEvents.find((e) => e.id === id);
  renderChart();
  renderAnalysisList();
  renderDetail(item);
  setActiveTab("event");
}

function getChatUserText(data) {
  const user = data.user || {};
  if (user.system_message) return user.system_message;
  const payload = user.payload || {};
  return payload.message || "";
}

function block(title, content) {
  return content == null || content === "" ? "" : `<div class="block"><h3>${escapeHtml(title)}</h3><pre>${escapeHtml(content)}</pre></div>`;
}

function renderDetail(item) {
  if (!item) {
    $("detail-title").textContent = "詳細";
    $("tab-event").innerHTML = '<div class="empty">イベントを選択してください。</div>';
    return;
  }

  $("detail-title").textContent = `${eventLabel(item.kind)} 詳細`;
  const d = item.data || {};
  let html = `
    <div class="kv">
      <div class="key">時刻</div><div>${escapeHtml(fmtTime(item.created_at))}</div>
      <div class="key">種類</div><div>${escapeHtml(eventLabel(item.kind))}</div>
      <div class="key">task_id</div><div>${escapeHtml(item.task_id || "-")}</div>
      <div class="key">session_id</div><div>${escapeHtml(item.session_id || "-")}</div>
      <div class="key">親密度</div><div>${escapeHtml(item.love)}</div>
    </div>`;

  if (item.kind === "chat") {
    const ai = d.ai || {};
    const payload = d.user && d.user.payload ? d.user.payload : {};
    html += block("ユーザー/システム送信", getChatUserText(d));
    html += block("AI応答", ai.text || ai.message || "");
    html += block("送信時コード", payload.code || "");
    html += block("直前出力", payload.prev_output || "");
  } else if (item.kind === "execute") {
    html += block("実行コード", (d.start || {}).code || "");
    html += block("標準入力", (d.start || {}).stdin || "");
    html += block("実行結果", (d.result || {}).result || (d.result || {}).error_message || "");
  } else if (item.kind === "grade") {
    const r = d.result || {};
    html += `<div class="kv"><div class="key">score</div><div>${escapeHtml(r.score ?? "-")}</div><div class="key">新記録</div><div>${escapeHtml(r.is_new_record == null ? "-" : (r.is_new_record ? "はい" : "いいえ"))}</div><div class="key">bonus_love</div><div>${escapeHtml(r.bonus_love ?? "-")}</div></div>`;
    html += block("理由", r.reason || "");
    html += block("改善点", r.improvement || "");
    html += block("コード", (d.start || {}).code || "");
  } else if (item.kind === "code") {
    html += block("コード", d.code || "");
  } else {
    html += block("event_data", JSON.stringify(d, null, 2));
  }
  html += block("生ログ", JSON.stringify(item.raw, null, 2));
  $("tab-event").innerHTML = html;
}

function renderManagePanel(errorMessage) {
  const p = state.selectedProfile;
  if (!p) {
    $("tab-manage").innerHTML = '<div class="empty">参加者を選択してください。</div>' + renderGlobalResetBlock();
    bindManageEvents();
    return;
  }

  const rows = state.taskProgress.map((row) => `
    <tr>
      <td title="${escapeHtml(row.task_id)}">${escapeHtml(row.task_id)}</td>
      <td><input class="tp-score" data-task="${escapeHtml(row.task_id)}" type="number" min="0" max="100" value="${escapeHtml(row.high_score)}"></td>
      <td><select class="tp-cleared" data-task="${escapeHtml(row.task_id)}"><option value="true" ${row.is_cleared ? "selected" : ""}>クリア</option><option value="false" ${!row.is_cleared ? "selected" : ""}>未クリア</option></select></td>
      <td><button class="secondary tp-save" data-task="${escapeHtml(row.task_id)}">保存</button></td>
    </tr>
  `).join("");

  $("tab-manage").innerHTML = `
    <div class="block">
      <h2>参加者管理</h2>
      ${errorMessage ? `<p class="error">${escapeHtml(errorMessage)}</p>` : ""}
      <div class="kv">
        <div class="key">participant_id</div><div>${escapeHtml(p.participant_id)}</div>
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
      <div class="actions"><button id="save-profile">プロフィールを保存</button><span id="manage-status" class="status"></span></div>
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
      <p class="note">task_progress、experiment_events、profiles を削除した後、Supabase Auth の匿名ユーザー本体も削除します。</p>
      <input id="delete-confirm" placeholder="${escapeHtml(p.participant_id)} と入力" class="full-input">
      <div class="actions"><button class="danger" id="delete-user">この参加者を削除</button></div>
    </div>
    ${renderGlobalResetBlock()}
  `;
  bindManageEvents();
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

function bindManageEvents() {
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
  if (!state.selectedProfile) return;
  setManageStatus("保存中...");
  try {
    const loveLevel = parseInt($("manage-love").value, 10);
    await postJSON("/api/admin/profile/update", {
      user_id: state.selectedProfile.id,
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
  if (!state.selectedProfile) return;
  const scoreInput = document.querySelector(`.tp-score[data-task="${CSS.escape(taskId)}"]`);
  const clearedInput = document.querySelector(`.tp-cleared[data-task="${CSS.escape(taskId)}"]`);
  const score = parseInt(scoreInput.value, 10);
  const cleared = clearedInput.value === "true";
  setManageStatus("進捗保存中...");
  try {
    await postJSON("/api/admin/task-progress/update", {
      user_id: state.selectedProfile.id,
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
  if (!state.selectedProfile) return;
  setManageStatus("削除中...");
  try {
    await postJSON("/api/admin/user/delete", {
      user_id: state.selectedProfile.id,
      participant_id: state.selectedProfile.participant_id,
      confirm: $("delete-confirm").value.trim().toUpperCase(),
    });
    state.selectedParticipantId = "";
    state.selectedProfile = null;
    state.rawEvents = [];
    state.analysisEvents = [];
    state.taskProgress = [];
    renderChart();
    renderAnalysisList();
    renderDetail(null);
    setManageStatus("削除完了");
    await loadProfiles();
  } catch (error) {
    setManageStatus(error.message, true);
  }
}

async function resetTaskProgress() {
  setManageStatus("task_progressリセット中...");
  try {
    await postJSON("/api/admin/reset/task-progress", { confirm: $("reset-task-confirm").value.trim() });
    state.taskProgress = [];
    setManageStatus("task_progressリセット完了");
    await loadTaskProgress();
  } catch (error) {
    setManageStatus(error.message, true);
  }
}

async function resetExperimentEvents() {
  setManageStatus("experiment_eventsリセット中...");
  try {
    await postJSON("/api/admin/reset/experiment-events", { confirm: $("reset-events-confirm").value.trim() });
    state.rawEvents = [];
    state.analysisEvents = [];
    setManageStatus("experiment_eventsリセット完了");
    buildAndRender();
    await loadProfiles();
  } catch (error) {
    setManageStatus(error.message, true);
  }
}

function setManageStatus(text, isError) {
  const el = $("manage-status");
  if (el) {
    el.textContent = text;
    el.classList.toggle("error", !!isError);
    el.classList.toggle("ok", !isError && /完了|成功/.test(text));
  } else {
    setStatus("profile-status", text, isError);
  }
}

function csvEscape(value) {
  const text = String(value == null ? "" : value);
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function downloadFile(filename, text, type) {
  const blob = new Blob([text], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

function downloadCSV(filename, text) {
  downloadFile(filename, "\uFEFF" + text, "text/csv;charset=utf-8");
}

function downloadProfilesCSV() {
  const headers = ["participant_id", "name", "role", "love_level", "last_updated", "log_count", "last_event_at", "id"];
  const rows = state.profiles.map((p) => headers.map((h) => csvEscape(p[h])).join(","));
  downloadCSV("profiles.csv", [headers.join(","), ...rows].join("\r\n"));
}

function downloadEventsCSV() {
  const headers = ["created_at", "participant_id", "role", "session_id", "task_id", "event_type", "event_data", "user_id", "id"];
  const rows = state.rawEvents.map((e) => headers.map((h) => csvEscape(h === "event_data" ? JSON.stringify(e.event_data || {}) : e[h])).join(","));
  downloadCSV(`${state.selectedParticipantId}_events.csv`, [headers.join(","), ...rows].join("\r\n"));
}

function setActiveTab(tab) {
  document.querySelectorAll(".tab").forEach((btn) => btn.classList.toggle("active", btn.dataset.tab === tab));
  document.querySelectorAll(".tab-pane").forEach((pane) => pane.classList.toggle("active", pane.id === `tab-${tab}`));
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function setupResizableLayout() {
  const shell = document.querySelector(".shell");
  if (!shell) return;
  function pxVar(name, fallback) {
    const raw = getComputedStyle(shell).getPropertyValue(name).trim();
    const value = parseFloat(raw);
    return Number.isFinite(value) ? value : fallback;
  }
  shell.querySelectorAll("[data-resize]").forEach((handle) => {
    handle.addEventListener("pointerdown", (event) => {
      if (window.matchMedia("(max-width: 1180px)").matches) return;
      event.preventDefault();
      handle.setPointerCapture(event.pointerId);
      shell.classList.add("resizing");
      const mode = handle.dataset.resize;
      const startX = event.clientX;
      const startY = event.clientY;
      const rect = shell.getBoundingClientRect();
      const startParticipants = pxVar("--participants-w", 330);
      const startDetail = pxVar("--detail-w", 430);
      const startEvents = pxVar("--events-h", 270);
      const maxParticipants = Math.max(260, rect.width - startDetail - 520);
      const maxDetail = Math.max(320, rect.width - startParticipants - 520);
      const maxEvents = Math.max(180, rect.height - 300);

      function onMove(moveEvent) {
        if (mode === "participants") {
          shell.style.setProperty("--participants-w", clamp(startParticipants + (moveEvent.clientX - startX), 240, maxParticipants) + "px");
        } else if (mode === "detail") {
          shell.style.setProperty("--detail-w", clamp(startDetail - (moveEvent.clientX - startX), 320, maxDetail) + "px");
        } else if (mode === "timeline") {
          shell.style.setProperty("--events-h", clamp(startEvents - (moveEvent.clientY - startY), 160, maxEvents) + "px");
        }
      }

      function onUp() {
        shell.classList.remove("resizing");
        handle.removeEventListener("pointermove", onMove);
        handle.removeEventListener("pointerup", onUp);
        handle.removeEventListener("pointercancel", onUp);
      }

      handle.addEventListener("pointermove", onMove);
      handle.addEventListener("pointerup", onUp);
      handle.addEventListener("pointercancel", onUp);
    });
  });
}

function bindEvents() {
  $("load-profiles").addEventListener("click", loadProfiles);
  $("load-events").addEventListener("click", loadEvents);
  $("download-profiles").addEventListener("click", downloadProfilesCSV);
  $("download-events-csv").addEventListener("click", downloadEventsCSV);
  $("download-events-json").addEventListener("click", () => {
    downloadFile(`${state.selectedParticipantId}_events.json`, JSON.stringify(state.rawEvents, null, 2), "application/json;charset=utf-8");
  });
  $("filter-event-type").addEventListener("change", buildAndRender);
  $("show-code-snapshots").addEventListener("change", buildAndRender);
  $("back-app").addEventListener("click", () => { location.href = "/"; });
  $("admin-password").addEventListener("keydown", (e) => {
    if (e.key === "Enter") loadProfiles();
  });
  document.querySelectorAll(".tab").forEach((btn) => btn.addEventListener("click", () => setActiveTab(btn.dataset.tab)));
}

bindEvents();
renderManagePanel();
setupResizableLayout();
