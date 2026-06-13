(function(global) {
  const charts = {};

  function canDraw(canvasId) {
    const canvas = document.getElementById(canvasId);
    const fallback = document.getElementById(`${canvasId}-fallback`);
    if (!canvas) return false;
    if (!global.Chart) {
      canvas.style.display = "none";
      if (fallback) {
        fallback.style.display = "block";
        fallback.textContent = "Chart.jsを読み込めませんでした。表データは利用できます。";
      }
      return false;
    }
    if (fallback) fallback.style.display = "none";
    canvas.style.display = "block";
    return true;
  }

  function draw(canvasId, config) {
    if (!canDraw(canvasId)) return;
    if (charts[canvasId]) charts[canvasId].destroy();
    charts[canvasId] = new Chart(document.getElementById(canvasId), config);
  }

  function bar(canvasId, labels, datasets, title) {
    draw(canvasId, {
      type: "bar",
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: "bottom" }, title: { display: !!title, text: title } },
        scales: { y: { beginAtZero: true } },
      },
    });
  }

  function scatter(canvasId, datasets, xTitle, yTitle) {
    draw(canvasId, {
      type: "scatter",
      data: { datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: "bottom" } },
        scales: {
          x: { title: { display: true, text: xTitle || "" } },
          y: { title: { display: true, text: yTitle || "" } },
        },
      },
    });
  }

  global.AdminCharts = { bar, scatter };
})(window);
