(function(global) {
  function finite(values) {
    return values.map(Number).filter(Number.isFinite);
  }

  function mean(values) {
    const xs = finite(values);
    return xs.length ? xs.reduce((sum, value) => sum + value, 0) / xs.length : NaN;
  }

  function median(values) {
    const xs = finite(values).sort((a, b) => a - b);
    if (!xs.length) return NaN;
    const mid = Math.floor(xs.length / 2);
    return xs.length % 2 ? xs[mid] : (xs[mid - 1] + xs[mid]) / 2;
  }

  function stddev(values) {
    const xs = finite(values);
    if (xs.length < 2) return NaN;
    const avg = mean(xs);
    return Math.sqrt(xs.reduce((sum, value) => sum + Math.pow(value - avg, 2), 0) / (xs.length - 1));
  }

  function pearson(xs, ys) {
    const pairs = xs.map((x, index) => [Number(x), Number(ys[index])]).filter(([x, y]) => Number.isFinite(x) && Number.isFinite(y));
    if (pairs.length < 2) return NaN;
    const mx = mean(pairs.map(([x]) => x));
    const my = mean(pairs.map(([, y]) => y));
    const numerator = pairs.reduce((sum, [x, y]) => sum + (x - mx) * (y - my), 0);
    const dx = Math.sqrt(pairs.reduce((sum, [x]) => sum + Math.pow(x - mx, 2), 0));
    const dy = Math.sqrt(pairs.reduce((sum, [, y]) => sum + Math.pow(y - my, 2), 0));
    return dx && dy ? numerator / (dx * dy) : NaN;
  }

  function cohenD(aValues, bValues) {
    const a = finite(aValues);
    const b = finite(bValues);
    if (a.length < 2 || b.length < 2) return NaN;
    const varianceA = Math.pow(stddev(a), 2);
    const varianceB = Math.pow(stddev(b), 2);
    const pooled = Math.sqrt(((a.length - 1) * varianceA + (b.length - 1) * varianceB) / (a.length + b.length - 2));
    return pooled ? (mean(a) - mean(b)) / pooled : NaN;
  }

  function fmt(value, digits) {
    if (!Number.isFinite(value)) return "-";
    const scale = Math.pow(10, digits == null ? 2 : digits);
    return String(Math.round(value * scale) / scale);
  }

  global.AdminStats = { finite, mean, median, stddev, pearson, cohenD, fmt };
})(window);
