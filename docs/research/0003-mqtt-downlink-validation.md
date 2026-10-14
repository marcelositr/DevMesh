# Validação do downlink MQTT Meshtastic

## Objetivo

Separar três coisas diferentes: conectividade MQTT, entrega de um envelope Protobuf ao filtro usado pelo firmware e aceitação real do pacote pelo rádio. Um teste de broker sozinho não comprova a terceira etapa.

## Comportamento confirmado no firmware de referência

O código em [MQTT.cpp no commit fixado pelo projeto](https://github.com/meshtastic/firmware/blob/8e6a88d06f44cad26f1e8d7cd402939ccacb9b4c/src/mqtt/MQTT.cpp) mostra que:

- Com a raiz `msh`, os tópicos criptografados começam com `msh/2/e/`.
- Para cada canal com downlink habilitado, o firmware assina `msh/2/e/<canal>/+`.
- A carga recebida deve ser um `ServiceEnvelope` Protobuf válido, com `packet`, `channel_id` e `gateway_id`.
- O nome do canal deve corresponder a um canal local com downlink habilitado, exceto o tratamento especial de `PKI`.
- Com `encryption_enabled` ativado, o firmware descarta pacotes MQTT já decodificados. Publicar texto puro ou JSON arbitrário não é um teste válido do caminho criptografado.
- O firmware ignora envelopes enviados pelo próprio nó quando reconhece seu próprio gateway ID ou pacote de origem. Ver o próprio pacote ser ecoado pelo broker não prova downlink.

## Teste automatizado

O script `scripts/check_meshtastic_downlink_transport.sh` sobe um Mosquitto descartável, assina o filtro `msh/2/e/LongFast/+` e publica o fixture sintético em `msh/2/e/LongFast/!a1b2c3d4`. Em seguida, compara os bytes recebidos com os publicados.

Esse teste verifica somente a correspondência do tópico e o transporte de bytes pelo broker. O fixture é sintético; não é uma mensagem cifrada válida para o canal real do usuário e não deve ser publicado no broker doméstico. O teste não comprova aceitação pelo firmware, decifragem, encaminhamento por LoRa nem recepção por outro nó.

## Evidências atuais do teste físico

Na configuração doméstica observada em 2026-10-14:

- O nó `!a35aa590` autenticou no broker `192.168.0.2:1883`.
- Os logs mostraram inscrições em `msh/2/e/LongFast/+`, `msh/2/e/ITUVERAVA/+` e `msh/2/e/PKI/+`.
- O nó publicou envelopes em `msh/2/e/LongFast/!a35aa590`; o broker os entregou de volta ao próprio nó e a um assinante de teste.
- Não foi observada, até aqui, uma mensagem de teste válida originada por outro gateway e aceita pelo firmware via MQTT.

## Próxima etapa para o teste com hardware

1. Corrigir e verificar a configuração de região LoRa do rádio para a região aplicável ao Brasil antes de qualquer transmissão.
2. Gerar ou obter um `ServiceEnvelope` válido com uma origem de gateway diferente do próprio nó, canal permitido e pacote cifrado compatível com as chaves de teste.
3. Publicar uma única mensagem não retida no filtro de downlink apropriado.
4. Conferir o log do broker, o log/estado do firmware e, se houver um segundo nó de teste, a recepção LoRa.
5. Registrar separadamente sucesso de transporte MQTT, aceitação do firmware e transmissão/recepção LoRa.

Não usar o fixture sintético nem publicar texto puro como se fossem mensagens de rádio válidas. Não publicar pacotes de teste como retained.
