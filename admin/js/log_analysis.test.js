"use strict";

const assert = require("node:assert/strict");
global.AdminStats = require("./stats.js");
const logAnalysis = require("./log_analysis.js");

function close(actual, expected, tolerance = 1e-9) {
  assert.ok(Math.abs(actual - expected) <= tolerance, `${actual} is not close to ${expected}`);
}

function event(id, createdAt, participantId, eventType, eventData, taskId = "task3", sessionId = "s1", role = "experimental") {
  return {
    id,
    created_at: createdAt,
    participant_id: participantId,
    role,
    session_id: sessionId,
    task_id: taskId,
    event_type: eventType,
    event_data: eventData || {},
  };
}

const rawEvents = [
  event("1", "2026-01-01T00:00:00.000Z", "P1", "session_start", { love_level: 10 }, "", "s1"),
  event("2", "2026-01-01T00:00:10.000Z", "P1", "screen_transition", { screen: "editor", action: "enter" }, "task3"),
  event("3", "2026-01-01T00:00:20.000Z", "P1", "chat_user_payload", { request_id: "chat-1", source: "user_chat", payload: { message: "help" } }),
  event("4", "2026-01-01T00:00:21.000Z", "P1", "chat_ai_response", { request_id: "chat-1", source: "user_chat", text: "ok", love_up: 2 }),
  event("5", "2026-01-01T00:00:22.000Z", "P1", "love_change", { request_id: "chat-1", source: "ai_response", delta: 2, before: 10, after: 12 }),
  event("6", "2026-01-01T00:00:30.000Z", "P1", "execute_start", { code: "bad" }),
  event("7", "2026-01-01T00:00:31.000Z", "P1", "execute_result", { is_error: true, error_message: "compile error" }),
  event("8", "2026-01-01T00:00:32.000Z", "P1", "chat_user_payload", { request_id: "fb-1", source: "system_trigger", system_message: "実行フィードバック" }),
  event("9", "2026-01-01T00:00:33.000Z", "P1", "chat_ai_response", { request_id: "fb-1", source: "system_trigger", text: "fix it" }),
  event("10", "2026-01-01T00:00:40.000Z", "P1", "execute_start", { code: "better" }),
  event("11", "2026-01-01T00:00:41.000Z", "P1", "execute_result", { is_error: false, result: "ok" }),
  event("12", "2026-01-01T00:00:50.000Z", "P1", "grade_start", { code: "better" }),
  event("13", "2026-01-01T00:00:51.000Z", "P1", "grade_result", { score: 60, reason: "low" }),
  event("14", "2026-01-01T00:01:00.000Z", "P1", "grade_start", { code: "clear" }),
  event("15", "2026-01-01T00:01:01.000Z", "P1", "grade_result", { score: 85, bonus_love: 5, is_new_record: true }),
  event("16", "2026-01-01T00:01:02.000Z", "P1", "love_change", { source: "high_score_bonus", delta: 5, before: 12, after: 17 }),
  event("17", "2026-01-01T00:01:10.000Z", "P1", "screen_transition", { screen: "editor", action: "exit" }),
  event("18", "2026-01-01T00:02:00.000Z", "P1", "lecture_view", { lecture_num: 1 }, "", "s1"),
];

const profiles = [{ id: "u1", participant_id: "P1", role: "experimental", love_level: 17 }];
const tasks = { task3: { difficulty: 3, category: "basic" } };
const metadata = { excluded_participants: "", included_episode_min: 3, n: 1, generated_at: "2026-01-01T00:03:00.000Z" };
const analysisEvents = logAnalysis.buildAnalysisEvents(rawEvents);

assert.equal(analysisEvents.filter((item) => item.kind === "chat").length, 1);
assert.equal(analysisEvents.filter((item) => item.kind === "execute").length, 2);
assert.equal(analysisEvents.find((item) => item.kind === "execute" && item.data.result && item.data.result.is_error).data.feedback.ai.text, "fix it");

const behavior = logAnalysis.buildParticipantBehaviorSummary(profiles, analysisEvents, rawEvents, tasks, metadata)[0];
assert.equal(behavior.participant_id, "P1");
assert.equal(behavior.attempted_task_count, 1);
assert.equal(behavior.cleared_task_count, 1);
assert.equal(behavior.optional_task_count, 1);
assert.equal(behavior.error_count, 1);
assert.equal(behavior.retry_after_error_count, 1);
assert.equal(behavior.retry_after_low_score_count, 1);
assert.equal(behavior.feedback_to_retry_count, 1);
assert.equal(behavior.love_gain_from_ai, 2);
assert.equal(behavior.love_gain_from_score_bonus, 5);
assert.equal(behavior.max_score_reference, 85);
assert.ok(!Object.prototype.hasOwnProperty.call(behavior, "max_score"));

const task = logAnalysis.buildTaskAttemptSummary(profiles, analysisEvents, tasks, metadata)[0];
assert.equal(task.task_id, "task3");
assert.equal(task.cleared, true);
assert.equal(task.attempts_until_clear, 2);
assert.equal(task.grades_until_clear, 2);
assert.equal(task.retried_after_error, true);
assert.equal(task.retried_after_low_score, true);
assert.equal(task.is_optional_task, true);

const loveRows = logAnalysis.buildLoveTransitionBehaviorSummary(profiles, analysisEvents, metadata);
assert.equal(loveRows.length, 2);
assert.equal(loveRows[0].love_source, "ai_response");
assert.equal(loveRows[0].next_action_within_3min, true);
assert.equal(loveRows[0].next_execute_done, true);
assert.equal(loveRows[1].next_action_type, "leave_task");

const correlations = logAnalysis.buildCorrelationStats([{ chat_user_count: 2, agentIntimacy: 4 }, { chat_user_count: 4, agentIntimacy: 5 }], [
  { log_key: "chat_user_count", survey_key: "agentIntimacy", label: "test" },
], metadata);
assert.equal(correlations[0].n, 2);
close(correlations[0].pearson_r, 1);
close(correlations[0].spearman_rho, 1);

const progressOnlyProfiles = [
  { id: "u2", participant_id: "P2", role: "control", love_level: 0 },
];
const progressOnlyRows = [
  { id: 1, user_id: "u2", task_id: "task1", high_score: 70, is_cleared: true, updated_at: "2026-01-01T00:00:00.000Z" },
  { id: 2, user_id: "u2", task_id: "task2", high_score: 85, is_cleared: false, updated_at: "2026-01-01T00:01:00.000Z" },
  { id: 3, user_id: "u2", task_id: "task3", high_score: 79, is_cleared: false, updated_at: "2026-01-01T00:02:00.000Z" },
  { id: 4, user_id: "u2", task_id: "task3", high_score: 60, is_cleared: false, updated_at: "2026-01-01T00:03:00.000Z" },
];
const progressOnlyBehavior = logAnalysis.buildParticipantBehaviorSummary(progressOnlyProfiles, [], [], tasks, metadata, progressOnlyRows)[0];
assert.equal(progressOnlyBehavior.progress_attempted_task_count, 3);
assert.equal(progressOnlyBehavior.progress_cleared_task_count, 2);
assert.equal(progressOnlyBehavior.log_attempted_task_count, 0);
assert.equal(progressOnlyBehavior.log_cleared_task_count, 0);
assert.equal(progressOnlyBehavior.attempted_task_count_final, 3);
assert.equal(progressOnlyBehavior.cleared_task_count_final, 2);
assert.equal(progressOnlyBehavior.attempted_task_count, 3);
assert.equal(progressOnlyBehavior.cleared_task_count, 2);
assert.equal(progressOnlyBehavior.high_score_reference, 85);

const duplicateProgressRows = [
  { id: 10, user_id: "u2", task_id: "task4", high_score: 75, is_cleared: false, updated_at: "2026-01-01T00:01:00.000Z" },
  { id: 11, user_id: "u2", task_id: "task4", high_score: 90, is_cleared: false, updated_at: "2026-01-01T00:00:00.000Z" },
];
const duplicateBehavior = logAnalysis.buildParticipantBehaviorSummary(progressOnlyProfiles, [], [], tasks, metadata, duplicateProgressRows)[0];
assert.equal(duplicateBehavior.progress_attempted_task_count, 1);
assert.equal(duplicateBehavior.progress_cleared_task_count, 1);
assert.equal(duplicateBehavior.high_score_reference, 90);

const mixedEvents = logAnalysis.buildAnalysisEvents([
  event("m1", "2026-01-01T00:00:00.000Z", "P2", "execute_start", {}, "task1", "s2", "control"),
  event("m2", "2026-01-01T00:00:01.000Z", "P2", "execute_result", { result: "ok" }, "task1", "s2", "control"),
]);
const mixedBehavior = logAnalysis.buildParticipantBehaviorSummary(progressOnlyProfiles, mixedEvents, [], tasks, metadata, [
  { id: 20, user_id: "u2", task_id: "task1", high_score: 90, is_cleared: true, updated_at: "2026-01-01T00:00:00.000Z" },
])[0];
assert.equal(mixedBehavior.log_attempted_task_count, 1);
assert.equal(mixedBehavior.progress_attempted_task_count, 1);
assert.equal(mixedBehavior.attempted_task_count_final, 1);

const taskProgressSummary = logAnalysis.buildTaskAttemptSummary(progressOnlyProfiles, [], tasks, metadata, progressOnlyRows);
const progressClear = taskProgressSummary.find((row) => row.task_id === "task2");
assert.equal(progressClear.task_progress_high_score, 85);
assert.equal(progressClear.task_progress_is_cleared, false);
assert.equal(progressClear.cleared_by_progress, false);
assert.equal(progressClear.cleared_by_log, false);
assert.equal(progressClear.cleared_final, true);
assert.equal(progressClear.clear_status_source, "high_score_80");

console.log("log analysis tests passed");
