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
- [x] Confirmar no CI a matriz de versões; o smoke check MQTT concluiu com sucesso em 2026-10-15. O teste é de esquemas Protobuf, não de compatibilidade integral entre versões de firmware.
- [ ] Manter baseline estável e executar testes adicionais contra o esquema mais novo sem promover automaticamente a versão nova a baseline.


### Comparação de campos entre Protobufs v2.7.26 e v2.8.0

A comparação dos campos declarados em `mesh.proto`, `telemetry.proto` e `mqtt.proto` identificou:

- `Position`: mesmos nomes e números de campo nas duas versões. A descrição de `ground_speed` mudou de m/s em v2.7.26 para km/h em v2.8.0. Como o tipo e o número do campo permanecem iguais, a codificação binária não detecta essa mudança semântica. Não converter unidades sem identificar a versão/origem do dado.
- `ServiceEnvelope` e `MapReport`: mesmos campos e números nas duas versões. `MapReport` inclui coordenadas, nome, identificadores indiretos e metadados do rádio, então continua sendo dado sensível mesmo sem o payload cifrado.
- `EnvironmentMetrics`: v2.8.0 acrescenta campos opcionais de ADC (`adc_voltage_ch0` a `adc_voltage_ch7`), temperaturas One-Wire (`one_wire_temperature_ch0` a `one_wire_temperature_ch7`) e dois campos de raios (`lightning_strike_count_1h`, `lightning_distance_km`).
- `AirQualityMetrics`: v2.8.0 acrescenta `pm_status_flags` no campo 26.
- As mensagens `DeviceMetrics`, `PowerMetrics`, `LocalStats`, `HealthMetrics`, `HostMetrics` e o contêiner `Telemetry` não mostraram diferenças de campos nesta comparação.

Implicação para o DevMesh: encaminhar envelopes sem reserializar continua sendo a opção mais segura para preservar campos que a versão local desconhece. Se no futuro houver decodificação analítica, campos novos devem ser opcionais e a unidade de cada métrica precisa ser explícita. Esta comparação cobre apenas os tipos listados e as duas revisões fixadas, não todos os esquemas nem todas as versões de firmware.

### Fase B: observação somente leitura
- [x] Criar `scripts/audit_mqtt_capture.py`, uma ferramenta de observação limitada por tempo e quantidade, com assinatura MQTT somente leitura.
- [x] Garantir que o resumo não exponha tópicos completos, IDs de nós, nomes de canais, credenciais, coordenadas ou bytes de payload; não grava payloads nem publica mensagens.
- [x] Adicionar testes sintéticos para envelopes cifrados, metadados ausentes e famílias de tópicos opacas.
- [x] Cobrir a classificação sintética por `POSITION_APP` e `TELEMETRY_APP` quando o envelope já contém um payload decodificado; isso valida apenas a classificação pelo portnum, não a capacidade de identificar esses tipos dentro de ciphertext real.
- [x] Cobrir um portnum futuro desconhecido em envelope sintético; o auditor retorna `decoded_unknown_portnum` sem expor o número nem o payload. Isso valida tolerância do classificador, não a interpretação do tipo desconhecido.
- [x] Acrescentar fixture sintética de MapReport em tópico de mapa; a classificação informa apenas se campos de posição não nulos existem e descarta seus valores.
- [x] Cobrir um `MapReport` malformado e confirmar que o resumo retorna apenas um status genérico, sem reproduzir o payload.
- [ ] Confirmar em captura autorizada se MapReport aparece no broker real; ainda não há evidência de captura dessa família.
- [x] Executar a ferramenta no broker autorizado e registrar apenas o resumo sanitizado (captura real em 2026-10-15).
- [x] Confirmar que a captura identifica envelopes MQTT cifrados sem expor payload ou identificadores; a janela observada teve 11 envelopes e 774 bytes agregados.
- [ ] Comparar famílias de dados esperadas com tipos realmente identificáveis; como os envelopes estavam cifrados, a captura não identifica se eram texto, posição, telemetria ou outros tipos.
- [x] Confirmar em broker Mosquitto descartável que o transporte MQTT preserva byte a byte um ServiceEnvelope sintético, inclusive um campo Protobuf desconhecido; CI automatizada passou.
- [ ] Medir em tráfego real se o encaminhamento aumenta tráfego inesperadamente; a captura de 11 envelopes não basta para determinar isso.

### Fase C: hardware
- [ ] Confirmar região de rádio apropriada antes de qualquer transmissão.
- [ ] Usar canal privado e mensagens de baixa frequência.
- [ ] Verificar separadamente MQTT, aceitação pelo firmware e recepção LoRa por segundo nó, se disponível.
- [ ] Testar posição/telemetria com dados controlados sem divulgar localização real.

## Ferramenta de observação somente leitura

O script `scripts/audit_mqtt_capture.py` assina um filtro MQTT por até 300 segundos e para após até 10.000 mensagens (padrões: 30 segundos e 500 mensagens). O padrão é `msh/#`; ele pode ser limitado com `--topic`. Credenciais, quando necessárias, são lidas das variáveis `DEVMESH_MQTT_USERNAME` e `DEVMESH_MQTT_PASSWORD`, nunca de argumentos. O resumo inclui somente contagens agregadas, categorias de tópicos, estado de conexão e volume total de bytes. Não publica, não grava payloads e não exibe tópicos completos ou metadados pessoais. Em `msh/2/map/...`, a ferramenta valida o envelope e, para `MAP_REPORT_APP`, informa apenas se latitude/longitude têm valores não nulos; nunca registra os valores. Isso detecta somente presença de campos de posição, não valida precisão, identidade, política de opt-in nem publicação externa. O teste de CI usa fixtures sintéticos. Em 2026-10-15, uma captura real autorizada de 60 segundos no broker doméstico conectou e teve a assinatura aceita; recebeu 11 envelopes cifrados (774 bytes agregados), sem salvar payloads nem publicar mensagens. Isso confirma que havia tráfego MQTT durante a janela, mas não revela as famílias internas dos payloads cifrados. Uma observação sem mensagens é inconclusiva, não prova ausência de tráfego.

## Implementação inicial de CI

O script `scripts/check_meshtastic_data_compatibility.sh` cria e valida fixtures sintéticos contra os esquemas oficiais Protobufs v2.8.0, fixados por tag e commit. O script `scripts/check_meshtastic_schema_matrix.sh` compara os tipos comuns Position, Telemetry, User e MapReport entre os esquemas v2.7.26 e v2.8.0, também com commits fixados. Também cobre payload vazio, omissão do booleano `false` padrão em MapReport e rejeição de mensagem truncada. O teste MQTT de downlink acrescenta um campo desconhecido sintético e confirma que o broker preserva todos os bytes sem tentar interpretar o envelope. Testes de CLI verificam que a chave não seja exibida nos logs e que o texto sensível possa ser fornecido por stdin, sem colocá-lo nos argumentos do processo. Essas verificações precisam passar no CI antes de serem consideradas validadas; são testes sintéticos e não decodificam tráfego real nem provam que todos os campos são enviados pelo firmware.

## Resultado CI confirmado

Em 2026-10-15, o job `MQTT connectivity and Meshtastic payload validation` passou, incluindo o teste de transporte MQTT, os fixtures de localização/telemetria, a matriz Protobuf v2.7.26/v2.8.0, o modelo de criptografia AES-CTR e os testes isolados de autenticação e ACL. O job de referência criptográfica upstream também passou. Isso confirma os testes automatizados executados, não a recepção de mensagens em hardware real.

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
