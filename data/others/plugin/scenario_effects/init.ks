; scenario_effects - simple scenario UI/effect macros
[loadjs storage="plugin/scenario_effects/scenario_effects.js"]

[macro name=rect_show]
[iscript]
window.scenarioEffects.showRect(mp);
[endscript]
[endmacro]

[macro name=rect_hide]
[iscript]
window.scenarioEffects.hideRect(mp);
[endscript]
[endmacro]

[macro name=rect_clear]
[iscript]
window.scenarioEffects.clearRects();
[endscript]
[endmacro]

[macro name=chara_tilt]
[iscript]
window.scenarioEffects.tiltChara(mp);
mp._scenario_effects_wait = window.scenarioEffects.getWaitTime(mp, 180);
[endscript]
[wait time="&mp._scenario_effects_wait"]
[endmacro]

[macro name=chara_untilt]
[iscript]
window.scenarioEffects.untiltChara(mp);
mp._scenario_effects_wait = window.scenarioEffects.getWaitTime(mp, 180);
[endscript]
[wait time="&mp._scenario_effects_wait"]
[endmacro]

[macro name=chara_tilt_bounce]
[iscript]
window.scenarioEffects.tiltBounceChara(mp);
mp._scenario_effects_wait = window.scenarioEffects.getBounceWaitTime(mp, 120);
[endscript]
[wait time="&mp._scenario_effects_wait"]
[endmacro]

[return]
