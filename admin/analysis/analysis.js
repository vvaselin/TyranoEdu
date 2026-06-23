(function() {
  "use strict";

  const { $, escapeHtml, setStatus, downloadCSV } = window.AdminUI;
  const api = window.AdminAPI;
  const charts = window.AdminCharts;
  const stats = window.AdminStats;
  const logAnalysis = window.AdminLogAnalysis;

  const state = {
    profiles: [],
    experimentData: null,
    rows: [],
    rawEvents: [],
    analysisEvents: [],
    tasks: {},
    participantBehaviorSummary: [],
    taskAttemptSummary: [],
    loveTransitionBehaviorSummary: [],
    surveyLogCorrelationStats: [],
    groupAttributeLogSummary: [],
  };
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
    programmingExperience: "これまでにプログラミングをした経験がある。",
    cppExperience: "C++の経験がある。",
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
    { label: "C++の基本的なプログラムを自力で作成できると思う", short: "自力で作成できる", column: COLUMNS.preSelfCoding, preKey: "preSelfCoding", postKey: "postSelfCoding", gainKey: "selfCodingGain", csvKey: "self_coding" },
    { label: "プログラムにエラーが出ても原因を探して修正できると思う", short: "エラーを修正できる", column: COLUMNS.preDebug, preKey: "preDebug", postKey: "postDebug", gainKey: "debugGain", csvKey: "debug" },
    { label: "難しいプログラミング課題でも、諦めずに取り組めると思う", short: "諦めずに取り組める", column: COLUMNS.prePersistence, preKey: "prePersistence", postKey: "postPersistence", gainKey: "persistenceGain", csvKey: "persistence" },
    { label: "プログラミング学習に興味がある", short: "学習に興味がある", column: COLUMNS.preInterest, preKey: "preInterest", postKey: "postInterest", gainKey: "interestGain", csvKey: "interest" },
    { label: "今後もプログラミングを学び続けたいと思う", short: "学び続けたい", column: COLUMNS.preContinue, preKey: "preContinue", postKey: "postContinue", gainKey: "continueGain", csvKey: "continue" },
  ];

  const POST_EVALUATION_METRICS = [
    { key: "learningUsefulness", short: "学習有用性", label: COLUMNS.usefulness },
    { key: "continuedUse", short: "継続利用意向", label: COLUMNS.continuedUse },
    { key: "enjoyment", short: "楽しさ", label: COLUMNS.enjoyment },
    { key: "accomplishment", short: "達成感", label: COLUMNS.accomplishment },
    { key: "anxiety", short: "不安・プレッシャー", label: COLUMNS.anxiety },
    { key: "agentIntimacy", short: "親しみ", label: COLUMNS.intimacy },
    { key: "agentTogetherness", short: "一緒に学習している感覚", label: COLUMNS.together },
    { key: "agentRelationshipGrowth", short: "関係が深まった感覚", label: COLUMNS.relationship },
    { key: "episodeMotivation", short: "エピソードによる動機づけ", label: COLUMNS.episodeMotivation },
  ];

  const INTIMACY_METRICS = [
    { key: "intimacyMotivation", short: "学習継続意欲の向上", label: "親密度が上昇することで、学習を続けたいという気持ちが高まった" },
    { key: "intimacyCloseness", short: "エージェントとの距離", label: "親密度の変化に応じて、エージェントとの距離が近づいたと感じた" },
    { key: "intimacyNaturalness", short: "反応変化の自然さ", label: "親密度に応じたエージェントの言葉遣いや反応の変化は自然だった" },
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

  const { finite, mean, median, standardDeviation: sd, summarize, compareGroups } = stats;
  function fmt(value, digits) { return stats.fmt(value, digits); }
  function fmtP(value) {
    if (!Number.isFinite(value)) return "-";
    return value < 0.001 ? "&lt; .001" : value.toFixed(3);
  }
  function n(values) { return finite(values).length; }
  function number(value) {
    const cleaned = clean(value).replace(/[^0-9.-]/g, "");
    if (!cleaned) return NaN;
    const x = Number(cleaned);
    return Number.isFinite(x) ? x : NaN;
  }
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
        episodeCount: Number.isFinite(Number(profile.episode_count)) ? Number(profile.episode_count) : 0,
        gender: genderLabel(valueOf(pre, COLUMNS.gender)),
        programmingExperience: scale(valueOf(pre, COLUMNS.programmingExperience)),
        cppExperience: scale(valueOf(pre, COLUMNS.cppExperience)),
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
      const attitudePreValues = ATTITUDE_ITEMS.map((item) => row[item.preKey]);
      const attitudePostValues = ATTITUDE_ITEMS.map((item) => row[item.postKey]);
      const hasCompleteAttitudePair = attitudePreValues.every(Number.isFinite) && attitudePostValues.every(Number.isFinite);
      row.preAttitudeAverage = hasCompleteAttitudePair ? mean(attitudePreValues) : NaN;
      row.postAttitudeAverage = hasCompleteAttitudePair ? mean(attitudePostValues) : NaN;
      row.attitudeAverageGain = hasCompleteAttitudePair ? row.postAttitudeAverage - row.preAttitudeAverage : NaN;
      ILS_AXES.forEach((axis) => { row[axis.key] = ilsScore(ilsRow, axis); });
      return row;
    });
  }

  function filteredRows() {
    const role = $("role-filter").value;
    const text = clean($("participant-filter").value).toLowerCase();
    const include25nm467r = $("include-25nm467r").checked;
    const requireThreeEpisodes = $("episode-filter").checked;
    return state.rows.filter((row) =>
      (include25nm467r || row.participantId !== "25NM467R")
      && (!requireThreeEpisodes || row.episodeCount >= 3)
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

  function comparisonCells(rows, key, options) {
    const showQuartiles = !options || options.showQuartiles !== false;
    const exp = byRole(rows, "experimental", key);
    const ctrl = byRole(rows, "control", key);
    const comparison = compareGroups(exp, ctrl);
    const e = comparison.groupA_summary;
    const c = comparison.groupB_summary;
    const hedgesAttributes = comparison.hedgesGReason
      ? ` class="na" title="${escapeHtml(comparison.hedgesGReason)}"`
      : "";
    const groupCells = (summary, divider) => `<td${divider ? ' class="role-divider"' : ""}>${summary.n}</td><td>${fmt(summary.mean)}</td><td>${fmt(summary.sd)}</td><td>${fmt(summary.median)}</td>`
      + (showQuartiles ? `<td>${fmt(summary.q1)}</td><td>${fmt(summary.q3)}</td>` : "")
      + `<td>${fmt(summary.iqr)}</td>`;
    return groupCells(e, false) + groupCells(c, true)
      + `<td>${fmt(comparison.meanDiff)}</td><td>${fmt(comparison.medianDiff)}</td><td>${fmt(comparison.mannWhitneyU)}</td>`
      + `<td>${fmtP(comparison.pValue)}</td><td>${fmt(comparison.cliffsDelta)}</td><td>${escapeHtml(comparison.cliffsDeltaLabel || "-")}</td><td${hedgesAttributes}>${fmt(comparison.hedgesG)}</td>`;
  }

  function comparisonColumnHeaders(showQuartiles) {
    const quartileHeaders = showQuartiles === false ? "" : "<th>実験 Q1</th><th>実験 Q3</th>";
    const controlQuartileHeaders = showQuartiles === false ? "" : "<th>統制 Q1</th><th>統制 Q3</th>";
    return `<th>実験 n</th><th>実験 平均</th><th>実験 SD</th><th>実験 中央値</th>${quartileHeaders}<th>実験 IQR</th>`
      + `<th class="role-divider">統制 n</th><th>統制 平均</th><th>統制 SD</th><th>統制 中央値</th>${controlQuartileHeaders}<th>統制 IQR</th>`
      + '<th>平均差</th><th>中央値差</th><th>Mann–Whitney U</th><th>p値</th><th>Cliff’s delta</th><th>Cliff’s delta 解釈</th><th>Hedges’ g</th>';
  }

  function comparisonHeader() {
    return `<thead><tr><th class="metric-name">指標</th>${comparisonColumnHeaders()}</tr></thead>`;
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

  function changePoint(row, metricLabel, preKey, postKey, gainKey) {
    return {
      participantId: row.participantId,
      roleLabel: ROLE_LABEL[row.role] || row.role,
      value: row[gainKey],
      pre: row[preKey],
      post: row[postKey],
      gain: row[gainKey],
      episodeCount: row.episodeCount,
      metricLabel,
      valueKind: preKey === "preScore" ? "score" : "response",
    };
  }

  function changeGroup(rows, role, label, tickLabel, color, metricLabel, preKey, postKey, gainKey) {
    const points = rows
      .filter((row) => row.role === role && Number.isFinite(row[gainKey]))
      .map((row) => changePoint(row, metricLabel, preKey, postKey, gainKey));
    return {
      label,
      tickLabel,
      color,
      points,
      summary: summarize(points.map((point) => point.value)),
    };
  }

  function valueGroup(rows, role, label, color, metric, position) {
    const points = rows
      .filter((row) => row.role === role && Number.isFinite(row[metric.key]))
      .map((row) => ({
        participantId: row.participantId,
        roleLabel: ROLE_LABEL[row.role] || row.role,
        value: row[metric.key],
        episodeCount: row.episodeCount,
        metricLabel: metric.label,
        valueKind: "postOnly",
      }));
    return {
      label,
      color,
      position,
      points,
      summary: summarize(points.map((point) => point.value)),
    };
  }

  function renderTests(rows) {
    const metrics = [
      { key: "preScore", label: "事前テスト" },
      { key: "postScore", label: "事後テスト" },
      { key: "testGain", label: "変化量（事後－事前）" },
    ];
    $("test-table").innerHTML = '<colgroup><col class="test-metric-col"><col class="test-stat-col" span="21"></colgroup>' + comparisonHeader() + `<tbody>${comparisonRows(rows, metrics)}</tbody>`;
    charts.boxplotWithPoints("test-chart", [
      changeGroup(rows, "experimental", "実験群", "実験群", COLORS.experimental, "事前・事後テスト", "preScore", "postScore", "testGain"),
      changeGroup(rows, "control", "統制群", "統制群", COLORS.control, "事前・事後テスト", "preScore", "postScore", "testGain"),
    ], {
      xTitle: "群",
      yTitle: "テスト得点の変化量（事後－事前）",
      legendItems: [
        { label: "実験群", color: COLORS.experimental },
        { label: "統制群", color: COLORS.control },
      ],
    });
  }

  function renderAttitude(rows) {
    const attribute = $("attitude-attribute-select").value;
    const categories = attributeCategories(rows, attribute);
    const categoryRows = (category) => rows.filter((row) => attributeValue(row, attribute) === category);
    const legendItems = [
      { label: "実験群", color: COLORS.experimental },
      { label: "統制群", color: COLORS.control },
    ];

    const itemRows = ATTITUDE_ITEMS.flatMap((item) => categories.map((category, categoryIndex) => {
      const questionCell = categoryIndex === 0
        ? `<td class="metric-name grouped-cell" rowspan="${categories.length}">${escapeHtml(item.label)}</td>`
        : "";
      return `<tr class="${categoryIndex === 0 ? "group-start" : ""}">${questionCell}<td class="attribute-name dimension-divider">${escapeHtml(category)}</td>${comparisonCells(categoryRows(category), item.gainKey, { showQuartiles: false })}</tr>`;
    })).join("");
    $("attitude-table").innerHTML = `<thead><tr><th class="metric-name">質問項目</th><th class="attribute-name dimension-divider">属性区分</th>${comparisonColumnHeaders(false)}</tr></thead><tbody>${itemRows || '<tr><td colspan="19" class="na">対象データなし</td></tr>'}</tbody>`;

    const itemEntries = ATTITUDE_ITEMS.flatMap((item) => categories.map((category) => ({ item, category })));
    const itemLabels = itemEntries.map(({ item, category }) => attribute === "all"
      ? [item.label]
      : [item.label, `属性: ${category}`]);
    const itemGroups = itemEntries.flatMap(({ item, category }, itemIndex) => {
      const selectedRows = categoryRows(category);
      const experimental = changeGroup(selectedRows, "experimental", `${item.label}・${category}・実験群`, item.label, COLORS.experimental, item.label, item.preKey, item.postKey, item.gainKey);
      const control = changeGroup(selectedRows, "control", `${item.label}・${category}・統制群`, item.label, COLORS.control, item.label, item.preKey, item.postKey, item.gainKey);
      experimental.position = itemIndex - 0.17;
      control.position = itemIndex + 0.17;
      return [experimental, control];
    });
    $("attitude-chart").parentElement.style.height = `${Math.max(520, itemEntries.length * 90 + 130)}px`;
    charts.boxplotWithPoints("attitude-chart", itemGroups, {
      orientation: "horizontal",
      min: -4,
      max: 4,
      xTitle: "5件法回答の変化量（事後－事前）",
      yTitle: "質問項目",
      itemLabels,
      legendItems,
    });
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
    $("ils-table").classList.add("balance-compact");
    $("ils-table").classList.add("ils-axis-table");
    $("ils-table").classList.remove("balance-category-table", "balance-numeric-table");
    const tableRows = ILS_AXES.map((axis) => {
      const e = ilsCounts(rows, "experimental", axis), c = ilsCounts(rows, "control", axis);
      const cell = (count, total) => `${count}<small>${total ? fmt(count / total * 100, 1) + "%" : "-"}</small>`;
      return `<tr><td class="metric-name">${escapeHtml(axis.left)} ↔ ${escapeHtml(axis.right)}</td><td>${e.total}</td><td>${cell(e.left, e.total)}</td><td>${cell(e.balanced, e.total)}</td><td>${cell(e.right, e.total)}</td><td>${fmt(e.signedMean)}</td><td>${c.total}</td><td>${cell(c.left, c.total)}</td><td>${cell(c.balanced, c.total)}</td><td>${cell(c.right, c.total)}</td><td>${fmt(c.signedMean)}</td></tr>`;
    }).join("");
    $("ils-table").innerHTML = '<colgroup><col class="ils-axis-col"><col class="ils-stat-col" span="10"></colgroup>'
      + `<thead><tr><th class="metric-name">軸</th><th>実験 n</th><th>左側</th><th>均衡</th><th>右側</th><th>実験 符号平均</th><th>統制 n</th><th>左側</th><th>均衡</th><th>右側</th><th>統制 符号平均</th></tr></thead><tbody>${tableRows}</tbody>`;
    charts.groupedBar("ils-chart", ILS_AXES.map((a) => a.short), [
      { label: "実験群（左側を＋）", backgroundColor: COLORS.experimental, data: ILS_AXES.map((axis) => ilsCounts(rows, "experimental", axis).signedMean) },
      { label: "統制群（左側を＋）", backgroundColor: COLORS.control, data: ILS_AXES.map((axis) => ilsCounts(rows, "control", axis).signedMean) },
    ], { beginAtZero: false, min: -11, max: 11, yTitle: "A回答数－B回答数" });
  }

  function balanceMetrics(target) {
    const base = {
      programmingExperience: [{ key: "programmingExperience", label: COLUMNS.programmingExperience, scale: true }],
      cppExperience: [{ key: "cppExperience", label: COLUMNS.cppExperience, scale: true }],
      novelExperience: [{ key: "novelPreferenceValue", label: COLUMNS.novel, scale: true }],
      storyEmpathy: [{ key: "storyEmpathyValue", label: COLUMNS.empathy, scale: true }],
      preAttitude: ATTITUDE_ITEMS.map((item) => ({ key: item.preKey, label: item.label, scale: true })),
      preTest: [{ key: "preScore", label: "事前テスト得点", scale: false }],
    };
    base.preQuestionnaire = [
      ...base.programmingExperience,
      ...base.cppExperience,
      ...base.preAttitude,
      ...base.novelExperience,
      ...base.storyEmpathy,
    ];
    return base[target] || [];
  }

  function renderCategoricalBalance(rows, key, label) {
    $("ils-table").classList.add("balance-compact");
    $("ils-table").classList.remove("ils-axis-table");
    $("ils-table").classList.add("balance-category-table");
    $("ils-table").classList.remove("balance-numeric-table");
    const validRows = rows.filter((row) => row[key] && !String(row[key]).includes("不明"));
    const categories = Array.from(new Set(validRows.map((row) => row[key])));
    const totals = {
      experimental: validRows.filter((row) => row.role === "experimental").length,
      control: validRows.filter((row) => row.role === "control").length,
    };
    const rowsHtml = categories.map((category) => {
      const exp = validRows.filter((row) => row.role === "experimental" && row[key] === category).length;
      const ctrl = validRows.filter((row) => row.role === "control" && row[key] === category).length;
      const expPct = totals.experimental ? exp / totals.experimental * 100 : null;
      const ctrlPct = totals.control ? ctrl / totals.control * 100 : null;
      const diff = expPct != null && ctrlPct != null ? expPct - ctrlPct : null;
      const pct = (value) => Number.isFinite(value) ? `${fmt(value)}%` : "-";
      return `<tr><td class="metric-name">${escapeHtml(label)}</td><td>${escapeHtml(category)}</td><td>${exp}</td><td>${pct(expPct)}</td><td>${ctrl}</td><td>${pct(ctrlPct)}</td><td>${Number.isFinite(diff) ? `${fmt(diff)} pp` : "-"}</td><td class="na">参考値</td></tr>`;
    }).join("");
    $("ils-table").innerHTML = '<colgroup><col class="balance-item-col"><col class="balance-category-col"><col class="balance-category-stat-col" span="6"></colgroup>'
      + `<thead><tr><th class="metric-name">項目名</th><th>カテゴリ</th><th>実験群 n</th><th>実験群 %</th><th>統制群 n</th><th>統制群 %</th><th>差分 percentage point</th><th>備考</th></tr></thead><tbody>${rowsHtml || '<tr><td colspan="8" class="na">対象データなし</td></tr>'}</tbody>`;
    charts.groupedBar("ils-chart", ["実験群", "統制群"], categories.map((category, index) => ({
      label: category,
      backgroundColor: index % 2 ? COLORS.controlPre : COLORS.experimentalPre,
      data: [
        validRows.filter((row) => row.role === "experimental" && row[key] === category).length,
        validRows.filter((row) => row.role === "control" && row[key] === category).length,
      ],
    })), { stacked: true, yTitle: "人数" });
    const differences = categories.map((category) => {
      const exp = validRows.filter((row) => row.role === "experimental" && row[key] === category).length;
      const ctrl = validRows.filter((row) => row.role === "control" && row[key] === category).length;
      return totals.experimental && totals.control ? exp / totals.experimental * 100 - ctrl / totals.control * 100 : null;
    }).filter(Number.isFinite);
    const maxDifference = differences.length ? Math.max(...differences.map(Math.abs)) : null;
    $("balance-summary").textContent = maxDifference == null
      ? "両群を比較できるデータがありません。"
      : `${label}の最大割合差は${fmt(maxDifference, 1)} percentage pointでした。人数が少ないため参考情報として扱います。`;
  }

  function renderNumericBalance(rows, metrics, target) {
    $("ils-table").classList.remove("balance-compact");
    $("ils-table").classList.remove("ils-axis-table");
    $("ils-table").classList.remove("balance-category-table");
    $("ils-table").classList.add("balance-numeric-table");
    const groups = metrics.flatMap((metric, index) => [
      valueGroup(rows, "experimental", `${metric.label}・実験群`, COLORS.experimental, metric, index - 0.17),
      valueGroup(rows, "control", `${metric.label}・統制群`, COLORS.control, metric, index + 0.17),
    ]);
    $("ils-chart").parentElement.style.height = `${Math.max(390, metrics.length * 90 + 130)}px`;
    charts.boxplotWithPoints("ils-chart", groups, {
      orientation: "horizontal",
      min: metrics.every((metric) => metric.scale) ? 1 : undefined,
      max: metrics.every((metric) => metric.scale) ? 5 : undefined,
      xTitle: metrics.every((metric) => metric.scale) ? "事前回答（1～5）" : "得点",
      yTitle: "事前属性・初期状態",
      itemLabels: metrics.map((metric) => [metric.label]),
      legendItems: [
        { label: "実験群", color: COLORS.experimental },
        { label: "統制群", color: COLORS.control },
      ],
    });
    $("ils-table").innerHTML = '<colgroup><col class="balance-metric-col"><col class="balance-stat-col" span="21"></colgroup>'
      + comparisonHeader() + `<tbody>${comparisonRows(rows, metrics)}</tbody>`;
    const comparisons = metrics.map((metric) => ({ metric, comparison: compareGroups(byRole(rows, "experimental", metric.key), byRole(rows, "control", metric.key)) }));
    const comparable = comparisons.filter(({ comparison }) => comparison.groupA_summary.n && comparison.groupB_summary.n);
    const notable = comparisons.find(({ comparison }) => Number.isFinite(comparison.cliffsDelta) && Math.abs(comparison.cliffsDelta) >= 0.33);
    $("balance-summary").textContent = !comparable.length
      ? "両群を比較できるデータがありません。"
      : notable
      ? `${notable.metric.label}は群間で${notable.comparison.cliffsDelta > 0 ? "実験群" : "統制群"}がやや高い傾向でした（Cliff’s delta=${fmt(notable.comparison.cliffsDelta)}）。群分け時点の参考情報です。`
      : "中央値、IQR、Cliff’s deltaを総合すると、表示中の項目に大きな偏りは見られませんでした。群分け時点の参考情報です。";
  }

  function renderBalance(rows) {
    const target = $("balance-target-select").value;
    $("ils-chart").parentElement.style.height = "390px";
    if (target === "ils") {
      renderIls(rows);
      const visualAxis = ILS_AXES.find((axis) => axis.key === "ilsVisualVerbal");
      const expVisual = ilsCounts(rows, "experimental", visualAxis);
      const ctrlVisual = ilsCounts(rows, "control", visualAxis);
      const sharedVisualTendency = expVisual.left > expVisual.right && ctrlVisual.left > ctrlVisual.right;
      $("balance-summary").textContent = sharedVisualTendency
        ? "Felder–Silverman学習スタイルでは、視覚型傾向が両群で多く見られました。人数が少ないため参考情報として扱います。"
        : "Felder–Silverman学習スタイルの人数・割合は、少人数のため参考情報として扱います。";
      return;
    }
    if (target === "gender") {
      renderCategoricalBalance(rows, "gender", "性別");
      return;
    }
    renderNumericBalance(rows, balanceMetrics(target), target);
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
    const metrics = selectedMetric === "all"
      ? POST_EVALUATION_METRICS
      : POST_EVALUATION_METRICS.filter((metric) => metric.key === selectedMetric);
    const categories = attributeCategories(rows, attribute);
    const entries = metrics.flatMap((metric) => categories.map((category) => ({ metric, category })));
    const rowsForCategory = (category) => rows.filter((row) => attributeValue(row, attribute) === category);
    const table = entries.map(({ metric, category }, index) => {
      const categoryIndex = index % categories.length;
      const metricCell = categoryIndex === 0
        ? `<td class="metric-name grouped-cell" rowspan="${categories.length}">${escapeHtml(metric.label)}</td>`
        : "";
      return `<tr class="${categoryIndex === 0 ? "group-start" : ""}">${metricCell}<td class="attribute-name dimension-divider">${escapeHtml(category)}</td>${comparisonCells(rowsForCategory(category), metric.key)}</tr>`;
    }).join("");
    $("attribute-table").innerHTML = `<thead><tr><th class="metric-name">評価指標</th><th class="attribute-name dimension-divider">属性区分</th>${comparisonColumnHeaders()}</tr></thead><tbody>${table || '<tr><td colspan="23" class="na">対象データなし</td></tr>'}</tbody>`;

    const chartBox = $("attribute-chart").parentElement;
    chartBox.style.height = `${Math.max(520, entries.length * 90 + 130)}px`;
    const itemLabels = entries.map(({ metric, category }) => attribute === "all"
      ? [metric.label]
      : [metric.label, `属性: ${category}`]);
    const chartGroups = entries.flatMap(({ metric, category }, itemIndex) => {
      const selectedRows = rowsForCategory(category);
      return [
        valueGroup(selectedRows, "experimental", `${metric.label}・${category}・実験群`, COLORS.experimental, metric, itemIndex - 0.17),
        valueGroup(selectedRows, "control", `${metric.label}・${category}・統制群`, COLORS.control, metric, itemIndex + 0.17),
      ];
    });
    charts.boxplotWithPoints("attribute-chart", chartGroups, {
      orientation: "horizontal",
      min: 1,
      max: 5,
      xTitle: "5件法回答",
      yTitle: "事後評価項目",
      itemLabels,
      legendItems: [
        { label: "実験群", color: COLORS.experimental },
        { label: "統制群", color: COLORS.control },
      ],
    });
  }

  function renderIntimacy(rows) {
    const experimentalRows = rows.filter((row) => row.role === "experimental");
    const attribute = $("intimacy-attribute-select").value;
    const categories = attributeCategories(experimentalRows, attribute);
    const entries = INTIMACY_METRICS.flatMap((metric) =>
      categories.map((category) => ({ metric, category }))
    );
    const valuesFor = (key, category) => experimentalRows
      .filter((row) => attributeValue(row, attribute) === category)
      .map((row) => row[key]);
    const attributeRows = entries.map(({ metric, category }, index) => {
      const values = valuesFor(metric.key, category);
      const summary = summarize(values);
      const categoryIndex = index % categories.length;
      const metricCell = categoryIndex === 0
        ? `<td class="metric-name grouped-cell" rowspan="${categories.length}">${escapeHtml(metric.label)}</td>`
        : "";
      return `<tr class="${categoryIndex === 0 ? "group-start" : ""}">${metricCell}<td class="attribute-name dimension-divider">${escapeHtml(category)}</td>`
        + `<td>${summary.n}</td><td>${fmt(summary.mean)}</td><td>${fmt(summary.sd)}</td><td>${fmt(summary.median)}</td>`
        + `<td>${fmt(summary.q1)}</td><td>${fmt(summary.q3)}</td><td>${fmt(summary.iqr)}</td><td>${fmt(summary.min)}</td><td>${fmt(summary.max)}</td>`
        + '<td class="na">実験群のみの項目のため、群間比較なし</td></tr>';
    }).join("");
    $("intimacy-table").innerHTML = '<colgroup><col class="intimacy-metric-col"><col class="intimacy-attribute-col"><col class="intimacy-stat-col" span="9"><col class="intimacy-comparison-col"></colgroup>'
      + `<thead><tr><th class="metric-name">評価項目</th><th class="attribute-name dimension-divider">属性区分</th><th>n</th><th>平均</th><th>SD</th><th>中央値</th><th>Q1</th><th>Q3</th><th>IQR</th><th>min</th><th>max</th><th>群間比較</th></tr></thead><tbody>${attributeRows || '<tr><td colspan="12" class="na">対象データなし</td></tr>'}</tbody>`;

    const chartBox = $("intimacy-chart").parentElement;
    chartBox.style.height = `${Math.max(440, entries.length * 90 + 130)}px`;
    const itemLabels = entries.map(({ metric, category }) => attribute === "all"
      ? [metric.label]
      : [metric.label, `属性: ${category}`]);
    const chartGroups = entries.map(({ metric, category }, itemIndex) =>
      valueGroup(
        experimentalRows.filter((row) => attributeValue(row, attribute) === category),
        "experimental",
        `${metric.label}・${category}・実験群`,
        COLORS.experimental,
        metric,
        itemIndex
      )
    );
    charts.boxplotWithPoints("intimacy-chart", chartGroups, {
      orientation: "horizontal",
      min: 1,
      max: 5,
      xTitle: "5件法回答",
      yTitle: "親密度システム評価項目",
      itemLabels,
      legendItems: [{ label: "実験群", color: COLORS.experimental }],
    });
  }

  function renderParticipants(rows) {
    const ilsCell = (row, key) => row[key] ? row[key].label : "-";
    const attitudeHeaders = ATTITUDE_ITEMS.flatMap((item) => [
      `${item.label}（事前）`, `${item.label}（事後）`, `${item.label}（変化量）`,
    ]);
    const headers = [
      "ID", "名前", "群", "閲覧エピソード数", "性別", "事前テスト", "事後テスト", "差",
      ...attitudeHeaders,
      "ノベル嗜好", "感情移入", "ACT/REF", "SNS/INT", "VIS/VRB", "SEQ/GLO",
      "楽しさ", "達成感", "学習への有用性", "継続利用意向",
    ];
    const body = rows.map((row) => {
      const attitudeCells = ATTITUDE_ITEMS.flatMap((item) => [
        fmt(row[item.preKey]), fmt(row[item.postKey]), fmt(row[item.gainKey]),
      ]);
      const cells = [
        escapeHtml(row.participantId), escapeHtml(row.name), escapeHtml(ROLE_LABEL[row.role] || row.role), escapeHtml(row.episodeCount), escapeHtml(row.gender),
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

  const LOG_METRICS = [
    { key: "cleared_task_count", label: "クリア到達課題数" },
    { key: "attempted_task_count", label: "着手課題数" },
    { key: "execute_count", label: "実行回数" },
    { key: "retry_after_error_count", label: "エラー後の再挑戦回数" },
    { key: "retry_after_low_score_count", label: "低得点後の再挑戦回数" },
    { key: "feedback_to_retry_count", label: "フィードバック後の再挑戦回数" },
    { key: "chat_user_count", label: "ユーザーチャット数" },
    { key: "love_total_gain", label: "親密度上昇量合計" },
    { key: "love_gain_from_ai", label: "AI応答由来の親密度上昇量" },
    { key: "optional_task_count", label: "任意課題数" },
  ];

  const CORRELATION_DEFINITIONS = [
    { log_key: "chat_user_count", survey_key: "agentIntimacy", label: "ユーザーチャット数 × エージェントへの親しみ" },
    { log_key: "chat_user_count", survey_key: "agentTogetherness", label: "ユーザーチャット数 × 一緒に学習している感覚" },
    { log_key: "love_total_gain", survey_key: "agentRelationshipGrowth", label: "親密度上昇量合計 × 関係が深まった感覚" },
    { log_key: "love_gain_from_ai", survey_key: "intimacyCloseness", label: "AI応答由来の親密度上昇量 × 距離が近づいた感覚" },
    { log_key: "feedback_to_retry_count", survey_key: "persistenceGain", label: "フィードバック後の再挑戦回数 × 諦めずに取り組める意識の変化" },
    { log_key: "retry_after_error_count", survey_key: "debugGain", label: "エラー後の再挑戦回数 × エラー修正意識の変化" },
    { log_key: "cleared_task_count", survey_key: "postScore", label: "クリア到達課題数 × 事後テスト得点" },
    { log_key: "optional_task_count", survey_key: "postContinue", label: "任意課題数 × 学習継続意識" },
    { log_key: "story_or_episode_view_count", survey_key: "episodeMotivation", label: "ストーリー・エピソード閲覧数 × エピソード進行の動機づけ評価" },
  ];

  const COLUMN_LABELS = {
    participant_id: "参加者ID",
    group: "群",
    event_time: "イベント時刻",
    love_before: "変動前の親密度",
    love_after: "変動後の親密度",
    love_delta: "親密度変化量",
    love_source: "変動要因",
    related_task_id: "関連課題",
    previous_action_type: "直前の行動",
    next_action_type: "直後の行動",
    next_action_within_3min: "3分以内の次行動",
    next_action_within_5min: "5分以内の次行動",
    next_task_continued: "課題継続",
    next_chat_sent: "チャット送信",
    next_execute_done: "再実行",
    next_grade_done: "再採点",
    next_story_or_episode_viewed: "ストーリー・エピソード閲覧",
    session_count: "セッション数",
    total_duration_min: "総利用時間（分）",
    attempted_task_count: "着手課題数",
    cleared_task_count: "クリア到達課題数",
    optional_task_count: "任意課題数",
    execute_count: "実行回数",
    grade_count: "採点回数",
    chat_user_count: "ユーザーチャット数",
    chat_ai_count: "AI応答数",
    code_snapshot_count: "コード保存数",
    error_count: "エラー回数",
    error_rate: "エラー率",
    retry_after_error_count: "エラー後の再挑戦回数",
    retry_after_low_score_count: "低得点後の再挑戦回数",
    feedback_to_retry_count: "フィードバック後の再挑戦回数",
    feedback_to_chat_count: "フィードバック後のチャット数",
    feedback_to_leave_count: "フィードバック後の離脱数",
    love_change_count: "親密度変動回数",
    love_total_gain: "親密度上昇量合計",
    love_gain_from_ai: "AI応答由来の親密度上昇量",
    love_gain_from_score_bonus: "高得点ボーナス由来の親密度上昇量",
    final_love: "最終親密度",
    max_score_reference: "最高点（参考）",
    story_or_episode_view_count: "ストーリー・エピソード閲覧数",
    agentIntimacy: "エージェントへの親しみ",
    agentTogetherness: "一緒に学習している感覚",
    agentRelationshipGrowth: "関係が深まった感覚",
    intimacyCloseness: "親密度変化に応じて距離が近づいた感覚",
    persistenceGain: "諦めずに取り組める意識の変化",
    debugGain: "エラーを修正できると思う意識の変化",
    postScore: "事後テスト得点",
    postContinue: "今後も学び続けたい意識",
    episodeMotivation: "エピソード進行の動機づけ評価",
    task_id: "課題ID",
    task_category: "課題カテゴリ",
    is_optional_task: "任意課題",
    task_started_at: "課題開始時刻",
    first_execute_at: "初回実行時刻",
    first_grade_at: "初回採点時刻",
    cleared_at: "クリア時刻",
    left_task_at: "課題離脱時刻",
    first_grade_score: "初回採点得点",
    clear_score: "クリア時得点",
    cleared: "クリア",
    attempts_until_clear: "クリアまでの実行回数",
    grades_until_clear: "クリアまでの採点回数",
    time_until_first_execute_sec: "初回実行までの時間（秒）",
    time_until_first_grade_sec: "初回採点までの時間（秒）",
    time_until_clear_sec: "クリアまでの時間（秒）",
    retried_after_error: "エラー後に再挑戦",
    retried_after_low_score: "低得点後に再挑戦",
    used_chat_before_clear: "クリア前にチャット利用",
    used_chat_after_error: "エラー後にチャット利用",
    used_chat_after_low_score: "低得点後にチャット利用",
    label: "分析項目",
    log_metric: "ログ指標",
    survey_metric: "アンケート指標",
    n: "人数",
    pearson_r: "Pearsonの相関係数",
    pearson_p_value_approx: "Pearsonのp値（参考）",
    spearman_rho: "Spearmanの順位相関係数",
    spearman_p_value_approx: "Spearmanのp値（参考）",
    attribute: "属性",
    attribute_value: "属性区分",
    programming_experience: "プログラミング経験",
    cpp_experience: "C++経験",
    pre_test: "事前テスト",
    pre_attitude: "事前学習意識",
    novel_experience: "ノベルゲーム経験",
    story_empathy: "キャラクター・物語への感情移入",
    ilsActiveReflective: "学習スタイル（能動型・内省型）",
    ilsSensingIntuitive: "学習スタイル（感覚型・直観型）",
    ilsVisualVerbal: "学習スタイル（視覚型・言語型）",
    ilsSequentialGlobal: "学習スタイル（逐次型・全体型）",
    metric: "指標",
    metric_label: "指標名",
    mean: "平均",
    median: "中央値",
    sd: "標準偏差",
    q1: "第1四分位",
    q3: "第3四分位",
    min: "最小",
    max: "最大",
  };

  const VALUE_LABELS = {
    experimental: "実験群",
    control: "統制群",
    all: "全体",
    ai_response: "AI応答",
    high_score_bonus: "高得点ボーナス",
    chat_user_payload: "ユーザー発話",
    chat_ai_response: "AI応答",
    execute_result: "実行結果",
    grade_result: "採点結果",
    love_change: "親密度変動",
    lecture_view: "講義閲覧",
    screen_transition: "画面遷移",
    task_intro_knowledge: "課題前の基本構文表示",
    chat_user: "ユーザー発話",
    chat_ai: "AI応答",
    execute: "実行",
    execute_error: "実行エラー",
    grade: "採点",
    grade_clear: "クリア採点",
    leave_task: "課題離脱",
    story_or_episode: "ストーリー・エピソード閲覧",
    screen_enter: "画面入場",
    screen_exit: "画面離脱",
    yes_or_high: "あり・高群",
    no_or_low: "なし・低群",
    high: "高群",
    low: "低群",
    pre_test_high: "事前テスト高群",
    pre_test_low: "事前テスト低群",
    pre_attitude_high: "事前学習意識高群",
    pre_attitude_low: "事前学習意識低群",
  };

  function logMetadata(rows) {
    const included = new Set(rows.map((row) => row.participantId));
    const excluded = state.rows.map((row) => row.participantId).filter((id) => id && !included.has(id));
    return {
      excluded_participants: excluded.join(";"),
      included_episode_min: $("episode-filter").checked ? 3 : "",
      group: $("role-filter").value || "all",
      n: rows.length,
      generated_at: new Date().toISOString(),
    };
  }

  function rowsWithLogMetrics(rows, behaviorRows) {
    const behaviorById = new Map((behaviorRows || []).map((row) => [row.participant_id, row]));
    return rows.map((row) => {
      const behavior = behaviorById.get(row.participantId) || {};
      return {
        ...row,
        ...behavior,
        participant_id: row.participantId,
        group: row.role,
        story_or_episode_view_count: row.episodeCount,
      };
    });
  }

  function currentLogInputs(rows) {
    const ids = new Set(rows.map((row) => row.participantId));
    const profiles = state.profiles.filter((profile) => ids.has(profile.participant_id));
    const events = state.analysisEvents.filter((event) => ids.has(event.participant_id || (event.raw && event.raw[0] && event.raw[0].participant_id)));
    const rawEvents = state.rawEvents.filter((event) => ids.has(event.participant_id));
    return { profiles, events, rawEvents };
  }

  function refreshLogSummaries(rows) {
    if (!logAnalysis) return rows;
    const metadata = logMetadata(rows);
    const { profiles, events, rawEvents } = currentLogInputs(rows);
    state.participantBehaviorSummary = logAnalysis.buildParticipantBehaviorSummary(profiles, events, rawEvents, state.tasks, metadata);
    state.taskAttemptSummary = logAnalysis.buildTaskAttemptSummary(profiles, events, state.tasks, metadata);
    state.loveTransitionBehaviorSummary = logAnalysis.buildLoveTransitionBehaviorSummary(profiles, events, metadata);
    const mergedRows = rowsWithLogMetrics(rows, state.participantBehaviorSummary);
    state.surveyLogCorrelationStats = logAnalysis.buildCorrelationStats(mergedRows, CORRELATION_DEFINITIONS, metadata);
    state.groupAttributeLogSummary = logAnalysis.buildGroupAttributeLogSummary(mergedRows, LOG_METRICS, logAttributeDefinitions(), metadata);
    return mergedRows;
  }

  function logAttributeDefinitions() {
    const highLow = (key, label) => ({
      key,
      value(row) {
        const value = Number(row[key]);
        if (!Number.isFinite(value)) return "";
        const valid = state.rows.map((item) => Number(item[key])).filter(Number.isFinite);
        const med = median(valid);
        if (!Number.isFinite(med)) return "";
        return value >= med ? `${label}_high` : `${label}_low`;
      },
    });
    return [
      { key: "programming_experience", value: (row) => Number(row.programmingExperience) >= 3 ? "yes_or_high" : Number.isFinite(Number(row.programmingExperience)) ? "no_or_low" : "" },
      { key: "cpp_experience", value: (row) => Number(row.cppExperience) >= 3 ? "yes_or_high" : Number.isFinite(Number(row.cppExperience)) ? "no_or_low" : "" },
      highLow("preScore", "pre_test"),
      highLow("preAttitudeAverage", "pre_attitude"),
      { key: "novel_experience", value: (row) => Number(row.novelPreferenceValue) >= 3 ? "yes_or_high" : Number.isFinite(Number(row.novelPreferenceValue)) ? "no_or_low" : "" },
      { key: "story_empathy", value: (row) => Number(row.storyEmpathyValue) >= 4 ? "high" : Number.isFinite(Number(row.storyEmpathyValue)) ? "low" : "" },
      ...ILS_AXES.map((axis) => ({ key: axis.key, value: (row) => row[axis.key] && row[axis.key].label })),
    ];
  }

  function formatColumnLabel(key) {
    return COLUMN_LABELS[key] || LOG_METRICS.find((metric) => metric.key === key)?.label || key;
  }

  function formatGroupName(group) {
    return VALUE_LABELS[group] || group || "";
  }

  function formatEventType(type) {
    return VALUE_LABELS[type] || type || "";
  }

  function formatDisplayValue(key, value) {
    if (value == null || value === "") return "";
    if (typeof value === "boolean") return value ? "はい" : "いいえ";
    if (key === "group") return formatGroupName(value);
    if (key === "love_source" || key === "previous_action_type" || key === "next_action_type") return formatEventType(value);
    if (key === "attribute" || key === "attribute_value" || key === "metric" || key === "log_metric" || key === "survey_metric") return formatColumnLabel(VALUE_LABELS[value] || value);
    if (typeof value === "string" && VALUE_LABELS[value]) return VALUE_LABELS[value];
    if (typeof value === "number") return Number.isInteger(value) ? String(value) : fmt(value, 2);
    return String(value);
  }

  function renderPlainTable(tableId, headers, rows, limit) {
    const visibleRows = rows.slice(0, limit || rows.length);
    const body = visibleRows.map((row) => `<tr>${headers.map((header) => `<td>${escapeHtml(formatDisplayValue(header, row[header]))}</td>`).join("")}</tr>`).join("");
    $(tableId).innerHTML = `<thead><tr>${headers.map((header) => `<th>${escapeHtml(formatColumnLabel(header))}</th>`).join("")}</tr></thead><tbody>${body || `<tr><td colspan="${headers.length}" class="na">表示できるデータがありません</td></tr>`}</tbody>`;
  }

  function renderLogSummaryChart(rows) {
    const select = $("log-metric-select");
    if (!select) return;
    if (!select.options.length) {
      select.innerHTML = LOG_METRICS.map((metric) => `<option value="${escapeHtml(metric.key)}">${escapeHtml(metric.label)}</option>`).join("");
    }
    const metric = LOG_METRICS.find((item) => item.key === select.value) || LOG_METRICS[0];
    select.value = metric.key;
    const group = (role, color) => {
      const points = rows.filter((row) => row.group === role && Number.isFinite(Number(row[metric.key]))).map((row) => ({
        participantId: row.participant_id,
        roleLabel: formatGroupName(role),
        value: Number(row[metric.key]),
        episodeCount: row.episodeCount,
        metricLabel: metric.label,
        valueKind: "postOnly",
      }));
      return { label: formatGroupName(role), tickLabel: formatGroupName(role), color, points, summary: summarize(points.map((point) => point.value)) };
    };
    charts.boxplotWithPoints("log-summary-chart", [
      group("experimental", COLORS.experimental),
      group("control", COLORS.control),
    ], {
      yTitle: metric.label,
      tooltipFormatter(point) {
        const lines = [
          `参加者ID: ${point.participantId || "-"}`,
          `群: ${point.roleLabel || "-"}`,
          `${metric.label}: ${Number.isFinite(point.value) ? point.value.toFixed(2) : "-"}`,
        ];
        if (Number.isFinite(point.episodeCount)) lines.push(`エピソード閲覧数: ${point.episodeCount}`);
        return lines;
      },
      legendItems: [
        { label: formatGroupName("experimental"), color: COLORS.experimental },
        { label: formatGroupName("control"), color: COLORS.control },
      ],
    });
  }

  function renderCorrelationScatter(rows) {
    const select = $("correlation-select");
    if (!select || !charts.scatter) return;
    if (!select.options.length) {
      select.innerHTML = CORRELATION_DEFINITIONS.map((definition, index) => `<option value="${index}">${escapeHtml(definition.label)}</option>`).join("");
    }
    const definition = CORRELATION_DEFINITIONS[Number(select.value) || 0] || CORRELATION_DEFINITIONS[0];
    const points = rows.map((row) => ({
      x: Number(row[definition.log_key]),
      y: Number(row[definition.survey_key]),
      participantId: row.participantId,
      group: row.role,
    })).filter((point) => Number.isFinite(point.x) && Number.isFinite(point.y));
    charts.scatter("correlation-chart", points, {
      xTitle: formatColumnLabel(definition.log_key),
      yTitle: formatColumnLabel(definition.survey_key),
      colors: COLORS,
      groupLabels: { experimental: formatGroupName("experimental"), control: formatGroupName("control") },
    });
  }

  function renderLoveTransitionTimeline(rows) {
    const tableRows = state.loveTransitionBehaviorSummary.slice(0, 80);
    renderPlainTable("love-transition-table", [
      "participant_id", "group", "event_time", "love_before", "love_after", "love_delta", "love_source",
      "related_task_id", "previous_action_type", "next_action_type", "next_action_within_3min",
      "next_task_continued", "next_chat_sent", "next_execute_done", "next_grade_done", "next_story_or_episode_viewed",
    ], tableRows);
    if (!charts.line) return;
    const labels = tableRows.map((row) => `${row.participant_id} ${row.event_time || ""}`.trim());
    charts.line("love-transition-chart", labels, [
      { label: "親密度変化量", borderColor: COLORS.experimental, backgroundColor: COLORS.experimental, data: tableRows.map((row) => row.love_delta || 0) },
      { label: "課題継続", borderColor: COLORS.control, backgroundColor: COLORS.control, data: tableRows.map((row) => row.next_task_continued ? 1 : 0) },
    ], { yTitle: "親密度変化量 / 課題継続" });
  }

  function renderLogAnalysis(rows) {
    const mergedRows = refreshLogSummaries(rows);
    renderLogSummaryChart(mergedRows);
    renderPlainTable("behavior-summary-table", [
      "participant_id", "group", "session_count", "total_duration_min", "attempted_task_count", "cleared_task_count",
      "optional_task_count", "execute_count", "grade_count", "chat_user_count", "chat_ai_count", "error_count",
      "error_rate", "retry_after_error_count", "retry_after_low_score_count", "feedback_to_retry_count",
      "feedback_to_chat_count", "feedback_to_leave_count", "love_change_count", "love_total_gain",
      "love_gain_from_ai", "love_gain_from_score_bonus", "final_love", "max_score_reference",
    ], state.participantBehaviorSummary);
    renderPlainTable("task-attempt-table", [
      "participant_id", "group", "task_id", "task_category", "is_optional_task", "task_started_at",
      "first_execute_at", "first_grade_at", "cleared_at", "left_task_at", "execute_count", "grade_count",
      "error_count", "first_grade_score", "clear_score", "max_score_reference", "cleared",
      "attempts_until_clear", "grades_until_clear", "time_until_first_execute_sec",
      "time_until_first_grade_sec", "time_until_clear_sec", "retried_after_error",
      "retried_after_low_score", "used_chat_before_clear", "used_chat_after_error", "used_chat_after_low_score",
    ], state.taskAttemptSummary, 300);
    renderLoveTransitionTimeline(mergedRows);
    renderPlainTable("correlation-table", [
      "label", "log_metric", "survey_metric", "group", "n", "pearson_r", "pearson_p_value_approx", "spearman_rho", "spearman_p_value_approx",
    ], state.surveyLogCorrelationStats);
    renderCorrelationScatter(mergedRows);
    renderPlainTable("group-attribute-log-table", [
      "attribute", "attribute_value", "metric", "group", "n", "mean", "median", "sd", "q1", "q3", "min", "max",
    ], state.groupAttributeLogSummary, 500);
  }

  function renderAll() {
    const rows = filteredRows();
    renderSummary(rows); renderTests(rows); renderAttitude(rows); renderBalance(rows); renderAttributes(rows); renderParticipants(rows); renderIntimacy(rows); renderLogAnalysis(rows);
    $("download-analysis-csv").disabled = rows.length === 0;
    $("download-stats-csv").disabled = rows.length === 0;
    ["download-participant-behavior-csv", "download-task-attempt-csv", "download-love-transition-csv", "download-survey-log-correlation-csv", "download-group-attribute-log-csv"].forEach((id) => {
      const button = $(id);
      if (button) button.disabled = rows.length === 0;
    });
  }

  async function loadAnalysis() {
    api.setPassword($("admin-password").value);
    if (!api.getPassword()) return setStatus("analysis-status", "管理パスワードを入力してください", true);
    setStatus("analysis-status", "読み込み中...");
    try {
      const [profiles, experimentData, events, tasks] = await Promise.all([
        api.fetchJSON("/api/admin/profiles"),
        api.fetchJSON("/api/admin/experiment-data"),
        api.fetchJSON("/api/admin/events?limit=200000"),
        fetch("/data/others/tasks.json").then((response) => response.ok ? response.json() : {}),
      ]);
      state.profiles = profiles.profiles || [];
      state.experimentData = experimentData;
      state.rawEvents = events.events || [];
      state.analysisEvents = logAnalysis ? logAnalysis.buildAnalysisEvents(state.rawEvents) : [];
      state.tasks = tasks || {};
      buildRows(); renderAll();
      setStatus("analysis-status", `${state.rows.length}名を読み込みました`);
    } catch (error) {
      setStatus("analysis-status", error.message || String(error), true);
    }
  }

  function downloadLogCsv(filename, rows) {
    const list = rows || [];
    const headers = Array.from(list.reduce((set, row) => {
      Object.keys(row || {}).forEach((key) => set.add(key));
      return set;
    }, new Set()));
    downloadCSV(filename, headers, list.map((row) => headers.map((header) => row[header])));
  }

  function downloadRows() {
    const rows = filteredRows();

    const headers = [
      "participant_id",
      "name",
      "role",
      "episode_count",
      "gender",
      "pre_test",
      "post_test",
      "test_gain",
      ...ATTITUDE_ITEMS.flatMap((item) => [
        `pre_${item.csvKey}`,
        `post_${item.csvKey}`,
        `${item.csvKey}_gain`,
      ]),
      "pre_attitude_average",
      "post_attitude_average",
      "attitude_average_gain",
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
      r.episodeCount,
      r.gender,
      r.preScore,
      r.postScore,
      r.testGain,
      ...ATTITUDE_ITEMS.flatMap((item) => [r[item.preKey], r[item.postKey], r[item.gainKey]]),
      r.preAttitudeAverage,
      r.postAttitudeAverage,
      r.attitudeAverageGain,
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

  function exportMetadata() {
    return [
      $("include-25nm467r").checked,
      $("episode-filter").checked,
      $("episode-filter").checked ? 3 : "",
      $("role-filter").value || "all",
      new Date().toISOString(),
    ];
  }

  const metadataHeaders = ["include_25NM467R", "episode_filter_enabled", "min_episode_read_count", "group_filter", "exported_at"];
  const comparisonCsvHeaders = [
    "record_type", "section", "metric", "category",
    "experimental_n", "experimental_percent", "experimental_mean", "experimental_sd", "experimental_median", "experimental_q1", "experimental_q3", "experimental_iqr",
    "control_n", "control_percent", "control_mean", "control_sd", "control_median", "control_q1", "control_q3", "control_iqr",
    "mean_diff", "median_diff", "mann_whitney_u", "p_value", "cliffs_delta", "cliffs_delta_label", "hedges_g",
    ...metadataHeaders,
  ];

  function valuesForDefinition(rows, role, definition) {
    const selected = rows.filter((row) => row.role === role);
    return definition.values ? definition.values(selected) : selected.map((row) => row[definition.key]);
  }

  function comparisonCsvRow(rows, definition, section, metadata) {
    const comparison = compareGroups(
      valuesForDefinition(rows, "experimental", definition),
      valuesForDefinition(rows, "control", definition)
    );
    const e = comparison.groupA_summary, c = comparison.groupB_summary;
    return [
      "numeric", section, definition.label, "",
      e.n, "", e.mean, e.sd, e.median, e.q1, e.q3, e.iqr,
      c.n, "", c.mean, c.sd, c.median, c.q1, c.q3, c.iqr,
      comparison.meanDiff, comparison.medianDiff, comparison.mannWhitneyU, comparison.pValue,
      comparison.cliffsDelta, comparison.cliffsDeltaLabel, comparison.hedgesG,
      ...metadata,
    ];
  }

  function prePostDefinitions() {
    return [
      { key: "testGain", label: "事前・事後テストの変化量" },
      ...ATTITUDE_ITEMS.map((item) => ({ key: item.gainKey, label: `${item.label}（変化量）` })),
    ];
  }

  function balanceDefinitions() {
    return [
      ...balanceMetrics("preQuestionnaire"),
      ...balanceMetrics("preTest"),
      ...ILS_AXES.map((axis) => ({
        label: `${axis.left}－${axis.right} 符号付きスコア`,
        values: (selectedRows) => selectedRows.map((row) => row[axis.key] && row[axis.key].signed),
      })),
    ];
  }

  function categoricalCsvRows(rows, key, label, section, metadata) {
    const valueFor = typeof key === "function" ? key : (row) => row[key];
    const valid = rows.filter((row) => valueFor(row) && !String(valueFor(row)).includes("不明"));
    const categories = Array.from(new Set(valid.map(valueFor)));
    const expTotal = valid.filter((row) => row.role === "experimental").length;
    const ctrlTotal = valid.filter((row) => row.role === "control").length;
    return categories.map((category) => {
      const exp = valid.filter((row) => row.role === "experimental" && valueFor(row) === category).length;
      const ctrl = valid.filter((row) => row.role === "control" && valueFor(row) === category).length;
      return [
        "categorical", section, label, category,
        exp, expTotal ? exp / expTotal * 100 : "", "", "", "", "", "", "",
        ctrl, ctrlTotal ? ctrl / ctrlTotal * 100 : "", "", "", "", "", "", "",
        "", "", "", "", "", "", "",
        ...metadata,
      ];
    });
  }

  function downloadStatsCsv() {
    const rows = filteredRows();
    const selected = $("stats-export-select").value;
    const metadata = exportMetadata();
    if (selected === "participants") {
      const headers = ["participant_id", "name", "role", "episode_count", "gender", "programming_experience", "cpp_experience", "pre_test", ...ATTITUDE_ITEMS.map((item) => `pre_${item.csvKey}`), ...metadataHeaders];
      const data = rows.map((row) => [row.participantId, row.name, row.role, row.episodeCount, row.gender, row.programmingExperience, row.cppExperience, row.preScore, ...ATTITUDE_ITEMS.map((item) => row[item.preKey]), ...metadata]);
      downloadCSV("participant_level_summary.csv", headers, data);
      return;
    }
    if (selected === "intimacy") {
      const headers = ["metric", "n", "mean", "sd", "median", "q1", "q3", "iqr", "min", "max", ...metadataHeaders];
      const data = INTIMACY_METRICS.map((metric) => {
        const summary = summarize(rows.filter((row) => row.role === "experimental").map((row) => row[metric.key]));
        return [metric.label, summary.n, summary.mean, summary.sd, summary.median, summary.q1, summary.q3, summary.iqr, summary.min, summary.max, ...metadata];
      });
      downloadCSV("intimacy_system_stats.csv", headers, data);
      return;
    }
    let definitions = [], filename = "group_comparison_stats.csv", section = "group_comparison";
    let extraRows = [];
    if (selected === "change") {
      definitions = prePostDefinitions(); filename = "pre_post_change_stats.csv"; section = "pre_post_change";
    } else if (selected === "post") {
      definitions = POST_EVALUATION_METRICS; filename = "post_survey_group_stats.csv"; section = "post_survey";
    } else if (selected === "balance") {
      definitions = balanceDefinitions(); filename = "attribute_balance_stats.csv"; section = "attribute_balance";
      extraRows = [
        ...categoricalCsvRows(rows, "gender", "性別", section, metadata),
        ...ILS_AXES.flatMap((axis) => categoricalCsvRows(rows, (row) => row[axis.key] && row[axis.key].label, `${axis.left}－${axis.right}`, section, metadata)),
      ];
    } else {
      definitions = [...prePostDefinitions(), ...POST_EVALUATION_METRICS];
    }
    downloadCSV(filename, comparisonCsvHeaders, [
      ...definitions.map((definition) => comparisonCsvRow(rows, definition, section, metadata)),
      ...extraRows,
    ]);
  }

  $("load-analysis").addEventListener("click", loadAnalysis);
  $("download-analysis-csv").addEventListener("click", downloadRows);
  $("download-stats-csv").addEventListener("click", downloadStatsCsv);
  [
    ["download-participant-behavior-csv", "participant_behavior_summary.csv", () => state.participantBehaviorSummary],
    ["download-task-attempt-csv", "task_attempt_summary.csv", () => state.taskAttemptSummary],
    ["download-love-transition-csv", "love_transition_behavior_summary.csv", () => state.loveTransitionBehaviorSummary],
    ["download-survey-log-correlation-csv", "survey_log_correlation_stats.csv", () => state.surveyLogCorrelationStats],
    ["download-group-attribute-log-csv", "group_attribute_log_summary.csv", () => state.groupAttributeLogSummary],
  ].forEach(([id, filename, rows]) => {
    const button = $(id);
    if (button) button.addEventListener("click", () => downloadLogCsv(filename, rows()));
  });
  ["role-filter", "include-25nm467r", "episode-filter", "attitude-attribute-select", "balance-target-select", "attribute-select", "evaluation-select", "intimacy-attribute-select", "log-metric-select", "correlation-select"].forEach((id) => {
    const element = $(id);
    if (element) element.addEventListener("change", renderAll);
  });
  $("participant-filter").addEventListener("input", renderAll);
  $("admin-password").addEventListener("keydown", (event) => { if (event.key === "Enter") loadAnalysis(); });
  $("admin-password").value = api.getPassword();
})();
