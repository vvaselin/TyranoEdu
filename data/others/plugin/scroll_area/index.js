(function () {
  var new_tag = {};

  new_tag['scroll_area'] = {
    vital: ["id", "width", "height", "contents_w"],
    pm: {
      id: "",
      width: "1280",
      height: "720",
      top: "0",
      left: "0",
      contents_w: "3000",
      zindex: "20000000"
    },
    start: function (pm) {
      var target_layer = TYRANO.kag.layer.getLayer("fix");
      
      var main_wrapper = $("<div />").css({
        "position": "absolute",
        "top": pm.top + "px",
        "left": pm.left + "px",
        "width": pm.width + "px",
        "height": pm.height + "px",
        "z-index": pm.zindex,
        "overflow": "hidden",
        "background-image": "linear-gradient(90deg, #81eeff, #b898ff80)"
      }).attr('id', pm.id);

      var scroll_view = $("<div />").css({
        "position": "absolute",
        "top": "0px",
        "left": "0px",
        "width": "100%",
        "height": "100%",
        "overflow-x": "scroll",
        "overflow-y": "hidden",
        "pointer-events": "auto"
      }).addClass("scroll_scrollable").attr('id', pm.id + "_view");

      // マウスホイール
      scroll_view.on('wheel', function(e) {
        var delta = e.originalEvent.deltaY ? e.originalEvent.deltaY : e.originalEvent.wheelDelta * -1;
        $(this).scrollLeft($(this).scrollLeft() + delta);
        e.preventDefault();
      });

      var btn_left = $("<div class='scroll_arrow_btn left'><span>◀</span></div>");
      var btn_right = $("<div class='scroll_arrow_btn right'><span>▶</span></div>");

      // --- 長押しスクロール管理 ---
      var scrollInterval = null;
      var scrollSpeed = 15; // 1回あたりのスクロール量（px）

      var startScrolling = function(direction) {
        if (scrollInterval) return; 
        scrollInterval = setInterval(function() {
          var current = scroll_view.scrollLeft();
          scroll_view.scrollLeft(current + (direction * scrollSpeed));
        }, 16); // 約60fpsで滑らかに移動
      };

      var stopScrolling = function() {
        if (scrollInterval) {
          clearInterval(scrollInterval);
          scrollInterval = null;
        }
      };

      // ボタン押し下げイベント
      btn_left.on('mousedown touchstart', function(e) { startScrolling(-1); e.preventDefault(); });
      btn_right.on('mousedown touchstart', function(e) { startScrolling(1); e.preventDefault(); });

      // 停止条件（ボタンから離れた、指を離した、ボタン外へ出た）
      btn_left.on('mouseup mouseleave touchend', stopScrolling);
      btn_right.on('mouseup mouseleave touchend', stopScrolling);
      
      // 画面上のどこでマウスを離しても確実に止めるための設定
      // イベント名にIDを付与して、削除時にこのエリアの分だけ消せるようにする
      $(window).on('mouseup.' + pm.id + ' touchend.' + pm.id, stopScrolling);

      var inner_div = $("<div />").css({
        "width": pm.contents_w + "px",
        "height": pm.height + "px",
        "position": "relative"
      }).attr('id', pm.id + "_inner");

      scroll_view.append(inner_div);
      main_wrapper.append(scroll_view);
      main_wrapper.append(btn_left);
      main_wrapper.append(btn_right);
      target_layer.append(main_wrapper);
      
      TYRANO.kag.ftag.nextOrder();
    }
  };

  new_tag['scroll_area_in'] = {
    vital: ["id", "name"],
    start: function (pm) {
      var ary = pm.name.split(',');
      var $inner = $('#' + pm.id + "_inner");
      for (var i = 0; i < ary.length; i++) {
        var target = $("." + ary[i].trim());
        target.appendTo($inner).css({ "z-index": "10", "pointer-events": "auto" });
      }
      TYRANO.kag.ftag.nextOrder();
    }
  };

  new_tag['scroll_area_del'] = {
    vital: ["id"],
    start: function (pm) {
      // ウィンドウに貼ったイベントも解除
      $(window).off('.' + pm.id);
      $('#' + pm.id).remove();
      TYRANO.kag.ftag.nextOrder();
    }
  };

  $.extend(TYRANO.kag.ftag.master_tag, new_tag);
})();