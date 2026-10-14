# Testes iniciais do DevMesh

## Verificação básica do broker MQTT

O script `scripts/check_mqtt_smoke.sh` inicia um broker Mosquitto descartável usando `tests/mosquitto/mosquitto.conf`.

```sh
bash scripts/check_mqtt_smoke.sh
```

Requisitos: Docker com permissão para iniciar contêineres e acesso à imagem `eclipse-mosquitto:2.1.2-alpine`.

O teste usa três clientes simulados: A publica mensagens, B e C recebem mensagens em tópicos públicos autorizados e assinaturas em tópicos diferentes demonstram roteamento por tópico. O broker permite acesso anônimo somente no ambiente descartável.

## Transporte binário Meshtastic entre três nós

O script `scripts/check_meshtastic_mqtt.sh` simula o nó A publicando um fixture binário `ServiceEnvelope` como mensagem retida num broker descartável. Os nós B e C assinam o filtro de tópico e recebem a mensagem retida, mesmo que iniciem depois da publicação. Em seguida, verificam que os bytes recebidos são idênticos aos publicados.

```sh
bash scripts/check_meshtastic_mqtt.sh
```

A retenção é usada somente para remover a corrida de inicialização entre publicação e assinatura dentro deste teste. Não representa a configuração de retenção recomendada para mensagens Meshtastic em produção.

O fixture `tests/fixtures/meshtastic-service-envelope.hex` é sintético e contém um `MeshPacket` com bytes no campo `encrypted`. O teste comprova entrega e preservação de bytes, mas **não** comprova que esses bytes resultem de criptografia real nem que o nó C não consiga decifrá-los. Ele não valida ACL nem decodifica Protobuf.

## Validação estrutural Protobuf com o esquema oficial

O script `scripts/check_meshtastic_protobuf.sh` usa `protoc` e as definições oficiais de `meshtastic/protobufs`, fixadas na versão `v2.8.0` e no commit `7b2464c9b8c1521f93852261e4123826e5b25e11`.

```sh
bash scripts/check_meshtastic_protobuf.sh
```

Requisitos: Git, `protoc` e `xxd`. O teste baixa a versão fixada, decodifica o fixture como `meshtastic.ServiceEnvelope`, verifica campos esperados e recodifica o conteúdo para comparar os bytes com o original.

**Limite:** o fixture não é uma captura de dispositivo real. A validação confirma a estrutura segundo a versão fixada do esquema, não criptografia real, interoperabilidade integral com firmware, downlink ou funcionamento de rádio LoRa. O esquema é obtido durante o teste e não é incorporado ao código do DevMesh.

## Modelo de criptografia AES-CTR de canal

O script `scripts/check_meshtastic_crypto_model.sh` verifica dois vetores AES-CTR de referência usados pelo teste criptográfico do firmware Meshtastic, confere a disposição de bytes do nonce e executa o modelo com OpenSSL num broker descartável. Os vetores são definidos no teste oficial `test/test_crypto/test_main.cpp` do firmware [v2.8.1.8e6a88d, commit `8e6a88d06f44cad26f1e8d7cd402939ccacb9b4c`](https://github.com/meshtastic/firmware/blob/8e6a88d06f44cad26f1e8d7cd402939ccacb9b4c/test/test_crypto/test_main.cpp), com base nos vetores RFC 3686.

```sh
bash scripts/check_meshtastic_crypto_model.sh
```

O nonce do modelo segue a disposição de canal documentada e conferida no código fixado de `CryptoEngine.cpp`: `packet_id` little-endian de 64 bits, `from_node` little-endian de 32 bits e contador de bloco de 32 bits. O teste usa chaves e texto sintéticos, sem segredos reais.

O modelo publica o ciphertext no broker descartável. B e C recebem os mesmos bytes; B recupera o texto com a chave correta e C, usando outra chave, não recupera o texto original.

**Limites:** os vetores de referência conferem o primitivo AES-CTR do OpenSSL com vetores também usados pelo teste do firmware. Isso **não** executa `CryptoEngine.cpp`, não é um vetor de mensagem gerado por um dispositivo e não prova interoperabilidade integral. A conferência do nonce testa a codificação esperada, não toda a lógica interna do firmware. AES-CTR não autentica o conteúdo, e uma saída diferente com chave errada não equivale a uma garantia criptográfica geral. O teste também não cobre mensagens diretas PKI/AES-CCM, assinatura ou integridade.

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

**Importante:** esse isolamento é imposto pela ACL do broker MQTT. Não é o mesmo que criptografia de canal Meshtastic. Num canal cifrado real, um nó sem a chave pode receber e retransmitir bytes cifrados, mas não ler o conteúdo. O modelo AES-CTR independente e a conferência de vetores estão implementados, mas a execução do código criptográfico do firmware Meshtastic e a validação de um payload de canal gerado pelo firmware ainda não estão implementadas.

## Limitações conhecidas

Os testes não comprovam criptografia real dos canais Meshtastic, confidencialidade ponta a ponta, segurança de produção, alcance ou retransmissão LoRa, nem interoperabilidade integral com firmware ou hardware. Resultados ainda não executados não devem ser descritos como aprovados.
