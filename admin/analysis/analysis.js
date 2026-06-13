(function() {
  const { $, escapeHtml, setStatus, downloadCSV } = window.AdminUI;
  const api = window.AdminAPI;
  const stats = window.AdminStats;
  const charts = window.AdminCharts;

  const state = {
    profiles: [],
    events: [],
    progress: [],
    experimentData: null,
    tasks: {},
    categories: [],
    taskMeta: new Map(),
    quotaTaskIds: [],
    rows: [],
  };

  const LIKERT = {
    "非常にそう思う": 5,
    "少しそう思う": 4,
    "どちらともいえない": 3,
    "あまりそう思わない": 2,
    "全くそう思わない": 1,
  };

  const COLORS = {
    experimental: "#0f8b8d",
    control: "#ea7a12",
    quota: "#2563eb",
    advanced: "#7c3aed",
  };

  const EXPERIENCE_COLUMNS = {
    programming: "これまでにプログラミングをした経験がある。",
    cpp: "C++の経験がある。",
    languages: "その他に経験したことのあるプログラミング言語と期間を記入してください。　例) C# / 2年, Python / 1.5年",
    selfCoding: "C++の基本的なプログラムを自力で作成できると思う。",
    debug: "プログラムにエラーが出ても原因を探して修正できると思う。",
    persistence: "難しいプログラミング課題でも、諦めずに取り組めると思う。",
  };

  function normalizeId(value) {
    return String(value || "").trim().toUpperCase();
  }

  function cleanText(value) {
    return String(value || "").replace(/\u200b|\u200c|\u200d|\ufeff/g, "").trim();
  }

  function num(value) {
    const parsed = Number(String(value == null ? "" : value).replace(/[^\d.-]/g, ""));
    return Number.isFinite(parsed) ? parsed : NaN;
  }

  function likert(value) {
    return LIKERT[cleanText(value)] || NaN;
  }

  function fmt(value, digits) {
    return stats.fmt(value, digits == null ? 2 : digits);
  }

  function pct(value) {
    return Number.isFinite(value) ? `${fmt(value * 100, 1)}%` : "-";
  }

  function asTime(value) {
    const time = new Date(value).getTime();
    return Number.isFinite(time) ? time : 0;
  }

  function getData(event) {
    return event && event.event_data ? event.event_data : {};
  }

  function getRequestId(event) {
    const data = getData(event);
    return data.request_id || (data.payload && data.payload.request_id) || "";
  }

  function isSystemTriggerLog(event) {
    const data = getData(event);
    return data.source === "system_trigger" || data.is_system_trigger === true;
  }

  function dataset(key) {
    return state.experimentData && state.experimentData.datasets ? state.experimentData.datasets[key] : null;
  }

  function rowByStudent(ds, studentId) {
    if (!ds || !ds.rows || !ds.by_student_id) return null;
    const index = ds.by_student_id[normalizeId(studentId)];
    return Number.isInteger(index) ? ds.rows[index] : null;
  }

  function scoreMax(ds) {
    if (!ds || !ds.columns) return NaN;
    const pointColumns = ds.columns.filter((column) => column.startsWith("点数 - "));
    return pointColumns.length || NaN;
  }

  function eventBelongsToProfile(event, profile) {
    if (event.user_id && profile.id && event.user_id === profile.id) return true;
    if (event.participant_id && profile.participant_id && normalizeId(event.participant_id) === normalizeId(profile.participant_id)) return true;
    return false;
  }

  function progressBelongsToProfile(row, profile) {
    return row.user_id && profile.id && row.user_id === profile.id;
  }

  function buildTaskMetadata(tasks) {
    state.tasks = tasks || {};
    state.categories = Array.isArray(tasks._categories)
      ? tasks._categories.map((category) => ({ id: category.id, label: category.label, short: category.short || category.label }))
      : [];
    state.taskMeta = new Map();
    Object.keys(tasks || {}).forEach((taskId) => {
      if (!/^task\d+$/.test(taskId)) return;
      const task = tasks[taskId] || {};
      const difficulty = Number(task.difficulty);
      state.taskMeta.set(taskId, {
        taskId,
        category: task.category || "未分類",
        difficulty,
        title: task.title || taskId,
        isQuotaTask: Number.isFinite(difficulty) && difficulty <= 2,
        isAdvancedTask: Number.isFinite(difficulty) && difficulty >= 3,
      });
    });
    state.quotaTaskIds = Array.from(state.taskMeta.values())
      .filter((task) => task.isQuotaTask)
      .sort(compareTasks)
      .map((task) => task.taskId);
  }

  function compareTasks(a, b) {
    const ac = categoryIndex(a.category);
    const bc = categoryIndex(b.category);
    if (ac !== bc) return ac - bc;
    if (a.difficulty !== b.difficulty) return a.difficulty - b.difficulty;
    return a.taskId.localeCompare(b.taskId, "ja", { numeric: true });
  }

  function categoryIndex(categoryLabel) {
    const index = state.categories.findIndex((category) => category.label === categoryLabel);
    return index >= 0 ? index : 999;
  }

  function emptyTaskMetric(taskId) {
    const meta = state.taskMeta.get(taskId) || { taskId, category: "未分類", difficulty: NaN };
    return {
      taskId,
      category: meta.category,
      difficulty: meta.difficulty,
      isQuotaTask: !!meta.isQuotaTask,
      isAdvancedTask: !!meta.isAdvancedTask,
      maxScore: NaN,
      cleared: false,
      executeCount: 0,
      executeErrorCount: 0,
      gradeCount: 0,
      chatCount: 0,
      systemFeedbackCount: 0,
      editorMs: 0,
      estimatedSessions: 0,
      firstClearExecuteCount: NaN,
      scoreEvents: [],
      chatTimes: [],
    };
  }

  function buildLogMetrics(profile) {
    const perTask = new Map();
    const events = state.events
      .filter((event) => eventBelongsToProfile(event, profile))
      .filter((event) => event.task_id !== "sandbox" && getData(event).is_sandbox !== true)
      .sort((a, b) => asTime(a.created_at) - asTime(b.created_at));
    const progress = state.progress.filter((row) => progressBelongsToProfile(row, profile) && row.task_id !== "sandbox");
    const openEditors = new Map();
    const lastEventByKey = new Map();
    const systemRequests = new Set();

    function task(taskId) {
      const key = taskId || "(taskなし)";
      if (!perTask.has(key)) perTask.set(key, emptyTaskMetric(key));
      return perTask.get(key);
    }

    events.forEach((event) => {
      const data = getData(event);
      const time = asTime(event.created_at);
      const taskId = event.task_id || "";
      const key = `${event.session_id || ""}|${taskId}`;
      if (time) lastEventByKey.set(key, time);
      if (taskId) task(taskId);

      if (event.event_type === "screen_transition" && data.screen === "editor") {
        if (data.action === "enter") {
          if (!openEditors.has(key)) openEditors.set(key, { time, taskId });
        } else if (data.action === "exit") {
          const open = openEditors.get(key);
          if (open && time >= open.time) {
            task(taskId).editorMs += time - open.time;
            openEditors.delete(key);
          }
        }
      }

      if (event.event_type === "execute_start") {
        task(taskId).executeCount++;
      } else if (event.event_type === "execute_result" && data.is_error === true) {
        task(taskId).executeErrorCount++;
      } else if (event.event_type === "grade_result") {
        const t = task(taskId);
        const score = num(data.score);
        t.gradeCount++;
        if (Number.isFinite(score)) {
          t.scoreEvents.push({ time, score });
          t.maxScore = Number.isFinite(t.maxScore) ? Math.max(t.maxScore, score) : score;
          if (score >= 80) {
            t.cleared = true;
            if (!Number.isFinite(t.firstClearExecuteCount)) t.firstClearExecuteCount = t.executeCount;
          }
        }
      } else if (event.event_type === "chat_user_payload") {
        const t = task(taskId);
        if (isSystemTriggerLog(event)) {
          const requestId = getRequestId(event) || `${event.session_id || ""}-${event.created_at}`;
          systemRequests.add(requestId);
          t.systemFeedbackCount++;
        } else {
          t.chatCount++;
          t.chatTimes.push(time);
        }
      }
    });

    openEditors.forEach((open, key) => {
      const end = lastEventByKey.get(key);
      if (!Number.isFinite(end) || end < open.time) return;
      const t = task(open.taskId);
      t.editorMs += end - open.time;
      t.estimatedSessions++;
    });

    progress.forEach((row) => {
      const t = task(row.task_id);
      if (row.is_cleared) t.cleared = true;
      const highScore = num(row.high_score);
      if (Number.isFinite(highScore)) t.maxScore = Number.isFinite(t.maxScore) ? Math.max(t.maxScore, highScore) : highScore;
    });

    const allTasks = Array.from(perTask.values());
    const quotaTasks = state.quotaTaskIds.map((taskId) => perTask.get(taskId) || emptyTaskMetric(taskId));
    const advancedTasks = allTasks.filter((t) => t.isAdvancedTask);
    const aggregate = aggregateTasks(allTasks);
    const quota = aggregateTasks(quotaTasks);
    const advanced = aggregateTasks(advancedTasks);

    return {
      eventCount: events.length,
      systemFeedbackCount: systemRequests.size,
      perTask,
      ...prefixMetrics("all", aggregate),
      ...prefixMetrics("quota", quota),
      ...prefixMetrics("advanced", advanced),
      quotaAiNextScoreImprovement: aiNextScoreImprovement(quotaTasks),
    };
  }

  function aggregateTasks(tasks) {
    const executeCount = sum(tasks, "executeCount");
    const executeErrorCount = sum(tasks, "executeErrorCount");
    const gradeCount = sum(tasks, "gradeCount");
    const chatCount = sum(tasks, "chatCount");
    const systemFeedbackCount = sum(tasks, "systemFeedbackCount");
    const editorMs = sum(tasks, "editorMs");
    const clearedTasks = tasks.filter((t) => t.cleared).length;
    const scoreValues = tasks.map((t) => t.maxScore).filter(Number.isFinite);
    return {
      taskCount: tasks.length,
      clearedTasks,
      completionRate: tasks.length ? clearedTasks / tasks.length : NaN,
      avgScore: stats.mean(scoreValues),
      maxScore: scoreValues.length ? Math.max(...scoreValues) : NaN,
      executeCount,
      gradeCount,
      chatCount,
      systemFeedbackCount,
      editorMinutes: editorMs / 60000,
      errorRate: executeCount ? executeErrorCount / executeCount : NaN,
      firstClearExecuteAvg: stats.mean(tasks.map((t) => t.firstClearExecuteCount)),
      estimatedEditorSessions: sum(tasks, "estimatedSessions"),
    };
  }

  function prefixMetrics(prefix, metrics) {
    const out = {};
    Object.keys(metrics).forEach((key) => {
      out[`${prefix}${key[0].toUpperCase()}${key.slice(1)}`] = metrics[key];
    });
    return out;
  }

  function sum(items, key) {
    return items.reduce((total, item) => total + (Number(item[key]) || 0), 0);
  }

  function aiNextScoreImprovement(tasks) {
    const values = [];
    tasks.forEach((task) => {
      task.chatTimes.forEach((chatTime) => {
        const previous = task.scoreEvents.filter((score) => score.time < chatTime).pop();
        const next = task.scoreEvents.find((score) => score.time > chatTime);
        if (previous && next) values.push(next.score - previous.score);
      });
    });
    return stats.mean(values);
  }

  function surveyMetrics(studentId, role) {
    const pre1 = rowByStudent(dataset("pre_survey_1"), studentId) || {};
    const post = rowByStudent(dataset(role === "experimental" ? "post_survey_experimental" : "post_survey_control"), studentId) || {};
    const programmingExperience = likert(pre1[EXPERIENCE_COLUMNS.programming]);
    const cppExperience = likert(pre1[EXPERIENCE_COLUMNS.cpp]);
    const selfCoding = likert(pre1[EXPERIENCE_COLUMNS.selfCoding]);
    const debug = likert(pre1[EXPERIENCE_COLUMNS.debug]);
    const persistence = likert(pre1[EXPERIENCE_COLUMNS.persistence]);
    const experienceScore = stats.mean([programmingExperience, cppExperience, selfCoding, debug, persistence]);
    const valuesByIncludes = (row, patterns) => Object.keys(row)
      .filter((column) => patterns.some((pattern) => column.includes(pattern)))
      .map((column) => likert(row[column]));
    return {
      programmingExperience,
      cppExperience,
      selfCoding,
      debug,
      persistence,
      experienceScore,
      languageExperience: pre1[EXPERIENCE_COLUMNS.languages] || "",
      postSystem: stats.mean(valuesByIncludes(post, ["楽しかった", "上手くこなせた", "役立つ", "使って学習を続けたい"])),
      postIntimacy: stats.mean(valuesByIncludes(post, ["親しみ", "一緒に学習", "関係が深ま", "親密度"])),
      freeReason: post["評価の理由について教えてください。"] || "",
      freeAgent: post["エージェントの言葉や振る舞いで印象に残ったことがあれば教えてください。"] || "",
      freeMotivation: post["学習のやる気が上がった（または下がった）瞬間があれば教えてください。"] || "",
      freeComment: post["自由記述(システムの感想・不満点など)"] || "",
    };
  }

  function buildRows() {
    const preDataset = dataset("pre_test");
    const postDataset = dataset("post_test");
    const preMax = scoreMax(preDataset);
    const postMax = scoreMax(postDataset);
    const maxScore = Number.isFinite(postMax) ? postMax : preMax;

    state.rows = state.profiles.map((profile) => {
      const studentId = normalizeId(profile.participant_id);
      const pre = rowByStudent(preDataset, studentId);
      const post = rowByStudent(postDataset, studentId);
      const preScore = pre ? num(pre["合計点数"]) : NaN;
      const postScore = post ? num(post["合計点数"]) : NaN;
      const gain = Number.isFinite(preScore) && Number.isFinite(postScore) ? postScore - preScore : NaN;
      const normalizedGain = Number.isFinite(gain) && Number.isFinite(maxScore) && maxScore > preScore ? gain / (maxScore - preScore) : NaN;
      const logs = buildLogMetrics(profile);
      const survey = surveyMetrics(studentId, profile.role);
      return {
        id: profile.id,
        participantId: studentId,
        name: profile.name || "",
        role: profile.role || "未割当",
        loveLevel: num(profile.love_level),
        preScore,
        postScore,
        gain,
        normalizedGain,
        preLevel: preScoreLevel(preScore),
        hasPre: !!pre,
        hasPost: !!post,
        ...logs,
        ...survey,
      };
    });
  }

  function preScoreLevel(score) {
    if (!Number.isFinite(score)) return "不明";
    if (score <= 1) return "低";
    if (score <= 3) return "中";
    return "高";
  }

  function filteredRows() {
    const role = $("role-filter").value;
    const text = $("participant-filter").value.trim().toLowerCase();
    return state.rows.filter((row) => {
      if (role && row.role !== role) return false;
      if (!text) return true;
      return `${row.participantId} ${row.name}`.toLowerCase().includes(text);
    });
  }

  function groupValues(rows, key, role) {
    return rows.filter((row) => row.role === role).map((row) => row[key]);
  }

  function renderSummary(rows) {
    const exp = rows.filter((row) => row.role === "experimental").length;
    const ctrl = rows.filter((row) => row.role === "control").length;
    const matched = rows.filter((row) => row.hasPre || row.hasPost).length;
    $("summary-cards").innerHTML = [
      ["対象参加者", rows.length],
      ["experimental", exp],
      ["control", ctrl],
      ["CSV結合済み", matched],
      ["ノルマ課題", state.quotaTaskIds.join(", ")],
    ].map(([label, value]) => `<div class="summary-card"><div class="label">${escapeHtml(label)}</div><div class="value">${escapeHtml(value)}</div></div>`).join("");
  }

  function renderStatsTable(id, rows, metrics) {
    const header = "<thead><tr><th class=\"metric-name\">指標</th><th>Exp n</th><th>Exp平均</th><th>Exp中央値</th><th>Exp SD</th><th>Ctrl n</th><th>Ctrl平均</th><th>Ctrl中央値</th><th>Ctrl SD</th><th>平均差</th><th>Cohen's d</th></tr></thead>";
    const body = metrics.map((metric) => {
      const exp = groupValues(rows, metric.key, "experimental");
      const ctrl = groupValues(rows, metric.key, "control");
      const expMean = stats.mean(exp);
      const ctrlMean = stats.mean(ctrl);
      return `<tr>
        <td class="metric-name">${escapeHtml(metric.label)}</td>
        <td>${stats.finite(exp).length}</td><td>${fmt(expMean)}</td><td>${fmt(stats.median(exp))}</td><td>${fmt(stats.stddev(exp))}</td>
        <td>${stats.finite(ctrl).length}</td><td>${fmt(ctrlMean)}</td><td>${fmt(stats.median(ctrl))}</td><td>${fmt(stats.stddev(ctrl))}</td>
        <td>${fmt(expMean - ctrlMean)}</td><td>${fmt(stats.cohenD(exp, ctrl))}</td>
      </tr>`;
    }).join("");
    $(id).innerHTML = header + `<tbody>${body || '<tr><td colspan="11">対象データなし</td></tr>'}</tbody>`;
  }

  function fmt(value, digits) {
    return stats.fmt(value, digits == null ? 2 : digits);
  }

  function pct(value) {
    return Number.isFinite(value) ? `${fmt(value * 100, 1)}%` : "-";
  }

  function renderLearning(rows) {
    renderStatsTable("learning-table", rows, [
      { key: "preScore", label: "事前テスト" },
      { key: "postScore", label: "事後テスト" },
      { key: "gain", label: "点数差" },
      { key: "normalizedGain", label: "正規化ゲイン" },
      { key: "quotaClearedTasks", label: "ノルマ10問 達成数" },
      { key: "quotaCompletionRate", label: "ノルマ10問 達成率" },
      { key: "quotaAvgScore", label: "ノルマ10問 平均最高スコア" },
      { key: "quotaErrorRate", label: "ノルマ10問 エラー率" },
      { key: "quotaChatCount", label: "ノルマ10問 AI会話回数" },
      { key: "advancedClearedTasks", label: "発展課題 達成数" },
    ]);
    charts.bar("learning-chart", ["事前", "事後", "差", "ノルマ達成率"], [
      { label: "experimental", backgroundColor: COLORS.experimental, data: ["preScore", "postScore", "gain", "quotaCompletionRate"].map((key) => stats.mean(groupValues(rows, key, "experimental"))) },
      { label: "control", backgroundColor: COLORS.control, data: ["preScore", "postScore", "gain", "quotaCompletionRate"].map((key) => stats.mean(groupValues(rows, key, "control"))) },
    ]);
  }

  function renderExperience(rows) {
    renderStatsTable("experience-table", rows, [
      { key: "programmingExperience", label: "プログラミング経験" },
      { key: "cppExperience", label: "C++経験" },
      { key: "selfCoding", label: "C++自力作成感" },
      { key: "debug", label: "エラー修正自己効力感" },
      { key: "persistence", label: "難課題への粘り強さ" },
      { key: "experienceScore", label: "経験・自己効力感平均" },
      { key: "preScore", label: "事前テスト" },
    ]);
    renderPreLevelTable(rows);
    renderLanguageExperience(rows);
  }

  function renderPreLevelTable(rows) {
    const levels = ["低", "中", "高", "不明"];
    const html = levels.map((level) => {
      const levelRows = rows.filter((row) => row.preLevel === level);
      return `<tr>
        <td>${escapeHtml(level)}</td>
        <td>${levelRows.length}</td>
        <td>${levelRows.filter((r) => r.role === "experimental").length}</td>
        <td>${levelRows.filter((r) => r.role === "control").length}</td>
        <td>${fmt(stats.mean(levelRows.map((r) => r.gain)))}</td>
        <td>${fmt(stats.mean(levelRows.map((r) => r.quotaCompletionRate)))}</td>
      </tr>`;
    }).join("");
    $("pre-level-table").innerHTML = `<thead><tr><th>事前水準</th><th>人数</th><th>Exp</th><th>Ctrl</th><th>平均点数差</th><th>ノルマ達成率</th></tr></thead><tbody>${html}</tbody>`;
  }

  function renderLanguageExperience(rows) {
    $("language-table").innerHTML = "<thead><tr><th>ID</th><th>群</th><th>経験言語・期間</th></tr></thead><tbody>" + rows.map((row) => `
      <tr><td>${escapeHtml(row.participantId)}</td><td>${escapeHtml(row.role)}</td><td class="free-text">${escapeHtml(row.languageExperience)}</td></tr>
    `).join("") + "</tbody>";
  }

  function renderQuotaCorrelations(rows) {
    const metrics = [
      ["quotaCompletionRate", "ノルマ達成率"],
      ["quotaFirstClearExecuteAvg", "初回クリアまでの実行回数"],
      ["quotaErrorRate", "ノルマエラー率"],
      ["quotaAiNextScoreImprovement", "AI利用後の次回採点改善"],
      ["quotaChatCount", "ノルマAI会話回数"],
      ["quotaGradeCount", "ノルマ採点回数"],
    ];
    $("correlation-table").innerHTML = "<thead><tr><th class=\"metric-name\">探索指標</th><th>点数差 r</th><th>正規化ゲイン r</th></tr></thead><tbody>" + metrics.map(([key, label]) => `
      <tr><td class="metric-name">${escapeHtml(label)}</td><td>${fmt(stats.pearson(rows.map((r) => r[key]), rows.map((r) => r.gain)))}</td><td>${fmt(stats.pearson(rows.map((r) => r[key]), rows.map((r) => r.normalizedGain)))}</td></tr>
    `).join("") + "</tbody>";
    charts.scatter("scatter-chart", [
      { label: "experimental", backgroundColor: COLORS.experimental, data: rows.filter((r) => r.role === "experimental").map((r) => ({ x: r.quotaCompletionRate, y: r.gain })) },
      { label: "control", backgroundColor: COLORS.control, data: rows.filter((r) => r.role === "control").map((r) => ({ x: r.quotaCompletionRate, y: r.gain })) },
    ], "ノルマ10問達成率", "点数差");
  }

  function taskRows(rows, mode) {
    const taskIds = Array.from(state.taskMeta.values())
      .filter((task) => mode === "quota" ? task.isQuotaTask : task.isAdvancedTask)
      .sort(compareTasks)
      .map((task) => task.taskId);
    return taskIds.map((taskId) => {
      const meta = state.taskMeta.get(taskId);
      const out = { taskId, category: meta.category, difficulty: meta.difficulty };
      ["experimental", "control"].forEach((role) => {
        const items = rows.filter((row) => row.role === role).map((row) => row.perTask.get(taskId) || emptyTaskMetric(taskId));
        out[role] = taskStats(items);
      });
      return out;
    });
  }

  function categoryRows(rows) {
    return state.categories.map((category) => {
      const taskIds = Array.from(state.taskMeta.values()).filter((task) => task.category === category.label).map((task) => task.taskId);
      const out = { category: category.label };
      ["experimental", "control"].forEach((role) => {
        const items = rows.filter((row) => row.role === role).flatMap((row) => taskIds.map((taskId) => row.perTask.get(taskId) || emptyTaskMetric(taskId)));
        out[role] = taskStats(items);
      });
      return out;
    });
  }

  function taskStats(items) {
    const executeCount = sum(items, "executeCount");
    const executeErrorCount = sum(items, "executeErrorCount");
    return {
      n: items.length,
      clearRate: items.length ? items.filter((item) => item.cleared).length / items.length : NaN,
      avgScore: stats.mean(items.map((item) => item.maxScore)),
      avgExecute: stats.mean(items.map((item) => item.executeCount)),
      avgGrade: stats.mean(items.map((item) => item.gradeCount)),
      avgChat: stats.mean(items.map((item) => item.chatCount)),
      avgEditor: stats.mean(items.map((item) => item.editorMs / 60000)),
      errorRate: executeCount ? executeErrorCount / executeCount : NaN,
    };
  }

  function renderQuotaTasks(rows) {
    const quota = taskRows(rows, "quota");
    renderTaskTable("quota-task-table", quota);
    charts.bar("task-chart", quota.map((row) => row.taskId), [
      { label: "Exp達成率", backgroundColor: COLORS.experimental, data: quota.map((row) => Number.isFinite(row.experimental.clearRate) ? row.experimental.clearRate * 100 : 0) },
      { label: "Ctrl達成率", backgroundColor: COLORS.control, data: quota.map((row) => Number.isFinite(row.control.clearRate) ? row.control.clearRate * 100 : 0) },
    ], "ノルマ10問 達成率(%)");
  }

  function renderCategoryTasks(rows) {
    renderCategoryTable("category-table", categoryRows(rows));
    renderTaskTable("advanced-task-table", taskRows(rows, "advanced"));
  }

  function renderTaskTable(id, rows) {
    $(id).innerHTML = "<thead><tr><th>task</th><th>カテゴリ</th><th>難易度</th><th>Exp達成率</th><th>Ctrl達成率</th><th>Exp最高</th><th>Ctrl最高</th><th>Exp実行</th><th>Ctrl実行</th><th>Exp採点</th><th>Ctrl採点</th><th>Exp会話</th><th>Ctrl会話</th><th>Expエラー率</th><th>Ctrlエラー率</th></tr></thead><tbody>" + rows.map((row) => `
      <tr><td>${escapeHtml(row.taskId)}</td><td class="metric-name">${escapeHtml(row.category)}</td><td>${escapeHtml(row.difficulty)}</td><td>${pct(row.experimental.clearRate)}</td><td>${pct(row.control.clearRate)}</td><td>${fmt(row.experimental.avgScore)}</td><td>${fmt(row.control.avgScore)}</td><td>${fmt(row.experimental.avgExecute)}</td><td>${fmt(row.control.avgExecute)}</td><td>${fmt(row.experimental.avgGrade)}</td><td>${fmt(row.control.avgGrade)}</td><td>${fmt(row.experimental.avgChat)}</td><td>${fmt(row.control.avgChat)}</td><td>${pct(row.experimental.errorRate)}</td><td>${pct(row.control.errorRate)}</td></tr>
    `).join("") + "</tbody>";
  }

  function renderCategoryTable(id, rows) {
    $(id).innerHTML = "<thead><tr><th class=\"metric-name\">カテゴリ</th><th>Exp達成率</th><th>Ctrl達成率</th><th>Exp最高</th><th>Ctrl最高</th><th>Exp実行</th><th>Ctrl実行</th><th>Exp会話</th><th>Ctrl会話</th><th>Exp滞在分</th><th>Ctrl滞在分</th><th>Expエラー率</th><th>Ctrlエラー率</th></tr></thead><tbody>" + rows.map((row) => `
      <tr><td class="metric-name">${escapeHtml(row.category)}</td><td>${pct(row.experimental.clearRate)}</td><td>${pct(row.control.clearRate)}</td><td>${fmt(row.experimental.avgScore)}</td><td>${fmt(row.control.avgScore)}</td><td>${fmt(row.experimental.avgExecute)}</td><td>${fmt(row.control.avgExecute)}</td><td>${fmt(row.experimental.avgChat)}</td><td>${fmt(row.control.avgChat)}</td><td>${fmt(row.experimental.avgEditor)}</td><td>${fmt(row.control.avgEditor)}</td><td>${pct(row.experimental.errorRate)}</td><td>${pct(row.control.errorRate)}</td></tr>
    `).join("") + "</tbody>";
  }

  function renderSurveys(rows) {
    renderStatsTable("survey-table", rows, [
      { key: "postSystem", label: "事後 システム評価" },
      { key: "postIntimacy", label: "事後 親密度/エージェント評価" },
      { key: "experienceScore", label: "事前 経験・自己効力感平均" },
    ]);
    $("free-text-table").innerHTML = "<thead><tr><th>ID</th><th>群</th><th>評価理由</th><th>印象</th><th>やる気</th><th>自由記述</th></tr></thead><tbody>" + rows.map((row) => `
      <tr><td>${escapeHtml(row.participantId)}</td><td>${escapeHtml(row.role)}</td><td class="free-text">${escapeHtml(row.freeReason)}</td><td class="free-text">${escapeHtml(row.freeAgent)}</td><td class="free-text">${escapeHtml(row.freeMotivation)}</td><td class="free-text">${escapeHtml(row.freeComment)}</td></tr>
    `).join("") + "</tbody>";
  }

  function renderParticipants(rows) {
    $("participant-table").innerHTML = "<thead><tr><th>ID</th><th>名前</th><th>群</th><th>事前</th><th>事後</th><th>差</th><th>正規化</th><th>事前水準</th><th>経験平均</th><th>ノルマ達成</th><th>ノルマ率</th><th>ノルマ平均</th><th>ノルマ実行</th><th>ノルマエラー率</th><th>ノルマ会話</th><th>AI後改善</th><th>発展達成</th></tr></thead><tbody>" + rows.map((row) => `
      <tr><td>${escapeHtml(row.participantId || "未完了")}</td><td>${escapeHtml(row.name)}</td><td>${escapeHtml(row.role)}</td><td>${fmt(row.preScore)}</td><td>${fmt(row.postScore)}</td><td>${fmt(row.gain)}</td><td>${fmt(row.normalizedGain)}</td><td>${escapeHtml(row.preLevel)}</td><td>${fmt(row.experienceScore)}</td><td>${fmt(row.quotaClearedTasks, 0)}</td><td>${pct(row.quotaCompletionRate)}</td><td>${fmt(row.quotaAvgScore)}</td><td>${fmt(row.quotaExecuteCount, 0)}</td><td>${pct(row.quotaErrorRate)}</td><td>${fmt(row.quotaChatCount, 0)}</td><td>${fmt(row.quotaAiNextScoreImprovement)}</td><td>${fmt(row.advancedClearedTasks, 0)}</td></tr>
    `).join("") + "</tbody>";
  }

  function renderAll() {
    const rows = filteredRows();
    renderSummary(rows);
    renderLearning(rows);
    renderExperience(rows);
    renderQuotaCorrelations(rows);
    renderQuotaTasks(rows);
    renderCategoryTasks(rows);
    renderSurveys(rows);
    renderParticipants(rows);
    $("download-analysis-csv").disabled = rows.length === 0;
  }

  async function loadAnalysis() {
    api.setPassword($("admin-password").value);
    if (!api.getPassword()) {
      setStatus("analysis-status", "管理パスワードを入力してください", true);
      return;
    }
    setStatus("analysis-status", "読み込み中...");
    try {
      const [profiles, events, progress, experimentData, tasks] = await Promise.all([
        api.fetchJSON("/api/admin/profiles"),
        api.fetchJSON("/api/admin/events?limit=200000"),
        api.fetchJSON("/api/admin/task-progress"),
        api.fetchJSON("/api/admin/experiment-data"),
        fetch("/data/others/tasks.json").then((res) => res.json()),
      ]);
      state.profiles = profiles.profiles || [];
      state.events = events.events || [];
      state.progress = progress.task_progress || [];
      state.experimentData = experimentData;
      buildTaskMetadata(tasks);
      buildRows();
      renderAll();
      setStatus("analysis-status", `${state.rows.length}名 / ${state.events.length}ログ / ノルマ${state.quotaTaskIds.length}問`);
    } catch (error) {
      setStatus("analysis-status", error.message, true);
    }
  }

  function downloadRows() {
    const rows = filteredRows();
    const headers = ["participant_id", "name", "role", "pre_score", "post_score", "gain", "normalized_gain", "pre_level", "experience_score", "programming_experience", "cpp_experience", "self_coding", "debug", "persistence", "quota_cleared_tasks", "quota_completion_rate", "quota_avg_score", "quota_execute_count", "quota_grade_count", "quota_error_rate", "quota_chat_count", "quota_ai_next_score_improvement", "advanced_cleared_tasks", "language_experience"];
    downloadCSV("analysis_participant_metrics.csv", headers, rows.map((row) => [
      row.participantId, row.name, row.role, row.preScore, row.postScore, row.gain, row.normalizedGain, row.preLevel, row.experienceScore, row.programmingExperience, row.cppExperience, row.selfCoding, row.debug, row.persistence, row.quotaClearedTasks, row.quotaCompletionRate, row.quotaAvgScore, row.quotaExecuteCount, row.quotaGradeCount, row.quotaErrorRate, row.quotaChatCount, row.quotaAiNextScoreImprovement, row.advancedClearedTasks, row.languageExperience,
    ]));
  }

  function bindEvents() {
    $("load-analysis").addEventListener("click", loadAnalysis);
    $("download-analysis-csv").addEventListener("click", downloadRows);
    $("role-filter").addEventListener("change", renderAll);
    $("participant-filter").addEventListener("input", renderAll);
    $("admin-password").addEventListener("keydown", (event) => {
      if (event.key === "Enter") loadAnalysis();
    });
  }

  $("admin-password").value = api.getPassword();
  bindEvents();
})();
