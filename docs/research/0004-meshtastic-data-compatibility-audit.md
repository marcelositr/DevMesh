# Auditoria de compatibilidade dos dados Meshtastic

- **Estado:** plano de auditoria, não implementação completa.
- **Objetivo:** preservar a compatibilidade com firmware e apps Meshtastic normais, sem exigir mudanças do usuário.
- **Método:** cruzar (1) documentação oficial, (2) código/esquemas dos projetos oficiais e (3) implementações clientes/ecossistema; registrar divergências antes de decidir.

## Fontes e política de versões

- Documentação MQTT: https://meshtastic.org/docs/configuration/module/mqtt/
- Firmware MQTT atual: https://github.com/meshtastic/firmware/blob/develop/src/mqtt/MQTT.cpp
- Esquemas oficiais: https://github.com/meshtastic/protobufs
- Cliente Python: https://github.com/meshtastic/python

A referência instalada no nó de teste é firmware 2.7.26.54e0d8d. A pesquisa de 2026 também encontra firmware 2.8.1 como alpha e Protobufs 2.8.0 como versão publicada mais recente. Não atualizar firmware do usuário nem trocar a referência de compatibilidade automaticamente: usar uma versão estável como baseline de teste e adicionar versões novas em uma matriz separada. Confirmar os estados das versões novamente antes de cada alteração relevante.

## Famílias de dados a auditar

| Família | Exemplos | Política inicial |
|---|---|---|
| Mensagens | texto, destino, ID, canal, saltos | Encaminhar o envelope sem modificações |
| Posição | latitude/longitude, altitude, horário, fontes e precisão | Não registrar ou publicar coordenadas por padrão |
| Telemetria de dispositivo | bateria, tensão, utilização de canal, uptime | Preservar payload; não inventar campos ausentes |
| Telemetria ambiental e qualidade do ar | sensores disponíveis no firmware | Não presumir sensores; testar campos opcionais |
| Identidade e estado do nó | nome, ID, hardware, papel, versão | Minimizar identificadores pessoais nos logs |
| Vizinhos e enlace | NeighborInfo, RSSI/SNR quando fornecidos, saltos | Distinguir métricas observadas de métricas ausentes |
| Waypoints e mapas | posição compartilhada e MapReport | Não publicar localização externa sem opt-in explícito |
| Roteamento e confirmações | Routing, ACK/NACK, traceroute | Tratar como protocolo; não sintetizar respostas |
| Administração e módulos | configurações, comandos, dados específicos de módulos | Não executar, alterar ou retransmitir comandos nesta fase |
| Tipos desconhecidos | portnums/campos de versões futuras | Preservar bytes quando possível e não falhar só por desconhecer o tipo |

Esta matriz lista categorias possíveis, não garante que cada dispositivo ou versão envie todos esses dados.

## Fatos importantes encontrados

1. O envelope MQTT Protobuf transporta metadados e um MeshPacket; não é texto puro.
2. O firmware verifica se o canal permite downlink e pode descartar certos formatos de payload conforme a configuração de criptografia.
3. O MQTT pode incluir MapReport não cifrado quando o reporte de mapa está habilitado. A documentação oficial diz que ele pode conter nome, ID, posição com precisão configurada, altitude, hardware, papel, versão e parâmetros de rádio. Isso exige uma auditoria de privacidade própria, não apenas inspeção do canal cifrado.
4. Os esquemas evoluem: telemetria possui múltiplas famílias e novos tipos de hardware/sensor são adicionados. Não fixar uma lista rígida de campos como se fosse universal.
5. Cliente Python e firmware têm decodificadores para diferentes portnums; usar esses projetos como cruzamento, não como substituto dos esquemas oficiais.
6. Compatibilidade MQTT, compatibilidade Protobuf, decodificação do payload, comportamento do aplicativo e entrega física LoRa são resultados diferentes e devem ser reportados separadamente.

## Regras de desenho

- Encaminhamento transparente deve funcionar mesmo quando o DevMesh não consegue decifrar ou interpretar o payload.
- Nunca fabricar posição, RSSI, SNR, bateria ou timestamp ausentes.
- Não registrar PSKs, senhas, chaves privadas, coordenadas exatas nem payloads completos em logs/CI.
- Não enviar coordenadas para mapas públicos, MQTT público ou serviços externos por padrão.
- Não alterar IDs, canal, destino, saltos, ciphertext ou campos desconhecidos no caminho de encaminhamento.
- Testes sintéticos não provam aceitação pelo firmware ou transmissão LoRa.
- Não tratar nomes/IDs removidos como anonimização suficiente: coordenadas e identificadores persistentes também podem permitir rastreamento.

## Plano

### Fase A: CI sem hardware
- [x] Fixar Protobufs oficiais por tag e commit imutável no script de teste inicial.
- [x] Criar fixtures sintéticos iniciais para Position, Telemetry de dispositivo/ambiente/qualidade do ar, User, NeighborInfo, Waypoint e MapReport, usando Protobufs v2.8.0 fixado por commit.
- [x] Implementar no CI decode/encode dos fixtures, round-trip binário, payload vazio, omissão do booleano false padrão e rejeição de mensagem truncada.
- [x] Acrescentar um campo Protobuf desconhecido sintético ao envelope no teste MQTT e verificar preservação byte a byte sem decodificar o payload no caminho de transporte.
- [x] Acrescentar testes de regressão da CLI para garantir que a chave do canal e uma chave inválida não apareçam em stdout/stderr; ler texto sensível pela entrada padrão para evitar expô-lo nos argumentos do processo.
- [x] Confirmar no CI os testes acima; o smoke check MQTT concluiu com sucesso em 2026-10-15.
- [x] Implementar matriz de compatibilidade de esquemas Protobuf para v2.7.26 e v2.8.0, com SHAs completos fixados e fixtures comuns de Position, Telemetry, User e MapReport.
- [x] Confirmar no CI a matriz de versões estáveis; o smoke check MQTT concluiu com sucesso em 2026-10-15. O teste é de esquemas Protobuf, não de compatibilidade integral entre versões de firmware.
- [x] Registrar a situação histórica da branch oficial `develop`: em 2026-10-12 ela ainda estava atrás da v2.8.0; em 2026-10-15 já estava 256 commits à frente da v2.8.0 (`a2a27f4f992e7d48d12cd5ee0dd486bac3f43e93`). A referência experimental de firmware é separada da matriz de Protobufs.
- [x] Acrescentar o snapshot da branch oficial `master`, fixado no commit `28f4f5f5c31c0323bfb86d890a1acaff15d1c4c6` (2026-10-12), como faixa experimental separada.
- [x] Confirmar no CI a matriz ampliada com o snapshot `master`; o smoke check MQTT do commit `4d362a6` concluiu com sucesso em 2026-10-15, incluindo as três revisões fixadas.
- [x] Revisar diferenças semânticas relevantes entre v2.8.0 e `master`; as limitações e riscos conhecidos estão registrados abaixo.
- [x] Investigar a falha da matriz experimental no CI de 2026-10-15: as duas versões estáveis passaram, mas a compilação de `master` não encontrou `google/protobuf/descriptor.proto`.
- [x] Corrigir o script para incluir diretórios padrão do sistema que contenham os arquivos `.proto` do Protobuf, sem ignorar erros de compilação nem enfraquecer os fixtures.


### Referências experimentais atuais: firmware e Protobufs

As referências abaixo pertencem a repositórios diferentes e não devem ser confundidas:

- **Firmware Meshtastic:** o commit de `develop` observado em 2026-10-15 é `a2a27f4f992e7d48d12cd5ee0dd486bac3f43e93`. Ele está 256 commits à frente do firmware v2.8.0 e 90 commits à frente da referência de release v2.8.1 usada anteriormente pela CI. A comparação inclui mudanças em `src/mesh/CryptoEngine.cpp`, `src/mesh/CryptoEngine.h` e `test/test_crypto/test_main.cpp`.
- **Protobufs:** o snapshot `master` fixado em `28f4f5f5c31c0323bfb86d890a1acaff15d1c4c6` continua sendo a revisão usada pela matriz de esquemas. A branch `develop` do repositório Protobufs estava no commit `ba16bfc731ab7e23f6be5a8e73358b1973e73822`, de 2026-07-01, portanto não é substituta do snapshot `master` mais recente.

A CI criptográfica foi ampliada para testar em faixas separadas a release v2.8.1 (`8e6a88d06f44cad26f1e8d7cd402939ccacb9b4c`) e o snapshot imutável de firmware `develop` (`a2a27f4f992e7d48d12cd5ee0dd486bac3f43e93`). Cada faixa executa a suíte upstream de criptografia e os cinco vetores sintéticos AES-CTR comparados byte a byte com OpenSSL. Isso não valida todas as plataformas de hardware, todos os modos criptográficos, nem entrega física LoRa; o resultado de cada faixa deve ser confirmado no CI antes de considerar a atualização validada.

### Comparação de campos entre Protobufs v2.7.26 e v2.8.0

A comparação dos campos declarados em `mesh.proto`, `telemetry.proto` e `mqtt.proto` identificou nas versões estáveis v2.7.26 e v2.8.0:

- `Position`: mesmos nomes e números de campo nas duas versões. A descrição de `ground_speed` mudou de m/s em v2.7.26 para km/h em v2.8.0. Como o tipo e o número do campo permanecem iguais, a codificação binária não detecta essa mudança semântica. Não converter unidades sem identificar a versão/origem do dado.
- `ServiceEnvelope` e `MapReport`: mesmos campos e números nas duas versões. `MapReport` inclui coordenadas, nome, identificadores indiretos e metadados do rádio, então continua sendo dado sensível mesmo sem o payload cifrado.
- `EnvironmentMetrics`: v2.8.0 acrescenta campos opcionais de ADC (`adc_voltage_ch0` a `adc_voltage_ch7`), temperaturas One-Wire (`one_wire_temperature_ch0` a `one_wire_temperature_ch7`) e dois campos de raios (`lightning_strike_count_1h`, `lightning_distance_km`).
- `AirQualityMetrics`: v2.8.0 acrescenta `pm_status_flags` no campo 26.
- As mensagens `DeviceMetrics`, `PowerMetrics`, `LocalStats`, `HealthMetrics`, `HostMetrics` e o contêiner `Telemetry` não mostraram diferenças de campos nesta comparação.

Implicação para o DevMesh: encaminhar envelopes sem reserializar continua sendo a opção mais segura para preservar campos que a versão local desconhece. Se no futuro houver decodificação analítica, campos novos devem ser opcionais e a unidade de cada métrica precisa ser explícita. Esta comparação cobre apenas os tipos listados nas duas revisões estáveis e no snapshot experimental fixados, não todos os esquemas nem todas as versões de firmware. O snapshot `master` foi adicionado como faixa experimental separada; passar seus fixtures comuns não o torna uma versão estável nem substitui uma comparação de semântica dos campos.

### Incidente de CI: includes do Protobuf no snapshot experimental

Em 2026-10-15, a execução `38791804483` passou pelas etapas anteriores, incluindo a validação de esquemas estáveis v2.7.26 e v2.8.0. A etapa da matriz falhou somente ao compilar o snapshot experimental `master`: `protoc` não encontrou `google/protobuf/descriptor.proto`, seguido por erros em cascata nos imports e tipos de configuração. A evidência aponta para uma falha na resolução de dependências de compilação, não para uma incompatibilidade demonstrada dos fixtures com o esquema experimental.

**Primeira correção e causa raiz:** a tentativa inicial de localizar `descriptor.proto` nos diretórios padrão não bastou. O log da nova execução (`38794149745`) repetiu a ausência do arquivo, mostrando que a imagem do runner instalava `protobuf-compiler`, mas não o pacote de desenvolvimento que fornece os `.proto` padrão. A matriz estável continuou passando; o erro ocorreu na compilação do snapshot experimental.

**Correção complementar aplicada:** o workflow `.github/workflows/mqtt-smoke.yml` agora instala `libprotobuf-dev` junto com `protobuf-compiler`. O script `scripts/check_meshtastic_schema_matrix.sh` mantém a inclusão explícita dos diretórios e uma falha clara caso `descriptor.proto` realmente esteja ausente. Não ignoramos erros de compilação nem removemos o snapshot experimental.

**Resultado da correção:** validado pelo smoke check MQTT `38794503973`, concluído com sucesso em 2026-10-15 no commit `4d362a6dab271b945541610bcdfdfc7f4fe6b516`. A execução incluiu a matriz das revisões v2.7.26, v2.8.0 e do snapshot experimental `master`. Isso confirma a compilação e os fixtures definidos, não compatibilidade integral do firmware.

### Diferenças relevantes entre v2.8.0 e o snapshot experimental master

A comparação oficial de commits entre v2.8.0 (`7b2464c9b8c1521f93852261e4123826e5b25e11`) e o snapshot `master` (`28f4f5f5c31c0323bfb86d890a1acaff15d1c4c6`) indica 149 commits à frente. A revisão de arquivos identificou mudanças que merecem acompanhamento:

- **Criptografia de canal:** `ChannelSettings.use_aead = 8` habilita experimentalmente AES-CCM com tag de autenticação de 12 bytes. A documentação do esquema diz que todos os nós do canal precisam estar configurados de forma compatível; não se deve presumir que AES-CTR e AES-CCM sejam intercambiáveis. O DevMesh deve continuar encaminhando o envelope opaco sem tentar decifrá-lo ou reserializá-lo.
- **Novo tipo de aplicação:** `PAGING_APP = 38`, com payload `PagingPacket`, para alertas que exigem confirmação humana. O classificador atual não interpreta semanticamente esse tipo futuro.
- **Telemetria ambiental:** novos tipos/campos incluem `SoilWaterMetrics`; o esquema reserva números e nomes antes presentes em `EnvironmentMetrics`. Isso reforça que consumidores não devem assumir que todas as métricas ambientais residem em uma única mensagem.
- **Roteamento e identidade de hardware:** o esquema adiciona campos de prova de ACK/NACK e novos valores de `HardwareModel`. Os valores desconhecidos devem continuar preservados no encaminhamento transparente.

**Limite da validação:** a matriz automatizada exercita fixtures comuns de Position, Telemetry, User e MapReport. Ela não valida a semântica de `use_aead`, não decodifica `PagingPacket`, não cobre todos os novos campos de telemetria/roteamento e não demonstra compatibilidade integral do firmware. Essas diferenças ficam registradas como riscos conhecidos, não como funcionalidades já suportadas pelo auditor.

### Fase B: observação somente leitura
- [x] Criar `scripts/audit_mqtt_capture.py`, uma ferramenta de observação limitada por tempo e quantidade, com assinatura MQTT somente leitura.
- [x] Garantir que o resumo não exponha tópicos completos, IDs de nós, nomes de canais, credenciais, coordenadas ou bytes de payload; não grava payloads nem publica mensagens.
- [x] Adicionar testes sintéticos para envelopes cifrados, metadados ausentes e famílias de tópicos opacas.
- [x] Tratar qualquer desconexão antes do encerramento controlado como falha, inclusive quando o código de motivo não indica falha; marcar a limpeza antes de chamar `disconnect()` para não confundir o encerramento esperado com uma queda. Teste sintético dedicado cobre o caso.
- [x] Cobrir rejeição de conexão pelo broker e rejeição da assinatura MQTT; ambos devem retornar falha e sinalizar corretamente os estados de conexão/assinatura.
- [x] Cobrir falha local imediata de `client.subscribe()` (antes da resposta do broker); a conexão permanece identificada separadamente, a assinatura fica como não aceita e a CLI retorna código 2. CI MQTT e referência criptográfica passaram no commit `a9edec3978d11dace4b573c46a814be5c54d679b` em 2026-10-15.
- [x] Cobrir a classificação sintética por `POSITION_APP` e `TELEMETRY_APP` quando o envelope já contém um payload decodificado; isso valida apenas a classificação pelo portnum, não a capacidade de identificar esses tipos dentro de ciphertext real.
- [x] Cobrir um portnum futuro desconhecido em envelope sintético; o auditor retorna `decoded_unknown_portnum` sem expor o número nem o payload. Isso valida tolerância do classificador, não a interpretação do tipo desconhecido.
- [x] Acrescentar fixture sintética de MapReport em tópico de mapa; a classificação informa apenas se campos de posição não nulos existem e descarta seus valores.
- [x] Acrescentar regressão de ponta a ponta da CLI para MapReport: confirma que coordenadas, canal e ID do nó não aparecem no relatório e que o cliente MQTT simulado não publica mensagens.
- [x] Reconhecer tópicos MQTT com raiz regional, como `msh/ANZ/2/e/...` e `msh/ANZ/2/map/...`, além do formato sem região; testes sintéticos cobrem ambos sem expor identificadores.
- [x] Cobrir um `MapReport` malformado e confirmar que o resumo retorna apenas um status genérico, sem reproduzir o payload.
- [ ] Confirmar em captura autorizada se MapReport aparece no broker real; ainda não há evidência de captura dessa família.
- [x] Executar a ferramenta no broker autorizado e registrar apenas o resumo sanitizado (captura real em 2026-10-15).
- [x] Confirmar que a captura real recebeu tráfego MQTT sem expor payload ou identificadores; a janela observada teve 11 envelopes e 774 bytes agregados. A classificação por família da captura anterior será revalidada com o classificador regional corrigido.
- [ ] Comparar famílias de dados esperadas com tipos realmente identificáveis; como os envelopes estavam cifrados, a captura não identifica se eram texto, posição, telemetria ou outros tipos.
- [x] Confirmar em broker Mosquitto descartável que o transporte MQTT preserva byte a byte um ServiceEnvelope sintético, inclusive um campo Protobuf desconhecido; CI automatizada passou.
- [ ] Medir em tráfego real se o encaminhamento aumenta tráfego inesperadamente; a captura de 11 envelopes não basta para determinar isso.

### Fase C: hardware
- [ ] Confirmar região de rádio apropriada antes de qualquer transmissão.
- [ ] Usar canal privado e mensagens de baixa frequência.
- [ ] Verificar separadamente MQTT, aceitação pelo firmware e recepção LoRa por segundo nó, se disponível.
- [ ] Testar posição/telemetria com dados controlados sem divulgar localização real.

## Ferramenta de observação somente leitura

O script `scripts/audit_mqtt_capture.py` assina um filtro MQTT por até 300 segundos e para após até 10.000 mensagens (padrões: 30 segundos e 500 mensagens). O padrão é `msh/#`; ele pode ser limitado com `--topic`. Credenciais, quando necessárias, são lidas das variáveis `DEVMESH_MQTT_USERNAME` e `DEVMESH_MQTT_PASSWORD`, nunca de argumentos. A opção `--tls` habilita TLS com validação pelas autoridades certificadoras do sistema; use-a quando o broker oferecer TLS, especialmente ao atravessar redes não confiáveis. Ela fica desativada por padrão para preservar a compatibilidade com brokers locais sem TLS; sem essa opção, a conexão não é criptografada pelo transporte MQTT. O resumo inclui somente contagens agregadas, categorias de tópicos, estado de conexão e volume total de bytes. Não publica, não grava payloads e não exibe tópicos completos ou metadados pessoais. Os estados são independentes: `connected` indica que a conexão foi estabelecida e não sofreu desconexão inesperada durante a observação; o encerramento local controlado ao final não o limpa. `subscription_accepted` indica se o broker aceitou a assinatura. Assim, uma assinatura recusada pode resultar em `connected: true`, `subscription_accepted: false` e código de saída 2. Falha na conexão ou qualquer desconexão antes do encerramento controlado retorna código 2, inclusive se o código de motivo recebido não estiver marcado como falha; a limpeza marca explicitamente o encerramento antes de chamar `disconnect()`, para que a desconexão local esperada não seja tratada como falha. O encerramento ocorre quando o prazo expira, o limite de mensagens é atingido ou ocorre falha de conexão/assinatura. Em tópicos de mapa como `msh/2/map/...` e `msh/ANZ/2/map/...`, a ferramenta valida o envelope e, para `MAP_REPORT_APP`, informa apenas se latitude/longitude têm valores não nulos; nunca registra os valores. O classificador também reconhece tópicos cifrados sob raízes regionais, como `msh/ANZ/2/e/...`, além de `msh/2/e/...`. Isso detecta somente presença de campos de posição, não valida precisão, identidade, política de opt-in nem publicação externa. Os testes de CI usam fixtures sintéticos e clientes MQTT simulados, incluindo recusa de conexão/assinatura e desconexão inesperada; não substituem teste de rede ou hardware. Em 2026-10-15, uma captura real autorizada de 60 segundos no broker doméstico conectou e teve a assinatura aceita; recebeu 11 envelopes MQTT (774 bytes agregados), sem salvar payloads nem publicar mensagens. Como a versão usada na captura ainda não reconhecia raízes regionais como `msh/ANZ/2/e/...`, não considero a classificação de família daquela captura revalidada. Repetir a captura com o classificador corrigido fica pendente para a etapa de validação real. A contagem agregada confirma que havia tráfego MQTT durante a janela, mas não revela por si só as famílias internas dos payloads. Uma observação sem mensagens é inconclusiva, não prova ausência de tráfego.

## Implementação inicial de CI

O script `scripts/check_meshtastic_data_compatibility.sh` cria e valida fixtures sintéticos contra os esquemas oficiais Protobufs v2.8.0, fixados por tag e commit. O script `scripts/check_meshtastic_schema_matrix.sh` compara os tipos comuns Position, Telemetry, User e MapReport entre os esquemas v2.7.26 e v2.8.0 e inclui o snapshot experimental `master` de 2026-10-12, todos fixados por SHA. Também cobre payload vazio, omissão do booleano `false` padrão em MapReport e rejeição de mensagem truncada. O teste MQTT de downlink acrescenta um campo desconhecido sintético e confirma que o broker preserva todos os bytes sem tentar interpretar o envelope. Testes de CLI verificam que a chave não seja exibida nos logs e que o texto sensível possa ser fornecido por stdin, sem colocá-lo nos argumentos do processo. Essas verificações precisam passar no CI antes de serem consideradas validadas; são testes sintéticos e não decodificam tráfego real nem provam que todos os campos são enviados pelo firmware.

## Resultado CI confirmado

Em 2026-10-15, no commit `876e9034b7b12155f77cca1cdb99f2ca9c9793bd`, o MQTT smoke check passou na execução [#175](https://github.com/marcelositr/DevMesh/actions/runs/38826458816), incluindo transporte MQTT, fixtures de localização/telemetria, matriz Protobuf v2.7.26/v2.8.0 e snapshot experimental `master`, modelo AES-CTR e verificações isoladas de autenticação/ACL. A CI criptográfica passou nas duas referências fixadas na execução [#138](https://github.com/marcelositr/DevMesh/actions/runs/38826458820): firmware release v2.8.1 e snapshot `develop` de 2026-10-15. Em ambas, a suíte upstream, cinco vetores AES-CTR comparados byte a byte com OpenSSL e a validação sintética Protobuf/MQTT concluíram com sucesso. Isso confirma somente os testes automatizados executados, não a recepção de mensagens em hardware real nem a transmissão LoRa.

## Critério de aceitação

Declarar apenas **compatibilidade de encaminhamento MQTT** quando envelopes forem preservados e testes de transporte passarem. Declarar compatibilidade de cada família de dados somente após fixtures oficiais validados e evidência apropriada. Não afirmar compatibilidade total com Meshtastic a partir de CI sintético isolado.

## Fontes consultadas para a primeira análise

- Documentação MQTT oficial: https://meshtastic.org/docs/configuration/module/mqtt/
- Firmware MQTT oficial: https://github.com/meshtastic/firmware/blob/develop/src/mqtt/MQTT.cpp
- Esquemas MQTT: https://github.com/meshtastic/protobufs/blob/master/meshtastic/mqtt.proto
- Esquemas de telemetria: https://github.com/meshtastic/protobufs/blob/master/meshtastic/telemetry.proto
- Esquemas de malha e posição: https://github.com/meshtastic/protobufs/blob/master/meshtastic/mesh.proto
- Cliente Python: https://github.com/meshtastic/python
- Lançamentos de firmware: https://github.com/meshtastic/firmware/releases
- Lançamentos Protobuf: https://github.com/meshtastic/protobufs/releases


### Raiz MQTT no construtor de downlink

O firmware oficial pode acrescentar o sufixo regional à raiz quando usa o servidor e a raiz padrão; em servidores personalizados, a raiz configurada pelo usuário prevalece. Para evitar presumir que toda instalação usa `msh`, o construtor `scripts/build_mqtt_downlink.py` aceita `--root-topic` (padrão `msh`) e valida o valor antes de compor o tópico. Por exemplo, uma instalação configurada explicitamente com raiz `msh/ANZ` pode gerar tópicos sob `msh/ANZ/2/e/...`. Isso altera apenas o tópico do envelope local gerado; não conecta ao broker nem transmite. O comportamento precisa ser confirmado pela CI antes de ser considerado validado.
