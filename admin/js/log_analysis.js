(function(root, factory) {
  const api = factory(root && root.AdminStats);
  if (typeof module === "object" && module.exports) module.exports = api;
  if (root) root.AdminLogAnalysis = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function(stats) {
  "use strict";

  const CLEAR_SCORE = 80;

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function asTime(value) {
    const t = new Date(value).getTime();
    return Number.isFinite(t) ? t : 0;
  }

  function isoOrNull(value) {
    if (!Number.isFinite(value) || value <= 0) return null;
    return new Date(value).toISOString();
  }

  function number(value) {
    if (value == null || value === "") return null;
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  function getData(event) {
    return event && event.event_data ? event.event_data : {};
  }

  function getRequestId(event) {
    const data = getData(event);
    return data.request_id || (data.payload && data.payload.request_id) || "";
  }

  function isSystemTriggerLog(event) {
    const data = getData(event);
    return data.source === "system_trigger" || data.is_system_trigger === true;
  }

  function classifySystemFeedback(data) {
    const text = String((data && (data.system_message || data.message)) || (data && data.payload && data.payload.message) || "");
    if (/採点|score|grade/i.test(text)) return "grade";
    if (/実行|execute|コード実行|コンパイル/i.test(text)) return "execute";
    return "";
  }

  function normalizeLoveValue(value) {
    const parsed = parseInt(value, 10);
    return Number.isFinite(parsed) ? clamp(parsed, 0, 100) : null;
  }

  function getEventLoveFromData(event) {
    const data = event && event.data ? event.data : getData(event);
    const raw = event && event.rawType ? { event_type: event.rawType } : event;
    if (raw && raw.event_type === "love_change" && data.after != null) return normalizeLoveValue(data.after);
    if (data.love_level != null) return normalizeLoveValue(data.love_level);
    if (data.payload && data.payload.love_level != null) return normalizeLoveValue(data.payload.love_level);
    return null;
  }

  function buildAnalysisEvents(rawEvents) {
    const raw = (rawEvents || []).slice().sort((a, b) => asTime(a.created_at) - asTime(b.created_at));
    const out = [];
    const chatByRequest = new Map();
    const systemFeedbackByRequest = new Map();
    const pendingExecute = new Map();
    const pendingGrade = new Map();
    const latestExecute = new Map();
    const latestGrade = new Map();
    const keyFor = (event) => `${event.session_id || ""}|${event.task_id || ""}`;
    const add = (item) => {
      out.push(item);
      return item;
    };
    const base = (event, kind, data) => ({
      id: `${kind}-${event.id || out.length}-${out.length}`,
      kind,
      rawType: event.event_type,
      created_at: event.created_at,
      time: asTime(event.created_at),
      task_id: event.task_id || "",
      session_id: event.session_id || "",
      participant_id: event.participant_id || "",
      role: event.role || "",
      data: data || {},
      raw: [event],
      love: 0,
    });
    const attachFeedbackToTarget = (feedback, target) => {
      if (!feedback || !target) return;
      if (!target.data.feedback) target.data.feedback = {};
      Object.assign(target.data.feedback, feedback);
      feedback.attached = true;
      feedback.raw.forEach((rawEvent) => {
        if (!target.raw.some((existing) => existing.id === rawEvent.id)) target.raw.push(rawEvent);
      });
    };
    const attachPendingFeedbackForTarget = (targetKind, key, target) => {
      systemFeedbackByRequest.forEach((feedback) => {
        if (feedback.attached) return;
        if (feedback.key !== key) return;
        if (feedback.targetKind && feedback.targetKind !== targetKind) return;
        attachFeedbackToTarget(feedback, target);
      });
    };
    const attachSystemFeedback = (event, data) => {
      const requestId = getRequestId(event) || `${event.session_id || ""}-${event.created_at}`;
      let feedback = systemFeedbackByRequest.get(requestId);
      if (!feedback) {
        feedback = { request_id: requestId, raw: [] };
        systemFeedbackByRequest.set(requestId, feedback);
      }
      feedback.key = keyFor(event);
      if (event.event_type === "chat_user_payload") {
        feedback.user = data;
        feedback.targetKind = classifySystemFeedback(data);
      } else {
        feedback.ai = data;
      }
      feedback.raw.push(event);

      const key = keyFor(event);
      let target = null;
      if (feedback.targetKind === "grade") target = latestGrade.get(key);
      else if (feedback.targetKind === "execute") target = latestExecute.get(key);
      else target = latestGrade.get(key) || latestExecute.get(key);
      attachFeedbackToTarget(feedback, target);
    };

    raw.forEach((event) => {
      const data = getData(event);
      if (event.event_type === "chat_user_payload" || event.event_type === "chat_ai_response") {
        if (isSystemTriggerLog(event) || systemFeedbackByRequest.has(getRequestId(event))) {
          attachSystemFeedback(event, data);
          return;
        }
        const requestId = getRequestId(event) || `${event.session_id || ""}-${event.created_at}`;
        let item = chatByRequest.get(requestId);
        if (!item) {
          item = add(base(event, "chat", { request_id: requestId }));
          chatByRequest.set(requestId, item);
        }
        if (event.event_type === "chat_user_payload") item.data.user = data;
        else item.data.ai = data;
        if (!item.raw.some((existing) => existing.id === event.id)) item.raw.push(event);
        item.created_at = item.raw.map((rawEvent) => rawEvent.created_at).sort()[0];
        item.time = asTime(item.created_at);
        return;
      }
      if (event.event_type === "task_intro_knowledge") {
        add(base(event, "intro", data));
        return;
      }
      if (event.event_type === "execute_start") {
        const item = base(event, "execute", { start: data });
        pendingExecute.set(keyFor(event), item);
        add(item);
        return;
      }
      if (event.event_type === "execute_result") {
        const key = keyFor(event);
        const item = pendingExecute.get(key) || add(base(event, "execute", {}));
        item.data.result = data;
        item.raw.push(event);
        pendingExecute.delete(key);
        latestExecute.set(key, item);
        attachPendingFeedbackForTarget("execute", key, item);
        return;
      }
      if (event.event_type === "grade_start") {
        const item = base(event, "grade", { start: data });
        pendingGrade.set(keyFor(event), item);
        add(item);
        return;
      }
      if (event.event_type === "grade_result") {
        const key = keyFor(event);
        const item = pendingGrade.get(key) || add(base(event, "grade", {}));
        item.data.result = data;
        item.raw.push(event);
        pendingGrade.delete(key);
        latestGrade.set(key, item);
        attachPendingFeedbackForTarget("grade", key, item);
        return;
      }
      if (event.event_type === "session_start") add(base(event, "session", data));
      else if (event.event_type === "lecture_view") add(base(event, "lecture", data));
      else if (event.event_type === "code_snapshot") add(base(event, "code", data));
      else if (event.event_type === "love_change") add(base(event, "love", data));
      else if (event.event_type === "screen_transition") add(base(event, "screen", data));
      else add(base(event, "other", data));
    });

    out.sort((a, b) => a.time - b.time);
    assignLoveValues(out);
    return out;
  }

  function assignLoveValues(events) {
    const sessionStart = events.find((event) => event.kind === "session" && Number.isFinite(getEventLoveFromData(event)));
    const firstLoggedLove = sessionStart
      ? getEventLoveFromData(sessionStart)
      : events.map(getEventLoveFromData).find((value) => Number.isFinite(value));
    let current = Number.isFinite(firstLoggedLove) ? firstLoggedLove : 0;

    events.forEach((item) => {
      if (item.kind === "session") {
        const sessionLove = getEventLoveFromData(item.raw[0]);
        if (Number.isFinite(sessionLove)) current = sessionLove;
      } else if (item.kind === "love" && item.data.after != null) {
        const next = normalizeLoveValue(item.data.after);
        if (Number.isFinite(next)) current = next;
      }
      item.love = clamp(current, 0, 100);
    });
  }

  function isUserChat(item) {
    return item.kind === "chat" && item.data && item.data.user && item.data.user.source !== "system_trigger";
  }

  function isExecuteError(item) {
    if (item.kind !== "execute") return false;
    const result = (item.data && item.data.result) || {};
    return result.is_error === true || result.error === true || !!result.error_message;
  }

  function gradeScore(item) {
    if (item.kind !== "grade") return null;
    return number(item.data && item.data.result && item.data.result.score);
  }

  function isLowScore(item) {
    const score = gradeScore(item);
    return Number.isFinite(score) && score < CLEAR_SCORE;
  }

  function isClearedGrade(item) {
    const score = gradeScore(item);
    return Number.isFinite(score) && score >= CLEAR_SCORE;
  }

  function hasFeedback(item) {
    return !!(item.data && item.data.feedback && (item.data.feedback.ai || item.data.feedback.user));
  }

  function isLeaveEvent(item) {
    return item.kind === "screen" && item.data && item.data.screen === "editor" && item.data.action === "exit";
  }

  function taskMeta(tasks, taskId) {
    return (tasks && tasks[taskId]) || {};
  }

  function isOptionalTask(tasks, taskId) {
    const task = taskMeta(tasks, taskId);
    if (typeof task.is_optional_task === "boolean") return task.is_optional_task;
    if (typeof task.optional === "boolean") return task.optional;
    const difficulty = number(task.difficulty);
    return Number.isFinite(difficulty) ? difficulty >= 3 : false;
  }

  function taskCategory(tasks, taskId) {
    return taskMeta(tasks, taskId).category || "";
  }

  function groupEventsByParticipant(events) {
    const map = new Map();
    (events || []).forEach((event) => {
      const participantId = event.participant_id || (event.raw && event.raw[0] && event.raw[0].participant_id) || "";
      if (!participantId) return;
      if (!map.has(participantId)) map.set(participantId, []);
      map.get(participantId).push(event);
    });
    map.forEach((items) => items.sort((a, b) => a.time - b.time));
    return map;
  }

  function groupRawEventsByParticipant(rawEvents) {
    const map = new Map();
    (rawEvents || []).forEach((event) => {
      const participantId = event.participant_id || "";
      if (!participantId) return;
      if (!map.has(participantId)) map.set(participantId, []);
      map.get(participantId).push(event);
    });
    return map;
  }

  function countRetryAfter(events, predicate) {
    let count = 0;
    events.forEach((event, index) => {
      if (!event.task_id || !predicate(event)) return;
      const next = events.slice(index + 1).find((candidate) =>
        candidate.task_id === event.task_id && (candidate.kind === "execute" || candidate.kind === "grade" || isLeaveEvent(candidate) || isUserChat(candidate))
      );
      if (next && (next.kind === "execute" || next.kind === "grade")) count += 1;
    });
    return count;
  }

  function feedbackNextActionCounts(events) {
    const counts = { retry: 0, chat: 0, leave: 0 };
    events.forEach((event, index) => {
      if (!hasFeedback(event)) return;
      const next = events.slice(index + 1).find((candidate) =>
        candidate.kind === "execute" || candidate.kind === "grade" || isUserChat(candidate) || isLeaveEvent(candidate)
      );
      if (!next) return;
      if ((next.kind === "execute" || next.kind === "grade") && (!event.task_id || next.task_id === event.task_id)) counts.retry += 1;
      else if (isUserChat(next)) counts.chat += 1;
      else if (isLeaveEvent(next)) counts.leave += 1;
    });
    return counts;
  }

  function buildParticipantBehaviorSummary(profiles, analysisEvents, rawEvents, tasks, metadata, taskProgressRows) {
    const eventsByParticipant = groupEventsByParticipant(analysisEvents);
    const rawByParticipant = groupRawEventsByParticipant(rawEvents);
    const progressByParticipant = normalizeTaskProgress(profiles, taskProgressRows);
    const meta = metadata || {};
    return (profiles || []).map((profile) => {
      const participantId = profile.participant_id || "";
      const events = eventsByParticipant.get(participantId) || [];
      const raw = rawByParticipant.get(participantId) || [];
      const progressRows = progressByParticipant.get(participantId) || new Map();
      const sessionIds = new Set(raw.map((event) => event.session_id).filter(Boolean));
      const sessions = new Map();
      raw.forEach((event) => {
        const key = event.session_id || `no-session:${event.id || event.created_at}`;
        const t = asTime(event.created_at);
        if (!Number.isFinite(t) || t <= 0) return;
        const current = sessions.get(key) || { min: t, max: t };
        current.min = Math.min(current.min, t);
        current.max = Math.max(current.max, t);
        sessions.set(key, current);
      });
      const totalDurationMin = Array.from(sessions.values()).reduce((sum, session) => sum + Math.max(0, session.max - session.min) / 60000, 0);
      const logAttemptedTasks = new Set(events.filter((event) => event.task_id && (event.kind === "execute" || event.kind === "grade" || event.kind === "code" || event.kind === "intro")).map((event) => event.task_id));
      const logClearedTasks = new Set(events.filter((event) => event.task_id && isClearedGrade(event)).map((event) => event.task_id));
      const progressAttemptedTasks = new Set(Array.from(progressRows.keys()));
      const progressClearedTasks = new Set(Array.from(progressRows.values()).filter(progressCleared).map((row) => row.task_id));
      const attemptedTasks = new Set([...logAttemptedTasks, ...progressAttemptedTasks]);
      const clearedTasks = new Set([...logClearedTasks, ...progressClearedTasks]);
      const optionalTasks = new Set(Array.from(attemptedTasks).filter((taskId) => isOptionalTask(tasks, taskId)));
      const executeCount = events.filter((event) => event.kind === "execute").length;
      const gradeCount = events.filter((event) => event.kind === "grade").length;
      const chatUserCount = events.filter(isUserChat).length;
      const chatAiCount = events.filter((event) => event.kind === "chat" && event.data && event.data.ai && (!event.data.user || event.data.user.source !== "system_trigger")).length;
      const codeSnapshotCount = events.filter((event) => event.kind === "code").length;
      const errorCount = events.filter(isExecuteError).length;
      const loveEvents = events.filter((event) => event.kind === "love");
      const loveGain = (source) => loveEvents
        .filter((event) => !source || event.data.source === source)
        .reduce((sum, event) => sum + Math.max(0, number(event.data.delta) || 0), 0);
      const feedbackCounts = feedbackNextActionCounts(events);
      const finalLove = loveEvents.length ? number(loveEvents[loveEvents.length - 1].data.after) : number(profile.love_level);
      const progressScores = Array.from(progressRows.values()).map((row) => row.high_score).filter(Number.isFinite);
      const latestProgressUpdatedAt = Array.from(progressRows.values()).map((row) => row.updated_at).filter(Boolean).sort().pop() || null;
      const progressMaxScore = progressScores.length ? Math.max(...progressScores) : null;
      const logMaxScore = maxScoreReference(events);
      const highScoreReference = Number.isFinite(progressMaxScore) ? progressMaxScore : logMaxScore;

      return {
        participant_id: participantId,
        group: profile.role || "",
        session_count: sessionIds.size || sessions.size,
        total_duration_min: totalDurationMin || null,
        progress_attempted_task_count: progressAttemptedTasks.size,
        progress_cleared_task_count: progressClearedTasks.size,
        log_attempted_task_count: logAttemptedTasks.size,
        log_cleared_task_count: logClearedTasks.size,
        attempted_task_count_final: attemptedTasks.size,
        cleared_task_count_final: clearedTasks.size,
        attempted_task_count: attemptedTasks.size,
        cleared_task_count: clearedTasks.size,
        clear_rate: attemptedTasks.size ? clearedTasks.size / attemptedTasks.size : null,
        optional_task_count: optionalTasks.size,
        execute_count: executeCount,
        grade_count: gradeCount,
        chat_user_count: chatUserCount,
        chat_ai_count: chatAiCount,
        code_snapshot_count: codeSnapshotCount,
        error_count: errorCount,
        error_rate: executeCount ? errorCount / executeCount : null,
        retry_after_error_count: countRetryAfter(events, isExecuteError),
        retry_after_low_score_count: countRetryAfter(events, isLowScore),
        feedback_to_retry_count: feedbackCounts.retry,
        feedback_to_chat_count: feedbackCounts.chat,
        feedback_to_leave_count: feedbackCounts.leave,
        love_change_count: loveEvents.length,
        love_total_gain: loveGain(),
        love_gain_from_ai: loveGain("ai_response"),
        love_gain_from_score_bonus: loveGain("high_score_bonus"),
        final_love: finalLove,
        high_score_reference: highScoreReference,
        task_progress_updated_at: latestProgressUpdatedAt,
        max_score_reference: highScoreReference,
        excluded_participants: meta.excluded_participants || "",
        included_episode_min: meta.included_episode_min == null ? "" : meta.included_episode_min,
        n: meta.n == null ? "" : meta.n,
        generated_at: meta.generated_at || "",
      };
    });
  }

  function maxScoreReference(events) {
    const scores = events.map(gradeScore).filter(Number.isFinite);
    return scores.length ? Math.max(...scores) : null;
  }

  function progressNumber(value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  function progressTime(value) {
    const t = asTime(value);
    return Number.isFinite(t) && t > 0 ? t : 0;
  }

  function normalizeTaskProgress(profiles, taskProgressRows) {
    const userToParticipant = new Map((profiles || []).map((profile) => [profile.id, profile.participant_id]));
    const mergedByKey = new Map();
    (taskProgressRows || []).forEach((row) => {
      const participantId = userToParticipant.get(row.user_id) || row.participant_id || "";
      const taskId = row.task_id || "";
      if (!participantId || !taskId) return;
      const key = `${participantId}|${taskId}`;
      const highScore = progressNumber(row.high_score);
      const current = mergedByKey.get(key) || {
        participant_id: participantId,
        user_id: row.user_id || "",
        task_id: taskId,
        high_score: null,
        is_cleared: null,
        updated_at: "",
      };

      if (Number.isFinite(highScore) && (!Number.isFinite(current.high_score) || highScore > current.high_score)) {
        current.high_score = highScore;
      }
      if (row.is_cleared === true) current.is_cleared = true;
      else if (current.is_cleared !== true && row.is_cleared === false) current.is_cleared = false;
      if (!current.updated_at || progressTime(row.updated_at) >= progressTime(current.updated_at)) {
        current.updated_at = row.updated_at || "";
        current.latest_id = row.id;
      }
      mergedByKey.set(key, current);
    });

    const byParticipant = new Map();
    mergedByKey.forEach((row) => {
      if (!byParticipant.has(row.participant_id)) byParticipant.set(row.participant_id, new Map());
      byParticipant.get(row.participant_id).set(row.task_id, row);
    });
    return byParticipant;
  }

  function progressCleared(row) {
    return !!(row && (row.is_cleared === true || (Number.isFinite(row.high_score) && row.high_score >= CLEAR_SCORE)));
  }

  function progressClearSource(row, clearedByLog) {
    if (row && row.is_cleared === true) return "task_progress";
    if (row && Number.isFinite(row.high_score) && row.high_score >= CLEAR_SCORE) return "high_score_80";
    if (clearedByLog) return "log";
    return "not_cleared";
  }

  function eventsForTask(events, taskId) {
    return events.filter((event) => event.task_id === taskId);
  }

  function firstTime(events, predicate) {
    const found = events.find(predicate);
    return found ? found.time : null;
  }

  function nextBeforeBoundary(events, startIndex, boundaryTime, predicate) {
    for (let index = startIndex + 1; index < events.length; index += 1) {
      const event = events[index];
      if (Number.isFinite(boundaryTime) && event.time > boundaryTime) return false;
      if (predicate(event)) return true;
    }
    return false;
  }

  function buildTaskAttemptSummary(profiles, analysisEvents, tasks, metadata, taskProgressRows) {
    const eventsByParticipant = groupEventsByParticipant(analysisEvents);
    const profileById = new Map((profiles || []).map((profile) => [profile.participant_id, profile]));
    const progressByParticipant = normalizeTaskProgress(profiles, taskProgressRows);
    const meta = metadata || {};
    const rows = [];
    const participantIds = Array.from(new Set([
      ...Array.from(eventsByParticipant.keys()),
      ...Array.from(progressByParticipant.keys()),
    ]));
    participantIds.forEach((participantId) => {
      const events = eventsByParticipant.get(participantId) || [];
      const progressRows = progressByParticipant.get(participantId) || new Map();
      const taskIds = Array.from(new Set([
        ...events.filter((event) => event.task_id && event.task_id !== "sandbox").map((event) => event.task_id),
        ...Array.from(progressRows.keys()),
      ])).sort();
      taskIds.forEach((taskId) => {
        const taskEvents = eventsForTask(events, taskId);
        const progressRow = progressRows.get(taskId) || null;
        const clearEvent = taskEvents.find(isClearedGrade);
        const clearTime = clearEvent ? clearEvent.time : null;
        const leaveTime = firstTime(taskEvents, isLeaveEvent);
        const boundary = Number.isFinite(clearTime) ? clearTime : leaveTime;
        const firstGrade = taskEvents.find((event) => event.kind === "grade");
        const executeEvents = taskEvents.filter((event) => event.kind === "execute");
        const gradeEvents = taskEvents.filter((event) => event.kind === "grade");
        const taskStarted = firstTime(taskEvents, (event) => event.kind === "intro" || (event.kind === "screen" && event.data.screen === "editor" && event.data.action === "enter"))
          || firstTime(taskEvents, (event) => event.kind === "execute" || event.kind === "grade" || isUserChat(event));
        const errorIndexes = taskEvents.map((event, index) => isExecuteError(event) ? index : -1).filter((index) => index >= 0);
        const lowScoreIndexes = taskEvents.map((event, index) => isLowScore(event) ? index : -1).filter((index) => index >= 0);
        const usedChatBeforeClear = taskEvents.some((event) => isUserChat(event) && (!Number.isFinite(clearTime) || event.time < clearTime));
        const clearedByLog = !!clearEvent;
        const clearedByProgress = !!(progressRow && progressRow.is_cleared === true);
        const clearedFinal = clearedByProgress || clearedByLog || !!(progressRow && Number.isFinite(progressRow.high_score) && progressRow.high_score >= CLEAR_SCORE);
        const highScoreReference = Number.isFinite(progressRow && progressRow.high_score) ? progressRow.high_score : maxScoreReference(taskEvents);

        rows.push({
          participant_id: participantId,
          group: (profileById.get(participantId) || {}).role || "",
          task_id: taskId,
          task_category: taskCategory(tasks, taskId),
          is_optional_task: isOptionalTask(tasks, taskId),
          task_started_at: isoOrNull(taskStarted),
          first_execute_at: isoOrNull(firstTime(taskEvents, (event) => event.kind === "execute")),
          first_grade_at: isoOrNull(firstTime(taskEvents, (event) => event.kind === "grade")),
          cleared_at: isoOrNull(clearTime),
          left_task_at: isoOrNull(leaveTime),
          execute_count: executeEvents.length,
          grade_count: gradeEvents.length,
          error_count: executeEvents.filter(isExecuteError).length,
          first_grade_score: firstGrade ? gradeScore(firstGrade) : null,
          clear_score: clearEvent ? gradeScore(clearEvent) : null,
          task_progress_high_score: progressRow ? progressRow.high_score : null,
          task_progress_is_cleared: progressRow ? progressRow.is_cleared : null,
          task_progress_updated_at: progressRow ? progressRow.updated_at : null,
          cleared_by_progress: clearedByProgress,
          cleared_by_log: clearedByLog,
          cleared_final: clearedFinal,
          clear_status_source: progressClearSource(progressRow, clearedByLog),
          high_score_reference: highScoreReference,
          max_score_reference: highScoreReference,
          cleared: clearedFinal,
          attempts_until_clear: clearEvent ? taskEvents.filter((event) => event.kind === "execute" && event.time <= clearTime).length : null,
          grades_until_clear: clearEvent ? taskEvents.filter((event) => event.kind === "grade" && event.time <= clearTime).length : null,
          time_until_first_execute_sec: secondsBetween(taskStarted, firstTime(taskEvents, (event) => event.kind === "execute")),
          time_until_first_grade_sec: secondsBetween(taskStarted, firstTime(taskEvents, (event) => event.kind === "grade")),
          time_until_clear_sec: secondsBetween(taskStarted, clearTime),
          retried_after_error: errorIndexes.some((index) => nextBeforeBoundary(taskEvents, index, boundary, (event) => event.kind === "execute" || event.kind === "grade")),
          retried_after_low_score: lowScoreIndexes.some((index) => nextBeforeBoundary(taskEvents, index, boundary, (event) => event.kind === "execute" || event.kind === "grade")),
          used_chat_before_clear: usedChatBeforeClear,
          used_chat_after_error: errorIndexes.some((index) => nextBeforeBoundary(taskEvents, index, boundary, isUserChat)),
          used_chat_after_low_score: lowScoreIndexes.some((index) => nextBeforeBoundary(taskEvents, index, boundary, isUserChat)),
          excluded_participants: meta.excluded_participants || "",
          included_episode_min: meta.included_episode_min == null ? "" : meta.included_episode_min,
          n: meta.n == null ? "" : meta.n,
          generated_at: meta.generated_at || "",
        });
      });
    });
    return rows;
  }

  function secondsBetween(start, end) {
    return Number.isFinite(start) && Number.isFinite(end) && end >= start ? (end - start) / 1000 : null;
  }

  function actionType(event) {
    if (!event) return "";
    if (isUserChat(event)) return "chat_user";
    if (event.kind === "chat" && event.data && event.data.ai) return "chat_ai";
    if (event.kind === "execute") return isExecuteError(event) ? "execute_error" : "execute";
    if (event.kind === "grade") return isClearedGrade(event) ? "grade_clear" : "grade";
    if (event.kind === "love") return "love_change";
    if (event.kind === "lecture") return "story_or_episode";
    if (isLeaveEvent(event)) return "leave_task";
    if (event.kind === "screen") return `screen_${event.data.action || ""}`;
    return event.kind || "";
  }

  function relatedTaskIdForLove(events, index) {
    const event = events[index];
    if (event.task_id) return event.task_id;
    const requestId = event.data && event.data.request_id;
    if (requestId) {
      const related = events.slice(0, index).reverse().find((candidate) =>
        candidate.task_id && candidate.raw && candidate.raw.some((rawEvent) => getRequestId(rawEvent) === requestId)
      );
      if (related) return related.task_id;
    }
    const previousTask = events.slice(0, index).reverse().find((candidate) => candidate.task_id);
    return previousTask ? previousTask.task_id : "";
  }

  function buildLoveTransitionBehaviorSummary(profiles, analysisEvents, metadata) {
    const eventsByParticipant = groupEventsByParticipant(analysisEvents);
    const profileById = new Map((profiles || []).map((profile) => [profile.participant_id, profile]));
    const meta = metadata || {};
    const rows = [];
    eventsByParticipant.forEach((events, participantId) => {
      events.forEach((event, index) => {
        if (event.kind !== "love") return;
        const next = events.slice(index + 1).find((candidate) => candidate.kind !== "love");
        const previous = events.slice(0, index).reverse().find((candidate) => candidate.kind !== "love");
        const deltaMs = next ? next.time - event.time : null;
        const relatedTaskId = relatedTaskIdForLove(events, index);
        rows.push({
          participant_id: participantId,
          group: (profileById.get(participantId) || {}).role || "",
          event_time: isoOrNull(event.time),
          love_before: number(event.data.before),
          love_after: number(event.data.after),
          love_delta: number(event.data.delta),
          love_source: event.data.source || "",
          related_task_id: relatedTaskId,
          previous_action_type: actionType(previous),
          next_action_type: actionType(next),
          next_action_within_3min: Number.isFinite(deltaMs) ? deltaMs <= 180000 : false,
          next_action_within_5min: Number.isFinite(deltaMs) ? deltaMs <= 300000 : false,
          next_task_continued: !!(next && relatedTaskId && next.task_id === relatedTaskId && (next.kind === "execute" || next.kind === "grade" || isUserChat(next))),
          next_chat_sent: !!(next && isUserChat(next)),
          next_execute_done: !!(next && next.kind === "execute"),
          next_grade_done: !!(next && next.kind === "grade"),
          next_story_or_episode_viewed: !!(next && next.kind === "lecture"),
          excluded_participants: meta.excluded_participants || "",
          included_episode_min: meta.included_episode_min == null ? "" : meta.included_episode_min,
          n: meta.n == null ? "" : meta.n,
          generated_at: meta.generated_at || "",
        });
      });
    });
    return rows;
  }

  function ranks(values) {
    const indexed = values.map((value, index) => ({ value, index })).sort((a, b) => a.value - b.value);
    const out = Array(values.length).fill(null);
    for (let start = 0; start < indexed.length;) {
      let end = start + 1;
      while (end < indexed.length && indexed[end].value === indexed[start].value) end += 1;
      const rank = (start + 1 + end) / 2;
      for (let index = start; index < end; index += 1) out[indexed[index].index] = rank;
      start = end;
    }
    return out;
  }

  function spearman(xs, ys) {
    const pairs = pairedNumbers(xs, ys);
    if (pairs.length < 2) return null;
    return pearsonValue(ranks(pairs.map(([x]) => x)), ranks(pairs.map(([, y]) => y)));
  }

  function pearsonValue(xs, ys) {
    if (stats && typeof stats.pearson === "function") return stats.pearson(xs, ys);
    const pairs = pairedNumbers(xs, ys);
    if (pairs.length < 2) return null;
    const meanX = pairs.reduce((sum, pair) => sum + pair[0], 0) / pairs.length;
    const meanY = pairs.reduce((sum, pair) => sum + pair[1], 0) / pairs.length;
    const numerator = pairs.reduce((sum, [x, y]) => sum + (x - meanX) * (y - meanY), 0);
    const dx = Math.sqrt(pairs.reduce((sum, [x]) => sum + Math.pow(x - meanX, 2), 0));
    const dy = Math.sqrt(pairs.reduce((sum, [, y]) => sum + Math.pow(y - meanY, 2), 0));
    return dx && dy ? numerator / (dx * dy) : null;
  }

  function pairedNumbers(xs, ys) {
    return (xs || []).map((x, index) => [number(x), number((ys || [])[index])])
      .filter(([x, y]) => Number.isFinite(x) && Number.isFinite(y));
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

  function buildCorrelationStats(rows, definitions, metadata) {
    const meta = metadata || {};
    return (definitions || []).map((definition) => {
      const pairs = rows.map((row) => [number(row[definition.log_key]), number(row[definition.survey_key])])
        .filter(([x, y]) => Number.isFinite(x) && Number.isFinite(y));
      const xs = pairs.map(([x]) => x);
      const ys = pairs.map(([, y]) => y);
      const pearson = pearsonValue(xs, ys);
      const spear = spearman(xs, ys);
      return {
        log_metric: definition.log_key,
        survey_metric: definition.survey_key,
        label: definition.label || `${definition.log_key} x ${definition.survey_key}`,
        group: definition.group || meta.group || "all",
        n: pairs.length,
        pearson_r: pearson,
        pearson_p_value_approx: correlationPValueApprox(pearson, pairs.length),
        spearman_rho: spear,
        spearman_p_value_approx: correlationPValueApprox(spear, pairs.length),
        excluded_participants: meta.excluded_participants || "",
        included_episode_min: meta.included_episode_min == null ? "" : meta.included_episode_min,
        generated_at: meta.generated_at || "",
      };
    });
  }

  function buildGroupAttributeLogSummary(rows, metrics, attributeDefinitions, metadata) {
    const meta = metadata || {};
    const out = [];
    (attributeDefinitions || []).forEach((attribute) => {
      const values = Array.from(new Set(rows.map(attribute.value).filter((value) => value != null && value !== "")));
      values.forEach((attributeValue) => {
        ["experimental", "control"].forEach((group) => {
          const selected = rows.filter((row) => row.group === group && attribute.value(row) === attributeValue);
          (metrics || []).forEach((metric) => {
            const xs = selected.map((row) => row[metric.key]).filter((value) => Number.isFinite(number(value))).map(number);
            const summary = stats && stats.summarize ? stats.summarize(xs) : simpleSummary(xs);
            out.push({
              attribute: attribute.key,
              attribute_value: attributeValue,
              metric: metric.key,
              metric_label: metric.label || metric.key,
              group,
              n: summary.n,
              mean: summary.mean,
              median: summary.median,
              sd: summary.sd,
              q1: summary.q1,
              q3: summary.q3,
              min: summary.min,
              max: summary.max,
              excluded_participants: meta.excluded_participants || "",
              included_episode_min: meta.included_episode_min == null ? "" : meta.included_episode_min,
              generated_at: meta.generated_at || "",
            });
          });
        });
      });
    });
    return out;
  }

  function simpleSummary(values) {
    const xs = values.filter(Number.isFinite).sort((a, b) => a - b);
    if (!xs.length) return { n: 0, mean: null, median: null, sd: null, q1: null, q3: null, min: null, max: null };
    const meanValue = xs.reduce((sum, value) => sum + value, 0) / xs.length;
    return { n: xs.length, mean: meanValue, median: xs[Math.floor(xs.length / 2)], sd: null, q1: xs[0], q3: xs[xs.length - 1], min: xs[0], max: xs[xs.length - 1] };
  }

  return {
    CLEAR_SCORE,
    asTime,
    buildAnalysisEvents,
    assignLoveValues,
    buildParticipantBehaviorSummary,
    buildTaskAttemptSummary,
    buildLoveTransitionBehaviorSummary,
    buildCorrelationStats,
    buildGroupAttributeLogSummary,
    isOptionalTask,
    spearman,
    correlationPValueApprox,
  };
});
