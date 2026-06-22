(function() {
  "use strict";

  const { $, escapeHtml, setStatus, downloadCSV } = window.AdminUI;
  const api = window.AdminAPI;
  const charts = window.AdminCharts;

  const state = { profiles: [], experimentData: null, rows: [] };
  const COLORS = {
    experimental: "#0f8b8d",
    experimentalPre: "#58a5a6",
    control: "#ea7a12",
    controlPre: "#e99b55",
  };
  const ROLE_LABEL = { experimental: "実験群", control: "統制群" };

  const COLUMNS = {
    id: "学籍番号",
    gender: "性別",
    preSelfCoding: "C++の基本的なプログラムを自力で作成できると思う。",
    preDebug: "プログラムにエラーが出ても原因を探して修正できると思う。",
    prePersistence: "難しいプログラミング課題でも、諦めずに取り組めると思う。",
    preInterest: "プログラミング学習に興味がある。",
    preContinue: "今後もプログラミングを学び続けたいと思う。",
    novel: "ノベルゲームやビジュアルノベル（例：『逆転裁判』『Fate』など）を普段からプレイしている。",
    empathy: "ゲームや物語に登場するキャラクターに感情移入しやすい。",
    enjoyment: "このシステムでの学習は楽しかった。",
    accomplishment: "課題を上手くこなせたと感じた。",
    anxiety: "学習中、不安やプレッシャーを感じた。",
    usefulness: "このシステムはプログラミング学習に役立つと思う。",
    continuedUse: "今後もこのシステムを使って学習を続けたいと思う。",
    intimacy: "エージェントに対して親しみを感じた。",
    together: "エージェントと一緒に学習している感覚があった。",
    relationship: "エージェントとの関係が深まっているように感じた。",
    episodeMotivation: "エピソードを進めることが、課題に取り組む動機づけになった。",
    intimacyMotivation: "親密度が上がる仕組みによって、学習を続けようという気持ちが高まった。",
    intimacyCloseness: "親密度の変化に応じて、エージェントとの距離が近づいたように感じた。",
    intimacyNaturalness: "親密度に応じたエージェントの言葉遣いや反応の変化は自然だった。",
  };

  const ATTITUDE_ITEMS = [
    { label: "C++の基本的なプログラムを自力で作成できると思う", short: "自力作成", column: COLUMNS.preSelfCoding, preKey: "preSelfCoding", postKey: "postSelfCoding", gainKey: "selfCodingGain", csvKey: "self_coding" },
    { label: "プログラムにエラーが出ても原因を探して修正できると思う", short: "エラー修正", column: COLUMNS.preDebug, preKey: "preDebug", postKey: "postDebug", gainKey: "debugGain", csvKey: "debug" },
    { label: "難しいプログラミング課題でも、諦めずに取り組めると思う", short: "課題への継続", column: COLUMNS.prePersistence, preKey: "prePersistence", postKey: "postPersistence", gainKey: "persistenceGain", csvKey: "persistence" },
    { label: "プログラミング学習に興味がある", short: "学習への興味", column: COLUMNS.preInterest, preKey: "preInterest", postKey: "postInterest", gainKey: "interestGain", csvKey: "interest" },
    { label: "今後もプログラミングを学び続けたいと思う", short: "学習継続意向", column: COLUMNS.preContinue, preKey: "preContinue", postKey: "postContinue", gainKey: "continueGain", csvKey: "continue" },
  ];

  const INTIMACY_METRICS = [
    ["intimacyMotivation", "親密度が上昇することで、学習を続けたいという気持ちが高まった"],
    ["intimacyCloseness", "親密度の変化に応じて、エージェントとの距離が近づいたと感じた"],
    ["intimacyNaturalness", "親密度に応じたエージェントの言葉遣いや反応の変化は自然だった"],
  ];

  const ILS_AXES = [
    { key: "ilsActiveReflective", short: "ACT/REF", left: "活動型", right: "内省型", start: 1 },
    { key: "ilsSensingIntuitive", short: "SNS/INT", left: "感覚型", right: "直観型", start: 2 },
    { key: "ilsVisualVerbal", short: "VIS/VRB", left: "視覚型", right: "言語型", start: 3 },
    { key: "ilsSequentialGlobal", short: "SEQ/GLO", left: "順序型", right: "全体型", start: 4 },
  ];

  function clean(value) {
    return String(value == null ? "" : value).replace(/[\u200b-\u200d\ufeff]/g, "").trim();
  }

  function normalizeId(value) {
    return clean(value).toUpperCase().replace(/[^0-9A-Z]/g, "");
  }

  function finite(values) { return values.filter(Number.isFinite); }
  function mean(values) { const xs = finite(values); return xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : NaN; }
  function median(values) { const xs = finite(values).sort((a, b) => a - b); if (!xs.length) return NaN; const m = Math.floor(xs.length / 2); return xs.length % 2 ? xs[m] : (xs[m - 1] + xs[m]) / 2; }
  function sd(values) { const xs = finite(values); if (xs.length < 2) return NaN; const m = mean(xs); return Math.sqrt(xs.reduce((s, x) => s + (x - m) ** 2, 0) / (xs.length - 1)); }
  function cohenD(a, b) { const x = finite(a), y = finite(b); if (x.length < 2 || y.length < 2) return NaN; const vx = sd(x) ** 2, vy = sd(y) ** 2; const pooled = Math.sqrt(((x.length - 1) * vx + (y.length - 1) * vy) / (x.length + y.length - 2)); return pooled ? (mean(x) - mean(y)) / pooled : NaN; }
  function fmt(value, digits) { return Number.isFinite(value) ? value.toFixed(digits == null ? 2 : digits) : "-"; }
  function n(values) { return finite(values).length; }
  function number(value) { const x = Number(clean(value).replace(/[^0-9.-]/g, "")); return Number.isFinite(x) ? x : NaN; }
  function scale(value) { const x = number(value); return x >= 1 && x <= 5 ? x : NaN; }

  function datasets() {
    return Object.values((state.experimentData && state.experimentData.datasets) || {}).filter((ds) => ds && Array.isArray(ds.rows));
  }

  function hasColumn(ds, text) {
    return (ds.columns || Object.keys(ds.rows[0] || {})).some((column) => clean(column).includes(text));
  }

  function findDataset(required, preferredKeys) {
    const map = (state.experimentData && state.experimentData.datasets) || {};
    for (const key of preferredKeys || []) {
      if (map[key] && required.every((text) => hasColumn(map[key], text))) return map[key];
    }
    return datasets().find((ds) => required.every((text) => hasColumn(ds, text))) || null;
  }

  function findColumn(row, target) {
    if (!row) return null;
    if (Object.prototype.hasOwnProperty.call(row, target)) return target;
    const normalized = clean(target).replace(/^[.。]+/, "");
    return Object.keys(row).find((column) => clean(column).replace(/^[.。]+/, "").endsWith(normalized)) || null;
  }

  function valueOf(row, target) {
    const column = findColumn(row, target);
    return column ? row[column] : undefined;
  }

  function rowId(row) {
    if (!row) return "";
    const key = Object.keys(row).find((column) => clean(column).includes("学籍番号"));
    return normalizeId(key ? row[key] : "");
  }

  function rowFor(ds, participantId) {
    if (!ds) return null;
    const id = normalizeId(participantId);
    if (ds.by_student_id && Number.isInteger(ds.by_student_id[id])) return ds.rows[ds.by_student_id[id]];
    return ds.rows.find((row) => rowId(row) === id) || null;
  }

  function testScore(row) {
    if (!row) return NaN;
    const total = valueOf(row, "合計点数");
    if (total !== undefined) return number(total);
    return mean(Object.keys(row).filter((key) => /点数\s*-?\s*\d+$/.test(clean(key))).map((key) => number(row[key])));
  }

  function postRowsFor(role, id, expDs, ctrlDs) {
    return rowFor(role === "experimental" ? expDs : ctrlDs, id);
  }

  function ilsScore(row, axis) {
    if (!row) return { signed: NaN, label: "不明", strength: "不明" };
    const questionColumns = Array.from({ length: 11 }, (_, i) => String(axis.start + i * 4));
    const answers = questionColumns.map((column) => clean(row[column]).toUpperCase()).filter((x) => x === "A" || x === "B");
    let signed = NaN;
    if (answers.length) signed = answers.filter((x) => x === "A").length - answers.filter((x) => x === "B").length;
    if (!Number.isFinite(signed)) {
      const direct = number(valueOf(row, axis.short));
      if (Number.isFinite(direct)) return { signed: NaN, label: `方向不明（強さ${direct}）`, strength: strengthLabel(direct) };
      return { signed: NaN, label: "不明", strength: "不明" };
    }
    const magnitude = Math.abs(signed);
    const label = signed > 0 ? axis.left : signed < 0 ? axis.right : "均衡";
    return { signed, label, strength: strengthLabel(magnitude) };
  }

  function strengthLabel(magnitude) {
    if (!Number.isFinite(magnitude)) return "不明";
    if (magnitude <= 3) return "軽度・均衡";
    if (magnitude <= 7) return "中程度";
    return "強い";
  }

  function band(value) {
    if (!Number.isFinite(value)) return "不明";
    if (value <= 2) return "低（1–2）";
    if (value === 3) return "中（3）";
    return "高（4–5）";
  }

  function genderLabel(value) {
    const x = number(value);
    return x === 0 ? "男性" : x === 1 ? "女性" : "その他・不明";
  }

  function buildRows() {
    const preTest = findDataset(["合計点数", "学籍番号"], ["pre_test"]);
    const postTest = datasets().find((ds) => ds !== preTest && hasColumn(ds, "合計点数") && hasColumn(ds, "学籍番号")) || findDataset(["合計点数"], ["post_test"]);
    const preSurvey = findDataset(["性別", "ノベルゲーム", "感情移入"], ["pre_survey_1"]);
    const postSurveyDatasets = datasets().filter((ds) => hasColumn(ds, "このシステムでの学習は楽しかった"));
    const postExp = ((state.experimentData && state.experimentData.datasets) || {}).post_survey_experimental
      || postSurveyDatasets.find((ds) => hasColumn(ds, "親密度が上がる仕組み")) || null;
    const postCtrl = ((state.experimentData && state.experimentData.datasets) || {}).post_survey_control
      || postSurveyDatasets.find((ds) => ds !== postExp && !hasColumn(ds, "親密度が上がる仕組み")) || null;
    const ils = findDataset(["ACT/REF", "SNS/INT", "VIS/VRB", "SEQ/GLO"], ["ils", "pre_survey_2"]);

    state.rows = state.profiles.map((profile) => {
      const participantId = normalizeId(profile.participant_id);
      const pre = rowFor(preSurvey, participantId) || {};
      const post = postRowsFor(profile.role, participantId, postExp, postCtrl) || {};
      const preScore = testScore(rowFor(preTest, participantId));
      const postScore = testScore(rowFor(postTest, participantId));
      const ilsRow = rowFor(ils, participantId);
      const row = {
        participantId,
        name: profile.name || "",
        role: profile.role || "unassigned",
        gender: genderLabel(valueOf(pre, COLUMNS.gender)),
        novelPreferenceValue: scale(valueOf(pre, COLUMNS.novel)),
        storyEmpathyValue: scale(valueOf(pre, COLUMNS.empathy)),
        novelPreference: band(scale(valueOf(pre, COLUMNS.novel))),
        storyEmpathy: band(scale(valueOf(pre, COLUMNS.empathy))),
        preScore,
        postScore,
        testGain: Number.isFinite(preScore) && Number.isFinite(postScore) ? postScore - preScore : NaN,
        enjoyment: scale(valueOf(post, COLUMNS.enjoyment)),
        accomplishment: scale(valueOf(post, COLUMNS.accomplishment)),
        anxiety: scale(valueOf(post, COLUMNS.anxiety)),
        learningUsefulness: scale(valueOf(post, COLUMNS.usefulness)),
        continuedUse: scale(valueOf(post, COLUMNS.continuedUse)),
        agentIntimacy: scale(valueOf(post, COLUMNS.intimacy)),
        agentTogetherness: scale(valueOf(post, COLUMNS.together)),
        agentRelationshipGrowth: scale(valueOf(post, COLUMNS.relationship)),
        episodeMotivation: scale(valueOf(post, COLUMNS.episodeMotivation)),
        intimacyMotivation: scale(valueOf(post, COLUMNS.intimacyMotivation)),
        intimacyCloseness: scale(valueOf(post, COLUMNS.intimacyCloseness)),
        intimacyNaturalness: scale(valueOf(post, COLUMNS.intimacyNaturalness)),
        hasPreSurvey: !!rowFor(preSurvey, participantId),
        hasPostSurvey: !!postRowsFor(profile.role, participantId, postExp, postCtrl),
        hasIls: !!ilsRow,
      };
      ATTITUDE_ITEMS.forEach((item) => {
        row[item.preKey] = scale(valueOf(pre, item.column));
        row[item.postKey] = scale(valueOf(post, item.column));
        row[item.gainKey] = Number.isFinite(row[item.preKey]) && Number.isFinite(row[item.postKey])
          ? row[item.postKey] - row[item.preKey]
          : NaN;
      });
      ILS_AXES.forEach((axis) => { row[axis.key] = ilsScore(ilsRow, axis); });
      return row;
    });
  }

  function filteredRows() {
    const role = $("role-filter").value;
    const text = clean($("participant-filter").value).toLowerCase();
    const include25nm467r = $("include-25nm467r").checked;
    return state.rows.filter((row) =>
      (include25nm467r || row.participantId !== "25NM467R")
      && (!role || row.role === role)
      && (!text || `${row.participantId} ${row.name}`.toLowerCase().includes(text))
    );
  }

  function byRole(rows, role, key) { return rows.filter((row) => row.role === role).map((row) => row[key]); }

  function renderSummary(rows) {
    const exp = rows.filter((r) => r.role === "experimental").length;
    const ctrl = rows.filter((r) => r.role === "control").length;
    const testPairs = rows.filter((r) => Number.isFinite(r.preScore) && Number.isFinite(r.postScore)).length;
    const surveyPairs = rows.filter((row) => ATTITUDE_ITEMS.every((item) =>
      Number.isFinite(row[item.preKey]) && Number.isFinite(row[item.postKey])
    )).length;
    const ilsCount = rows.filter((r) => r.hasIls).length;
    const cards = [
      ["対象参加者", rows.length, "現在の絞り込み"],
      ["実験群", exp, "experimental"],
      ["統制群", ctrl, "control"],
      ["テスト対応あり", testPairs, "事前・事後とも回答"],
      ["意識尺度対応あり", surveyPairs, "事前・事後とも回答"],
      ["ILS結合あり", ilsCount, "学習スタイル回答"],
    ];
    $("summary-cards").innerHTML = cards.map(([label, value, detail]) => `<div class="summary-card"><div class="label">${escapeHtml(label)}</div><div class="value">${escapeHtml(value)}</div><div class="detail">${escapeHtml(detail)}</div></div>`).join("");
  }

  function comparisonRows(rows, metrics) {
    return metrics.map((metric) => {
      return `<tr><td class="metric-name">${escapeHtml(metric.label)}</td>${comparisonCells(rows, metric.key)}</tr>`;
    }).join("");
  }

  function comparisonCells(rows, key) {
    const exp = byRole(rows, "experimental", key);
    const ctrl = byRole(rows, "control", key);
    return `<td>${n(exp)}</td><td>${fmt(mean(exp))}</td><td>${fmt(median(exp))}</td><td>${fmt(sd(exp))}</td><td class="role-divider">${n(ctrl)}</td><td>${fmt(mean(ctrl))}</td><td>${fmt(median(ctrl))}</td><td>${fmt(sd(ctrl))}</td><td>${fmt(mean(exp) - mean(ctrl))}</td><td>${fmt(cohenD(exp, ctrl))}</td>`;
  }

  function comparisonHeader() {
    return "<thead><tr><th class=\"metric-name\">指標</th><th>実験 n</th><th>実験 平均</th><th>実験 中央値</th><th>実験 SD</th><th class=\"role-divider\">統制 n</th><th>統制 平均</th><th>統制 中央値</th><th>統制 SD</th><th>平均差</th><th>Cohen's d</th></tr></thead>";
  }

  function groupedChartLabels(entries, groupLabel, detailLabel, showDetails) {
    if (!showDetails) return entries.map(groupLabel);
    const labels = [];
    for (let start = 0; start < entries.length;) {
      let end = start + 1;
      const group = groupLabel(entries[start]);
      while (end < entries.length && groupLabel(entries[end]) === group) end += 1;
      const middle = start + Math.floor((end - start - 1) / 2);
      for (let index = start; index < end; index += 1) {
        const detail = detailLabel(entries[index]);
        labels.push(index === middle ? `${group}　｜　${detail}` : detail);
      }
      start = end;
    }
    return labels;
  }

  function renderTests(rows) {
    const metrics = [
      { key: "preScore", label: "事前テスト" },
      { key: "postScore", label: "事後テスト" },
      { key: "testGain", label: "変化量（事後－事前）" },
    ];
    $("test-table").innerHTML = '<colgroup><col class="test-metric-col"><col class="test-stat-col" span="10"></colgroup>' + comparisonHeader() + `<tbody>${comparisonRows(rows, metrics)}</tbody>`;
    charts.line("test-chart", ["事前", "事後"], [
      { label: `実験群（対応n=${n(byRole(rows, "experimental", "testGain"))}）`, borderColor: COLORS.experimental, backgroundColor: COLORS.experimental, data: [mean(byRole(rows, "experimental", "preScore")), mean(byRole(rows, "experimental", "postScore"))] },
      { label: `統制群（対応n=${n(byRole(rows, "control", "testGain"))}）`, borderColor: COLORS.control, backgroundColor: COLORS.control, data: [mean(byRole(rows, "control", "preScore")), mean(byRole(rows, "control", "postScore"))] },
    ], { yTitle: "平均得点", beginAtZero: true });
  }

  function renderAttitude(rows) {
    const attribute = $("attitude-attribute-select").value;
    const categories = attributeCategories(rows, attribute);
    const categoryRows = (category) => rows.filter((row) => attributeValue(row, attribute) === category);
    const timePoints = [
      { label: "事前", keyName: "preKey" },
      { label: "事後", keyName: "postKey" },
      { label: "変化量", keyName: "gainKey" },
    ];
    const tableRows = ATTITUDE_ITEMS.flatMap((item) => timePoints.flatMap((time, timeIndex) =>
      categories.map((category, categoryIndex) => {
        const questionCell = timeIndex === 0 && categoryIndex === 0
          ? `<td class="metric-name grouped-cell" rowspan="${timePoints.length * categories.length}">${escapeHtml(item.label)}</td>`
          : "";
        const timeCell = categoryIndex === 0
          ? `<td class="time-name grouped-cell" rowspan="${categories.length}">${escapeHtml(time.label)}</td>`
          : "";
        const rowClass = timeIndex === 0 && categoryIndex === 0 ? "group-start" : categoryIndex === 0 ? "subgroup-start" : "";
        return `<tr class="${rowClass}">${questionCell}${timeCell}<td class="attribute-name dimension-divider">${escapeHtml(category)}</td>${comparisonCells(categoryRows(category), item[time.keyName])}</tr>`;
      })
    )).join("");
    $("attitude-table").innerHTML = `<thead><tr><th class="metric-name">質問</th><th class="time-name">時点</th><th class="attribute-name dimension-divider">属性区分</th><th>実験 n</th><th>実験 平均</th><th>実験 中央値</th><th>実験 SD</th><th class="role-divider">統制 n</th><th>統制 平均</th><th>統制 中央値</th><th>統制 SD</th><th>平均差</th><th>Cohen's d</th></tr></thead><tbody>${tableRows || '<tr><td colspan="13" class="na">対象データなし</td></tr>'}</tbody>`;

    const chartEntries = ATTITUDE_ITEMS.flatMap((item) => categories.map((category) => ({ item, category })));
    const chartLabels = groupedChartLabels(chartEntries, ({ item }) => item.label, ({ category }) => category, attribute !== "all");
    const roleValues = (role, timeKey) => chartEntries.map(({ item, category }) =>
      mean(byRole(categoryRows(category), role, item[timeKey]))
    );
    $("attitude-chart").parentElement.style.height = `${Math.min(1200, Math.max(620, chartEntries.length * 60 + 100))}px`;
    charts.horizontalBar("attitude-chart", chartLabels, [
      { label: "実験群・事前", backgroundColor: COLORS.experimentalPre, data: roleValues("experimental", "preKey") },
      { label: "実験群・事後", backgroundColor: COLORS.experimental, data: roleValues("experimental", "postKey") },
      { label: "統制群・事前", backgroundColor: COLORS.controlPre, data: roleValues("control", "preKey") },
      { label: "統制群・事後", backgroundColor: COLORS.control, data: roleValues("control", "postKey") },
    ], { min: 1, max: 5, xTitle: "5件法平均" });
  }

  function ilsCounts(rows, role, axis) {
    const selected = rows.filter((r) => r.role === role).map((r) => r[axis.key]).filter((v) => v && v.label !== "不明" && !v.label.startsWith("方向不明"));
    return {
      total: selected.length,
      left: selected.filter((v) => v.label === axis.left).length,
      balanced: selected.filter((v) => v.label === "均衡").length,
      right: selected.filter((v) => v.label === axis.right).length,
      signedMean: mean(selected.map((v) => v.signed)),
    };
  }

  function renderIls(rows) {
    const tableRows = ILS_AXES.map((axis) => {
      const e = ilsCounts(rows, "experimental", axis), c = ilsCounts(rows, "control", axis);
      const cell = (count, total) => `${count}<small>${total ? fmt(count / total * 100, 1) + "%" : "-"}</small>`;
      return `<tr><td class="metric-name">${escapeHtml(axis.left)} ↔ ${escapeHtml(axis.right)}</td><td>${e.total}</td><td>${cell(e.left, e.total)}</td><td>${cell(e.balanced, e.total)}</td><td>${cell(e.right, e.total)}</td><td>${fmt(e.signedMean)}</td><td>${c.total}</td><td>${cell(c.left, c.total)}</td><td>${cell(c.balanced, c.total)}</td><td>${cell(c.right, c.total)}</td><td>${fmt(c.signedMean)}</td></tr>`;
    }).join("");
    $("ils-table").innerHTML = `<thead><tr><th class="metric-name">軸</th><th>実験 n</th><th>左側</th><th>均衡</th><th>右側</th><th>実験 符号平均</th><th>統制 n</th><th>左側</th><th>均衡</th><th>右側</th><th>統制 符号平均</th></tr></thead><tbody>${tableRows}</tbody>`;
    charts.groupedBar("ils-chart", ILS_AXES.map((a) => a.short), [
      { label: "実験群（左側を＋）", backgroundColor: COLORS.experimental, data: ILS_AXES.map((axis) => ilsCounts(rows, "experimental", axis).signedMean) },
      { label: "統制群（左側を＋）", backgroundColor: COLORS.control, data: ILS_AXES.map((axis) => ilsCounts(rows, "control", axis).signedMean) },
    ], { beginAtZero: false, min: -11, max: 11, yTitle: "A回答数－B回答数" });
  }

  function attributeValue(row, key) {
    if (key === "all") return "全体";
    if (key.startsWith("ils")) return row[key] ? row[key].label : "不明";
    return row[key] || "不明";
  }

  function attributeCategories(rows, attribute) {
    const categories = Array.from(new Set(rows.map((row) => attributeValue(row, attribute))))
      .filter((value) => value !== "不明" && !String(value).startsWith("方向不明"));
    if (attribute !== "novelPreference") return categories;
    const order = ["高（4–5）", "中（3）", "低（1–2）"];
    return [
      ...order.filter((value) => categories.includes(value)),
      ...categories.filter((value) => !order.includes(value)),
    ];
  }

  function renderAttributes(rows) {
    const attribute = $("attribute-select").value;
    const evaluationSelect = $("evaluation-select");
    const selectedMetric = evaluationSelect.value;
    const allMetrics = Array.from(evaluationSelect.options)
      .filter((option) => option.value !== "all")
      .map((option) => ({ key: option.value, label: option.textContent }));
    const metrics = selectedMetric === "all"
      ? allMetrics
      : allMetrics.filter((metric) => metric.key === selectedMetric);
    const categories = attributeCategories(rows, attribute);
    const entries = metrics.flatMap((metric) => categories.map((category) => ({ metric, category })));
    const roleData = (role, category, metricKey) => rows
      .filter((r) => r.role === role && attributeValue(r, attribute) === category)
      .map((r) => r[metricKey]);
    const showAll = selectedMetric === "all";
    const table = entries.map(({ metric, category }, index) => {
      const e = roleData("experimental", category, metric.key), c = roleData("control", category, metric.key);
      const categoryIndex = index % categories.length;
      const metricCell = categoryIndex === 0
        ? `<td class="metric-name grouped-cell" rowspan="${categories.length}">${escapeHtml(metric.label)}</td>`
        : "";
      return `<tr class="${categoryIndex === 0 ? "group-start" : ""}">${metricCell}<td class="attribute-name dimension-divider">${escapeHtml(category)}</td><td>${n(e)}</td><td>${fmt(mean(e))}</td><td>${fmt(sd(e))}</td><td class="role-divider">${n(c)}</td><td>${fmt(mean(c))}</td><td>${fmt(sd(c))}</td><td>${fmt(mean(e) - mean(c))}</td></tr>`;
    }).join("");
    $("attribute-table").innerHTML = `<thead><tr><th class="metric-name">評価指標</th><th class="attribute-name dimension-divider">属性区分</th><th>実験 n</th><th>実験 平均</th><th>実験 SD</th><th class="role-divider">統制 n</th><th>統制 平均</th><th>統制 SD</th><th>平均差</th></tr></thead><tbody>${table || '<tr><td colspan="9" class="na">対象データなし</td></tr>'}</tbody>`;

    const chartBox = $("attribute-chart").parentElement;
    chartBox.style.height = showAll ? `${Math.min(1200, Math.max(390, entries.length * 34 + 100))}px` : "";
    if (showAll) {
      const labels = groupedChartLabels(entries, ({ metric }) => metric.label, ({ category }) => category, attribute !== "all");
      charts.horizontalBar("attribute-chart", labels, [
        { label: "実験群", backgroundColor: COLORS.experimental, data: entries.map(({ metric, category }) => mean(roleData("experimental", category, metric.key))) },
        { label: "統制群", backgroundColor: COLORS.control, data: entries.map(({ metric, category }) => mean(roleData("control", category, metric.key))) },
      ], { min: 1, max: 5, xTitle: "5件法平均" });
      return;
    }

    const metric = metrics[0];
    charts.groupedBar("attribute-chart", categories, [
      { label: "実験群", backgroundColor: COLORS.experimental, data: categories.map((category) => mean(roleData("experimental", category, metric.key))) },
      { label: "統制群", backgroundColor: COLORS.control, data: categories.map((category) => mean(roleData("control", category, metric.key))) },
    ], { min: 1, max: 5, beginAtZero: false, yTitle: "5件法平均" });
  }

  function renderIntimacy(rows) {
    const experimentalRows = rows.filter((row) => row.role === "experimental");
    const attribute = $("intimacy-attribute-select").value;
    const categories = attributeCategories(experimentalRows, attribute);
    const entries = INTIMACY_METRICS.flatMap(([key, label]) =>
      categories.map((category) => ({ key, label, category }))
    );
    const valuesFor = (key, category) => experimentalRows
      .filter((row) => attributeValue(row, attribute) === category)
      .map((row) => row[key]);
    const attributeRows = entries.map(({ key, label, category }, index) => {
      const values = valuesFor(key, category);
      const categoryIndex = index % categories.length;
      const metricCell = categoryIndex === 0
        ? `<td class="metric-name grouped-cell" rowspan="${categories.length}">${escapeHtml(label)}</td>`
        : "";
      return `<tr class="${categoryIndex === 0 ? "group-start" : ""}">${metricCell}<td class="attribute-name dimension-divider">${escapeHtml(category)}</td><td>${n(values)}</td><td>${fmt(mean(values))}</td><td>${fmt(median(values))}</td><td>${fmt(sd(values))}</td></tr>`;
    }).join("");
    $("intimacy-table").innerHTML = `<thead><tr><th class="metric-name">評価項目</th><th class="attribute-name dimension-divider">属性区分</th><th>n</th><th>平均</th><th>中央値</th><th>SD</th></tr></thead><tbody>${attributeRows || '<tr><td colspan="6" class="na">対象データなし</td></tr>'}</tbody>`;

    const chartBox = $("intimacy-chart").parentElement;
    chartBox.style.height = `${Math.max(390, entries.length * 38 + 100)}px`;
    const labels = groupedChartLabels(entries, ({ label }) => label, ({ category }) => category, attribute !== "all");
    charts.horizontalBar("intimacy-chart", labels, [
      {
        label: "実験群",
        backgroundColor: COLORS.experimental,
        data: entries.map(({ key, category }) => mean(valuesFor(key, category))),
      },
    ], { min: 1, max: 5, xTitle: "5件法平均" });
  }

  function renderParticipants(rows) {
    const ilsCell = (row, key) => row[key] ? row[key].label : "-";
    const attitudeHeaders = ATTITUDE_ITEMS.flatMap((item) => [
      `${item.short} 前`, `${item.short} 後`, `${item.short} 差`,
    ]);
    const headers = [
      "ID", "名前", "群", "性別", "事前テスト", "事後テスト", "差",
      ...attitudeHeaders,
      "ノベル嗜好", "感情移入", "ACT/REF", "SNS/INT", "VIS/VRB", "SEQ/GLO",
      "楽しさ", "達成感", "学習への有用性", "継続利用意向",
    ];
    const body = rows.map((row) => {
      const attitudeCells = ATTITUDE_ITEMS.flatMap((item) => [
        fmt(row[item.preKey]), fmt(row[item.postKey]), fmt(row[item.gainKey]),
      ]);
      const cells = [
        escapeHtml(row.participantId), escapeHtml(row.name), escapeHtml(ROLE_LABEL[row.role] || row.role), escapeHtml(row.gender),
        fmt(row.preScore), fmt(row.postScore), fmt(row.testGain),
        ...attitudeCells,
        fmt(row.novelPreferenceValue), fmt(row.storyEmpathyValue),
        escapeHtml(ilsCell(row, "ilsActiveReflective")), escapeHtml(ilsCell(row, "ilsSensingIntuitive")),
        escapeHtml(ilsCell(row, "ilsVisualVerbal")), escapeHtml(ilsCell(row, "ilsSequentialGlobal")),
        fmt(row.enjoyment), fmt(row.accomplishment), fmt(row.learningUsefulness), fmt(row.continuedUse),
      ];
      return `<tr>${cells.map((cell) => `<td>${cell}</td>`).join("")}</tr>`;
    }).join("");
    $("participant-table").innerHTML = `<thead><tr>${headers.map((header) => `<th>${escapeHtml(header)}</th>`).join("")}</tr></thead><tbody>${body}</tbody>`;
  }

  function renderAll() {
    const rows = filteredRows();
    renderSummary(rows); renderTests(rows); renderAttitude(rows); renderIls(rows); renderAttributes(rows); renderParticipants(rows); renderIntimacy(rows);
    $("download-analysis-csv").disabled = rows.length === 0;
  }

  async function loadAnalysis() {
    api.setPassword($("admin-password").value);
    if (!api.getPassword()) return setStatus("analysis-status", "管理パスワードを入力してください", true);
    setStatus("analysis-status", "読み込み中...");
    try {
      const [profiles, experimentData] = await Promise.all([
        api.fetchJSON("/api/admin/profiles"),
        api.fetchJSON("/api/admin/experiment-data"),
      ]);
      state.profiles = profiles.profiles || [];
      state.experimentData = experimentData;
      buildRows(); renderAll();
      setStatus("analysis-status", `${state.rows.length}名を読み込みました`);
    } catch (error) {
      setStatus("analysis-status", error.message || String(error), true);
    }
  }

  function downloadRows() {
    const rows = filteredRows();

    const headers = [
      "participant_id",
      "name",
      "role",
      "gender",
      "pre_test",
      "post_test",
      "test_gain",
      ...ATTITUDE_ITEMS.flatMap((item) => [
        `pre_${item.csvKey}`,
        `post_${item.csvKey}`,
        `${item.csvKey}_gain`,
      ]),
      "novel_preference",
      "story_empathy",
      "ils_act_ref",
      "ils_sns_int",
      "ils_vis_vrb",
      "ils_seq_glo",
      "enjoyment",
      "accomplishment",
      "learning_usefulness",
      "continued_use",
      "anxiety",
      "agent_intimacy",
      "agent_togetherness",
      "agent_relationship_growth",
      "episode_motivation",
      "intimacy_motivation",
      "intimacy_closeness",
      "intimacy_naturalness",
    ];

    const data = rows.map((r) => [
      r.participantId,
      r.name,
      r.role,
      r.gender,
      r.preScore,
      r.postScore,
      r.testGain,
      ...ATTITUDE_ITEMS.flatMap((item) => [r[item.preKey], r[item.postKey], r[item.gainKey]]),
      r.novelPreferenceValue,
      r.storyEmpathyValue,
      r.ilsActiveReflective.label,
      r.ilsSensingIntuitive.label,
      r.ilsVisualVerbal.label,
      r.ilsSequentialGlobal.label,
      r.enjoyment,
      r.accomplishment,
      r.learningUsefulness,
      r.continuedUse,
      r.anxiety,
      r.agentIntimacy,
      r.agentTogetherness,
      r.agentRelationshipGrowth,
      r.episodeMotivation,
      r.intimacyMotivation,
      r.intimacyCloseness,
      r.intimacyNaturalness,
    ]);

    downloadCSV("analysis_participant_metrics.csv", headers, data);
  }

  $("load-analysis").addEventListener("click", loadAnalysis);
  $("download-analysis-csv").addEventListener("click", downloadRows);
  ["role-filter", "include-25nm467r", "attitude-attribute-select", "attribute-select", "evaluation-select", "intimacy-attribute-select"].forEach((id) => $(id).addEventListener("change", renderAll));
  $("participant-filter").addEventListener("input", renderAll);
  $("admin-password").addEventListener("keydown", (event) => { if (event.key === "Enter") loadAnalysis(); });
  $("admin-password").value = api.getPassword();
})();
