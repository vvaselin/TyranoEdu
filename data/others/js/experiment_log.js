(function(global) {
    var MAX_STRING_LENGTH = 200000;

    function getF() {
        return global.TYRANO && TYRANO.kag && TYRANO.kag.stat ? TYRANO.kag.stat.f : {};
    }

    function ensureSessionId() {
        var f = getF();
        if (!f.session_id) {
            f.session_id = Date.now() + "-" + Math.random().toString(36).slice(2);
        }
        return f.session_id;
    }

    function trimLargeValues(value) {
        if (typeof value === "string") {
            if (value.length > MAX_STRING_LENGTH) {
                return value.slice(0, MAX_STRING_LENGTH) + "\n...[truncated]";
            }
            return value;
        }
        if (Array.isArray(value)) {
            return value.map(trimLargeValues);
        }
        if (value && typeof value === "object") {
            var out = {};
            Object.keys(value).forEach(function(key) {
                out[key] = trimLargeValues(value[key]);
            });
            return out;
        }
        return value;
    }

    global.ensureExperimentSessionId = ensureSessionId;

    global.logExperimentEvent = function(eventType, eventData, options) {
        var f = getF();
        if (!eventType) return Promise.resolve();
        options = options || {};

        var taskId = f.current_task_id || "";
        if (Object.prototype.hasOwnProperty.call(options, "task_id")) {
            taskId = options.task_id;
        }

        var payload = {
            user_id: f.user_id || "",
            participant_id: f.participant_id || "",
            role: f.user_role || "",
            session_id: ensureSessionId(),
            task_id: taskId,
            event_type: eventType,
            event_data: trimLargeValues(eventData || {})
        };

        return fetch("/api/experiment-log", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        }).then(function(response) {
            if (!response.ok) {
                return response.text().then(function(text) {
                    console.warn("[ExperimentLog] failed:", response.status, text);
                });
            }
        }).catch(function(error) {
            console.warn("[ExperimentLog] failed:", error);
        });
    };
})(window);
