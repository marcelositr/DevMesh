# Testes iniciais do DevMesh

## Verificação básica do broker MQTT

O script `scripts/check_mqtt_smoke.sh` inicia um broker Mosquitto descartável usando `tests/mosquitto/mosquitto.conf`.

```sh
bash scripts/check_mqtt_smoke.sh
```

Requisitos: Docker com permissão para iniciar contêineres e acesso à imagem `eclipse-mosquitto:2.1.2-alpine`.

O teste usa três clientes simulados: A publica mensagens, B e C recebem mensagens em tópicos públicos autorizados e assinaturas em tópicos diferentes demonstram roteamento por tópico. O broker permite acesso anônimo somente no ambiente descartável.

## Transporte binário Meshtastic entre três nós

O script `scripts/check_meshtastic_mqtt.sh` simula o nó A publicando um fixture binário `ServiceEnvelope` num tópico com formato Meshtastic. Os nós B e C assinam o filtro de tópico, confirmam suas assinaturas com o `SUBACK` do broker e verificam que os bytes recebidos são idênticos aos publicados.

```sh
bash scripts/check_meshtastic_mqtt.sh
```

O fixture `tests/fixtures/meshtastic-service-envelope.hex` é sintético e contém um `MeshPacket` com bytes no campo `encrypted`. O teste comprova entrega e preservação de bytes, mas **não** comprova que esses bytes resultem de criptografia real nem que o nó C não consiga decifrá-los. Ele não valida ACL nem decodifica Protobuf.

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

O teste verifica que B e C recebem mensagens no tópico público autorizado, B recebe mensagens no tópico restrito de A/B e C não consegue publicar nem receber nesse tópico.

**Importante:** esse isolamento é imposto pela ACL do broker MQTT. Não é o mesmo que criptografia de canal Meshtastic. Num canal cifrado real, um nó sem a chave pode receber e retransmitir bytes cifrados, mas não ler o conteúdo. A simulação criptográfica real ainda não está implementada.

## Limitações conhecidas

Os testes não comprovam criptografia real dos canais Meshtastic, confidencialidade ponta a ponta, segurança de produção, alcance ou retransmissão LoRa, nem interoperabilidade integral com firmware ou hardware. Resultados ainda não executados não devem ser descritos como aprovados.
