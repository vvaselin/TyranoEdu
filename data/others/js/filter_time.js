/**
 * Extends filter/free_filter with time and wait.
 */
(function () {
  "use strict";

  function isWait(pm) {
    return pm.wait === true || pm.wait === "true";
  }

  function getTime(pm) {
    var time = parseInt(pm.time, 10);
    return Number.isFinite(time) ? Math.max(time, 0) : 0;
  }

  function nextOnce(kag, cleanup) {
    var done = false;
    return function () {
      if (done) {
        return;
      }
      done = true;
      if (typeof cleanup === "function") {
        cleanup();
      }
      kag.ftag.nextOrder();
    };
  }

  function waitTransitionOrTimeout(kag, jObj, time, onDone) {
    var finish = nextOnce(kag, function () {
      clearTimeout(timer);
      jObj.off("transitionend.filter_time");
      jObj.off("webkitTransitionEnd.filter_time");
    });
    var timer = setTimeout(function () {
      onDone();
      finish();
    }, time + 50);

    jObj.one("transitionend.filter_time webkitTransitionEnd.filter_time", function () {
      onDone();
      finish();
    });
  }

  function getTarget(kag, pm, useAppliedTargets) {
    var jObj;
    if (useAppliedTargets && pm.layer === "") {
      jObj = $(".tyrano_filter_effect");
    } else if (pm.layer === "all") {
      jObj = $(".layer_camera");
    } else {
      jObj = kag.layer.getLayer(pm.layer, pm.page);
    }

    if (pm.name !== "") {
      jObj = jObj.find("." + pm.name);
    }

    return jObj;
  }

  function buildFilterString(pm) {
    var filterStr = "";
    if (pm.grayscale !== "") {
      filterStr += "grayscale(" + pm.grayscale + "%) ";
    }
    if (pm.sepia !== "") {
      filterStr += "sepia(" + pm.sepia + "%) ";
    }
    if (pm.saturate !== "") {
      filterStr += "saturate(" + pm.saturate + "%) ";
    }
    if (pm.hue !== "") {
      filterStr += "hue-rotate(" + pm.hue + "deg) ";
    }
    if (pm.invert !== "") {
      filterStr += "invert(" + pm.invert + "%) ";
    }
    if (pm.opacity !== "") {
      filterStr += "opacity(" + pm.opacity + "%) ";
    }
    if (pm.brightness !== "") {
      filterStr += "brightness(" + pm.brightness + "%) ";
    }
    if (pm.contrast !== "") {
      filterStr += "contrast(" + pm.contrast + "%) ";
    }
    if (pm.blur !== "") {
      filterStr += "blur(" + pm.blur + "px) ";
    }
    return filterStr;
  }

  tyrano.plugin.kag.tag.filter = {
    vital: [],
    pm: {
      layer: "all",
      page: "fore",
      name: "",
      grayscale: "",
      sepia: "",
      saturate: "",
      hue: "",
      invert: "",
      opacity: "",
      brightness: "",
      contrast: "",
      blur: "",
      time: 0,
      wait: "true"
    },
    start: function (pm) {
      var jObj = getTarget(this.kag, pm, false);
      var time = getTime(pm);
      var filterStr = buildFilterString(pm);

      if (!jObj || jObj.length === 0) {
        this.kag.ftag.nextOrder();
        return;
      }

      if (isWait(pm) && time > 0) {
        waitTransitionOrTimeout(this.kag, jObj, time, function () {
          jObj.addClass("tyrano_filter_effect");
        });
      }

      jObj.css({
        "-webkit-filter": filterStr,
        "-ms-filter": filterStr,
        "-moz-filter": filterStr,
        filter: filterStr,
        transition: "filter " + time + "ms, -webkit-filter " + time + "ms"
      });

      if (!isWait(pm) || time === 0) {
        jObj.addClass("tyrano_filter_effect");
        this.kag.ftag.nextOrder();
      }
    }
  };

  TYRANO.kag.ftag.master_tag.filter = TYRANO.kag.tag.filter;
  TYRANO.kag.ftag.master_tag.filter.kag = TYRANO.kag;

  tyrano.plugin.kag.tag.free_filter = {
    vital: [],
    pm: {
      layer: "",
      page: "fore",
      name: "",
      time: 0,
      wait: "true"
    },
    start: function (pm) {
      var jObj = getTarget(this.kag, pm, true);
      var time = getTime(pm);

      if (!jObj || jObj.length === 0) {
        this.kag.ftag.nextOrder();
        return;
      }

      if (isWait(pm) && time > 0) {
        waitTransitionOrTimeout(this.kag, jObj, time, function () {
          jObj.removeClass("tyrano_filter_effect");
        });
      }

      jObj.css({
        "-webkit-filter": "",
        "-ms-filter": "",
        "-moz-filter": "",
        filter: "",
        transition: "filter " + time + "ms, -webkit-filter " + time + "ms"
      });

      if (!isWait(pm) || time === 0) {
        jObj.removeClass("tyrano_filter_effect");
        this.kag.ftag.nextOrder();
      }
    }
  };

  TYRANO.kag.ftag.master_tag.free_filter = TYRANO.kag.tag.free_filter;
  TYRANO.kag.ftag.master_tag.free_filter.kag = TYRANO.kag;
})();
