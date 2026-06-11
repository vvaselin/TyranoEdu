const state = {
  password: "",
  profiles: [],
  rawEvents: [],
  allEvents: [],
  analysisEvents: [],
  taskProgress: [],
  allTaskProgress: [],
  groupAnalysisLoaded: false,
  groupMetrics: [],
  groupTaskRows: [],
  selectedUserId: "",
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
  intro: { label: "入場時知識", color: "#0891b2" },
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
  task_intro_knowledge: "入場時知識",
  execute_start: "実行開始",
  execute_result: "実行結果",
  grade_start: "採点開始",
  grade_result: "採点結果",
  code_snapshot: "コード保存",
  love_change: "親密度変化",
  screen_transition: "画面移動",
};

const EMOTION_LABELS = {
  joy: "喜び",
  trust: "信頼",
  fear: "不安",
  anger: "怒り",
  shy: "照れ",
  surprise: "驚き",
};

const EMOTION_ORDER = ["joy", "trust", "fear", "anger", "shy", "surprise"];
const EMOTION_MAX_VALUE = 5;
const CHART_METRICS = {
  fallbackWidth: 900,
  fallbackHeight: 430,
  minWidth: 320,
  minHeight: 180,
  minPointGap: 32,
  pad: { left: 54, right: 22, top: 24, bottom: 36 },
  labelFont: 12,
  pointRadius: 5,
  selectedPointRadius: 6,
  pointStroke: 2,
  lineStroke: 2,
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

function isSystemTriggerLog(e) {
  const data = getData(e);
  return data.source === "system_trigger" || data.is_system_trigger === true;
}

function classifySystemFeedback(data) {
  const text = String((data && (data.system_message || data.message)) || (data && data.payload && data.payload.message) || "");
  if (/採点|score|grade/i.test(text)) return "grade";
  if (/実行|execute|コード実行|コンパイル/i.test(text)) return "execute";
  return "";
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
    if (state.selectedUserId) {
      state.selectedProfile = state.profiles.find((p) => p.id === state.selectedUserId) || null;
      state.selectedParticipantId = (state.selectedProfile && state.selectedProfile.participant_id) || "";
    }
    renderProfiles();
    renderManagePanel();
    renderGroupPanel();
  } catch (error) {
    setStatus("profile-status", error.message, true);
  }
}

function renderProfiles() {
  $("profiles-body").innerHTML = state.profiles.map((p) => `
    <tr class="clickable ${p.id === state.selectedUserId ? "selected" : ""}" data-user-id="${escapeHtml(p.id)}">
      <td title="${escapeHtml(p.participant_id || p.id)}">${escapeHtml(p.participant_id || "未完了")}</td>
      <td title="${escapeHtml(p.name)}">${escapeHtml(p.name)}</td>
      <td>${escapeHtml(p.role || "未割当")}</td>
      <td>${escapeHtml(p.love_level)}</td>
      <td>${escapeHtml(p.log_count)}</td>
    </tr>
  `).join("");

  $("profiles-body").querySelectorAll("tr").forEach((row) => {
    row.addEventListener("click", () => {
      state.selectedUserId = row.dataset.userId;
      state.selectedProfile = state.profiles.find((p) => p.id === state.selectedUserId) || null;
      state.selectedParticipantId = (state.selectedProfile && state.selectedProfile.participant_id) || "";
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
  if (!state.selectedProfile) return;

  $("load-events").disabled = false;
  $("download-events-csv").disabled = false;
  $("download-events-json").disabled = false;
  $("timeline-title").textContent = `親密度タイムライン: ${state.selectedParticipantId || "未完了"}`;
  setStatus("event-status", "読み込み中...");

  const params = new URLSearchParams({
    limit: $("filter-limit").value || "5000",
  });
  if (state.selectedParticipantId) params.set("participant_id", state.selectedParticipantId);
  else params.set("user_id", state.selectedProfile.id);
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
    const params = new URLSearchParams();
    if (state.selectedProfile.participant_id) params.set("participant_id", state.selectedProfile.participant_id);
    else params.set("user_id", state.selectedProfile.id);
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
  const systemFeedbackByRequest = new Map();
  const pendingExecute = new Map();
  const pendingGrade = new Map();
  const latestExecute = new Map();
  const latestGrade = new Map();
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
  const attachFeedbackToTarget = (feedback, target) => {
    if (!feedback || !target) return;
    if (!target.data.feedback) target.data.feedback = {};
    Object.assign(target.data.feedback, feedback);
    feedback.raw.forEach((rawEvent) => {
      if (!target.raw.some((existing) => existing.id === rawEvent.id)) target.raw.push(rawEvent);
    });
  };
  const attachPendingFeedbackForTarget = (targetKind, key, target) => {
    systemFeedbackByRequest.forEach((feedback) => {
      if (feedback.key !== key) return;
      if (feedback.targetKind && feedback.targetKind !== targetKind) return;
      attachFeedbackToTarget(feedback, target);
    });
  };
  const attachSystemFeedback = (e, data) => {
    const rid = getRequestId(e) || `${e.session_id || ""}-${e.created_at}`;
    let feedback = systemFeedbackByRequest.get(rid);
    if (!feedback) {
      feedback = { request_id: rid, raw: [] };
      systemFeedbackByRequest.set(rid, feedback);
    }
    feedback.key = keyFor(e);
    if (e.event_type === "chat_user_payload") {
      feedback.user = data;
      feedback.targetKind = classifySystemFeedback(data);
    } else {
      feedback.ai = data;
    }
    feedback.raw.push(e);

    const key = keyFor(e);
    let target = null;
    if (feedback.targetKind === "grade") target = latestGrade.get(key);
    else if (feedback.targetKind === "execute") target = latestExecute.get(key);
    else target = latestGrade.get(key) || latestExecute.get(key);
    attachFeedbackToTarget(feedback, target);
  };

  raw.forEach((e) => {
    const d = getData(e);
    if (e.event_type === "chat_user_payload" || e.event_type === "chat_ai_response") {
      if (isSystemTriggerLog(e) || systemFeedbackByRequest.has(getRequestId(e))) {
        attachSystemFeedback(e, d);
        return;
      }
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
    if (e.event_type === "task_intro_knowledge") {
      add(base(e, "intro", d));
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
      latestExecute.set(key, item);
      attachPendingFeedbackForTarget("execute", key, item);
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
      latestGrade.set(key, item);
      attachPendingFeedbackForTarget("grade", key, item);
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
  const sessionStart = events.find((e) => e.kind === "session" && Number.isFinite(getEventLoveFromData(e)));
  const firstLoggedLove = sessionStart
    ? getEventLoveFromData(sessionStart)
    : events.map(getEventLoveFromData).find((v) => Number.isFinite(v));
  let current = Number.isFinite(firstLoggedLove) ? firstLoggedLove : 0;

  events.forEach((item) => {
    if (item.kind === "session") {
      const sessionLove = getEventLoveFromData(item.raw[0]);
      if (Number.isFinite(sessionLove)) current = sessionLove;
    } else if (item.kind === "love" && item.data.after != null) {
      const next = parseInt(item.data.after, 10);
      if (Number.isFinite(next)) current = next;
    }
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
  const rect = svg.getBoundingClientRect();
  const viewportWidth = Math.max(CHART_METRICS.minWidth, Math.round((svg.parentElement && svg.parentElement.clientWidth) || rect.width || CHART_METRICS.fallbackWidth));
  const requiredWidth = CHART_METRICS.pad.left + CHART_METRICS.pad.right + Math.max(0, events.length - 1) * CHART_METRICS.minPointGap;
  const width = Math.max(CHART_METRICS.minWidth, viewportWidth, requiredWidth);
  const height = Math.max(CHART_METRICS.minHeight, Math.round(rect.height || CHART_METRICS.fallbackHeight));
  const pad = CHART_METRICS.pad;
  svg.style.width = `${width}px`;
  svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
  svg.setAttribute("preserveAspectRatio", "none");
  svg.innerHTML = "";
  renderChartLegend(events);

  if (events.length === 0) {
    svg.innerHTML = `<text x="${width / 2}" y="${height / 2}" text-anchor="middle" fill="#64748b" font-size="${CHART_METRICS.labelFont}">表示できるイベントがありません</text>`;
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
    svg.insertAdjacentHTML("beforeend", `<line x1="${pad.left}" y1="${yy}" x2="${width - pad.right}" y2="${yy}" stroke="#e2e8f0" stroke-width="1"/><text x="${pad.left - 10}" y="${yy + 4}" text-anchor="end" fill="#64748b" font-size="${CHART_METRICS.labelFont}">${Math.round(val)}</text>`);
  }

  svg.insertAdjacentHTML("beforeend", `<polyline points="${events.map((e, index) => `${x(index)},${y(e.love || 0)}`).join(" ")}" fill="none" stroke="#334155" stroke-width="${CHART_METRICS.lineStroke}" opacity=".65"/>`);

  events.forEach((item, index) => {
    const cx = x(index);
    const cy = y(item.love || 0);
    const selected = item.id === state.selectedEventId;
    svg.insertAdjacentHTML("beforeend", `<circle data-id="${escapeHtml(item.id)}" cx="${cx}" cy="${cy}" r="${selected ? CHART_METRICS.selectedPointRadius : CHART_METRICS.pointRadius}" fill="${eventColor(item.kind)}" stroke="${selected ? "#111827" : "white"}" stroke-width="${CHART_METRICS.pointStroke}" style="cursor:pointer"><title>${escapeHtml(eventLabel(item.kind))} / ${escapeHtml(fmtTime(item.created_at))}</title></circle>`);
  });

  svg.querySelectorAll("[data-id]").forEach((node) => node.addEventListener("click", () => selectAnalysisEvent(node.dataset.id)));
}

function renderChartLegend(events) {
  const legend = $("chart-legend");
  if (!legend) return;
  const visibleKinds = Array.from(new Set((events || []).map((event) => event.kind || "other")));
  const orderedKinds = Object.keys(EVENT_META).filter((key) => visibleKinds.includes(key));
  legend.innerHTML = orderedKinds.map((key) => `
    <span class="legend-item">
      <span class="legend-dot" style="background:${eventColor(key)}"></span>
      <span>${escapeHtml(EVENT_META[key].label)}</span>
    </span>
  `).join("");
}

function summarizeAnalysisEvent(item) {
  const d = item.data || {};
  if (item.kind === "chat") {
    const src = d.user && d.user.source === "system_trigger" ? "システム" : "ユーザー";
    const text = getChatUserText(d).replace(/\s+/g, " ").slice(0, 60);
    return `${src}: ${text || "送信内容なし"}`;
  }
  if (item.kind === "intro") {
    if (d.error) return `入場時知識生成エラー: ${d.error_message || ""}`;
    return `入場時知識: ${String(d.ai_text || "").replace(/\s+/g, " ").slice(0, 70)}`;
  }
  if (item.kind === "execute") {
    const result = d.result && d.result.result ? String(d.result.result) : "";
    const suffix = d.feedback && d.feedback.ai ? " / AIフィードバックあり" : "";
    return (d.result ? (d.result.is_error ? "実行エラー" : result.replace(/\s+/g, " ").slice(0, 70)) : "実行開始") + suffix;
  }
  if (item.kind === "grade") {
    const r = d.result || {};
    const suffix = d.feedback && d.feedback.ai ? " / AIフィードバックあり" : "";
    return (r.score != null ? `${r.score}点 / 新記録:${r.is_new_record ? "はい" : "いいえ"} / ボーナス:${r.bonus_love || 0}` : "採点開始") + suffix;
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
  return stripInjectedChatContext(payload.message || "");
}

function stripInjectedChatContext(message) {
  return String(message || "")
    .replace(/\n*\[Conversation History\][\s\S]*$/i, "")
    .replace(/\n*\[Long Term Memory Info\][\s\S]*$/i, "")
    .trim();
}

function block(title, content) {
  return content == null || content === "" ? "" : `<div class="block"><h3>${escapeHtml(title)}</h3><pre>${escapeHtml(content)}</pre></div>`;
}

function getEmotionParameters(data) {
  const ai = data && data.ai ? data.ai : {};
  const parameters = ai.parameters || ai.params || (ai.payload && ai.payload.parameters);
  if (!parameters || typeof parameters !== "object" || Array.isArray(parameters)) return [];

  const keys = EMOTION_ORDER.concat(Object.keys(parameters).filter((key) => !EMOTION_ORDER.includes(key)));
  return keys.map((key) => {
    const value = Number(parameters[key]);
    if (!Number.isFinite(value)) return null;
    return {
      key,
      label: EMOTION_LABELS[key] || key,
      value,
    };
  }).filter(Boolean);
}

function emotionChoiceBlock(data) {
  const ai = data && data.ai ? data.ai : {};
  const emotion = ai.emotion || (ai.payload && ai.payload.emotion);
  if (!emotion) return "";
  return `<div class="block"><h3>選択emotion</h3><pre>${escapeHtml(emotion)}</pre></div>`;
}

function emotionParametersBlock(data) {
  const rows = getEmotionParameters(data);
  if (rows.length === 0) return "";

  const body = rows.map((row) => {
    const clampedValue = clamp(row.value, 0, EMOTION_MAX_VALUE);
    const width = Math.round((clampedValue / EMOTION_MAX_VALUE) * 100);
    return `
      <div class="emotion-row">
        <div class="emotion-label" title="${escapeHtml(row.key)}">${escapeHtml(row.label)}</div>
        <div class="emotion-track"><div class="emotion-fill" style="width:${width}%"></div></div>
        <div class="emotion-value">${escapeHtml(row.value)}/${EMOTION_MAX_VALUE}</div>
      </div>
    `;
  }).join("");

  return `<div class="block"><h3>感情パラメータ</h3><div class="emotion-chart">${body}</div></div>`;
}

function feedbackBlock(feedback) {
  if (!feedback) return "";
  const ai = feedback.ai || {};
  const user = feedback.user || {};
  let html = "";
  html += block("AIフィードバック", ai.text || ai.message || "");
  html += emotionChoiceBlock({ ai });
  html += emotionParametersBlock({ ai });
  html += block("フィードバック生成トリガー", user.system_message || (user.payload && user.payload.message) || "");
  return html;
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
    html += emotionChoiceBlock(d);
    html += emotionParametersBlock(d);
    html += block("送信時コード", payload.code || "");
    html += block("直前出力", payload.prev_output || "");
  } else if (item.kind === "intro") {
    if (d.error) html += block("エラー", d.error_message || "");
    html += block("AI応答", d.ai_text || "");
    html += block("生成トリガー", d.system_message || "");
    html += block("learned_topics", Array.isArray(d.learned_topics) ? d.learned_topics.join("\n") : d.learned_topics || "");
    html += block("固定stdin", d.fixed_stdin || "");
    html += emotionChoiceBlock({ ai: { emotion: d.emotion } });
  } else if (item.kind === "execute") {
    html += block("実行コード", (d.start || {}).code || "");
    html += block("標準入力", (d.start || {}).stdin || "");
    html += block("実行結果", (d.result || {}).result || (d.result || {}).error_message || "");
    html += feedbackBlock(d.feedback);
  } else if (item.kind === "grade") {
    const r = d.result || {};
    html += `<div class="kv"><div class="key">score</div><div>${escapeHtml(r.score ?? "-")}</div><div class="key">新記録</div><div>${escapeHtml(r.is_new_record == null ? "-" : (r.is_new_record ? "はい" : "いいえ"))}</div><div class="key">bonus_love</div><div>${escapeHtml(r.bonus_love ?? "-")}</div></div>`;
    html += block("理由", r.reason || "");
    html += block("改善点", r.improvement || "");
    html += feedbackBlock(d.feedback);
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
      <p class="note">task_progress、experiment_events、profiles を削除した後、Supabase Auth の匿名ユーザー本体も削除します。未完了ユーザーは DELETE_INCOMPLETE と入力します。</p>
      <input id="delete-confirm" placeholder="${escapeHtml(p.participant_id || "DELETE_INCOMPLETE")} と入力" class="full-input">
      <div class="actions"><button class="danger" id="delete-user">この参加者を削除</button></div>
    </div>
    ${renderGlobalResetBlock()}
  `;
  bindManageEvents();
}

const GROUP_METRICS = [
  { key: "finalLove", label: "最終親密度", fmt: fmtNumber },
  { key: "loveGain", label: "親密度増加量", fmt: fmtNumber },
  { key: "clearedTasks", label: "80点以上到達課題数", fmt: fmtNumber },
  { key: "avgScore", label: "平均スコア", fmt: fmtNumber },
  { key: "maxScore", label: "最高スコア", fmt: fmtNumber },
  { key: "executeCount", label: "実行回数", fmt: fmtNumber },
  { key: "executeErrorRate", label: "実行エラー率", fmt: fmtPercent },
  { key: "gradeCount", label: "採点回数", fmt: fmtNumber },
  { key: "gradeFailCount", label: "採点失敗回数", fmt: fmtNumber },
  { key: "regularChatCount", label: "通常AI会話回数", fmt: fmtNumber },
  { key: "systemFeedbackCount", label: "システムAIフィードバック回数", fmt: fmtNumber },
  { key: "avgAiScoreImprovement", label: "AI利用後スコア改善", fmt: fmtNumber },
  { key: "editorMinutes", label: "editor滞在分", fmt: fmtNumber },
  { key: "editorExitCount", label: "editor離脱回数", fmt: fmtNumber },
  { key: "firstExecuteMinutes", label: "初回実行まで分", fmt: fmtNumber },
  { key: "firstGradeMinutes", label: "初回採点まで分", fmt: fmtNumber },
  { key: "firstClearMinutes", label: "初回クリアまで分", fmt: fmtNumber },
];

function fmtNumber(value) {
  return Number.isFinite(value) ? (Math.round(value * 10) / 10).toLocaleString("ja-JP") : "-";
}

function fmtPercent(value) {
  return Number.isFinite(value) ? `${Math.round(value * 1000) / 10}%` : "-";
}

function fmtMinutes(value) {
  return Number.isFinite(value) ? `${fmtNumber(value)}分` : "-";
}

function mean(values) {
  const xs = values.filter(Number.isFinite);
  return xs.length ? xs.reduce((sum, v) => sum + v, 0) / xs.length : NaN;
}

function median(values) {
  const xs = values.filter(Number.isFinite).sort((a, b) => a - b);
  if (!xs.length) return NaN;
  const mid = Math.floor(xs.length / 2);
  return xs.length % 2 ? xs[mid] : (xs[mid - 1] + xs[mid]) / 2;
}

function stddev(values) {
  const xs = values.filter(Number.isFinite);
  if (xs.length < 2) return NaN;
  const avg = mean(xs);
  return Math.sqrt(xs.reduce((sum, v) => sum + Math.pow(v - avg, 2), 0) / (xs.length - 1));
}

function standardizedDiff(a, b) {
  const pooled = Math.sqrt((Math.pow(a.std, 2) + Math.pow(b.std, 2)) / 2);
  if (!Number.isFinite(pooled) || pooled === 0) return NaN;
  return (a.mean - b.mean) / pooled;
}

function statFor(metrics, key, role) {
  const values = metrics.filter((m) => m.role === role).map((m) => m[key]);
  return { n: values.filter(Number.isFinite).length, mean: mean(values), median: median(values), std: stddev(values) };
}

function getGroupFilters() {
  const taskEl = $("group-filter-task");
  const participantEl = $("group-filter-participant");
  const excludeSandboxEl = $("group-exclude-sandbox");
  const excludeIncompleteEl = $("group-exclude-incomplete");
  return {
    taskId: taskEl ? taskEl.value.trim() : "",
    participantText: participantEl ? participantEl.value.trim().toLowerCase() : "",
    excludeSandbox: !excludeSandboxEl || excludeSandboxEl.checked,
    excludeIncomplete: !excludeIncompleteEl || excludeIncompleteEl.checked,
  };
}

function isAnalysisRole(role) {
  return role === "experimental" || role === "control";
}

function isSandboxEvent(event) {
  const data = getData(event);
  return event.task_id === "sandbox" || data.is_sandbox === true;
}

function profileMatchesFilter(profile, filters) {
  if (!isAnalysisRole(profile.role)) return false;
  if (filters.excludeIncomplete && !profile.participant_id) return false;
  if (!filters.participantText) return true;
  const haystack = `${profile.participant_id || ""} ${profile.name || ""} ${profile.id || ""}`.toLowerCase();
  return haystack.includes(filters.participantText);
}

function eventBelongsToProfile(event, profile) {
  if (event.user_id && profile.id && event.user_id === profile.id) return true;
  if (event.participant_id && profile.participant_id && event.participant_id === profile.participant_id) return true;
  return false;
}

function taskProgressBelongsToProfile(row, profile) {
  return row.user_id && profile.id && row.user_id === profile.id;
}

function eventPassesGroupFilters(event, filters) {
  if (filters.excludeSandbox && isSandboxEvent(event)) return false;
  if (filters.taskId && event.task_id !== filters.taskId) return false;
  return true;
}

function uniqueEventTasks(events) {
  return Array.from(new Set(events.map((e) => e.task_id).filter((taskId) => taskId && taskId !== "sandbox"))).sort((a, b) => a.localeCompare(b, "ja", { numeric: true }));
}

async function loadGroupAnalysis() {
  if (!state.password) {
    setGroupStatus("管理パスワードを入力して参加者を読み込んでください", true);
    return;
  }
  setGroupStatus("群間分析データ読み込み中...");
  try {
    const [eventsData, progressData] = await Promise.all([
      fetchJSON("/api/admin/events?limit=200000"),
      fetchJSON("/api/admin/task-progress"),
    ]);
    state.allEvents = eventsData.events || [];
    state.allTaskProgress = progressData.task_progress || [];
    state.groupAnalysisLoaded = true;
    renderGroupPanel();
    setGroupStatus(`${state.allEvents.length}件の生ログ / ${state.allTaskProgress.length}件の進捗`);
  } catch (error) {
    setGroupStatus(error.message, true);
  }
}

function setGroupStatus(text, isError) {
  const el = $("group-status");
  if (!el) return;
  el.textContent = text;
  el.classList.toggle("error", !!isError);
  el.classList.toggle("ok", !isError && /件|完了|成功/.test(text));
}

function buildParticipantMetric(profile, allEvents, allTaskProgress, filters) {
  const events = allEvents
    .filter((event) => eventBelongsToProfile(event, profile))
    .filter((event) => eventPassesGroupFilters(event, filters))
    .sort((a, b) => asTime(a.created_at) - asTime(b.created_at));
  const progressRows = allTaskProgress.filter((row) => taskProgressBelongsToProfile(row, profile));
  const filteredProgressRows = progressRows.filter((row) => {
    if (filters.taskId && row.task_id !== filters.taskId) return false;
    if (filters.excludeSandbox && row.task_id === "sandbox") return false;
    return true;
  });
  const perTask = new Map();
  const scoreEvents = [];
  const regularChatTimes = [];
  const regularChatTasks = new Set();
  const systemFeedbackRequests = new Set();
  const loveValues = [];
  const clearedTasks = new Set();
  const openEditors = new Map();
  const lastEventTimeByKey = new Map();

  const ensureTask = (taskId) => {
    const key = taskId || "(taskなし)";
    if (!perTask.has(key)) {
      perTask.set(key, {
        taskId: key,
        scoreValues: [],
        maxScore: NaN,
        executeCount: 0,
        executeErrorCount: 0,
        gradeCount: 0,
        gradeFailCount: 0,
        regularChatCount: 0,
        systemFeedbackCount: 0,
        editorMs: 0,
        estimatedEditorSessions: 0,
        editorExitCount: 0,
        cleared: false,
      });
    }
    return perTask.get(key);
  };

  let executeCount = 0;
  let executeErrorCount = 0;
  let gradeCount = 0;
  let gradeFailCount = 0;
  let regularChatCount = 0;
  let systemFeedbackCount = 0;
  let loveChangeCount = 0;
  let firstEditorAt = NaN;
  let firstExecuteAt = NaN;
  let firstGradeAt = NaN;
  let firstClearAt = NaN;

  events.forEach((event) => {
    const data = getData(event);
    const time = asTime(event.created_at);
    const taskId = event.task_id || "";
    const key = `${event.session_id || ""}|${taskId}`;
    if (time) lastEventTimeByKey.set(key, time);
    if (taskId) ensureTask(taskId);

    const loggedLove = getEventLoveFromData(event);
    if (Number.isFinite(loggedLove)) loveValues.push(loggedLove);
    if (event.event_type === "love_change") loveChangeCount++;

    if (event.event_type === "screen_transition" && data.screen === "editor") {
      if (data.action === "enter") {
        if (!Number.isFinite(firstEditorAt)) firstEditorAt = time;
        if (!openEditors.has(key)) openEditors.set(key, { time, taskId });
      } else if (data.action === "exit") {
        const open = openEditors.get(key);
        const task = ensureTask(taskId);
        task.editorExitCount++;
        if (open && time >= open.time) {
          task.editorMs += time - open.time;
          openEditors.delete(key);
        }
      }
    }

    if (event.event_type === "execute_start") {
      executeCount++;
      ensureTask(taskId).executeCount++;
      if (!Number.isFinite(firstExecuteAt) && Number.isFinite(firstEditorAt)) firstExecuteAt = time;
    }
    if (event.event_type === "execute_result") {
      const isError = data.is_error === true;
      if (isError) {
        executeErrorCount++;
        ensureTask(taskId).executeErrorCount++;
      }
    }
    if (event.event_type === "grade_result") {
      gradeCount++;
      const score = Number(data.score);
      const task = ensureTask(taskId);
      task.gradeCount++;
      if (Number.isFinite(score)) {
        task.scoreValues.push(score);
        task.maxScore = Number.isFinite(task.maxScore) ? Math.max(task.maxScore, score) : score;
        scoreEvents.push({ time, taskId, score });
        if (score >= 80) {
          task.cleared = true;
          clearedTasks.add(taskId);
          if (!Number.isFinite(firstClearAt) && Number.isFinite(firstEditorAt)) firstClearAt = time;
        } else {
          gradeFailCount++;
          task.gradeFailCount++;
        }
      }
      if (!Number.isFinite(firstGradeAt) && Number.isFinite(firstEditorAt)) firstGradeAt = time;
    }
    if (event.event_type === "chat_user_payload") {
      const rid = getRequestId(event) || `${event.session_id || ""}-${event.created_at}`;
      const task = ensureTask(taskId);
      if (isSystemTriggerLog(event)) {
        systemFeedbackRequests.add(rid);
        task.systemFeedbackCount++;
      } else {
        regularChatCount++;
        task.regularChatCount++;
        regularChatTimes.push({ time, taskId });
        if (taskId) regularChatTasks.add(taskId);
      }
    }
  });

  openEditors.forEach((open, key) => {
    const end = lastEventTimeByKey.get(key);
    if (!Number.isFinite(end) || end < open.time) return;
    const task = ensureTask(open.taskId);
    task.editorMs += end - open.time;
    task.estimatedEditorSessions++;
  });

  filteredProgressRows.forEach((row) => {
    const task = ensureTask(row.task_id);
    task.taskProgressCleared = row.is_cleared;
    task.taskProgressHighScore = row.high_score;
  });

  const scoreValues = scoreEvents.map((row) => row.score);
  const aiImprovements = regularChatTimes.map((chat) => {
    const previous = scoreEvents.filter((s) => s.taskId === chat.taskId && s.time < chat.time).pop();
    const next = scoreEvents.find((s) => s.taskId === chat.taskId && s.time > chat.time);
    return previous && next ? next.score - previous.score : NaN;
  }).filter(Number.isFinite);
  const editorMs = Array.from(perTask.values()).reduce((sum, task) => sum + task.editorMs, 0);
  const editorExitCount = Array.from(perTask.values()).reduce((sum, task) => sum + task.editorExitCount, 0);
  const estimatedEditorSessions = Array.from(perTask.values()).reduce((sum, task) => sum + task.estimatedEditorSessions, 0);
  const initialLove = loveValues.length ? loveValues[0] : NaN;
  const finalLove = Number.isFinite(Number(profile.love_level)) ? Number(profile.love_level) : (loveValues.length ? loveValues[loveValues.length - 1] : NaN);

  return {
    profile,
    participant_id: profile.participant_id || "",
    name: profile.name || "",
    user_id: profile.id || "",
    role: profile.role || "",
    eventCount: events.length,
    finalLove,
    initialLove,
    loveGain: Number.isFinite(initialLove) && Number.isFinite(finalLove) ? finalLove - initialLove : NaN,
    loveChangeCount,
    clearedTasks: clearedTasks.size,
    taskProgressClearedCount: filteredProgressRows.filter((row) => row.is_cleared).length,
    avgScore: mean(scoreValues),
    maxScore: scoreValues.length ? Math.max(...scoreValues) : NaN,
    passScoreCount: scoreValues.filter((score) => score >= 80).length,
    executeCount,
    executeErrorCount,
    executeErrorRate: executeCount ? executeErrorCount / executeCount : NaN,
    gradeCount,
    gradeFailCount,
    regularChatCount,
    systemFeedbackCount: systemFeedbackRequests.size || systemFeedbackCount,
    avgAiScoreImprovement: mean(aiImprovements),
    editorMinutes: editorMs / 60000,
    editorExitCount,
    estimatedEditorSessions,
    firstExecuteMinutes: Number.isFinite(firstEditorAt) && Number.isFinite(firstExecuteAt) ? (firstExecuteAt - firstEditorAt) / 60000 : NaN,
    firstGradeMinutes: Number.isFinite(firstEditorAt) && Number.isFinite(firstGradeAt) ? (firstGradeAt - firstEditorAt) / 60000 : NaN,
    firstClearMinutes: Number.isFinite(firstEditorAt) && Number.isFinite(firstClearAt) ? (firstClearAt - firstEditorAt) / 60000 : NaN,
    aiTouchedTasks: regularChatTasks.size,
    perTask,
  };
}

function buildGroupAnalysis() {
  const filters = getGroupFilters();
  const profiles = state.profiles.filter((profile) => profileMatchesFilter(profile, filters));
  const metrics = profiles.map((profile) => buildParticipantMetric(profile, state.allEvents, state.allTaskProgress, filters));
  const taskRows = buildTaskComparisonRows(metrics);
  state.groupMetrics = metrics;
  state.groupTaskRows = taskRows;
  return { filters, metrics, taskRows };
}

function buildTaskComparisonRows(metrics) {
  const taskIds = Array.from(new Set(metrics.flatMap((metric) => Array.from(metric.perTask.keys()).filter((taskId) => taskId && taskId !== "(taskなし)")))).sort((a, b) => a.localeCompare(b, "ja", { numeric: true }));
  return taskIds.map((taskId) => {
    const roleStats = {};
    ["experimental", "control"].forEach((role) => {
      const rows = metrics.filter((metric) => metric.role === role).map((metric) => metric.perTask.get(taskId)).filter(Boolean);
      const participantCount = rows.length;
      roleStats[role] = {
        participantCount,
        clearRate: participantCount ? rows.filter((row) => row.cleared || row.taskProgressCleared).length / participantCount : NaN,
        avgScore: mean(rows.map((row) => row.maxScore)),
        avgExecute: mean(rows.map((row) => row.executeCount)),
        avgChat: mean(rows.map((row) => row.regularChatCount)),
        avgEditorMinutes: mean(rows.map((row) => row.editorMs / 60000)),
        errorRate: mean(rows.map((row) => row.executeCount ? row.executeErrorCount / row.executeCount : NaN)),
      };
    });
    return { taskId, experimental: roleStats.experimental, control: roleStats.control };
  });
}

function renderGroupPanel() {
  const pane = $("tab-group");
  if (!pane) return;
  const filters = getGroupFilters();
  const taskOptions = uniqueEventTasks(state.groupAnalysisLoaded ? state.allEvents : state.rawEvents);
  const selectedTask = filters.taskId;
  pane.innerHTML = `
    <div class="group-toolbar">
      <select id="group-filter-task">
        <option value="">全課題</option>
        ${taskOptions.map((taskId) => `<option value="${escapeHtml(taskId)}" ${taskId === selectedTask ? "selected" : ""}>${escapeHtml(taskId)}</option>`).join("")}
      </select>
      <input id="group-filter-participant" type="text" placeholder="participant/name" value="${escapeHtml(filters.participantText)}">
      <label class="check"><input id="group-exclude-sandbox" type="checkbox" ${filters.excludeSandbox ? "checked" : ""}>sandbox除外</label>
      <label class="check"><input id="group-exclude-incomplete" type="checkbox" ${filters.excludeIncomplete ? "checked" : ""}>未完了除外</label>
      <button id="load-group-analysis">群間分析を更新</button>
      <button class="secondary" id="download-group-csv" ${state.groupMetrics.length ? "" : "disabled"}>参加者別CSV</button>
      <span class="status" id="group-status">${state.groupAnalysisLoaded ? `${state.allEvents.length}件の生ログ` : "未読み込み"}</span>
    </div>
    <div id="group-analysis-body"></div>
  `;
  bindGroupPanelEvents();
  if (state.groupAnalysisLoaded) renderGroupAnalysisBody();
  else $("group-analysis-body").innerHTML = '<div class="empty">参加者を読み込んだ後、「群間分析を更新」を押してください。</div>';
}

function bindGroupPanelEvents() {
  const loadBtn = $("load-group-analysis");
  if (loadBtn) loadBtn.addEventListener("click", loadGroupAnalysis);
  const csvBtn = $("download-group-csv");
  if (csvBtn) csvBtn.addEventListener("click", downloadGroupMetricsCSV);
  ["group-filter-task", "group-filter-participant", "group-exclude-sandbox", "group-exclude-incomplete"].forEach((id) => {
    const el = $(id);
    if (!el) return;
    const eventName = el.type === "checkbox" ? "change" : "input";
    el.addEventListener(eventName, () => {
      if (state.groupAnalysisLoaded) renderGroupAnalysisBody();
    });
  });
}

function renderGroupAnalysisBody() {
  const body = $("group-analysis-body");
  if (!body) return;
  const { metrics, taskRows } = buildGroupAnalysis();
  body.innerHTML = [
    renderGroupSummaryTable(metrics),
    renderMetricRankingTable(metrics),
    renderTaskComparisonTable(taskRows),
    renderAiImprovementTable(metrics),
    renderParticipantMetricsTable(metrics),
  ].join("");
  bindGroupParticipantClicks();
  const csvBtn = $("download-group-csv");
  if (csvBtn) csvBtn.disabled = metrics.length === 0;
}

function renderGroupSummaryTable(metrics) {
  const rows = GROUP_METRICS.map((metric) => {
    const exp = statFor(metrics, metric.key, "experimental");
    const ctrl = statFor(metrics, metric.key, "control");
    const diff = Number.isFinite(exp.mean) && Number.isFinite(ctrl.mean) ? exp.mean - ctrl.mean : NaN;
    const d = standardizedDiff(exp, ctrl);
    return `
      <tr>
        <td>${escapeHtml(metric.label)}</td>
        <td>${metric.fmt(exp.mean)}</td>
        <td>${metric.fmt(ctrl.mean)}</td>
        <td>${metric.fmt(diff)}</td>
        <td>${metric.fmt(exp.median)}</td>
        <td>${metric.fmt(ctrl.median)}</td>
        <td>${escapeHtml(exp.n)} / ${escapeHtml(ctrl.n)}</td>
        <td>${fmtNumber(d)}</td>
      </tr>`;
  }).join("");
  return `
    <div class="block group-block">
      <h3>群別サマリー</h3>
      <div class="scroll group-table-scroll">
        <table class="group-table">
          <thead><tr><th>指標</th><th>experimental平均</th><th>control平均</th><th>差</th><th>experimental中央値</th><th>control中央値</th><th>人数</th><th>標準化差</th></tr></thead>
          <tbody>${rows || '<tr><td colspan="8">対象データなし</td></tr>'}</tbody>
        </table>
      </div>
    </div>`;
}

function renderMetricRankingTable(metrics) {
  const scoreRows = metrics.slice().sort((a, b) => (b.maxScore || -1) - (a.maxScore || -1)).slice(0, 12);
  const stuckRows = metrics.slice().sort((a, b) => (b.executeErrorRate || -1) - (a.executeErrorRate || -1)).slice(0, 12);
  const rowHtml = (metric, value) => `
    <tr class="clickable group-participant-row" data-user-id="${escapeHtml(metric.user_id)}">
      <td>${escapeHtml(metric.participant_id || "未完了")}</td>
      <td>${escapeHtml(metric.role)}</td>
      <td>${escapeHtml(metric.name)}</td>
      <td>${value}</td>
    </tr>`;
  return `
    <div class="block group-block">
      <h3>指標別ランキング</h3>
      <div class="group-columns">
        <div>
          <h3>最高スコア</h3>
          <div class="scroll group-small-scroll"><table><thead><tr><th>ID</th><th>群</th><th>名前</th><th>値</th></tr></thead><tbody>${scoreRows.map((m) => rowHtml(m, fmtNumber(m.maxScore))).join("") || '<tr><td colspan="4">対象データなし</td></tr>'}</tbody></table></div>
        </div>
        <div>
          <h3>実行エラー率</h3>
          <div class="scroll group-small-scroll"><table><thead><tr><th>ID</th><th>群</th><th>名前</th><th>値</th></tr></thead><tbody>${stuckRows.map((m) => rowHtml(m, fmtPercent(m.executeErrorRate))).join("") || '<tr><td colspan="4">対象データなし</td></tr>'}</tbody></table></div>
        </div>
      </div>
    </div>`;
}

function renderTaskComparisonTable(taskRows) {
  const rows = taskRows.map((row) => `
    <tr>
      <td>${escapeHtml(row.taskId)}</td>
      <td>${fmtPercent(row.experimental.clearRate)}</td>
      <td>${fmtPercent(row.control.clearRate)}</td>
      <td>${fmtNumber(row.experimental.avgScore)}</td>
      <td>${fmtNumber(row.control.avgScore)}</td>
      <td>${fmtNumber(row.experimental.avgExecute)}</td>
      <td>${fmtNumber(row.control.avgExecute)}</td>
      <td>${fmtNumber(row.experimental.avgChat)}</td>
      <td>${fmtNumber(row.control.avgChat)}</td>
      <td>${fmtMinutes(row.experimental.avgEditorMinutes)}</td>
      <td>${fmtMinutes(row.control.avgEditorMinutes)}</td>
      <td>${fmtPercent(row.experimental.errorRate)}</td>
      <td>${fmtPercent(row.control.errorRate)}</td>
    </tr>`).join("");
  return `
    <div class="block group-block">
      <h3>課題別比較</h3>
      <div class="scroll group-table-scroll">
        <table class="group-table wide">
          <thead><tr><th>task</th><th>Expクリア率</th><th>Ctrlクリア率</th><th>Expスコア</th><th>Ctrlスコア</th><th>Exp実行</th><th>Ctrl実行</th><th>Exp会話</th><th>Ctrl会話</th><th>Exp滞在</th><th>Ctrl滞在</th><th>Expエラー率</th><th>Ctrlエラー率</th></tr></thead>
          <tbody>${rows || '<tr><td colspan="13">対象データなし</td></tr>'}</tbody>
        </table>
      </div>
    </div>`;
}

function renderAiImprovementTable(metrics) {
  const rows = metrics.slice().sort((a, b) => (b.avgAiScoreImprovement || -Infinity) - (a.avgAiScoreImprovement || -Infinity)).map((m) => `
    <tr class="clickable group-participant-row" data-user-id="${escapeHtml(m.user_id)}">
      <td>${escapeHtml(m.participant_id || "未完了")}</td>
      <td>${escapeHtml(m.role)}</td>
      <td>${fmtNumber(m.avgAiScoreImprovement)}</td>
      <td>${escapeHtml(m.regularChatCount)}</td>
      <td>${escapeHtml(m.aiTouchedTasks)}</td>
      <td>${escapeHtml(m.systemFeedbackCount)}</td>
    </tr>`).join("");
  return `
    <div class="block group-block">
      <h3>AI利用前後の改善</h3>
      <div class="scroll group-table-scroll">
        <table>
          <thead><tr><th>ID</th><th>群</th><th>平均改善</th><th>通常会話</th><th>AI利用課題</th><th>システムFB</th></tr></thead>
          <tbody>${rows || '<tr><td colspan="6">対象データなし</td></tr>'}</tbody>
        </table>
      </div>
    </div>`;
}

function renderParticipantMetricsTable(metrics) {
  const rows = metrics.map((m) => `
    <tr class="clickable group-participant-row" data-user-id="${escapeHtml(m.user_id)}">
      <td>${escapeHtml(m.participant_id || "未完了")}</td>
      <td>${escapeHtml(m.role)}</td>
      <td>${escapeHtml(m.name)}</td>
      <td>${fmtNumber(m.finalLove)}</td>
      <td>${fmtNumber(m.loveGain)}</td>
      <td>${escapeHtml(m.clearedTasks)} / ${escapeHtml(m.taskProgressClearedCount)}</td>
      <td>${fmtNumber(m.avgScore)}</td>
      <td>${fmtNumber(m.maxScore)}</td>
      <td>${escapeHtml(m.executeCount)}</td>
      <td>${fmtPercent(m.executeErrorRate)}</td>
      <td>${escapeHtml(m.gradeCount)}</td>
      <td>${escapeHtml(m.regularChatCount)}</td>
      <td>${fmtMinutes(m.editorMinutes)}</td>
      <td>${escapeHtml(m.estimatedEditorSessions)}</td>
    </tr>`).join("");
  return `
    <div class="block group-block">
      <h3>参加者別メトリクス</h3>
      <div class="scroll group-table-scroll">
        <table class="group-table wide">
          <thead><tr><th>ID</th><th>群</th><th>名前</th><th>最終親密度</th><th>増加量</th><th>クリア/進捗</th><th>平均スコア</th><th>最高</th><th>実行</th><th>エラー率</th><th>採点</th><th>会話</th><th>滞在</th><th>推定滞在</th></tr></thead>
          <tbody>${rows || '<tr><td colspan="14">対象データなし</td></tr>'}</tbody>
        </table>
      </div>
    </div>`;
}

function bindGroupParticipantClicks() {
  document.querySelectorAll(".group-participant-row").forEach((row) => {
    row.addEventListener("click", () => {
      const profile = state.profiles.find((p) => p.id === row.dataset.userId);
      if (!profile) return;
      state.selectedUserId = profile.id;
      state.selectedProfile = profile;
      state.selectedParticipantId = profile.participant_id || "";
      state.selectedEventId = "";
      renderProfiles();
      renderManagePanel();
      setActiveTab("event");
      loadEvents();
      loadTaskProgress();
    });
  });
}

function downloadGroupMetricsCSV() {
  const metrics = state.groupMetrics.length ? state.groupMetrics : buildGroupAnalysis().metrics;
  const headers = [
    "participant_id", "name", "role", "event_count", "final_love", "initial_love", "love_gain", "love_change_count",
    "cleared_tasks_by_score", "cleared_tasks_by_task_progress", "avg_score", "max_score", "pass_score_count",
    "execute_count", "execute_error_count", "execute_error_rate", "grade_count", "grade_fail_count",
    "regular_chat_count", "system_feedback_count", "avg_ai_score_improvement", "editor_minutes", "editor_exit_count",
    "estimated_editor_sessions", "first_execute_minutes", "first_grade_minutes", "first_clear_minutes", "user_id",
  ];
  const rows = metrics.map((m) => [
    m.participant_id, m.name, m.role, m.eventCount, m.finalLove, m.initialLove, m.loveGain, m.loveChangeCount,
    m.clearedTasks, m.taskProgressClearedCount, m.avgScore, m.maxScore, m.passScoreCount,
    m.executeCount, m.executeErrorCount, m.executeErrorRate, m.gradeCount, m.gradeFailCount,
    m.regularChatCount, m.systemFeedbackCount, m.avgAiScoreImprovement, m.editorMinutes, m.editorExitCount,
    m.estimatedEditorSessions, m.firstExecuteMinutes, m.firstGradeMinutes, m.firstClearMinutes, m.user_id,
  ].map(csvEscape).join(","));
  downloadCSV("group_participant_metrics.csv", [headers.join(","), ...rows].join("\r\n"));
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
          participant_id: state.selectedProfile.participant_id || "",
          confirm: $("delete-confirm").value.trim().toUpperCase(),
        });
    state.selectedUserId = "";
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
  downloadCSV(`${state.selectedParticipantId || state.selectedUserId || "incomplete"}_events.csv`, [headers.join(","), ...rows].join("\r\n"));
}

function setActiveTab(tab) {
  document.querySelectorAll(".tab").forEach((btn) => btn.classList.toggle("active", btn.dataset.tab === tab));
  document.querySelectorAll(".tab-pane").forEach((pane) => pane.classList.toggle("active", pane.id === `tab-${tab}`));
  if (tab === "group") renderGroupPanel();
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
        renderChart();
      }

      function onUp() {
        shell.classList.remove("resizing");
        handle.removeEventListener("pointermove", onMove);
        handle.removeEventListener("pointerup", onUp);
        handle.removeEventListener("pointercancel", onUp);
        renderChart();
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
    downloadFile(`${state.selectedParticipantId || state.selectedUserId || "incomplete"}_events.json`, JSON.stringify(state.rawEvents, null, 2), "application/json;charset=utf-8");
  });
  $("filter-event-type").addEventListener("change", buildAndRender);
  $("show-code-snapshots").addEventListener("change", buildAndRender);
  window.addEventListener("resize", renderChart);
  $("admin-password").addEventListener("keydown", (e) => {
    if (e.key === "Enter") loadProfiles();
  });
  document.querySelectorAll(".tab").forEach((btn) => btn.addEventListener("click", () => setActiveTab(btn.dataset.tab)));
}

bindEvents();
renderManagePanel();
renderGroupPanel();
setupResizableLayout();
