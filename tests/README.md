# Testes iniciais do DevMesh

## Verificação básica do broker MQTT

O script `scripts/check_mqtt_smoke.sh` inicia um broker Mosquitto descartável usando `tests/mosquitto/mosquitto.conf`.

```sh
bash scripts/check_mqtt_smoke.sh
```

Requisitos: Docker com permissão para iniciar contêineres e acesso à imagem `eclipse-mosquitto:2.1.2-alpine`.

O teste usa três clientes simulados: A publica em tópicos públicos, B e C recebem mensagens autorizadas e assinaturas em tópicos diferentes demonstram o isolamento básico por tópico. O broker permite acesso anônimo somente no ambiente descartável.

## Transporte binário Meshtastic entre três nós

O script `scripts/check_meshtastic_mqtt.sh` simula o nó A publicando um fixture binário `ServiceEnvelope`. Os nós B e C assinam o filtro público LongFast e verificam que os bytes recebidos são idênticos aos publicados.

```sh
bash scripts/check_meshtastic_mqtt.sh
```

O fixture `tests/fixtures/meshtastic-service-envelope.hex` é sintético e contém um `MeshPacket` com bytes no campo `encrypted`. Este teste valida a entrega a dois assinantes e a preservação exata dos bytes. Não valida ACL nem decodifica Protobuf.

## Validação estrutural Protobuf com o esquema oficial

O script `scripts/check_meshtastic_protobuf.sh` usa `protoc` e as definições oficiais de `meshtastic/protobufs`, fixadas na versão `v2.8.0` e no commit `7b2464c9b8c1521f93852261e4123826e5b25e11`.

```sh
bash scripts/check_meshtastic_protobuf.sh
```

Requisitos: Git, `protoc` e `xxd`. O teste baixa a versão fixada, decodifica o fixture como `meshtastic.ServiceEnvelope`, verifica campos esperados e recodifica o conteúdo para comparar os bytes com o original.

**Limite:** o fixture não é uma captura de dispositivo real. A validação confirma a estrutura segundo a versão fixada do esquema, não criptografia real, interoperabilidade integral com firmware, downlink ou funcionamento de rádio LoRa. O esquema é obtido durante o teste e não é incorporado ao código do DevMesh.

## Verificação básica de autenticação

O script `scripts/check_mqtt_auth.sh` inicia um broker descartável com autenticação obrigatória e credenciais temporárias.

```sh
bash scripts/check_mqtt_auth.sh
```

O teste verifica que uma publicação anônima e uma senha inválida são recusadas, enquanto um cliente autenticado consegue publicar e outro cliente autenticado recebe a mensagem.

## Verificação de ACL por tópico

O script `scripts/check_mqtt_acl.sh` inicia um broker descartável com credenciais e regras temporárias.

```sh
bash scripts/check_mqtt_acl.sh
```

O teste verifica que B e C recebem mensagens no tópico público autorizado, B recebe mensagens privadas de A e C não consegue publicar nem receber mensagens no tópico privado de A/B.

Autenticação identifica o cliente; ACL restringe as operações permitidas por tópico. Essas regras não são uma configuração pronta para produção.

## Limitações conhecidas

Os testes não comprovam criptografia real dos canais Meshtastic, confidencialidade ponta a ponta, segurança de produção, alcance ou retransmissão LoRa, nem interoperabilidade integral com firmware ou hardware. Resultados ainda não executados não devem ser descritos como aprovados.
