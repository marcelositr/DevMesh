# Testes iniciais do DevMesh

## Verificação básica do broker MQTT

O script `scripts/check_mqtt_smoke.sh` inicia um broker Mosquitto descartável usando a configuração em `tests/mosquitto/mosquitto.conf`.

Execute na raiz do repositório:

```sh
bash scripts/check_mqtt_smoke.sh
```

Requisitos: Docker com permissão para iniciar contêineres e acesso à imagem `eclipse-mosquitto:2.1.2`.

O teste cria três clientes MQTT simulados:

- Nó A publica uma mensagem em um tópico público.
- Nós B e C recebem a mensagem desse tópico.
- Nó A publica em um tópico separado; um assinante desse tópico recebe a mensagem, enquanto um assinante de outro tópico não a recebe.

O broker de teste permite acesso anônimo de propósito, fica restrito ao ambiente descartável e não deve ser usado em produção.

## Transporte binário de um fixture Meshtastic

O script `scripts/check_meshtastic_mqtt.sh` publica e recebe um fixture binário no formato de um `ServiceEnvelope`, usando o padrão de tópico MQTT documentado pelo Meshtastic.

```sh
bash scripts/check_meshtastic_mqtt.sh
```

O fixture em `tests/fixtures/meshtastic-service-envelope.hex` representa um envelope com um `MeshPacket` que contém bytes no campo `encrypted`. Esse teste verifica que o broker transporta o payload sem alterar os bytes, mas não decodifica Protobuf.

## Validação estrutural Protobuf com o esquema oficial

O script `scripts/check_meshtastic_protobuf.sh` usa o compilador `protoc` e as definições oficiais do repositório `meshtastic/protobufs`, fixadas na versão `v2.8.0` e no commit `7b2464c9b8c1521f93852261e4123826e5b25e11`.

```sh
bash scripts/check_meshtastic_protobuf.sh
```

Requisitos: Git, `protoc` e `xxd`. O teste baixa a versão fixada das definições oficiais, decodifica o fixture como `meshtastic.ServiceEnvelope`, verifica os campos esperados e o recodifica para comparar os bytes resultantes com o original.

**Limite:** o fixture é sintético, não uma captura de um dispositivo real. A validação confirma a estrutura Protobuf segundo a versão fixada do esquema, não criptografia real, compatibilidade integral com firmware, downlink ou funcionamento de rádio LoRa. O esquema é obtido durante o teste e não é incorporado ao código do DevMesh.

## Verificação básica de autenticação

O script `scripts/check_mqtt_auth.sh` inicia um broker descartável com autenticação obrigatória e credenciais temporárias geradas durante a execução.

```sh
bash scripts/check_mqtt_auth.sh
```

O teste verifica que:

- uma publicação anônima é recusada;
- uma senha inválida é recusada;
- um cliente com credenciais válidas consegue publicar e outro cliente autenticado recebe a mensagem.

## Limitações conhecidas

Os testes atuais **não** comprovam:

- criptografia real dos canais Meshtastic ou confidencialidade ponta a ponta;
- autorização por ACL;
- comportamento de rádio LoRa, alcance ou retransmissão;
- segurança de uma configuração de produção.

Resultados ainda não executados não devem ser descritos como aprovados.
