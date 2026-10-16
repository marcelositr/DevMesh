# Validação do downlink MQTT Meshtastic

## Objetivo

Separar resultados diferentes: conectividade MQTT, transporte do envelope Protobuf, aceitação e exibição pelo firmware e eventual retransmissão/recepção por LoRa. Um teste de broker sozinho não comprova as etapas de hardware.

## Comportamento confirmado no firmware de referência

O código em [MQTT.cpp no commit fixado pelo projeto](https://github.com/meshtastic/firmware/blob/8e6a88d06f44cad26f1e8d7cd402939ccacb9b4c/src/mqtt/MQTT.cpp) mostra que:

- Com a raiz `msh`, os tópicos criptografados começam com `msh/2/e/`.
- Para cada canal com downlink habilitado, o firmware assina `msh/2/e/<canal>/+`.
- A carga recebida deve ser um `ServiceEnvelope` Protobuf válido, com `packet`, `channel_id` e `gateway_id`.
- O nome do canal deve corresponder a um canal local com downlink habilitado, exceto o tratamento especial de `PKI`.
- Com `encryption_enabled` ativado, o firmware descarta pacotes MQTT já decodificados. Publicar texto puro ou JSON arbitrário não é um teste válido do caminho criptografado.
- O firmware ignora envelopes enviados pelo próprio nó quando reconhece seu próprio gateway ID ou pacote de origem. Ver o próprio pacote ser ecoado pelo broker não prova downlink.
- Para canais AES-CTR tradicionais, o pacote contém um `Data` serializado e cifrado; o nonce depende do ID do pacote e do ID de origem. O hash do canal também precisa coincidir com o nome e a PSK efetiva.

## Testes automatizados

O script `scripts/check_meshtastic_downlink_transport.sh` sobe um Mosquitto descartável, assina o filtro `msh/2/e/LongFast/+` e publica o fixture sintético em `msh/2/e/LongFast/!a1b2c3d4`. Em seguida, compara os bytes recebidos com os publicados.

Esse teste verifica somente a correspondência do tópico e o transporte de bytes pelo broker. O fixture é sintético; não é uma mensagem cifrada válida para o canal real do usuário e não deve ser publicado no broker doméstico.

O script `scripts/build_mqtt_downlink.py` constrói um envelope Protobuf de texto cifrado para um canal privado de teste. A chave é solicitada com entrada oculta ou lida de `DEVMESH_CHANNEL_PSK_B64`; ela não é impressa nem gravada no repositório. Para texto sensível, usar `--text-stdin`, pois argumentos de linha de comando podem ficar visíveis para outros processos locais. `--text` continua disponível para conteúdo não sensível. O script só grava um arquivo binário local, não conecta ao broker e não transmite LoRa. Ele bloqueia nomes de canais de preset público e exige que os IDs de origem e gateway sejam diferentes do ID local informado. Os testes unitários validam a estrutura, a decifragem de volta ao texto original e as proteções básicas.

Os testes automatizados, por si sós, não comprovam que o firmware real aceita o envelope, que a PSK fornecida corresponde à configuração do rádio, ou que haverá transmissão/recepção LoRa.

## Evidências do teste físico

### Observações anteriores, 2026-10-14

- O nó `!a35aa590` autenticou no broker doméstico `192.168.0.2:1883`.
- Os logs mostraram inscrições em `msh/2/e/LongFast/+`, `msh/2/e/ITUVERAVA/+` e `msh/2/e/PKI/+`.
- O nó publicou envelopes em `msh/2/e/LongFast/!a35aa590`; o broker os entregou de volta ao próprio nó e a um assinante de teste.
- Naquele momento, ainda não havia evidência de uma mensagem de teste externa aceita pelo firmware via MQTT.

### Downlink cifrado validado, 2026-10-15

- Foi construído localmente um envelope `ServiceEnvelope` cifrado para o canal privado `ITUVERAVA`; a validação local confirmou a estrutura e a decifragem do payload de teste.
- O envelope foi publicado **uma única vez**, com QoS 1 e retenção desativada, no tópico `msh/2/e/ITUVERAVA/!a1b2c3d4`, pelo usuário MQTT autorizado no broker doméstico.
- O comando de publicação terminou com sucesso.
- O operador confirmou que a mensagem de teste apareceu tanto no display da Heltec quanto no aplicativo Android Meshtastic.
- Essa observação comprova, para esta configuração e este pacote de teste, o caminho MQTT até a aceitação/exibição pelo firmware e aplicativo. É evidência mais forte que o teste de transporte automatizado.
- O teste não comprova alcance ou retransmissão LoRa para um segundo nó, nem compatibilidade de todas as famílias de dados. Não foram publicadas coordenadas ou segredos na documentação.

## Próximas etapas

1. Preservar este resultado como evidência manual e não repetir a publicação só para reproduzir a confirmação.
2. Revisar a implementação e os testes para que a validação local do envelope permaneça reproduzível, sem depender de segredos reais.
3. Conferir o estado da CI no commit mais recente antes de ampliar a cobertura.
4. Se houver um segundo nó de teste disponível, planejar separadamente um teste de recepção/retransmissão LoRa com dados controlados e frequência baixa.
5. Para posição e telemetria, usar dados sintéticos ou controlados, sem expor localização real.

Não publicar o fixture sintético nem texto puro como se fossem mensagens de rádio válidas. Não publicar pacotes de teste como retained. O gerador permanece separado da publicação MQTT para evitar transmissão acidental. A confirmação manual descrita acima é evidência observada, não um teste automatizado de hardware.
