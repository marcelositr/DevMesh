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
- Para canais AES-CTR tradicionais, o pacote contém um `Data` serializado e cifrado; o nonce depende do ID do pacote e do ID de origem. O hash do canal também precisa coincidir com o nome e a PSK efetiva.

## Testes automatizados

O script `scripts/check_meshtastic_downlink_transport.sh` sobe um Mosquitto descartável, assina o filtro `msh/2/e/LongFast/+` e publica o fixture sintético em `msh/2/e/LongFast/!a1b2c3d4`. Em seguida, compara os bytes recebidos com os publicados.

Esse teste verifica somente a correspondência do tópico e o transporte de bytes pelo broker. O fixture é sintético; não é uma mensagem cifrada válida para o canal real do usuário e não deve ser publicado no broker doméstico.

O novo `scripts/build_mqtt_downlink.py` constrói um envelope Protobuf de texto cifrado para um canal privado de teste. A chave é solicitada com entrada oculta ou lida de `DEVMESH_CHANNEL_PSK_B64`; ela não é impressa nem gravada no repositório. O script só grava um arquivo binário local, não conecta ao broker e não transmite LoRa. Ele bloqueia nomes de canais de preset público e exige que os IDs de origem e gateway sejam diferentes do ID local informado. Os testes unitários validam a estrutura, a decifragem de volta ao texto original e as proteções básicas.

Esses testes não comprovam, por si sós, que o firmware real aceita o envelope, que a PSK fornecida corresponde à configuração do rádio, ou que haverá transmissão/recepção LoRa.

## Evidências atuais do teste físico

Na configuração doméstica observada em 2026-10-14:

- O nó `!a35aa590` autenticou no broker `192.168.0.2:1883`.
- Os logs mostraram inscrições em `msh/2/e/LongFast/+`, `msh/2/e/ITUVERAVA/+` e `msh/2/e/PKI/+`.
- O nó publicou envelopes em `msh/2/e/LongFast/!a35aa590`; o broker os entregou de volta ao próprio nó e a um assinante de teste.
- Não foi observada, até aqui, uma mensagem de teste válida originada por outro gateway e aceita pelo firmware via MQTT.

## Próxima etapa para o teste com hardware

1. Confirmar a região LoRa correta para o Brasil antes de qualquer transmissão.
2. Escolher um canal privado de teste com downlink habilitado; não usar o canal público LongFast para esse teste.
3. Gerar o envelope localmente com uma PSK que corresponda exatamente ao canal do rádio. Não guardar a PSK em arquivo versionado nem passá-la em argumento de linha de comando.
4. Conferir o tópico impresso pelo gerador e publicar uma única mensagem, sem retenção, somente depois de verificar os IDs sintéticos e a configuração do broker.
5. Conferir separadamente o log do broker, a aceitação pelo firmware e, se houver segundo nó de teste, a recepção LoRa.

Não publicar o fixture sintético nem texto puro como se fossem mensagens de rádio válidas. Não publicar pacotes de teste como retained. O gerador ainda não publica mensagens; essa etapa fica deliberadamente separada para evitar uma transmissão acidental.
