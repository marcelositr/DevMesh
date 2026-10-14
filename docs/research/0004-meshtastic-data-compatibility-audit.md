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
- [ ] Executar no CI a verificação decode/encode desses fixtures e a rejeição de uma mensagem truncada; o teste foi implementado, mas ainda não há resultado confirmado.
- [ ] Testar preservação de campos desconhecidos e tipos de payload desconhecidos; isso ainda não está coberto pelo script inicial.
- [ ] Verificar payload vazio, privacidade dos logs e matriz de versões adicionais.
- [ ] Garantir que os logs de teste não exponham conteúdo sensível.
- [ ] Manter baseline estável e executar testes adicionais contra o esquema mais novo sem promover automaticamente a versão nova a baseline.

### Fase B: observação somente leitura
- [ ] Capturar pequena amostra do broker autorizado, sem guardar credenciais ou coordenadas.
- [ ] Classificar somente metadados necessários; conteúdo cifrado sem chave permanece opaco.
- [ ] Comparar famílias esperadas com tipos realmente vistos e marcar ausência como inconclusiva.
- [ ] Confirmar que o encaminhamento preserva bytes e não aumenta tráfego inesperadamente.

### Fase C: hardware
- [ ] Confirmar região de rádio apropriada antes de qualquer transmissão.
- [ ] Usar canal privado e mensagens de baixa frequência.
- [ ] Verificar separadamente MQTT, aceitação pelo firmware e recepção LoRa por segundo nó, se disponível.
- [ ] Testar posição/telemetria com dados controlados sem divulgar localização real.

## Implementação inicial de CI

O script `scripts/check_meshtastic_data_compatibility.sh` cria e valida fixtures sintéticos contra os esquemas oficiais Protobufs v2.8.0, fixados por tag e commit. O workflow MQTT smoke executa o script. Essa etapa valida estrutura e round-trip dos tipos cobertos, não decodifica tráfego real nem prova que todos os campos são enviados pelo firmware. O resultado do CI do commit mais recente ainda precisa ser confirmado.

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
