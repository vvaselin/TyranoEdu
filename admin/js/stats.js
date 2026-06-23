(function(root, factory) {
  const stats = factory();
  if (typeof module === "object" && module.exports) module.exports = stats;
  if (root) root.AdminStats = stats;
})(typeof globalThis !== "undefined" ? globalThis : this, function() {
  "use strict";

  function finite(values) {
    if (!Array.isArray(values)) return [];
    return values.reduce((result, value) => {
      if (value == null || (typeof value === "string" && value.trim() === "")) return result;
      const numeric = Number(value);
      if (Number.isFinite(numeric)) result.push(numeric);
      return result;
    }, []);
  }

  function mean(values) {
    const xs = finite(values);
    return xs.length ? xs.reduce((sum, value) => sum + value, 0) / xs.length : null;
  }

  function quantile(sortedValues, probability) {
    if (!sortedValues.length) return null;
    const position = (sortedValues.length - 1) * probability;
    const lower = Math.floor(position);
    const fraction = position - lower;
    if (!fraction) return sortedValues[lower];
    return sortedValues[lower] + (sortedValues[lower + 1] - sortedValues[lower]) * fraction;
  }

  function median(values) {
    return quantile(finite(values).sort((a, b) => a - b), 0.5);
  }

  function standardDeviation(values) {
    const xs = finite(values);
    if (xs.length < 2) return null;
    const average = mean(xs);
    return Math.sqrt(xs.reduce((sum, value) => sum + Math.pow(value - average, 2), 0) / (xs.length - 1));
  }

  function pearson(xs, ys) {
    if (!Array.isArray(xs) || !Array.isArray(ys)) return null;
    const pairs = xs.map((x, index) => [x, ys[index]])
      .filter(([x, y]) => finite([x]).length && finite([y]).length)
      .map(([x, y]) => [Number(x), Number(y)]);
    if (pairs.length < 2) return null;
    const meanX = mean(pairs.map(([x]) => x));
    const meanY = mean(pairs.map(([, y]) => y));
    const numerator = pairs.reduce((sum, [x, y]) => sum + (x - meanX) * (y - meanY), 0);
    const denominatorX = Math.sqrt(pairs.reduce((sum, [x]) => sum + Math.pow(x - meanX, 2), 0));
    const denominatorY = Math.sqrt(pairs.reduce((sum, [, y]) => sum + Math.pow(y - meanY, 2), 0));
    return denominatorX && denominatorY ? numerator / (denominatorX * denominatorY) : null;
  }

  function ranks(values) {
    const xs = finite(values);
    const indexed = xs.map((value, index) => ({ value, index })).sort((a, b) => a.value - b.value);
    const out = Array(xs.length).fill(null);
    for (let start = 0; start < indexed.length;) {
      let end = start + 1;
      while (end < indexed.length && indexed[end].value === indexed[start].value) end += 1;
      const rank = (start + 1 + end) / 2;
      for (let index = start; index < end; index += 1) out[indexed[index].index] = rank;
      start = end;
    }
    return out;
  }

  function pairedFinite(xs, ys) {
    if (!Array.isArray(xs) || !Array.isArray(ys)) return [];
    return xs.map((x, index) => [x, ys[index]])
      .filter(([x, y]) => finite([x]).length && finite([y]).length)
      .map(([x, y]) => [Number(x), Number(y)]);
  }

  function spearman(xs, ys) {
    const pairs = pairedFinite(xs, ys);
    if (pairs.length < 2) return null;
    return pearson(ranks(pairs.map(([x]) => x)), ranks(pairs.map(([, y]) => y)));
  }

  function quartiles(values) {
    const xs = finite(values).sort((a, b) => a - b);
    if (!xs.length) return { q1: null, median: null, q3: null, iqr: null };
    const q1 = quantile(xs, 0.25);
    const middle = quantile(xs, 0.5);
    const q3 = quantile(xs, 0.75);
    return { q1, median: middle, q3, iqr: q3 - q1 };
  }

  function min(values) {
    const xs = finite(values);
    return xs.length ? Math.min(...xs) : null;
  }

  function max(values) {
    const xs = finite(values);
    return xs.length ? Math.max(...xs) : null;
  }

  function summarize(values) {
    const xs = finite(values);
    const qs = quartiles(xs);
    return {
      n: xs.length,
      mean: mean(xs),
      sd: standardDeviation(xs),
      median: qs.median,
      q1: qs.q1,
      q3: qs.q3,
      iqr: qs.iqr,
      min: min(xs),
      max: max(xs),
    };
  }

  function normalCdf(value) {
    const sign = value < 0 ? -1 : 1;
    const x = Math.abs(value) / Math.sqrt(2);
    const t = 1 / (1 + 0.3275911 * x);
    const erf = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * Math.exp(-x * x);
    return 0.5 * (1 + sign * erf);
  }

  function correlationPValueApprox(r, n) {
    if (!Number.isFinite(r) || n < 4) return null;
    if (Math.abs(r) >= 1) return 0;
    const z = 0.5 * Math.log((1 + r) / (1 - r)) * Math.sqrt(n - 3);
    return Math.max(0, Math.min(1, 2 * (1 - normalCdf(Math.abs(z)))));
  }

  function mannWhitneyU(groupA, groupB) {
    const a = finite(groupA);
    const b = finite(groupB);
    if (!a.length || !b.length) return { u: null, uA: null, uB: null, pValue: null };

    const ranked = [
      ...a.map((value) => ({ value, group: "a" })),
      ...b.map((value) => ({ value, group: "b" })),
    ].sort((left, right) => left.value - right.value);
    let rankSumA = 0;
    let tieCorrection = 0;
    for (let start = 0; start < ranked.length;) {
      let end = start + 1;
      while (end < ranked.length && ranked[end].value === ranked[start].value) end += 1;
      const averageRank = (start + 1 + end) / 2;
      for (let index = start; index < end; index += 1) {
        if (ranked[index].group === "a") rankSumA += averageRank;
      }
      const tieSize = end - start;
      tieCorrection += tieSize * tieSize * tieSize - tieSize;
      start = end;
    }

    const uA = rankSumA - a.length * (a.length + 1) / 2;
    const uB = a.length * b.length - uA;
    const u = Math.min(uA, uB);
    const expectedU = a.length * b.length / 2;
    if (Math.abs(u - expectedU) < Number.EPSILON * Math.max(1, expectedU)) {
      return { u: expectedU, uA: expectedU, uB: expectedU, pValue: 1 };
    }
    if (a.length < 2 || b.length < 2) return { u, uA, uB, pValue: null };
    const total = a.length + b.length;
    const variance = a.length * b.length / 12
      * ((total + 1) - tieCorrection / (total * (total - 1)));
    if (!(variance > 0)) return { u, uA, uB, pValue: null };
    const distance = Math.max(0, Math.abs(u - expectedU) - 0.5);
    const z = distance / Math.sqrt(variance);
    const pValue = Math.max(0, Math.min(1, 2 * (1 - normalCdf(z))));
    return { u, uA, uB, pValue };
  }

  function cliffsDelta(groupA, groupB) {
    const a = finite(groupA);
    const b = finite(groupB);
    if (!a.length || !b.length) return { delta: null, label: null };
    let dominance = 0;
    a.forEach((left) => b.forEach((right) => {
      if (left > right) dominance += 1;
      else if (left < right) dominance -= 1;
    }));
    const delta = dominance / (a.length * b.length);
    const magnitude = Math.abs(delta);
    const label = magnitude < 0.147 ? "negligible"
      : magnitude < 0.33 ? "small"
        : magnitude < 0.474 ? "medium" : "large";
    return { delta, label };
  }

  function hedgesG(groupA, groupB) {
    const a = finite(groupA);
    const b = finite(groupB);
    if (a.length < 2 || b.length < 2) return null;
    const degreesOfFreedom = a.length + b.length - 2;
    const varianceA = Math.pow(standardDeviation(a), 2);
    const varianceB = Math.pow(standardDeviation(b), 2);
    const pooledSd = Math.sqrt(((a.length - 1) * varianceA + (b.length - 1) * varianceB) / degreesOfFreedom);
    if (!(pooledSd > 0)) return null;
    const correction = 1 - 3 / (4 * degreesOfFreedom - 1);
    return correction * (mean(a) - mean(b)) / pooledSd;
  }

  function compareGroups(groupA, groupB) {
    const groupA_summary = summarize(groupA);
    const groupB_summary = summarize(groupB);
    const mannWhitney = mannWhitneyU(groupA, groupB);
    const cliff = cliffsDelta(groupA, groupB);
    const comparable = groupA_summary.n > 0 && groupB_summary.n > 0;
    const hedgesGValue = hedgesG(groupA, groupB);
    const hedgesGReason = hedgesGValue != null ? null
      : groupA_summary.n < 2 || groupB_summary.n < 2
        ? "各群2名未満のため算出不可"
        : groupA_summary.sd === 0 && groupB_summary.sd === 0
          ? "両群の分散が0のため算出不可"
          : "算出不可";
    return {
      groupA_summary,
      groupB_summary,
      meanDiff: comparable ? groupA_summary.mean - groupB_summary.mean : null,
      medianDiff: comparable ? groupA_summary.median - groupB_summary.median : null,
      mannWhitneyU: mannWhitney.u,
      pValue: mannWhitney.pValue,
      cliffsDelta: cliff.delta,
      cliffsDeltaLabel: cliff.label,
      hedgesG: hedgesGValue,
      hedgesGReason,
    };
  }

  function fmt(value, digits) {
    return typeof value === "number" && Number.isFinite(value)
      ? value.toFixed(digits == null ? 2 : digits)
      : "-";
  }

  return {
    finite,
    mean,
    median,
    standardDeviation,
    stddev: standardDeviation,
    pearson,
    spearman,
    correlationPValueApprox,
    quartiles,
    min,
    max,
    summarize,
    mannWhitneyU,
    cliffsDelta,
    hedgesG,
    compareGroups,
    fmt,
  };
});
