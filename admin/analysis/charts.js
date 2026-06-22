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
    draw(canvasId, {
      type: "line",
      data: { labels, datasets: datasets.map((ds) => ({ tension: 0.15, pointRadius: 4, pointHoverRadius: 6, ...ds })) },
      options: {
        ...common,
        plugins: { ...common.plugins, title: { display: !!opts.title, text: opts.title } },
        scales: {
          x: { grid: { display: false } },
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

  global.AdminCharts = { groupedBar, line, horizontalBar };
})(window);
