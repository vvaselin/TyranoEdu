"use strict";

const assert = require("node:assert/strict");

const elements = new Map();
global.window = global;
global.document = {
  getElementById(id) {
    if (!elements.has(id)) elements.set(id, { id, hidden: false, style: {}, textContent: "" });
    return elements.get(id);
  },
};
global.Chart = class ChartMock {
  constructor(canvas, config) {
    this.canvas = canvas;
    this.config = config;
    global.lastChart = this;
  }
  destroy() {}
};

require("./charts.js");

const groups = [
  {
    label: "実験群",
    tickLabel: "実験群",
    color: "#008080",
    summary: { n: 2, q1: 0.5, median: 1, q3: 1.5, min: 0, max: 2 },
    points: [
      { participantId: "A01", roleLabel: "実験群", value: 1, pre: 2, post: 3, gain: 1, episodeCount: 4, metricLabel: "テスト", valueKind: "score" },
      { participantId: "A02", roleLabel: "実験群", value: 2, pre: 1, post: 3, gain: 2, episodeCount: 3, metricLabel: "テスト" },
    ],
  },
  {
    label: "統制群",
    tickLabel: "統制群",
    color: "#ef7d00",
    summary: { n: 0, q1: null, median: null, q3: null, min: null, max: null },
    points: [],
  },
];

AdminCharts.boxplotWithPoints("chart", groups, { min: -4, max: 4 });
assert.equal(lastChart.config.data.datasets.length, 2);
assert.equal(lastChart.config.data.datasets[0].data.length, 2);
assert.equal(groups[0].summary.n, lastChart.config.data.datasets[0].data.length);
assert.equal(lastChart.config.data.datasets[1].data.length, 0);
assert.equal(lastChart.config.options.scales.y.min, -4);
assert.equal(lastChart.config.options.scales.y.max, 4);
assert.equal(lastChart.config.options.scales.x.ticks.callback(0), "実験群");
assert.equal(lastChart.config.options.scales.x.ticks.callback(1), "統制群");
assert.equal(lastChart.config.plugins[0].id, "zeroReferenceLine");
assert.equal(lastChart.config.plugins[1].id, "boxplotOverlay");

const firstPoint = lastChart.config.data.datasets[0].data[0];
assert.ok(firstPoint.x >= -0.14 && firstPoint.x <= 0.14);
assert.equal(firstPoint.y, firstPoint.value);
const tooltip = lastChart.config.options.plugins.tooltip.callbacks.label({ raw: firstPoint });
assert.ok(tooltip.includes("参加者ID: A01"));
assert.ok(tooltip.includes("事前得点: 2.00"));
assert.ok(tooltip.includes("事後得点: 3.00"));
assert.ok(tooltip.includes("変化量: 1.00"));
assert.ok(tooltip.includes("エピソード閲覧数: 4"));

AdminCharts.boxplotWithPoints("chart", groups, {});
assert.equal(lastChart.config.data.datasets[0].data[0].x, firstPoint.x);

groups[0].position = -0.17;
groups[1].position = 0.17;
groups[0].points[0].metricLabel = "C++の基本的なプログラムを自力で作成できると思う";
groups[0].points[0].valueKind = "response";
const attitudeLabels = [
  ["C++の基本的なプログラムを自力で作成できると思う"],
  ["プログラムにエラーが出ても原因を探して修正できると思う"],
  ["難しいプログラミング課題でも、諦めずに取り組めると思う"],
  ["プログラミング学習に興味がある"],
  ["今後もプログラミングを学び続けたいと思う"],
];
AdminCharts.boxplotWithPoints("horizontal-chart", groups, {
  orientation: "horizontal",
  itemLabels: attitudeLabels,
  legendItems: [{ label: "実験群", color: "#008080" }],
});
const horizontalPoint = lastChart.config.data.datasets[0].data[0];
assert.equal(horizontalPoint.x, horizontalPoint.value);
assert.ok(horizontalPoint.y > -0.24 && horizontalPoint.y < -0.10);
attitudeLabels.forEach((label, index) => assert.equal(lastChart.config.options.scales.y.ticks.callback(index), label));
assert.equal(lastChart.config.options.scales.y.ticks.display, false);
assert.equal(lastChart.config.options.layout.padding.left, 400);
assert.equal(lastChart.config.plugins[2].id, "questionAxisLabels");
assert.equal(lastChart.config.options.scales.x.title.text, "変化量（事後－事前）");
const horizontalTooltipTitle = lastChart.config.options.plugins.tooltip.callbacks.title([{ raw: lastChart.config.data.datasets[0].data[0] }]);
assert.equal(horizontalTooltipTitle, "質問項目: C++の基本的なプログラムを自力で作成できると思う");
const horizontalTooltip = lastChart.config.options.plugins.tooltip.callbacks.label({ raw: lastChart.config.data.datasets[0].data[0] });
assert.ok(horizontalTooltip.includes("事前回答: 2.00"));
assert.ok(horizontalTooltip.includes("事後回答: 3.00"));
const postOnlyTooltip = lastChart.config.options.plugins.tooltip.callbacks.label({
  raw: { ...lastChart.config.data.datasets[0].data[0], valueKind: "postOnly", value: 4 },
});
assert.ok(postOnlyTooltip.includes("参加者ID: A01"));
assert.ok(postOnlyTooltip.includes("群: 実験群"));
assert.ok(postOnlyTooltip.includes("回答: 4.00"));
assert.ok(!postOnlyTooltip.some((line) => line.startsWith("事前回答:")));

console.log("chart tests passed");
