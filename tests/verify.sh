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

echo "Verificação do DSP e dos níveis: OK"
