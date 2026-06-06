(function(global) {
    var config = global.AppProgressConfig || {};

    config.controlLoveLevel = 50;
    config.loveLevelThresholds = [0, 15, 30, 65, 100, 100];

    config.getControlLoveLevel = function() {
        return config.controlLoveLevel;
    };

    config.applyControlLoveLevel = function(f) {
        if (f && f.user_role === "control") {
            f.love_level = config.getControlLoveLevel();
        }
        return f ? f.love_level : config.getControlLoveLevel();
    };

    config.getUnlockedCountByLove = function(love, maxCount) {
        var unlockedCount = config.getLoveGaugeState(love).level;

        if (maxCount) {
            unlockedCount = Math.min(unlockedCount, maxCount);
        }
        return unlockedCount;
    };

    config.getLoveGaugeState = function(love) {
        var totalLove = parseInt(love) || 0;
        var thresholds = config.loveLevelThresholds;
        var currentLv = 1;
        var minLove = 0;
        var maxLove = 0;

        for (var i = 0; i < thresholds.length - 1; i++) {
            if (totalLove >= thresholds[i]) {
                currentLv = i + 1;
                minLove = thresholds[i];
                maxLove = thresholds[i + 1];
            }
        }

        var range = maxLove - minLove;
        var currentProgress = totalLove - minLove;
        var percent = range > 0 ? (currentProgress / range) * 100 : 100;
        var displayStr = currentProgress + " / " + range;

        if (totalLove >= 100) {
            displayStr = " (MAX)";
            percent = 100;
        }

        return {
            level: currentLv,
            minLove: minLove,
            maxLove: maxLove,
            range: range,
            currentProgress: currentProgress,
            percent: Math.min(100, Math.max(0, percent)),
            displayStr: displayStr
        };
    };

    global.AppProgressConfig = config;
})(window);
