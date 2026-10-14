# Levantamento mínimo do nó Meshtastic de referência

- **Projeto:** DevMesh
- **Estado:** levantamento inicial realizado; observação de tráfego ainda incompleta
- **Data:** 2026-10-13
- **Objetivo:** registrar somente o necessário para orientar a integração futura com Mosquitto e identificar o que ainda precisa ser verificado.
- **Método:** consulta somente leitura pela API de rede do próprio dispositivo, usando a CLI Meshtastic e a exportação de configuração.

## 1. Equipamento e firmware

| Campo | Resultado | Evidência |
|---|---|---|
| Modelo informado pelo firmware | `HELTEC_V4` | `--info` |
| Ambiente de compilação | `heltec-v4` | `--info` |
| Versão do firmware | `2.7.26.54e0d8d` | `--info` |
| Edição | `VANILLA` | `--info` |
| Papel do nó | `CLIENT` | Metadados/configuração |
| Transceptor | Família SX126x indicada | Log de inicialização; modelo exato não confirmado |
| Módulo GPS | Não identificado | Modelo não exposto nas saídas coletadas |

O modelo comercial/revisão física da placa, o modelo exato do transceptor e o modelo do GPS ainda devem ser confirmados por marcações físicas ou documentação confiável do fabricante.

## 2. Parâmetros de rádio relevantes

| Campo | Valor observado |
|---|---|
| Preset | `LONG_FAST` |
| Largura de banda | 250 kHz |
| Spreading factor | 11 |
| Coding rate | 5, correspondente ao formato 4/5 usado pela configuração |
| Limite de saltos | 6 |
| Potência configurada | 30 dBm |
| Região configurada | `ANZ` |
| Ganho de recepção SX126x | Ativado |
| Transmissão LoRa | Habilitada |

São valores de configuração, não medições independentes do sinal transmitido. A região `ANZ` precisa ser verificada antes de qualquer uso como configuração operacional adequada ao Brasil. Não alterar a região ou a potência durante este levantamento.

## 3. Interfaces e módulos importantes

- Wi-Fi habilitado; o nó recebeu um endereço na rede local.
- Bluetooth desabilitado na configuração consultada.
- MQTT habilitado, com JSON e TLS configurados.
- Os canais `LongFast` e `ITUVERAVA` aparecem com uplink e downlink MQTT habilitados.
- Telemetria do dispositivo habilitada, com intervalo configurado de 10.800 segundos (3 horas).
- Medição ambiental desabilitada.
- Store & Forward e Neighbor Info desabilitados.
- A configuração de GPS informa `gpsMode: ENABLED`, mas também `gpsEnabled: false`. Um log anterior registrou sincronização de horário por GPS/NMEA. Portanto, o estado atual do GPS permanece **inconclusivo**.

O broker, os nomes de usuário, as senhas, as chaves privadas, as chaves PSK e os identificadores sensíveis foram omitidos deliberadamente deste documento.

## 4. O que foi observado sobre o tráfego

Os logs fornecidos registraram atividade de inicialização do rádio, eventos de transmissão e conexão MQTT. A configuração indica publicação/recepção MQTT nos canais listados acima.

Isso **ainda não constitui uma captura completa de pacotes LoRa**. Não há evidência suficiente nesta coleta para caracterizar todos os tipos de pacote, taxas de ocorrência, RSSI/SNR por pacote ou comportamento de retransmissão.

Para o DevMesh, os dados prioritários a observar numa próxima coleta são:

1. Tipo de pacote e número de ocorrências por intervalo.
2. Campos disponíveis de origem/destino, identificador, canal, tipo de payload e saltos.
3. RSSI/SNR quando efetivamente fornecidos pelo receptor.
4. Diferença entre pacote recebido por rádio e mensagem publicada/recebida via MQTT.
5. Versão do firmware e horário da coleta para contextualizar cada resultado.

Não gerar mensagens em massa nem alterar a configuração para produzir dados artificiais.

## 5. Relevância para o DevMesh

O levantamento atual é suficiente para definir a próxima etapa de pesquisa: observar o formato e o comportamento das mensagens MQTT recebidas por um broker de teste autorizado, sem ainda implementar lógica de aplicação.

O servidor não deve presumir que todos os pacotes de rádio serão visíveis pelo MQTT. A visibilidade depende da configuração dos canais, das opções de encaminhamento, da criptografia e do comportamento do nó/broker.

## 6. Pendências

- Confirmar modelo/revisão física da placa.
- Identificar o modelo exato do transceptor LoRa e do módulo GPS.
- Resolver a discrepância entre os campos de configuração/estado do GPS.
- Confirmar a configuração regional aplicável antes de qualquer operação de rádio.
- Capturar e classificar uma amostra pequena de tráfego real, separando rádio e MQTT.
- Identificar a versão do protocolo apenas se uma ferramenta ou metadado confiável a expuser; não deduzi-la da versão do firmware ou de `minAppVersion`.

## 7. Segurança e privacidade

As saídas de diagnóstico compartilhadas durante a coleta continham credenciais de rede/MQTT e uma chave privada do dispositivo. Trate esses segredos como expostos: altere as senhas e avalie a rotação da chave privada pelo procedimento oficial do Meshtastic. Não armazene saídas brutas no repositório público.

Não publicar coordenadas precisas, identificadores pessoais desnecessários, chaves de canal, senhas ou URLs de configuração que incluam canais secretos.

## 8. Critério de conclusão desta etapa

A etapa inicial está concluída quando o inventário básico do equipamento e da configuração estiver registrado, as incertezas estiverem explícitas e houver um plano curto para observar o tráfego real. A análise detalhada do protocolo fica fora do escopo deste inventário mínimo.

## Referências

- [Documentação Meshtastic](https://meshtastic.org/docs/)
- [Documentação MQTT do Meshtastic](https://meshtastic.org/docs/software/integrations/mqtt/)
- [Heltec Automation](https://heltec.org/)
