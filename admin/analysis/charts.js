(function(global) {
  const instances = {};

  function ready(canvasId) {
    const canvas = document.getElementById(canvasId);
    const fallback = document.getElementById(`${canvasId}-fallback`);
    if (!canvas) return false;
    if (!global.Chart) {
      canvas.hidden = true;
      if (fallback) {
        fallback.hidden = false;
        fallback.textContent = "Chart.jsを読み込めませんでした。表は利用できます。";
      }
      return false;
    }
    canvas.hidden = false;
    if (fallback) fallback.hidden = true;
    return true;
  }

  function draw(canvasId, config) {
    if (!ready(canvasId)) return;
    if (instances[canvasId]) instances[canvasId].destroy();
    instances[canvasId] = new Chart(document.getElementById(canvasId), config);
  }

  const common = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: "nearest", intersect: false },
    plugins: {
      legend: { position: "bottom", labels: { usePointStyle: true, boxWidth: 10 } },
      tooltip: { callbacks: {} },
    },
  };

  function groupedBar(canvasId, labels, datasets, options) {
    const opts = options || {};
    draw(canvasId, {
      type: "bar",
      data: { labels, datasets },
      options: {
        ...common,
        plugins: {
          ...common.plugins,
          title: { display: !!opts.title, text: opts.title },
        },
        scales: {
          x: { stacked: !!opts.stacked, grid: { display: false } },
          y: {
            stacked: !!opts.stacked,
            beginAtZero: opts.beginAtZero !== false,
            min: Number.isFinite(opts.min) ? opts.min : undefined,
            max: Number.isFinite(opts.max) ? opts.max : undefined,
            title: { display: !!opts.yTitle, text: opts.yTitle || "" },
          },
        },
      },
    });
  }

  function line(canvasId, labels, datasets, options) {
    const opts = options || {};
    const pairLabelPlugin = {
      id: "pairAxisLabels",
      afterDraw(chart) {
        const pairLabels = opts.pairLabels || [];
        if (!pairLabels.length || !chart.scales.x) return;
        const { ctx, chartArea, scales } = chart;
        ctx.save();
        ctx.textAlign = "center";
        ctx.textBaseline = "top";
        ctx.fillStyle = opts.pairLabelColor || "#334155";
        ctx.font = opts.pairLabelFont || "600 11px sans-serif";
        pairLabels.forEach((label, index) => {
          const left = scales.x.getPixelForValue(index * 2);
          const right = scales.x.getPixelForValue(index * 2 + 1);
          const x = (left + right) / 2;
          const y = chartArea.bottom + (opts.pairLabelOffset || 34);
          ctx.fillText(label, x, y, opts.pairLabelMaxWidth || 120);
        });
        ctx.restore();
      },
    };
    draw(canvasId, {
      type: "line",
      data: { labels, datasets: datasets.map((ds) => ({ tension: 0.15, pointRadius: 4, pointHoverRadius: 6, ...ds })) },
      plugins: [pairLabelPlugin],
      options: {
        ...common,
        layout: opts.layout || undefined,
        plugins: {
          ...common.plugins,
          legend: { ...common.plugins.legend, display: opts.showLegend !== false },
          title: { display: !!opts.title, text: opts.title },
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: {
              autoSkip: opts.autoSkipX !== false,
              maxRotation: Number.isFinite(opts.maxRotation) ? opts.maxRotation : 0,
              minRotation: Number.isFinite(opts.minRotation) ? opts.minRotation : 0,
            },
          },
          y: {
            beginAtZero: opts.beginAtZero !== false,
            min: Number.isFinite(opts.min) ? opts.min : undefined,
            max: Number.isFinite(opts.max) ? opts.max : undefined,
            title: { display: !!opts.yTitle, text: opts.yTitle || "" },
          },
        },
      },
    });
  }

  function horizontalBar(canvasId, labels, datasets, options) {
    const opts = options || {};
    draw(canvasId, {
      type: "bar",
      data: { labels, datasets },
      options: {
        ...common,
        indexAxis: "y",
        interaction: { mode: "nearest", intersect: true },
        plugins: { ...common.plugins, title: { display: !!opts.title, text: opts.title } },
        scales: {
          x: {
            beginAtZero: true,
            stacked: !!opts.stacked,
            min: Number.isFinite(opts.min) ? opts.min : undefined,
            max: Number.isFinite(opts.max) ? opts.max : undefined,
            title: { display: !!opts.xTitle, text: opts.xTitle || "" },
          },
          y: { stacked: !!opts.stacked, grid: { display: false }, ticks: { autoSkip: false } },
        },
      },
    });
  }

  function stackedHorizontalPercentBar(canvasId, labels, datasets, options) {
    const opts = options || {};
    const separatorLinesPlugin = {
      id: "separatorLines",
      afterDatasetsDraw(chart) {
        const indexes = opts.separatorIndexes || [];
        if (!indexes.length || !chart.scales.y) return;
        const { ctx, chartArea, scales } = chart;
        ctx.save();
        ctx.strokeStyle = opts.separatorColor || "#cbd5e1";
        ctx.lineWidth = 1;
        indexes.forEach((index) => {
          const y = scales.y.getPixelForValue(index);
          ctx.beginPath();
          ctx.moveTo(chartArea.left, y);
          ctx.lineTo(chartArea.right, y);
          ctx.stroke();
        });
        ctx.restore();
      },
    };
    const groupedYLabelsPlugin = {
      id: "groupedYLabels",
      afterDraw(chart) {
        const labels = opts.groupedYLabels || [];
        if (!labels.length || !chart.scales.y) return;
        const { ctx, chartArea, scales } = chart;
        ctx.save();
        ctx.textAlign = "left";
        ctx.textBaseline = "middle";
        ctx.fillStyle = opts.groupedYLabelColor || "#334155";
        ctx.font = opts.groupedYLabelFont || "600 11px sans-serif";
        labels.forEach((label, groupIndex) => {
          const firstIndex = groupIndex * 3;
          const secondIndex = firstIndex + 1;
          const y = (scales.y.getPixelForValue(firstIndex) + scales.y.getPixelForValue(secondIndex)) / 2 + (opts.groupedYLabelOffsetY || 0);
          ctx.fillText(label, chartArea.left - (opts.groupedYLabelLeft || 150), y, opts.groupedYLabelMaxWidth || 140);
        });
        ctx.restore();
      },
    };
    draw(canvasId, {
      type: "bar",
      data: { labels, datasets },
      plugins: [separatorLinesPlugin, groupedYLabelsPlugin],
      options: {
        ...common,
        layout: opts.layout || undefined,
        indexAxis: "y",
        interaction: { mode: "nearest", intersect: true },
        plugins: {
          ...common.plugins,
          legend: {
            position: opts.legendPosition || "bottom",
            labels: {
              usePointStyle: true,
              boxWidth: 10,
              generateLabels() {
                if (Array.isArray(opts.legendItems)) {
                  return opts.legendItems.map((item) => ({
                    text: item.label,
                    fillStyle: item.color,
                    strokeStyle: item.color,
                    pointStyle: "rect",
                    hidden: false,
                  }));
                }
                return Chart.defaults.plugins.legend.labels.generateLabels.apply(this, arguments);
              },
            },
            onClick() {},
          },
          title: { display: !!opts.title, text: opts.title || "" },
          tooltip: {
            callbacks: {
              label(context) {
                if (typeof opts.tooltipLabel === "function") return opts.tooltipLabel(context);
                const dataset = context.dataset || {};
                const meta = Array.isArray(dataset.meta) ? dataset.meta[context.dataIndex] : null;
                const value = Number(context.parsed && context.parsed.x);
                const percent = Number.isFinite(value) ? value.toFixed(1) : "-";
                const count = meta && Number.isFinite(meta.count) ? meta.count : "-";
                const total = meta && Number.isFinite(meta.total) ? meta.total : "-";
                return `${dataset.label || ""}: ${percent}% (${count}/${total})`;
              },
            },
          },
        },
        scales: {
          x: {
            beginAtZero: true,
            stacked: true,
            min: 0,
            max: 100,
            title: { display: !!opts.xTitle, text: opts.xTitle || "" },
            ticks: {
              callback(value) { return `${value}%`; },
            },
          },
          y: {
            stacked: true,
            grid: { display: false },
            ticks: {
              autoSkip: false,
              callback(value) {
                const index = Number(value);
                return Array.isArray(opts.yTickLabels) ? opts.yTickLabels[index] : this.getLabelForValue(value);
              },
            },
          },
        },
      },
    });
  }

  function scatter(canvasId, points, options) {
    const opts = options || {};
    const colors = opts.colors || {};
    const groupLabels = opts.groupLabels || { experimental: "実験群", control: "統制群" };
    draw(canvasId, {
      type: "scatter",
      data: {
        datasets: [
          {
            label: groupLabels.experimental || "実験群",
            borderColor: colors.experimental || "#0f8b8d",
            backgroundColor: colors.experimental || "#0f8b8d",
            data: (points || []).filter((point) => point.group === "experimental"),
          },
          {
            label: groupLabels.control || "統制群",
            borderColor: colors.control || "#ea7a12",
            backgroundColor: colors.control || "#ea7a12",
            data: (points || []).filter((point) => point.group === "control"),
          },
        ],
      },
      options: {
        ...common,
        plugins: {
          ...common.plugins,
          title: { display: !!opts.title, text: opts.title || "" },
          tooltip: {
            callbacks: {
              label(context) {
                const point = context.raw || {};
                return [
                  `参加者ID: ${point.participantId || "-"}`,
                  `群: ${groupLabels[point.group] || point.group || "-"}`,
                  `${opts.xTitle || "x"}: ${Number.isFinite(point.x) ? point.x.toFixed(2) : "-"}`,
                  `${opts.yTitle || "y"}: ${Number.isFinite(point.y) ? point.y.toFixed(2) : "-"}`,
                ];
              },
            },
          },
        },
        scales: {
          x: {
            min: Number.isFinite(opts.xMin) ? opts.xMin : undefined,
            max: Number.isFinite(opts.xMax) ? opts.xMax : undefined,
            title: { display: !!opts.xTitle, text: opts.xTitle || "" },
          },
          y: {
            min: Number.isFinite(opts.yMin) ? opts.yMin : undefined,
            max: Number.isFinite(opts.yMax) ? opts.yMax : undefined,
            title: { display: !!opts.yTitle, text: opts.yTitle || "" },
          },
        },
      },
    });
  }

  function jitter(key) {
    const text = String(key || "");
    let hash = 0;
    for (let index = 0; index < text.length; index += 1) hash = ((hash << 5) - hash + text.charCodeAt(index)) | 0;
    return ((Math.abs(hash) % 1001) / 1000 - 0.5) * 0.28;
  }

  function boxplotPlugin(groups, orientation) {
    return {
      id: "boxplotOverlay",
      beforeDatasetsDraw(chart) {
        const { ctx, scales } = chart;
        if (!scales.x || !scales.y) return;
        ctx.save();
        groups.forEach((group, index) => {
          const summary = group.summary || {};
          if (!summary.n || !Number.isFinite(summary.q1) || !Number.isFinite(summary.q3)) return;
          const position = Number.isFinite(group.position) ? group.position : index;
          const categoryScale = orientation === "horizontal" ? scales.y : scales.x;
          const valueScale = orientation === "horizontal" ? scales.x : scales.y;
          const categoryPixel = categoryScale.getPixelForValue(position);
          const q1Pixel = valueScale.getPixelForValue(summary.q1);
          const q3Pixel = valueScale.getPixelForValue(summary.q3);
          const medianPixel = valueScale.getPixelForValue(summary.median);
          const minPixel = valueScale.getPixelForValue(summary.min);
          const maxPixel = valueScale.getPixelForValue(summary.max);
          const spacing = Math.abs(categoryScale.getPixelForValue(1) - categoryScale.getPixelForValue(0));
          const halfSize = orientation === "horizontal" ? Math.min(11, spacing * 0.13) : Math.min(26, spacing * 0.28);

          ctx.strokeStyle = group.color;
          ctx.lineWidth = 2;
          ctx.beginPath();
          if (orientation === "horizontal") {
            ctx.moveTo(minPixel, categoryPixel);
            ctx.lineTo(maxPixel, categoryPixel);
            ctx.moveTo(minPixel, categoryPixel - halfSize * 0.55);
            ctx.lineTo(minPixel, categoryPixel + halfSize * 0.55);
            ctx.moveTo(maxPixel, categoryPixel - halfSize * 0.55);
            ctx.lineTo(maxPixel, categoryPixel + halfSize * 0.55);
          } else {
            ctx.moveTo(categoryPixel, minPixel);
            ctx.lineTo(categoryPixel, maxPixel);
            ctx.moveTo(categoryPixel - halfSize * 0.55, minPixel);
            ctx.lineTo(categoryPixel + halfSize * 0.55, minPixel);
            ctx.moveTo(categoryPixel - halfSize * 0.55, maxPixel);
            ctx.lineTo(categoryPixel + halfSize * 0.55, maxPixel);
          }
          ctx.stroke();

          ctx.globalAlpha = 0.18;
          ctx.fillStyle = group.color;
          if (orientation === "horizontal") {
            ctx.fillRect(q1Pixel, categoryPixel - halfSize, q3Pixel - q1Pixel, halfSize * 2);
          } else {
            ctx.fillRect(categoryPixel - halfSize, q3Pixel, halfSize * 2, q1Pixel - q3Pixel);
          }
          ctx.globalAlpha = 1;
          if (orientation === "horizontal") {
            ctx.strokeRect(q1Pixel, categoryPixel - halfSize, q3Pixel - q1Pixel, halfSize * 2);
          } else {
            ctx.strokeRect(categoryPixel - halfSize, q3Pixel, halfSize * 2, q1Pixel - q3Pixel);
          }
          ctx.lineWidth = 3;
          ctx.beginPath();
          if (orientation === "horizontal") {
            ctx.moveTo(medianPixel, categoryPixel - halfSize);
            ctx.lineTo(medianPixel, categoryPixel + halfSize);
          } else {
            ctx.moveTo(categoryPixel - halfSize, medianPixel);
            ctx.lineTo(categoryPixel + halfSize, medianPixel);
          }
          ctx.stroke();
        });
        ctx.restore();
      },
    };
  }

  function zeroLinePlugin(orientation) {
    return {
      id: "zeroReferenceLine",
      beforeDatasetsDraw(chart) {
        const { ctx, chartArea, scales } = chart;
        const valueScale = orientation === "horizontal" ? scales.x : scales.y;
        if (!valueScale || valueScale.min > 0 || valueScale.max < 0) return;
        const zero = valueScale.getPixelForValue(0);
        ctx.save();
        ctx.strokeStyle = "#64748b";
        ctx.lineWidth = 1.5;
        ctx.setLineDash([5, 4]);
        ctx.beginPath();
        if (orientation === "horizontal") {
          ctx.moveTo(zero, chartArea.top);
          ctx.lineTo(zero, chartArea.bottom);
        } else {
          ctx.moveTo(chartArea.left, zero);
          ctx.lineTo(chartArea.right, zero);
        }
        ctx.stroke();
        ctx.restore();
      },
    };
  }

  function questionLabelsPlugin(itemLabels) {
    function wrap(text, maxLength) {
      const value = String(text || "");
      const lines = [];
      for (let index = 0; index < value.length; index += maxLength) lines.push(value.slice(index, index + maxLength));
      return lines.length ? lines : [""];
    }

    return {
      id: "questionAxisLabels",
      afterDraw(chart) {
        const { ctx, chartArea, scales } = chart;
        if (!scales.y || !itemLabels.length) return;
        const left = 14;
        const maxTextX = chartArea.left - 54;
        ctx.save();
        ctx.textAlign = "left";
        ctx.fillStyle = "#334155";
        itemLabels.forEach((label, index) => {
          const parts = Array.isArray(label) ? label : [label];
          const fullLabel = parts[0] || "";
          const attributeLabel = parts[1] || "";
          const fullLines = wrap(fullLabel, 22);
          const lines = [...fullLines, ...(attributeLabel ? [attributeLabel] : [])];
          const lineHeight = 14;
          const centerY = scales.y.getPixelForValue(index);
          let y = centerY - (lines.length - 1) * lineHeight / 2;
          lines.forEach((line, lineIndex) => {
            const isQuestionText = lineIndex < fullLines.length;
            ctx.font = isQuestionText ? "600 12px sans-serif" : "11px sans-serif";
            ctx.fillStyle = isQuestionText ? "#334155" : "#64748b";
            ctx.fillText(line, left, y, Math.max(80, maxTextX - left));
            y += lineHeight;
          });
        });
        ctx.restore();
      },
    };
  }

  function boxplotWithPoints(canvasId, groups, options) {
    const opts = options || {};
    const orientation = opts.orientation === "horizontal" ? "horizontal" : "vertical";
    const canvas = document.getElementById(canvasId);
    if (canvas) canvas.style.minWidth = orientation === "vertical"
      ? `${Math.max(0, groups.length * (opts.widthPerGroup || 86))}px`
      : "0px";
    const datasets = groups.map((group, groupIndex) => ({
      type: "scatter",
      label: group.legendLabel || group.label,
      borderColor: group.color,
      backgroundColor: group.color,
      pointRadius: 4,
      pointHoverRadius: 7,
      data: (group.points || []).map((point) => ({
        x: orientation === "horizontal" ? point.value : (Number.isFinite(group.position) ? group.position : groupIndex) + jitter(`${point.participantId}:${groupIndex}`),
        y: orientation === "horizontal" ? (Number.isFinite(group.position) ? group.position : groupIndex) + jitter(`${point.participantId}:${groupIndex}`) * 0.45 : point.value,
        ...point,
      })),
    }));
    draw(canvasId, {
      type: "scatter",
      data: { datasets },
      plugins: [
        zeroLinePlugin(orientation),
        boxplotPlugin(groups, orientation),
        ...(orientation === "horizontal" ? [questionLabelsPlugin(opts.itemLabels || [])] : []),
      ],
      options: {
        ...common,
        layout: orientation === "horizontal" ? { padding: { left: opts.labelAreaWidth || 400 } } : undefined,
        interaction: { mode: "nearest", intersect: true },
        plugins: {
          ...common.plugins,
          legend: {
            display: opts.showLegend !== false,
            position: "bottom",
            labels: {
              usePointStyle: true,
              boxWidth: 10,
              generateLabels() {
                return (opts.legendItems || []).map((item) => ({
                  text: item.label,
                  fillStyle: item.color,
                  strokeStyle: item.color,
                  pointStyle: "circle",
                  hidden: false,
                }));
              },
            },
            onClick() {},
          },
          title: { display: !!opts.title, text: opts.title || "" },
          tooltip: {
            callbacks: {
              title(items) {
                const raw = items[0] && items[0].raw;
                if (!raw) return "変化量";
                return raw.metricLabel ? `質問項目: ${raw.metricLabel}` : "変化量";
              },
              label(context) {
                const point = context.raw || {};
                if (typeof opts.tooltipFormatter === "function") return opts.tooltipFormatter(point);
                if (point.valueKind === "postOnly") {
                  const lines = [
                    `参加者ID: ${point.participantId || "-"}`,
                    `群: ${point.roleLabel || "-"}`,
                    `回答: ${Number.isFinite(point.value) ? point.value.toFixed(2) : "-"}`,
                  ];
                  if (Number.isFinite(point.episodeCount)) lines.push(`エピソード閲覧数: ${point.episodeCount}`);
                  return lines;
                }
                const preLabel = point.valueKind === "score" ? "事前得点" : "事前回答";
                const postLabel = point.valueKind === "score" ? "事後得点" : "事後回答";
                const lines = [
                  `参加者ID: ${point.participantId || "-"}`,
                  `群: ${point.roleLabel || "-"}`,
                  `${preLabel}: ${Number.isFinite(point.pre) ? point.pre.toFixed(2) : "-"}`,
                  `${postLabel}: ${Number.isFinite(point.post) ? point.post.toFixed(2) : "-"}`,
                  `変化量: ${Number.isFinite(point.gain) ? point.gain.toFixed(2) : "-"}`,
                ];
                if (Number.isFinite(point.episodeCount)) lines.push(`エピソード閲覧数: ${point.episodeCount}`);
                return lines;
              },
            },
          },
        },
        scales: orientation === "horizontal" ? {
          x: {
            type: "linear",
            min: Number.isFinite(opts.min) ? opts.min : undefined,
            max: Number.isFinite(opts.max) ? opts.max : undefined,
            title: { display: true, text: opts.xTitle || "変化量（事後－事前）" },
          },
          y: {
            type: "linear",
            min: -0.5,
            max: Math.max(0.5, (opts.itemLabels || []).length - 0.5),
            reverse: true,
            grid: { display: false },
            title: { display: true, text: opts.yTitle || "質問項目" },
            ticks: {
              display: false,
              autoSkip: false,
              stepSize: 1,
              callback(value) {
                const numeric = Number(value);
                const index = Math.round(numeric);
                return Math.abs(numeric - index) < 0.001 ? (opts.itemLabels || [])[index] || "" : "";
              },
            },
          },
        } : {
          x: {
            type: "linear",
            min: -0.5,
            max: Math.max(0.5, groups.length - 0.5),
            grid: { display: false },
            title: { display: !!opts.xTitle, text: opts.xTitle || "" },
            ticks: {
              autoSkip: false,
              maxRotation: 0,
              stepSize: 1,
              callback(value) {
                const numeric = Number(value);
                const index = Math.round(numeric);
                const group = Math.abs(numeric - index) < 0.001 ? groups[index] : null;
                return group ? group.tickLabel || group.label : "";
              },
            },
          },
          y: {
            beginAtZero: false,
            min: Number.isFinite(opts.min) ? opts.min : undefined,
            max: Number.isFinite(opts.max) ? opts.max : undefined,
            title: { display: true, text: opts.yTitle || "変化量（事後－事前）" },
          },
        },
      },
    });
  }

  global.AdminCharts = { groupedBar, line, horizontalBar, stackedHorizontalPercentBar, scatter, boxplotWithPoints };
})(window);
