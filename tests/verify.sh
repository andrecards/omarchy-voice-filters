#!/usr/bin/env bash
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
run="$plugin_dir/scripts/voicefilters-run"
target="alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source"

bash -n "$run" "$plugin_dir/scripts/voicefilters-ctl" "$plugin_dir/scripts/voicefilters-probe"

PLUGIN_DIR="$plugin_dir" node <<'JS'
const fs = require("node:fs");
const vm = require("node:vm");
const assert = require("node:assert/strict");
const code = fs.readFileSync(process.env.PLUGIN_DIR + "/Model.js", "utf8");
const model = {};
vm.runInNewContext(code, model);
assert.equal(model.normalizePreset("dictation"), "dictation");
for (const engine of ["auto", "rnnoise", "deepfilter"]) {
  assert.equal(model.resolveEngine("dictation", engine, true, true), "clean");
  assert.equal(model.setupGuide(engine, false, false, "dictation").needed, false);
}
assert.equal(model.eqCurveForPreset("dictation", {meetingEq: "warm"}), "");
assert.equal(model.eqTrimForPreset("dictation", {meetingEqBodyDb: 6}).body, 0);
// Exercita a navegação real do painel, incluindo confirmação sem voltar ao perfil ativo.
const panel = fs.readFileSync(process.env.PLUGIN_DIR + "/Panel.qml", "utf8");
const cursor = {tuneOpen: false, cursorActive: true, focusSection: "presets", presetIndex: 0,
  presets: ["dictation", "meeting", "podcast", "clean"].map(value => ({value})),
  displaySources: [{name: "mic"}], sourceIndex: 0, service: {preset: "dictation"}};
cursor.choosePreset = value => { cursor.chosen = value; };
vm.createContext(cursor);
for (const name of ["ensureCursor", "moveCursor", "activateCursor"]) {
  const match = panel.match(new RegExp("  function " + name + "\\([^]*?\\n  }"));
  assert.ok(match, name);
  vm.runInContext(match[0], cursor);
}
cursor.moveCursor(1, 0); assert.equal(cursor.presetIndex, 1);
cursor.moveCursor(1, 0); assert.equal(cursor.presetIndex, 1);
cursor.moveCursor(0, 1); assert.equal(cursor.presetIndex, 3);
cursor.moveCursor(-1, 0); assert.equal(cursor.presetIndex, 2);
cursor.moveCursor(-1, 0); assert.equal(cursor.presetIndex, 2);
cursor.activateCursor(); assert.equal(cursor.chosen, "podcast");
cursor.moveCursor(0, -1); assert.equal(cursor.presetIndex, 0);
cursor.moveCursor(0, -1); assert.equal(cursor.focusSection, "header");
cursor.moveCursor(0, 1); assert.equal(cursor.presetIndex, 0);
cursor.moveCursor(0, 1); cursor.moveCursor(0, 1);
assert.equal(cursor.focusSection, "sources");
cursor.moveCursor(0, -1); assert.equal(cursor.presetIndex, 2);
// O retorno usa somente uma leitura da fonte filtrada e uma saída explícita.
assert.equal(model.monitorCommand("").length, 0);
assert.equal(model.monitorCommand("voicefilters.aec.sink").length, 0);
const cmd = model.monitorCommand("alsa_output.test");
assert.equal(cmd[0], "pw-loopback");
assert.equal(cmd[cmd.indexOf("--capture") + 1], "voicefilters");
assert.equal(cmd[cmd.indexOf("--playback") + 1], "alsa_output.test");
assert.equal(JSON.parse(cmd[cmd.indexOf("--capture-props") + 1])["node.dont-reconnect"], true);
const preview = {monitorWanted: false, monitoring: false, monitorAvailable: true,
  monitorError: "", monitorSink: "alsa_output.test", Model: model,
  monitorProcess: {running: false}, monitorTimeout: {stop() { this.stopped = true; }}};
vm.createContext(preview);
for (const name of ["stopMonitor", "toggleMonitor"]) {
  const match = panel.match(new RegExp("  function " + name + "\\([^]*?\\n  }"));
  assert.ok(match, name); vm.runInContext(match[0], preview);
}
preview.toggleMonitor(); assert.equal(preview.monitorProcess.running, true);
preview.toggleMonitor(); assert.equal(preview.monitorProcess.running, false);
assert.equal(preview.monitorWanted, false);
preview.monitorAvailable = false; preview.toggleMonitor();
assert.equal(preview.monitorProcess.running, false);
assert.match(panel, /onMonitorAvailableChanged: if \(!monitorAvailable\) stopMonitor\(\)/);
assert.match(panel, /if \(!opened\) \{\s+stopMonitor\(\)/);
assert.match(panel, /interval: 60000; onTriggered: root.stopMonitor\(\)/);
const gentle = model.qualityParams("podcast", "good");
assert.equal(gentle.vad, 40);
assert.equal(gentle.grace, 500);
assert.equal(gentle.retro, 60);
const meeting = model.qualityParams("meeting", "better");
assert.equal(meeting.vad, 40);
assert.equal(meeting.grace, 500);
assert.equal(meeting.retro, 60);
assert.equal(model.sharedGainPatch("capture", 3).captureGainDb, 3);
assert.equal(model.gainDbToLinear(0), 1);
assert.equal(model.friendlyDeviceLabel("Alder Lake PCH-P High Definition Audio Controller Digital Microphone"), "Built-in microphone");
assert.equal(model.friendlyDeviceLabel("Alder Lake PCH-P High Definition Audio Controller Headset Mono Microphone"), "Headset microphone");
JS

podcast=$("$run" --dump --preset podcast --quality good --engine rnnoise --eq neutral --target "$target" --dir "$plugin_dir")
[[ $podcast == *'"VAD Threshold (%)" = 40.0'* ]]
[[ $podcast == *'"VAD Grace Period (ms)" = 500'* ]]
[[ $podcast == *'"Retroactive VAD Grace (ms)" = 60'* ]]
[[ $podcast == *'"cr" = 1.5'* ]]
[[ $podcast == *'"mk" = 1.4'* ]]
[[ $podcast == *'"th" = 0.891'* ]]

meeting=$("$run" --dump --preset meeting --quality better --engine rnnoise --eq neutral --target "$target" --dir "$plugin_dir")
[[ $meeting == *'"VAD Threshold (%)" = 40.0'* ]]
[[ $meeting == *'"VAD Grace Period (ms)" = 500'* ]]
[[ $meeting == *'"Retroactive VAD Grace (ms)" = 60'* ]]
[[ $meeting == *'"cr" = 1.8'* ]]

clean=$("$run" --dump --preset clean --engine clean --target "$target" --dir "$plugin_dir")
[[ $clean != *'name = denoise'* ]]
[[ $clean != *'name = comp'* ]]

# Ditado não deve herdar supressão, cancelamento de eco ou coloração de outro perfil.
for engine in auto rnnoise deepfilter clean; do
  for quality in good better best; do
    dictation=$("$run" --dump --preset dictation --quality "$quality" --engine "$engine" --eq bright --eq-body-db 6 --target "$target" --dir "$plugin_dir")
    [[ $dictation == *'"Freq" = 60.0'* ]]
    [[ $dictation != *'name = denoise'* ]]
    [[ $dictation != *'name = comp'* ]]
    [[ $dictation != *'name = eq_body'* ]]
    [[ $dictation != *'libpipewire-module-echo-cancel'* ]]
    [[ $dictation == *'output = "hp:Out" input = "outgain:In 1"'* ]]
  done
done

echo "Verificação do DSP e dos níveis: OK"
