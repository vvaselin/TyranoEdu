(function () {

  var new_tag = {};

  // 位置固定  // // // // // // // // // // // // // // // // // //
  new_tag['scroll_area'] = {

    // 必須変数
    vital: ["id", "width", "height", "contents_h"],

    pm: {
      id: "",
      name: "",
      top: "",
      bottom: "",
      right: "",
      left: "",
      width: "",
      height: "",
      zindex: "1",
      bar_w: 12,
      bar_r: "false",
      bg: "",
      bar_bg: "0xcccccc",
      tumami_bg: "0x666666",
      contents_h: ""

    },

    start: function (pm) {

      // 描画 - - - - - - - - - - - - - - - - -
      target_layer = this.kag.layer.getLayer("fix");

      var scroll_container = $("<div />");
      scroll_container.css({
        "position": "absolute",
        "width": pm.width + "px",
        "height": pm.height + "px",
        "z-index": pm.zindex
      })
      scroll_container.attr('id', pm.id + "_container");

      $.setName(scroll_container, pm.name);

      if (pm.bg) {
        scroll_container.css("background-color", $.convertColor(pm.bg));
      }

      if (pm.top) {
        scroll_container.css("top", pm.top + "px")
      } else if (pm.bottom) {
        scroll_container.css("bottom", pm.bottom + "px")
      }

      if (pm.left) {
        scroll_container.css("left", pm.left + "px")
      } else if (pm.right) {
        scroll_container.css("right", pm.right + "px")
      }

      scroll_container.addClass("scroll_container");

      target_layer.append(scroll_container);

      var scroll_scrollable = $("<div />");
      scroll_scrollable.addClass("scroll_scrollable");
      scroll_scrollable.css({
        "height": pm.height + "px",
        "margin-right": (pm.bar_w * -1) + "px"
      })
      scroll_container.append(scroll_scrollable);

      var scroll_adjustment = $("<div />");
      scroll_adjustment.addClass("scroll_adjustment");
      scroll_adjustment.css("height", pm.contents_h + "px")
      scroll_adjustment.attr('id', pm.id);
      scroll_scrollable.append(scroll_adjustment);

      // 中身の方が高さが低い場合、スクロールバー作成しないしスクロールイベントもつけない
      pm.height = parseInt(pm.height);
      pm.contents_h = parseInt(pm.contents_h);

      if (pm.height < pm.contents_h) {
        var scrollbar = $("<div />");
        scrollbar.addClass("scroll_scrollbar");
        scrollbar.css({
          "width": pm.bar_w + "px",
          "background-color": $.convertColor(pm.bar_bg)
        })
        scroll_container.append(scrollbar);

        var scrollbartumami = $("<div />");
        scrollbartumami.addClass("scrollbar-tumami");
        scrollbartumami.css("background-color", $.convertColor(pm.tumami_bg))

        if (pm.bar_r == "true") {
          scrollbar.css("border-radius", pm.bar_w);
          scrollbartumami.css("border-radius", pm.bar_w);
        }

        scrollbar.append(scrollbartumami);

        // スクロール処理 - - - - - - - - - - - - - - - - -

        var scrollable_height = scroll_scrollable.height();
        var adjustment_height = scroll_adjustment.height();
        var scrollbar_height = parseInt(scrollable_height * scrollable_height / adjustment_height);
        scrollbartumami.css('height', scrollbar_height);

        var active = false; // つまみを操作しているかどうか
        var click_y; // つまみ内のクリック位置

        var track = scrollable_height - scrollbar_height;
        var scrollbar_top = scrollbar.offset().top;
        var scrollbar_tumami_y = 0;
        var click_scrollbar_tumami_y = 0;

        scroll_scrollable.on('scroll', function () {
          if (active) return;
          // console.log("scroll");

          var offset = $(this).scrollTop() * track / (adjustment_height - scrollable_height);

          scrollbartumami.css('top', offset + 'px');
        });

        scroll_scrollable.on('mousedown touchstart', function (event) {
          event.stopPropagation();
          // console.log("mousedown");
          active = true;
          scrollbar_top = scrollbar.offset().top;
          click_y = event.pageY - scrollbar_top;
          click_scrollbar_tumami_y = parseInt(scrollbartumami.css('top'));
        });

        $(document).on('mouseup touchend', function () {
          event.stopPropagation();
          // console.log("mouseup");
          active = false;
        });

        $(document).on('mousemove touchmove', function (event) {
          event.stopPropagation();
          if (!active) return;
          // console.log("mousemove");

          scrollbar_tumami_y = click_scrollbar_tumami_y + ((event.pageY - scrollbar_top) / track * track) - click_y;

          // つまみが上下の領域外を超えないようにする
          if (scrollbar_tumami_y < 0) {
            scrollbar_tumami_y = 0;
          } else if (scrollbar_tumami_y > track) {
            scrollbar_tumami_y = track;
          }

          // つまみの位置設定
          scrollbartumami.css('top', scrollbar_tumami_y + 'px');

          // つまみの位置に応じてスクロールさせる
          scroll_scrollable.scrollTop(parseInt(scrollbartumami.css('top')) / track * (adjustment_height - scrollable_height));
        });

        // つまみを操作中はテキスト選択できないようにする
        $(document).on('selectstart', function () {
          if (active) return false;
        });
      }

      this.kag.ftag.nextOrder();
    }
  };

  // 位置固定  // // // // // // // // // // // // // // // // // //
  new_tag['scroll_area_in'] = {
    // 必須変数
    vital: ["id", "name"],

    pm: {
      id: "",
      name: ""
    },

    start: function (pm) {

      ary = pm.name.split(',');
      for (var i = 0; i < ary.length; i++) {
        $("." + ary[i]).appendTo($('#' + pm.id));
      }

      this.kag.ftag.nextOrder();
    }
  };

  // 削除  // // // // // // // // // // // // // // // // // //
  new_tag['scroll_area_del'] = {
    // 必須変数
    vital: ["id"],

    pm: {
      id: ""
    },

    start: function (pm) {

      ary = pm.id.split(',');
      for (var i = 0; i < ary.length; i++) {
        $("#" + ary[i] + "_container").remove();
      }

      this.kag.ftag.nextOrder();
    }
  };

  // 作成したタグの登録  // // // // // // // // // // // // // // // // // //
  for (var key in new_tag) {
    var tag = new_tag[key];
    tag.kag = TYRANO.kag;
    TYRANO.kag.ftag.master_tag[key] = tag;
  };

}());