(function() {
  "use strict";

  const { $, escapeHtml, setStatus, downloadCSV } = window.AdminUI;
  const api = window.AdminAPI;
  const charts = window.AdminCharts;

  const state = { profiles: [], experimentData: null, rows: [] };
  const COLORS = { experimental: "#0f8b8d", control: "#ea7a12" };
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
  function average(row, columns) { return mean(columns.map((column) => scale(valueOf(row, column)))); }

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
        preSelfEfficacy: average(pre, [COLUMNS.preSelfCoding, COLUMNS.preDebug, COLUMNS.prePersistence]),
        postSelfEfficacy: average(post, [COLUMNS.preSelfCoding, COLUMNS.preDebug, COLUMNS.prePersistence]),
        preMotivation: average(pre, [COLUMNS.preInterest, COLUMNS.preContinue]),
        postMotivation: average(post, [COLUMNS.preInterest, COLUMNS.preContinue]),
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
      row.selfEfficacyGain = Number.isFinite(row.preSelfEfficacy) && Number.isFinite(row.postSelfEfficacy) ? row.postSelfEfficacy - row.preSelfEfficacy : NaN;
      row.motivationGain = Number.isFinite(row.preMotivation) && Number.isFinite(row.postMotivation) ? row.postMotivation - row.preMotivation : NaN;
      ILS_AXES.forEach((axis) => { row[axis.key] = ilsScore(ilsRow, axis); });
      return row;
    });
  }

  function filteredRows() {
    const role = $("role-filter").value;
    const text = clean($("participant-filter").value).toLowerCase();
    return state.rows.filter((row) => (!role || row.role === role) && (!text || `${row.participantId} ${row.name}`.toLowerCase().includes(text)));
  }

  function byRole(rows, role, key) { return rows.filter((row) => row.role === role).map((row) => row[key]); }

  function renderSummary(rows) {
    const exp = rows.filter((r) => r.role === "experimental").length;
    const ctrl = rows.filter((r) => r.role === "control").length;
    const testPairs = rows.filter((r) => Number.isFinite(r.preScore) && Number.isFinite(r.postScore)).length;
    const surveyPairs = rows.filter((r) => Number.isFinite(r.preSelfEfficacy) && Number.isFinite(r.postSelfEfficacy)).length;
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
      const exp = byRole(rows, "experimental", metric.key);
      const ctrl = byRole(rows, "control", metric.key);
      return `<tr><td class="metric-name">${escapeHtml(metric.label)}</td><td>${n(exp)}</td><td>${fmt(mean(exp))}</td><td>${fmt(median(exp))}</td><td>${fmt(sd(exp))}</td><td>${n(ctrl)}</td><td>${fmt(mean(ctrl))}</td><td>${fmt(median(ctrl))}</td><td>${fmt(sd(ctrl))}</td><td>${fmt(mean(exp) - mean(ctrl))}</td><td>${fmt(cohenD(exp, ctrl))}</td></tr>`;
    }).join("");
  }

  function comparisonHeader() {
    return "<thead><tr><th class=\"metric-name\">指標</th><th>実験 n</th><th>実験 平均</th><th>実験 中央値</th><th>実験 SD</th><th>統制 n</th><th>統制 平均</th><th>統制 中央値</th><th>統制 SD</th><th>平均差</th><th>Cohen's d</th></tr></thead>";
  }

  function renderTests(rows) {
    const metrics = [
      { key: "preScore", label: "事前テスト" },
      { key: "postScore", label: "事後テスト" },
      { key: "testGain", label: "変化量（事後－事前）" },
    ];
    $("test-table").innerHTML = comparisonHeader() + `<tbody>${comparisonRows(rows, metrics)}</tbody>`;
    charts.line("test-chart", ["事前", "事後"], [
      { label: `実験群（対応n=${n(byRole(rows, "experimental", "testGain"))}）`, borderColor: COLORS.experimental, backgroundColor: COLORS.experimental, data: [mean(byRole(rows, "experimental", "preScore")), mean(byRole(rows, "experimental", "postScore"))] },
      { label: `統制群（対応n=${n(byRole(rows, "control", "testGain"))}）`, borderColor: COLORS.control, backgroundColor: COLORS.control, data: [mean(byRole(rows, "control", "preScore")), mean(byRole(rows, "control", "postScore"))] },
    ], { yTitle: "平均得点", beginAtZero: true });
  }

  function renderAttitude(rows) {
    const metrics = [
      { key: "preSelfEfficacy", label: "自己効力感・事前（3項目平均）" },
      { key: "postSelfEfficacy", label: "自己効力感・事後（3項目平均）" },
      { key: "selfEfficacyGain", label: "自己効力感・変化量" },
      { key: "preMotivation", label: "学習意欲・事前（2項目平均）" },
      { key: "postMotivation", label: "学習意欲・事後（2項目平均）" },
      { key: "motivationGain", label: "学習意欲・変化量" },
    ];
    $("attitude-table").innerHTML = comparisonHeader() + `<tbody>${comparisonRows(rows, metrics)}</tbody>`;
    charts.groupedBar("attitude-chart", ["自己効力感・事前", "自己効力感・事後", "学習意欲・事前", "学習意欲・事後"], [
      { label: "実験群", backgroundColor: COLORS.experimental, data: ["preSelfEfficacy", "postSelfEfficacy", "preMotivation", "postMotivation"].map((key) => mean(byRole(rows, "experimental", key))) },
      { label: "統制群", backgroundColor: COLORS.control, data: ["preSelfEfficacy", "postSelfEfficacy", "preMotivation", "postMotivation"].map((key) => mean(byRole(rows, "control", key))) },
    ], { min: 1, max: 5, beginAtZero: false, yTitle: "5件法平均" });
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
    if (key.startsWith("ils")) return row[key] ? row[key].label : "不明";
    return row[key] || "不明";
  }

  function renderAttributes(rows) {
    const attribute = $("attribute-select").value;
    const metric = $("evaluation-select").value;
    const categories = Array.from(new Set(rows.map((r) => attributeValue(r, attribute)))).filter((v) => v !== "不明" && !String(v).startsWith("方向不明"));
    const roleData = (role, category) => rows.filter((r) => r.role === role && attributeValue(r, attribute) === category).map((r) => r[metric]);
    const table = categories.map((category) => {
      const e = roleData("experimental", category), c = roleData("control", category);
      return `<tr><td class="metric-name">${escapeHtml(category)}</td><td>${n(e)}</td><td>${fmt(mean(e))}</td><td>${fmt(sd(e))}</td><td>${n(c)}</td><td>${fmt(mean(c))}</td><td>${fmt(sd(c))}</td><td>${fmt(mean(e) - mean(c))}</td></tr>`;
    }).join("");
    $("attribute-table").innerHTML = `<thead><tr><th class="metric-name">属性区分</th><th>実験 n</th><th>実験 平均</th><th>実験 SD</th><th>統制 n</th><th>統制 平均</th><th>統制 SD</th><th>平均差</th></tr></thead><tbody>${table || '<tr><td colspan="8" class="na">対象データなし</td></tr>'}</tbody>`;
    charts.groupedBar("attribute-chart", categories, [
      { label: "実験群", backgroundColor: COLORS.experimental, data: categories.map((x) => mean(roleData("experimental", x))) },
      { label: "統制群", backgroundColor: COLORS.control, data: categories.map((x) => mean(roleData("control", x))) },
    ], { min: 1, max: 5, beginAtZero: false, yTitle: "5件法平均" });
  }

  function renderItems(rows) {
    const metrics = [
      ["enjoyment", "このシステムでの学習は楽しかった"],
      ["accomplishment", "課題を上手くこなせた"],
      ["learningUsefulness", "このシステムは学習に役立つと思う"],
      ["continuedUse", "今後もこのシステムを使いたい"],
      ["anxiety", "不安・プレッシャーを感じた"],

      ["agentIntimacy", "エージェントに対して親しみを感じた"],
      ["agentTogetherness", "エージェントと一緒に学習している感覚があった"],
      ["agentRelationshipGrowth", "エージェントとの関係が深まっているように感じた"],

      ["episodeMotivation", "エピソードによる動機づけ"],
    ];

    $("item-table").innerHTML =
      comparisonHeader() +
      `<tbody>${comparisonRows(
        rows,
        metrics.map(([key, label]) => ({ key, label }))
      )}</tbody>`;

    charts.horizontalBar(
      "item-chart",
      metrics.map(([, label]) => label),
      [
        {
          label: "実験群",
          backgroundColor: COLORS.experimental,
          data: metrics.map(([key]) =>
            mean(byRole(rows, "experimental", key))
          ),
        },
        {
          label: "統制群",
          backgroundColor: COLORS.control,
          data: metrics.map(([key]) =>
            mean(byRole(rows, "control", key))
          ),
        },
      ],
      { max: 5, xTitle: "5件法平均" }
    );
  }

  function renderIntimacy(rows) {
    const experimentalRows = rows.filter(
      (row) => row.role === "experimental"
    );

    const metrics = [
      [
        "intimacyMotivation",
        "親密度が上昇することで、学習を続けたいという気持ちが高まった"
      ],
      [
        "intimacyCloseness",
        "親密度の変化に応じて、エージェントとの距離が近づいたと感じた"
      ],
      [
        "intimacyNaturalness",
        "親密度に応じたエージェントの言葉遣いや反応の変化は自然だった"
      ],
    ];

    const table = $("intimacy-table");

    if (!table) {
      return;
    }

    const tableRows = metrics
      .map(([key, label]) => {
        const values = experimentalRows
          .map((row) => Number(row[key]))
          .filter(Number.isFinite);

        return `
          <tr>
            <td class="metric-name">${escapeHtml(label)}</td>
            <td>${values.length}</td>
            <td>${fmt(mean(values))}</td>
            <td>${fmt(median(values))}</td>
            <td>${fmt(sd(values))}</td>
          </tr>
        `;
      })
      .join("");

    table.innerHTML = `
      <thead>
        <tr>
          <th class="metric-name">評価項目</th>
          <th>n</th>
          <th>平均</th>
          <th>中央値</th>
          <th>SD</th>
        </tr>
      </thead>
      <tbody>
        ${tableRows}
      </tbody>
    `;

    const chartValues = metrics.map(([key]) => {
      const values = experimentalRows
        .map((row) => Number(row[key]))
        .filter(Number.isFinite);

      return mean(values);
    });

    charts.horizontalBar(
      "intimacy-chart",
      metrics.map(([, label]) => label),
      [
        {
          label: "実験群",
          backgroundColor: COLORS.experimental,
          data: chartValues,
        },
      ],
      {
        max: 5,
        xTitle: "5件法平均",
      }
    );
  }

  function renderParticipants(rows) {
    const ilsCell = (row, key) => row[key] ? row[key].label : "-";
    $("participant-table").innerHTML = `<thead><tr><th>ID</th><th>名前</th><th>群</th><th>性別</th><th>事前テスト</th><th>事後テスト</th><th>差</th><th>自己効力感 前</th><th>自己効力感 後</th><th>差</th><th>学習意欲 前</th><th>学習意欲 後</th><th>差</th><th>ノベル嗜好</th><th>感情移入</th><th>ACT/REF</th><th>SNS/INT</th><th>VIS/VRB</th><th>SEQ/GLO</th><th>楽しさ</th><th>達成感</th><th>学習への有用性</th><th>継続利用意向</th></tr></thead><tbody>${rows.map((r) => `<tr><td>${escapeHtml(r.participantId)}</td><td>${escapeHtml(r.name)}</td><td>${escapeHtml(ROLE_LABEL[r.role] || r.role)}</td><td>${escapeHtml(r.gender)}</td><td>${fmt(r.preScore)}</td><td>${fmt(r.postScore)}</td><td>${fmt(r.testGain)}</td><td>${fmt(r.preSelfEfficacy)}</td><td>${fmt(r.postSelfEfficacy)}</td><td>${fmt(r.selfEfficacyGain)}</td><td>${fmt(r.preMotivation)}</td><td>${fmt(r.postMotivation)}</td><td>${fmt(r.motivationGain)}</td><td>${fmt(r.novelPreferenceValue)}</td><td>${fmt(r.storyEmpathyValue)}</td><td>${escapeHtml(ilsCell(r, "ilsActiveReflective"))}</td><td>${escapeHtml(ilsCell(r, "ilsSensingIntuitive"))}</td><td>${escapeHtml(ilsCell(r, "ilsVisualVerbal"))}</td><td>${escapeHtml(ilsCell(r, "ilsSequentialGlobal"))}</td><td>${fmt(r.enjoyment)}</td><td>${fmt(r.accomplishment)}</td><td>${fmt(r.learningUsefulness)}</td></tr>`).join("")}</tbody>`;
  }

  function renderAll() {
    const rows = filteredRows();
    renderSummary(rows); renderTests(rows); renderAttitude(rows); renderIls(rows); renderAttributes(rows); renderItems(rows); renderParticipants(rows); renderIntimacy(rows);
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
      "pre_self_efficacy",
      "post_self_efficacy",
      "self_efficacy_gain",
      "pre_motivation",
      "post_motivation",
      "motivation_gain",
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
      r.preSelfEfficacy,
      r.postSelfEfficacy,
      r.selfEfficacyGain,
      r.preMotivation,
      r.postMotivation,
      r.motivationGain,
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
  ["role-filter", "attribute-select", "evaluation-select"].forEach((id) => $(id).addEventListener("change", renderAll));
  $("participant-filter").addEventListener("input", renderAll);
  $("admin-password").addEventListener("keydown", (event) => { if (event.key === "Enter") loadAnalysis(); });
  $("admin-password").value = api.getPassword();
})();
