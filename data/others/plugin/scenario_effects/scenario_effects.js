(function () {
  "use strict";

  var RECT_CLASS = "scenario-effect-rect";
  var preparedTilts = {};

  function toNumber(value, fallback) {
    if (value === undefined || value === null || value === "") {
      return fallback;
    }
    var number = parseFloat(value);
    return Number.isFinite(number) ? number : fallback;
  }

  function toInt(value, fallback) {
    var number = toNumber(value, fallback);
    return Number.isFinite(number) ? Math.round(number) : fallback;
  }

  function isFalse(value) {
    return value === false || value === "false" || value === "0";
  }

  function cssColor(value, fallback) {
    if (value === undefined || value === null || value === "") {
      return fallback;
    }
    if (typeof $.convertColor === "function" && /^0x[0-9a-fA-F]{6}$/.test(String(value))) {
      return $.convertColor(value);
    }
    return String(value);
  }

  function getBaseLayer() {
    var $base = $("#tyrano_base");
    if ($base.length === 0) {
      $base = $("#root_layer_game");
    }
    return $base;
  }

  function sanitizeName(name) {
    return String(name || "default").replace(/[^\w-]/g, "_");
  }

  function rectId(name) {
    return "scenario-effect-rect-" + sanitizeName(name);
  }

  function showRect(pm) {
    var name = pm.name || "default";
    var id = rectId(name);
    var time = toInt(pm.time, 0);
    var opacity = toNumber(pm.opacity, 1);
    var $base = getBaseLayer();

    if ($base.length === 0) {
      console.warn("[scenario_effects] tyrano base layer was not found.");
      return;
    }

    $("#" + id).remove();

    var $rect = $("<div></div>");
    $rect.attr("id", id);
    $rect.addClass(RECT_CLASS);
    $rect.css({
      position: "absolute",
      left: toInt(pm.x, 0) + "px",
      top: toInt(pm.y, 0) + "px",
      width: toInt(pm.width, 100) + "px",
      height: toInt(pm.height, 100) + "px",
      border: toInt(pm.border, 3) + "px solid " + cssColor(pm.color, "#ffffff"),
      borderRadius: toInt(pm.radius, 0) + "px",
      background: cssColor(pm.bg, "transparent"),
      boxSizing: "border-box",
      pointerEvents: isFalse(pm.pointer) ? "none" : String(pm.pointer || "none"),
      zIndex: toInt(pm.z, 9999),
      opacity: time > 0 ? 0 : opacity,
      transition: time > 0 ? "opacity " + time + "ms ease" : ""
    });

    $base.append($rect);

    if (time > 0) {
      $rect.get(0).offsetHeight;
      $rect.css("opacity", opacity);
    }
  }

  function hideRect(pm) {
    var name = pm.name || "default";
    var time = toInt(pm.time, 0);
    var $rect = $("#" + rectId(name));

    if ($rect.length === 0) {
      return;
    }

    if (time > 0) {
      $rect.css({
        transition: "opacity " + time + "ms ease",
        opacity: 0
      });
      setTimeout(function () {
        $rect.remove();
      }, time);
    } else {
      $rect.remove();
    }
  }

  function clearRects() {
    $("." + RECT_CLASS).remove();
  }

  function getCharaContainer(name, quiet) {
    if (!name) {
      if (!quiet) {
        console.warn("[scenario_effects] chara name is required.");
      }
      return $();
    }

    var kag = window.TYRANO && window.TYRANO.kag;
    if (kag && kag.chara && typeof kag.chara.getCharaContainer === "function") {
      var $chara = kag.chara.getCharaContainer(name);
      if ($chara && $chara.length > 0) {
        return $chara;
      }
    }

    var escaped = $.escapeSelector ? $.escapeSelector(name) : name;
    var $fallback = $(".tyrano_chara." + escaped + ", .tyrano_chara[name='" + name + "']");
    if ($fallback.length === 0 && !quiet) {
      console.warn("[scenario_effects] chara was not found:", name);
    }
    return $fallback;
  }

  function ensureBaseTransform($chara) {
    $chara.each(function () {
      var $target = $(this);
      if ($target.attr("data-scenario-effects-base-transform") === undefined) {
        var current = $target.css("transform");
        $target.attr(
          "data-scenario-effects-base-transform",
          current && current !== "none" ? current : ""
        );
      }
    });
  }

  function applyTilt($chara, deg, time, origin) {
    ensureBaseTransform($chara);
    $chara.each(function () {
      var $target = $(this);
      var baseTransform = $target.attr("data-scenario-effects-base-transform") || "";
      var transform = (baseTransform ? baseTransform + " " : "") + "rotate(" + deg + "deg)";
      $target.css({
        transition: "transform " + time + "ms ease",
        transformOrigin: origin,
        transform: transform
      });
    });
  }

  function restoreTilt($chara, time) {
    $chara.each(function () {
      var $target = $(this);
      var baseTransform = $target.attr("data-scenario-effects-base-transform") || "";
      $target.css({
        transition: "transform " + time + "ms ease",
        transform: baseTransform
      });
      setTimeout(function () {
        if (baseTransform === "") {
          $target.css("transform", "");
        }
        $target.removeAttr("data-scenario-effects-base-transform");
      }, time);
    });
  }

  function tiltChara(pm) {
    var $chara = getCharaContainer(pm.name || pm.chara);
    if ($chara.length === 0) {
      return;
    }
    applyTilt($chara, toNumber(pm.deg, 8), toInt(pm.time, 180), pm.origin || "50% 100%");
  }

  function prepareTilt(pm) {
    var name = pm.name || pm.chara;
    if (!name) {
      console.warn("[scenario_effects] chara name is required for prepared tilt.");
      return;
    }

    preparedTilts[name] = {
      name: name,
      deg: toNumber(pm.deg, 8),
      origin: pm.origin || "50% 100%",
      time: toInt(pm.tilt_time !== undefined ? pm.tilt_time : pm.time, 0)
    };
  }

  function waitForChara(name, callback) {
    var start = Date.now();
    var timer = setInterval(function () {
      var $chara = getCharaContainer(name, true);
      if ($chara.length > 0) {
        clearInterval(timer);
        callback($chara);
        return;
      }

      if (Date.now() - start > 3000) {
        clearInterval(timer);
        console.warn("[scenario_effects] timed out waiting for chara:", name);
      }
    }, 16);
  }

  function applyPreparedTilt(name) {
    var prepared = preparedTilts[name];
    if (!prepared) {
      return;
    }

    waitForChara(name, function ($chara) {
      applyTilt($chara, prepared.deg, prepared.time, prepared.origin);
      delete preparedTilts[name];
    });
  }

  function untiltChara(pm) {
    var $chara = getCharaContainer(pm.name || pm.chara);
    if ($chara.length === 0) {
      return;
    }
    restoreTilt($chara, toInt(pm.time, 180));
  }

  function tiltBounceChara(pm) {
    var $chara = getCharaContainer(pm.name || pm.chara);
    if ($chara.length === 0) {
      return;
    }

    var deg = toNumber(pm.deg, 8);
    var time = toInt(pm.time, 120);
    var origin = pm.origin || "50% 100%";

    applyTilt($chara, deg, time, origin);
    setTimeout(function () {
      restoreTilt($chara, time);
    }, time);
  }

  function getWaitTime(pm, fallback) {
    if (isFalse(pm.wait)) {
      return 0;
    }
    return toInt(pm.time, fallback);
  }

  function getBounceWaitTime(pm, fallback) {
    if (isFalse(pm.wait)) {
      return 0;
    }
    return toInt(pm.time, fallback) * 2;
  }

  function copyCharaShowParams(pm) {
    var charaShowTag = tyrano.plugin.kag.tag.chara_show;
    var basePm = charaShowTag && charaShowTag.pm ? charaShowTag.pm : {};
    var showPm = {};

    Object.keys(basePm).forEach(function (key) {
      if (pm[key] !== undefined) {
        showPm[key] = pm[key];
      }
    });

    showPm.name = pm.name;
    return showPm;
  }

  function registerTag(name, tag) {
    tyrano.plugin.kag.tag[name] = tag;
    if (window.TYRANO && TYRANO.kag && TYRANO.kag.ftag && TYRANO.kag.ftag.master_tag) {
      TYRANO.kag.ftag.master_tag[name] = object(tag);
      TYRANO.kag.ftag.master_tag[name].kag = TYRANO.kag;
    }
  }

  function registerCharaShowHook() {
    if (!window.TYRANO || !TYRANO.kag || !TYRANO.kag.ftag || !TYRANO.kag.ftag.master_tag) {
      return;
    }

    var charaShow = TYRANO.kag.ftag.master_tag.chara_show;
    if (!charaShow || charaShow._scenarioEffectsHooked) {
      return;
    }

    var originalStart = charaShow.start;
    charaShow.start = function (pm) {
      var name = pm.name;
      originalStart.call(this, pm);
      if (preparedTilts[name]) {
        applyPreparedTilt(name);
      }
    };
    charaShow._scenarioEffectsHooked = true;
  }

  function registerScenarioEffectTags() {
    registerCharaShowHook();

    registerTag("chara_prepare_tilt", {
      vital: ["name"],
      pm: {
        name: "",
        deg: "8",
        origin: "50% 100%",
        tilt_time: "0"
      },
      start: function (pm) {
        prepareTilt(pm);
        this.kag.ftag.nextOrder();
      }
    });

    registerTag("chara_show_tilt", {
      vital: ["name"],
      pm: $.extend({}, tyrano.plugin.kag.tag.chara_show.pm, {
        deg: "8",
        origin: "50% 100%",
        tilt_time: "0"
      }),
      start: function (pm) {
        prepareTilt(pm);
        this.kag.ftag.startTag("chara_show", copyCharaShowParams(pm));
      }
    });
  }

  window.scenarioEffects = {
    showRect: showRect,
    hideRect: hideRect,
    clearRects: clearRects,
    tiltChara: tiltChara,
    prepareTilt: prepareTilt,
    applyPreparedTilt: applyPreparedTilt,
    untiltChara: untiltChara,
    tiltBounceChara: tiltBounceChara,
    getWaitTime: getWaitTime,
    getBounceWaitTime: getBounceWaitTime
  };

  registerScenarioEffectTags();
})();
