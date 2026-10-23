# Omarchy Voice Filters

A virtual PipeWire microphone with noise reduction, voice profiles, live gain controls, and an Omarchy bar panel. The output device is named `voicefilters`, so it can be selected in Superwhisper, meeting apps, recorders, or Omarchy's native Audio panel.

![Voice Filters panel](preview.png)

![Voice Filters settings](docs/settings.png)

## Install

```bash
omarchy plugin add https://github.com/andrecards/omarchy-voice-filters.git --enable
omarchy restart shell
```

The plugin needs Omarchy Shell and PipeWire. RNNoise uses `noise-suppression-for-voice`; the optional compressor and limiter use `lsp-plugins`. DeepFilterNet is optional. The panel identifies a missing processing engine and its package. It never installs packages itself.

Install `noise-suppression-for-voice` and, for compression and limiting, `lsp-plugins` through Omarchy's package menu. DeepFilterNet requires the optional `libdeep_filter_ladspa-bin` package from the AUR.

## Use

Open the Voice Filters bar widget and select a profile:

- **Recording** reduces noise without echo cancellation. It is the initial profile and usually suits dictation.
- **Meeting** adds WebRTC echo cancellation for calls played through speakers.
- **Natural** applies a high-pass filter and preserves ambient sound and music.

The tuning page offers engine selection, Gentle/Balanced/Strong processing, input and output gain from -12 to +12 dB, and a voice tone equalizer. Start at 0 dB gain. Strong processing can clip quiet syllables. If the physical microphone clips, lower its hardware input level first.

The plugin does not change the system default microphone on a new installation. Enable the default-input switch in the panel if you want applications to select it automatically. Otherwise select `voicefilters` in each application. The plugin restores the previous physical default when this option is turned off or the plugin is disabled.

Optional CLI controls:

```bash
omarchy-shell io.github.andrecards.voicefilters status
omarchy-shell io.github.andrecards.voicefilters tune
omarchy-shell io.github.andrecards.voicefilters preset podcast
omarchy-shell io.github.andrecards.voicefilters gain capture 0
omarchy-shell io.github.andrecards.voicefilters gain output 0
omarchy-shell io.github.andrecards.voicefilters off
omarchy-shell io.github.andrecards.voicefilters on
```

To use it in Superwhisper: `superwhisper audio select voicefilters`.

## Language

English is the base language. The plugin follows the language selected in Omarchy Setup > Language without a shell restart. Its `i18n/` catalogs currently provide English and Brazilian Portuguese; other languages fall back to English. English source labels alone are not machine translated by the Shell.

## Update and remove

```bash
omarchy plugin update io.github.andrecards.voicefilters
omarchy restart shell
omarchy plugin remove io.github.andrecards.voicefilters --yes
```

A full Shell restart after an update prevents stale QML or JavaScript code from keeping an old audio graph in memory. Before removal, select a physical microphone as the system default if the virtual one is active.

## Attribution and license

Based on [Omavoice](https://github.com/gigasolo/omavoice) by GigaSolo LLC. See [NOTICE](NOTICE) and [LICENSE](LICENSE) for the original MIT license and attribution.

## Perfil Ditado

O perfil **Ditado** aplica somente passa-altas de 60 Hz e os ganhos de entrada e saída. Ele ignora o motor de redução de ruído, a intensidade e a equalização selecionados nos outros perfis. Não usa gate, supressão neural, compressor ou cancelamento de eco; assim evita que esses processadores removam sílabas baixas. O ruído ambiente continua audível.

Selecione **Ditado** no painel ou execute `omarchy-shell io.github.andrecards.voicefilters preset dictation`. Comece com os dois ganhos em 0 dB. No Superwhisper, selecione `voicefilters` para usar esse áudio; selecionar o microfone físico ignora o plugin. O filtro não corrige palavras nem traduções: isso depende do reconhecedor e do pós-processamento. Compare uma mesma gravação antes e depois para avaliar o reconhecimento.

Validação do modelo e do grafo DSP: `bash tests/verify.sh`.

## Teste de voz

O botão **Ouvir minha voz** (atalho **T** com o painel aberto) reproduz o microfone filtrado na saída atual. Use fones para evitar retorno acústico. **Parar teste de voz**, fechar o painel, desligar o filtro, trocar o dispositivo ou iniciar uma captura `superwhisper-capture` encerra o retorno. Há também limite de 60 segundos.

O teste usa um único `pw-loopback`, criado somente durante a escuta, sem arquivos de áudio, mudanças no microfone padrão ou consultas periódicas. A captura do Superwhisper é observada por eventos do PipeWire. O retorno não é conectado à entrada de transcrição.
