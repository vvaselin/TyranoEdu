"use strict";

const assert = require("node:assert/strict");
const stats = require("./stats.js");

function close(actual, expected, tolerance = 1e-9) {
  assert.ok(Math.abs(actual - expected) <= tolerance, `${actual} is not close to ${expected}`);
}

assert.deepEqual(stats.finite([1, "2", "", "  ", null, undefined, NaN, Infinity]), [1, 2]);
assert.equal(stats.mean([]), null);
assert.equal(stats.median([]), null);
assert.equal(stats.standardDeviation([1]), null);
assert.deepEqual(stats.quartiles([1, 2, 3, 4]), { q1: 1.75, median: 2.5, q3: 3.25, iqr: 1.5 });

const summary = stats.summarize([1, 2, 3, 4]);
assert.equal(summary.n, 4);
assert.equal(summary.mean, 2.5);
close(summary.sd, Math.sqrt(5 / 3));
assert.equal(summary.min, 1);
assert.equal(summary.max, 4);
close(stats.pearson([1, 2, 3], [2, 4, 6]), 1);
assert.equal(stats.pearson([1], [2]), null);

const separated = stats.mannWhitneyU([1, 2, 3], [4, 5, 6]);
assert.equal(separated.u, 0);
close(separated.pValue, 0.080855598, 1e-6);

const tied = stats.mannWhitneyU([1, 2, 2], [2, 3, 3]);
assert.equal(tied.u, 1);
assert.ok(tied.pValue > 0 && tied.pValue <= 1);

assert.deepEqual(stats.mannWhitneyU([], [1]), { u: null, uA: null, uB: null, pValue: null });
assert.deepEqual(stats.cliffsDelta([1, 2], []), { delta: null, label: null });
assert.deepEqual(stats.cliffsDelta([3, 4], [1, 2]), { delta: 1, label: "large" });
assert.equal(stats.hedgesG([1], [2, 3]), null);
assert.equal(stats.hedgesG([2, 2], [2, 2]), null);

const comparison = stats.compareGroups([1, 2, 3], [4, 5, 6]);
assert.equal(comparison.meanDiff, -3);
assert.equal(comparison.medianDiff, -3);
assert.equal(comparison.mannWhitneyU, 0);
assert.equal(comparison.cliffsDelta, -1);
assert.equal(comparison.cliffsDeltaLabel, "large");
assert.ok(comparison.hedgesG < 0);

const emptyComparison = stats.compareGroups([], [1, 2]);
assert.equal(emptyComparison.meanDiff, null);
assert.equal(emptyComparison.medianDiff, null);
assert.equal(emptyComparison.pValue, null);
assert.equal(emptyComparison.hedgesG, null);

const constantComparison = stats.compareGroups([5, 5, 5], [5, 5, 5]);
assert.equal(constantComparison.groupA_summary.sd, 0);
assert.equal(constantComparison.mannWhitneyU, 4.5);
assert.equal(constantComparison.pValue, 1);
assert.equal(constantComparison.cliffsDelta, 0);
assert.equal(constantComparison.cliffsDeltaLabel, "negligible");
assert.equal(constantComparison.hedgesG, null);
assert.equal(constantComparison.hedgesGReason, "両群の分散が0のため算出不可");

const unequalConstantSizes = stats.compareGroups([5, 5], [5, 5, 5]);
assert.equal(unequalConstantSizes.mannWhitneyU, 3);
assert.equal(unequalConstantSizes.pValue, 1);
assert.equal(unequalConstantSizes.cliffsDelta, 0);

const identicalDistributions = stats.compareGroups([1, 2, 3], [1, 2, 3]);
assert.equal(identicalDistributions.mannWhitneyU, 4.5);
assert.equal(identicalDistributions.pValue, 1);
assert.equal(identicalDistributions.cliffsDelta, 0);
assert.equal(stats.mannWhitneyU([1], [2]).pValue, null);

const zeroMeanDifference = stats.compareGroups([-1, 0, 1], [1, 0, -1]);
assert.equal(zeroMeanDifference.meanDiff, 0);
assert.equal(zeroMeanDifference.hedgesG, 0);

console.log("stats tests passed");
