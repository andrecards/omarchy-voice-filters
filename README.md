# Filtros de Voz para Omarchy

Plugin de barra e serviço para Omarchy Shell. Ele publica a entrada virtual `voicefilters` no PipeWire e oferece perfis e controles de áudio no painel **Filtros de Voz**. O painel nativo **Áudio** seleciona essa entrada como selecionaria qualquer microfone.

## Instalação local

```bash
omarchy plugin add /home/admin/Projects/ferramentas-sistema/omarchy-voice-filters/plugin --enable
omarchy restart shell
```

Dependências: PipeWire, Omarchy Shell e `noise-suppression-for-voice` para RNNoise. `lsp-plugins` fornece compressor leve e limitador. DeepFilterNet é opcional; quando instalado, pode ser selecionado no painel. O plugin detecta motores ausentes.

Após atualizar o código do plugin, reinicie o Shell. Uma recarga parcial pode conservar o `Model.js` antigo na memória e reaplicar parâmetros anteriores ao nó PipeWire.

## Uso

Abra o widget **Filtros de Voz** na barra. Em **Perfil**, escolha:

- **Gravação**: denoise RNNoise, sem cancelamento de eco. É o padrão para ditado.
- **Reunião**: denoise e cancelamento de eco WebRTC para chamadas com alto-falantes.
- **Natural**: sem denoise neural e sem compressor; preserva o ambiente.

Na tela de ajustes, escolha o motor e a intensidade **Suave**, **Equilibrado** ou **Forte**. Para uma voz distante ou captada pelo microfone interno, comece em **Gravação / Suave / Neutro**. Em RNNoise, a intensidade muda sobretudo a porta de detecção de fala; o algoritmo de redução de ruído permanece ativo. **Forte** pode cortar sílabas fracas.

Os controles **Entrada** e **Saída** variam de -12 a +12 dB. Eles atuam ao vivo; comece em 0 dB e aumente somente depois de conferir o nível gravado. O ganho de entrada ocorre antes do filtro. O ganho de saída controla o sinal entregue aos aplicativos.

Comandos opcionais:

```bash
omarchy-shell admin.voicefilters tune
omarchy-shell admin.voicefilters preset podcast
omarchy-shell admin.voicefilters gain capture 0
omarchy-shell admin.voicefilters gain output 0
omarchy-shell admin.voicefilters off
omarchy-shell admin.voicefilters on
```

Se o Superwhisper estiver instalado, escolha `voicefilters` como microfone por `superwhisper audio select voicefilters`. Ao desligar o widget, o serviço restaura o microfone físico anterior como padrão do sistema.

## Verificação

```bash
bash tests/verify.sh
omarchy plugin validate .
omarchy-shell admin.voicefilters status
wpctl status
```

O teste automatizado confere as opções do DSP e o grafo gerado. A qualidade percebida depende do microfone, da distância e do ambiente: compare uma frase gravada diretamente e via `voicefilters`, nas mesmas condições, antes de elevar ganho ou intensidade.

## Origem

Projeto derivado de [Omavoice](https://github.com/gigasolo/omavoice), sob licença MIT. A licença original está em `LICENSE`; o registro de atribuição do projeto local está em `../NOTICE`.
