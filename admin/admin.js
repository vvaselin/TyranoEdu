const state = {
  password: "",
  profiles: [],
  rawEvents: [],
  analysisEvents: [],
  taskProgress: [],
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
  } catch (error) {
    setStatus("profile-status", error.message, true);
  }
}

function renderProfiles() {
  const body = $("profiles-body");
  if (!body) {
    setStatus("profile-status", "参加者一覧の表示領域が見つかりません。ページを再読み込みしてください。", true);
    return;
  }

  body.innerHTML = state.profiles.map((p) => `
    <tr class="clickable ${p.id === state.selectedUserId ? "selected" : ""}" data-user-id="${escapeHtml(p.id)}">
      <td title="${escapeHtml(p.participant_id || p.id)}">${escapeHtml(p.participant_id || "未完了")}</td>
      <td title="${escapeHtml(p.name)}">${escapeHtml(p.name)}</td>
      <td>${escapeHtml(p.role || "未割当")}</td>
      <td>${escapeHtml(p.love_level)}</td>
    </tr>
  `).join("");

  body.querySelectorAll("tr").forEach((row) => {
    row.addEventListener("click", () => {
      state.selectedUserId = row.dataset.userId;
      state.selectedProfile = state.profiles.find((p) => p.id === state.selectedUserId) || null;
      state.selectedParticipantId = (state.selectedProfile && state.selectedProfile.participant_id) || "";
      state.selectedEventId = "";
      renderProfiles();
      loadEvents();
    });
  });

  const downloadProfiles = $("download-profiles");
  if (downloadProfiles) downloadProfiles.disabled = state.profiles.length === 0;
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
setupResizableLayout();
