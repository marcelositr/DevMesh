# Levantamento inicial de equipamento Meshtastic para o DevMesh

- **Tipo:** plano de levantamento técnico de hardware e tráfego
- **Estado:** planejado; coleta real ainda não concluída
- **Data de abertura:** 2026-10-13
- **Objetivo:** conhecer um nó físico Meshtastic antes de definir integrações, arquitetura operacional ou qualquer implementação do DevMesh.

## 1. Por que este levantamento vem primeiro

O DevMesh pretende oferecer infraestrutura MQTT independente e compatível com o ecossistema Meshtastic. Antes de implementar o broker ou serviços auxiliares, precisamos distinguir o que o equipamento realmente fornece, o que o firmware anuncia, o que circula na rede e o que poderá ser observado com segurança.

Este documento define o inventário e o método de coleta. **Não afirma que a coleta já foi executada, que os campos abaixo estão todos disponíveis no equipamento ou que a integração já funciona.** Os resultados observados serão adicionados depois, com data, versão de firmware e método de obtenção.

## 2. Equipamento de referência

A primeira coleta deve usar um equipamento físico que o responsável consiga conectar e inspecionar localmente. Há registros prévios de uso de uma **Heltec WiFi LoRa 32 V4**, com identificação de placa reportada como `HTIT-WB32LAF V.4.3`. Esse dado é uma pista inicial e deve ser confirmado diretamente no equipamento antes de ser tratado como resultado desta coleta.

Não confundir a placa Heltec com o **M5Stack Cardputer Adv K132-ADV**, outro equipamento mencionado anteriormente. O levantamento inicial deve escolher apenas um dispositivo para manter o escopo controlado. A Heltec é a candidata inicial por já ter sido usada com Meshtastic, mas a escolha final deve ser confirmada na sessão de coleta.

## 3. Inventário de hardware

Registrar apenas dados observados ou confirmados por documentação do fabricante:

- Fabricante, modelo comercial, revisão e marcações impressas na placa.
- Microcontrolador/SoC, arquitetura, revisão de silício, memória flash e PSRAM, quando aplicável.
- Rádio LoRa: transceptor, banda/frequência configurada, região, potência configurada e antena/conector.
- GPS/GNSS: presença, modelo do módulo se identificável, estado de detecção, disponibilidade de posição e fonte da informação.
- Sensores e periféricos: tela, botões, bússola, acelerômetro, sensores ambientais, LEDs, buzzer ou outros componentes, indicando separadamente os presentes fisicamente e os suportados pelo firmware.
- Alimentação: USB/bateria, tensão/corrente apenas se mensuradas com instrumento, estado de carga e comportamento observado.
- Interfaces disponíveis: USB serial, Bluetooth, Wi-Fi e outras interfaces confirmadas.
- Antena, caixa e montagem, somente quando relevantes para interpretar o ensaio de rádio.

Para cada item, registrar **valor**, **origem da evidência** (inscrição física, saída do firmware, ferramenta ou documento oficial), **data** e **grau de confiança**. Não inferir um componente apenas pelo nome comercial da placa.

## 4. Inventário de firmware e configuração

Coletar, quando disponível na interface local do Meshtastic:

- Nome/modelo da placa informado pelo firmware.
- Versão e hash/build do firmware.
- Versão do protocolo, se exposta pela ferramenta.
- Nome curto e nome longo do nó, com os valores anonimizados no relatório público quando necessário.
- Papel do nó (por exemplo, CLIENT ou ROUTER), sem alterá-lo para o ensaio.
- Região LoRa, preset/modo de canal, frequência/canal, largura de banda, spreading factor/coding rate se expostos, potência configurada e limite de saltos.
- Estado do GPS, precisão configurada para localização e disponibilidade de coordenadas.
- Interfaces habilitadas e estado de conexão, sem registrar chaves, senhas ou identificadores de pareamento.
- Configurações relevantes de telemetria, posição, módulos e canais, sem copiar chaves de canal.

A configuração deve ser somente lida. Não atualizar firmware, alterar canais, mudar potência ou modificar a função do nó como parte deste levantamento, salvo se isso for acordado separadamente.

## 5. O que o nó troca com a rede Meshtastic

Observar durante uma janela definida e registrar **tipo de pacote, momento aproximado, direção/contexto, campos visíveis, frequência de ocorrência e método de observação**. Os tipos a procurar incluem, se realmente aparecerem:

- Anúncios de nó e informações de usuário.
- Atualizações de posição e dados de GPS.
- Telemetria de bateria, tensão e outros sensores suportados.
- Mensagens de texto e confirmações de entrega.
- Informações de rota, saltos, RSSI/SNR e metadados de recepção quando a ferramenta os expuser.
- Informações de canal e configuração que a interface local permitir ler.
- Dados administrativos, respostas a solicitações e eventos de conexão.
- Tráfego relacionado a MQTT, se houver configuração/integração MQTT ativa e se esse tráfego puder ser observado sem expor segredos.

Não presumir que todo tipo de pacote estará presente. A ausência durante a janela observada significa apenas “não observado nesta coleta”, e não “inexistente no protocolo”.

### 5.1 Limites de observação

O levantamento deve distinguir:

1. **Estado local do dispositivo:** dados apresentados pela interface local/API serial/Bluetooth.
2. **Pacotes recebidos pelo nó:** tráfego que o dispositivo ou cliente local consegue expor.
3. **Tráfego visto por outro nó:** observação de rádio separada, se houver um segundo equipamento disponível.
4. **Tráfego encaminhado por MQTT:** dados realmente publicados/recebidos por um broker, apenas se essa função estiver configurada e puder ser examinada.

Essas fontes não são equivalentes. Uma interface local pode apresentar uma visão parcial e não representa necessariamente todos os pacotes transmitidos no canal de rádio.

## 6. Métricas de rádio e operação

Quando disponíveis sem interferir na rede, registrar:

- Horário de início e fim da observação, fuso horário e duração.
- Número de nós distintos vistos e número de eventos/pacotes observados por tipo.
- RSSI, SNR e número de saltos quando expostos pela ferramenta.
- Estado do dispositivo, reinicializações e uptime se disponíveis.
- Estado da alimentação e variação de bateria, se apresentada pelo firmware.
- Perdas, mensagens não confirmadas ou falhas de conexão apenas quando houver evidência observável.
- Ambiente do ensaio em termos gerais (interior/exterior, antena utilizada e obstáculos relevantes), sem publicar localização residencial exata.

Não gerar tráfego artificial em massa, não enviar mensagens repetitivas e não alterar a configuração de rádio para produzir números. O objetivo é caracterizar o comportamento normal, com tráfego mínimo.

## 7. Privacidade e segurança da coleta

- Não publicar chaves PSK, credenciais MQTT, tokens, dados de pareamento ou arquivos de configuração que contenham segredos.
- Não publicar coordenadas residenciais exatas, trajetos pessoais, números de telefone ou conteúdo privado de mensagens.
- Usar nomes/IDs anonimizados na versão pública quando a identificação do nó não for necessária ao objetivo técnico.
- Não tentar decifrar mensagens privadas nem coletar conteúdo de canais para os quais não haja autorização.
- Se for necessário demonstrar a estrutura de um pacote, usar campos redigidos ou dados de teste próprios.
- Manter qualquer registro bruto potencialmente sensível fora do repositório público; publicar somente um resumo sanitizado.
- Não tratar endereço MAC, identificador de nó ou posição como informação automaticamente anônima.

## 8. Plano de coleta

1. Confirmar qual equipamento físico será usado e fotografar/ler as marcações da placa, se útil.
2. Registrar a versão do firmware e os dados disponíveis na interface local, sem mudar a configuração.
3. Exportar ou anotar somente informações de diagnóstico que não contenham segredos.
4. Observar o nó em operação normal por uma janela curta definida antes de iniciar.
5. Classificar cada observação por fonte: dispositivo, firmware, ferramenta local, segundo nó ou broker MQTT.
6. Redigir/anonimizar dados sensíveis e separar claramente observações, inferências e itens não confirmados.
7. Atualizar este documento com resultados, data, ambiente e limitações da coleta.
8. Só então usar as evidências para definir requisitos de integração com o Mosquitto e eventuais serviços auxiliares.

## 9. Modelo para os resultados

Preencher durante a coleta, não por estimativa:

| Campo | Resultado | Fonte/evidência | Estado |
|---|---|---|---|
| Equipamento e revisão | Pendente | Inscrição física/documentação | Não coletado |
| SoC e memória | Pendente | Firmware/documentação confiável | Não coletado |
| Transceptor LoRa | Pendente | Marcação/documentação | Não coletado |
| Módulo GPS/GNSS | Pendente | Inspeção/firmware/documentação | Não coletado |
| Firmware e protocolo | Pendente | Interface local | Não coletado |
| Região e parâmetros de rádio | Pendente | Configuração local | Não coletado |
| Papel do nó | Pendente | Configuração local | Não coletado |
| Interfaces ativas | Pendente | Observação local | Não coletado |
| Tipos de pacote observados | Pendente | Captura/diagnóstico | Não coletado |
| Métricas RSSI/SNR/saltos | Pendente | Recepção reportada | Não coletado |
| Estado de bateria/uptime | Pendente | Firmware/instrumento | Não coletado |
| MQTT ativo e dados observáveis | Pendente | Configuração/observação autorizada | Não coletado |
| Limitações e questões em aberto | Pendente | Análise da coleta | Não coletado |

## 10. Critério de conclusão

O levantamento será considerado suficiente para a primeira decisão de arquitetura quando:

- O equipamento e o firmware estiverem identificados com evidências.
- As interfaces e os tipos de dados realmente observáveis estiverem listados.
- As limitações de visibilidade estiverem documentadas.
- Os dados sensíveis estiverem removidos da versão pública.
- Cada conclusão estiver classificada como observada, documentada por fonte, inferida ou ainda desconhecida.

O relatório não precisa descobrir tudo o que o protocolo Meshtastic pode transportar. Precisa estabelecer uma linha de base realista do que **este equipamento, com esta versão de firmware e neste ambiente**, expõe para uma futura integração.

## 11. Referências oficiais para consulta

As páginas abaixo são pontos de partida para conferir informações durante a coleta; não substituem a evidência obtida no dispositivo:

- [Documentação Meshtastic](https://meshtastic.org/docs/)
- [Repositório oficial Meshtastic](https://github.com/meshtastic)
- [Documentação MQTT do Meshtastic](https://meshtastic.org/docs/software/integrations/mqtt/)
- [Heltec Automation](https://heltec.org/)

**Estado atual:** plano de levantamento registrado. Nenhuma coleta de hardware ou tráfego foi executada como parte deste documento.
