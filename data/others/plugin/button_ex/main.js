;(function () {
    /**
     * TODO :
     * - activeimg, autoimg, skipimg 対応
     * - disableimg実装再検討
     *
     */

    /**
     * nameパラメータをclassに変換
     * @param {String} name
     * @returns String
     */
    const name2class = (name = "") => {
        let cssclass = $.replaceAll(name, ",", ".")
        return cssclass
    }

    /**
     * 文字列を変数への参照に変換
     * @param {String} str
     * @returns {Object}
     */
    str2var = function (str) {
        let ary = str.replace(/\]/g, "").split(/\.|\[/g)
        let variable = window
        if (ary[0] === "f") {
            variable = TYRANO.kag.stat
        } else if (ary[0] === "sf" || ary[0] === "tf") {
            variable = TYRANO.kag.variable
        } else if (ary[0] === "TG") {
            variable = TYRANO.kag
        }
        ary.forEach(function (key) {
            key = key.replace(/"|'/g, "")
            variable = variable[key]
        })
        return variable
    }

    const setObserver = (parent_button, j_button) => {
        const observe = new MutationObserver(() => {
            j_button.css({
                background: `url(${parent_button.attr("src")})`,
            })
        })

        observe.observe(parent_button[0], {
            attributes: true,
        })
    }

    /**
     * ボタン機能拡張
     */
    tyrano.plugin.kag.tag.button_ex = {
        vital: ["name"],
        pm: {
            name: "", //ボタンのname
            enterimg: "", //マウスオーバー時の画像
            enter_fade: "0", //マウスオーバー時画像切り替え時間
            clickimg: "", //クリック時画像切り替え
            tip: "", //ツールチップ画像パス
            tip_pos: "", //ツールチップ位置（top, bottom, left, right, static）
            tip_margin: "0", //ツールチップとボタンの間隔
            tip_fade: "0", //ツールチップフェード時間
            tip_method: "fadeIn", //ツールチップ表示/非表示タイプ（bgタグmethodと同じ）
            tip_x: "0", //tip_pos=staticの時のツールチップ横位置
            tip_y: "0", //tip_pos=staticの時のツールチップ縦位置
            disableimg: "", //ボタン無効化する条件式
            disable: "", //ボタン無効化する条件式
            alpha: "0", //透明部分無効
        },

        start: function (pm) {
            var that = TYRANO
            var self = this
            var csscls = name2class(pm.name)
            var parent_button = $("img." + csscls)
            var j_button = $("<img />")

            if (parent_button.length == 0) {
                alert("親となるボタンがありません。nameパラメータは正しく指定されていますか？　対象：" + pm.name)
            }

            pm.p_top = parent_button.css("top")
            pm.p_left = parent_button.css("left")
            pm.p_width = 0
            pm.p_height = 0
            pm.src = parent_button.attr("src")

            const _relative = "../others/plugin/button_ex/blank.png"
            const _absolute = "./data/others/plugin/button_ex/blank.png"

            const parent_json = JSON.parse(parent_button.attr("data-event-pm"))
            parent_button.attr("data-event-pm", JSON.stringify(parent_json))

            j_button.attr("src", _absolute)

            let button_set = function (j_button, parent_button, pm) {
                //透明度取得用
                let context = null
                if (pm.alpha !== "0") {
                    context = self.setCanvas(pm)
                }

                j_button.css({
                    position: "absolute",
                    "z-index": 99999999,
                    top: pm.p_top,
                    left: pm.p_left,
                    width: pm.p_width,
                    height: pm.p_height,
                    "will-change": "background transition animation",
                    "background-image": "url(" + pm.src + ")",
                    "background-repeat": "no-repeat",
                    "background-size": "100% 100%",
                    width: pm.p_width + "px",
                    height: pm.p_height + "px",
                    transition: pm.enter_fade + "ms",
                })
                parent_button.css({
                    width: pm.p_width + "px",
                    height: pm.p_height + "px",
                    opacity: 0,
                })
                self.kag.setElmCursor(j_button, "pointer")

                $.setName(j_button, pm.name)
                if (parent_button.hasClass("fixlayer")) {
                    j_button.addClass("fixlayer")
                }
                that.kag.event.addEventElement({
                    tag: "button_ex",
                    j_target: j_button,
                    pm: pm,
                })
                parent_button.after(j_button)
                self.setEvent(j_button, pm)
                that.kag.ftag.nextOrder()
            }

            parent_button.on(
                "transitionend",
                function () {
                    parent_button.off("transitionend")
                    pm.p_width = parent_button.css("width").replace("px", "")
                    pm.p_height = parent_button.css("height").replace("px", "")

                    if (pm.p_width == 0) {
                        const getWidthReplay = function () {
                            console.error("button_ex getWidthReplay")
                            setTimeout(() => {
                                pm.p_width = parent_button.css("width").replace("px", "")
                                pm.p_height = parent_button.css("height").replace("px", "")
                                //alert("button_ex test")
                                if (pm.p_width != "0") {
                                    button_set(j_button, parent_button, pm)
                                } else {
                                    //また取得できていない場合は再帰処理
                                    getWidthReplay()
                                }
                            }, 100)
                        }
                        //この時点でwidth取得できていない場合は100ミリ秒後に再取得
                        getWidthReplay()
                    } else {
                        button_set(j_button, parent_button, pm)
                    }
                }.bind(this)
            )

            //トランジション発生させてCSS適用タイミングを拾う
            //位置の変更だと動きが見えてしまうので透明度に変更
            parent_button.css({
                transition: "5ms",
                //top: "+=1px",
                opacity: 0.99,
            })
        },

        setEvent: function (j_button, pm) {
            const that = this
            const self = tyrano.plugin.kag.tag.button_ex
            const csscls = name2class(pm.name)
            const parent_button = $("img." + csscls + ":first")

            const _ppm = JSON.parse(parent_button.attr("data-event-pm"))

            setObserver(parent_button, j_button)

            //ボタン活性／非活性切り替え
            let prevFlg = false
            const rfa = (timestamp) => {
                if (pm.disable !== "" && pm.disableimg != "") {
                    const isFlag = that.kag.embScript(pm.disable)
                    if (prevFlg !== isFlag) {
                        prevFlg = isFlag
                        if (isFlag) {
                            if (pm.disableimg != "") {
                                parent_button.attr({
                                    src: `./data/image/${pm.disableimg}`,
                                })
                            }
                        } else {
                            parent_button.attr({
                                src: `${pm.src}`,
                            })
                        }
                    }
                }
                starttime = timestamp
                requestAnimationFrame(rfa)
            }
            requestAnimationFrame(rfa)

            j_button.hover(
                function (ev) {
                    TYRANO.kag.variable.tf._button_ex_tip = true
                    //ボタン無効化
                    if (that.kag.embScript(pm.disable)) {
                        self.kag.setElmCursor(j_button, "default")

                        ev.stopPropagation()
                        return false
                    } else {
                        self.kag.setElmCursor(j_button, "pointer")
                    }

                    //ツールチップ表示
                    if (pm.tip != "") {
                        var p_top = parseInt(parent_button.css("top").replace("px", ""))
                        var p_left = parseInt(parent_button.css("left").replace("px", ""))
                        var p_right = parseInt(parent_button.css("right").replace("px", ""))
                        var p_bottom = parseInt(parent_button.css("bottom").replace("px", ""))
                        var p_width = parseInt(parent_button.css("width").replace("px", ""))
                        var p_height = parseInt(parent_button.css("height").replace("px", ""))

                        $(".__tip").remove()
                        var tip = $("<img />")
                        var fix = TYRANO.kag.layer.getLayer("fix")
                        fix.append(tip)
                        tip.attr("src", "./data/image/" + pm.tip)
                        tip.css({
                            top: "-1000px",
                            transition: "1ms all",
                            opacity: 0,
                            display: "inline-block",
                            position: "relative",
                        })
                        tip.on("transitionend", function () {
                            tip.off("transitionend")

                            tip.addClass("__tip")
                            tip.addClass("fixlayer")
                            var t_width = parseInt(tip.css("width").replace("px", ""))
                            var t_height = parseInt(tip.css("height").replace("px", ""))
                            var t_margin = parseInt(pm.tip_margin)
                            var t_spread = {}
                            var opt = {}
                            if (pm.tip_pos == "top") {
                                opt = {
                                    top: "",
                                    position: "absolute",
                                    bottom: p_bottom + p_height + t_margin + "px",
                                    left: p_left + (p_width - t_width) / 2 + "px",
                                }
                            } else if (pm.tip_pos == "right") {
                                opt = {
                                    position: "absolute",
                                    top: p_top + (p_height - t_height) / 2 + "px",
                                    left: p_left + p_width + t_margin + "px",
                                }
                            } else if (pm.tip_pos == "bottom") {
                                opt = {
                                    top: "",
                                    position: "absolute",
                                    bottom: p_bottom - p_height - t_margin + "px",
                                    left: p_left + (p_width - t_width) / 2 + "px",
                                }
                            } else if (pm.tip_pos == "left") {
                                opt = {
                                    position: "absolute",
                                    top: p_top + (p_height - t_height) / 2 + "px",
                                    right: p_right + p_width + t_margin + "px",
                                }
                            } else if (pm.tip_pos == "static") {
                                opt = {
                                    position: "absolute",
                                    top: pm.tip_y + "px",
                                    left: pm.tip_x + "px",
                                }
                            }
                            opt["z-index"] = 999999999
                            opt["transition"] = "none"
                            opt["transform"] = ""
                            opt["opacity"] = 1
                            opt["pointer-events"] = "none"
                            tip.css(opt)
                            $.trans(pm.tip_method, tip, pm.tip_fade, "show", function () {
                                //既にマウスがボタンから離れていたら
                                if (TYRANO.kag.variable.tf._button_ex_tip == false) {
                                    tip.remove()
                                }
                            })
                            //この時点でtipが複数表示されていたら最後以外を消す
                            if ($(".__tip").length > 1) {
                                $(".__tip:not(:last)").remove()
                            }
                        })
                        tip.css({
                            top: "-=1px",
                            //opacity: 0.01,
                        })
                    }
                    parent_button.trigger("mouseover")
                },
                function (ev) {
                    //ボタン無効化
                    if (that.kag.embScript(pm.disable)) {
                        ev.stopPropagation()
                        return false
                    }

                    self.kag.setElmCursor(j_button, "pointer")
                    TYRANO.kag.variable.tf._button_ex_tip = false

                    //ツールチップ消去
                    var tip = $(".__tip")
                    $.trans(pm.tip_method, tip, pm.tip_fade, "hide", function () {
                        tip.remove()
                    })
                    parent_button.trigger("mouseleave")
                }
            )

            j_button.on("mousemove", function (ev) {
                if (pm.alpha === "0") {
                    return false
                }
                const canvas = self.setCanvas(pm)

                //ボタン画像内でマウスカーソル移動させた場合、透明度を都度取得
                const alpha = self.getPosition(ev, canvas)
                if (alpha < pm.alpha) {
                    //透明度あり→なしへ移動
                    j_button.trigger("mouseleave")
                    return false
                } else {
                    //透明度なし→ありへ移動
                    j_button.trigger("mouseenter")
                    return false
                }
            })

            j_button.on("click", function (ev) {
                const canvas = self.setCanvas(pm)
                const alpha = self.getPosition(ev, canvas)
                if (alpha < pm.alpha) {
                    //透明度なし部分はクリック無効
                    return false
                }
                //ボタン無効化
                if (that.kag.embScript(pm.disable)) {
                    ev.stopPropagation()
                } else {
                    //TIP画像削除
                    $(".__tip").remove()
                    parent_button.trigger("tap")
                    parent_button.trigger("click")
                }
            })
        },
        //透明度取得
        getPosition: function (event, canvas) {
            if (canvas !== null) {
                const rect = event.target.getBoundingClientRect()
                const left = event.clientX - rect.left
                const top = event.clientY - rect.top
                //画面サイズ可変のため拡大率取得
                const scale = parseFloat($(".tyrano_base").css("transform").replace("matrix(", "").replace(")", "").split(",")[0])
                const alpha = canvas.getImageData(left / scale, top / scale, 1, 1)
                return alpha.data[3]
            } else {
                return 0
            }
        },
        //キャンバスを準備
        setCanvas: function (pm) {
            const csscls = name2class(pm.name)
            const img = new Image()
            img.src = pm.src
            const canvas = document.createElement("canvas")
            const context = canvas.getContext("2d")
            context.canvas.width = pm.p_width
            context.canvas.height = pm.p_height
            context.drawImage(img, 0, 0, parseInt(pm.p_width), parseInt(pm.p_height))
            return context
        },
    }
    tyrano.plugin.kag.ftag.master_tag.button_ex = tyrano.plugin.kag.tag.button_ex
    tyrano.plugin.kag.ftag.master_tag.button_ex.kag = tyrano.plugin.kag

    //ロード復帰時
    tyrano.plugin.kag.tag.button_ex_restore = {
        vital: [],
        pm: {},
        start: function () {
            //ボタン画像をもとに戻しておく
            let elms = $("img[data-event-tag=button]+img[data-event-tag=button_ex]")
            elms.each(function () {
                const ppm = JSON.parse($(this).prev().attr("data-event-pm"))
                $(this)
                    .prev()
                    .css({
                        "background-image": `url(./data/image/${ppm.graphic})`,
                    })
            })
            //ツールチップ消去
            $(".__tip").remove()
            TYRANO.kag.ftag.nextOrder()
        },
    }
    tyrano.plugin.kag.ftag.master_tag.button_ex_restore = tyrano.plugin.kag.tag.button_ex_restore
    tyrano.plugin.kag.ftag.master_tag.button_ex_restore.kag = tyrano.plugin.kag
})()
