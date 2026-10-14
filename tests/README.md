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

O fixture em `tests/fixtures/meshtastic-service-envelope.hex` representa um envelope com um `MeshPacket` que contém bytes no campo `encrypted`. Os campos e números de campo seguem as definições oficiais `mqtt.proto` e `mesh.proto`. O teste converte os bytes hexadecimais para binário e compara exatamente o payload publicado com o recebido.

**Limite:** esse teste verifica transporte binário sem alteração pelo broker, não decodificação Protobuf nem validação integral do protocolo. O fixture não contém uma mensagem cifrada por um dispositivo real e não comprova criptografia Meshtastic, interoperabilidade com firmware, downlink ou funcionamento de rádio LoRa.

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

- decodificação Protobuf integral ou compatibilidade com firmware Meshtastic;
- criptografia real dos canais Meshtastic ou confidencialidade ponta a ponta;
- autorização por ACL;
- comportamento de rádio LoRa, alcance ou retransmissão;
- segurança de uma configuração de produção.

Resultados ainda não executados não devem ser descritos como aprovados.
