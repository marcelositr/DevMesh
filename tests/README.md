# Testes iniciais do DevMesh

## Verificação da configuração doméstica

O script `scripts/check_home_deployment.sh` valida a configuração versionada em `deploy/home/` usando um broker Mosquitto descartável e um arquivo de senhas sintético. Ele verifica inicialização, entrega autenticada, rejeição de acesso anônimo e de senha incorreta, além de impedir leitura e publicação fora do prefixo MQTT `msh/#`. O teste adiciona uma conta observadora somente à cópia temporária da ACL para verificar as duas direções; os arquivos do repositório não são alterados.

```sh
bash scripts/check_home_deployment.sh
```

Requisitos: Docker Engine, Docker Compose, Python 3 e acesso à imagem `eclipse-mosquitto:2.1.2-alpine`. O teste remove os contêineres e o volume temporário ao terminar.

**Limites:** o teste valida a configuração do broker e as permissões MQTT num contêiner local. Não valida TLS, integração com dispositivos físicos, payloads capturados de rádio nem prontidão para produção.

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

O modelo publica o ciphertext no broker descartável. B e C recebem os mesmos bytes; B recupera o texto com a chave correta e C, usando outra chave, não recupera o texto original. O teste também altera deliberadamente um bit do ciphertext e verifica que o bit correspondente do texto decifrado muda sem erro de autenticação, demonstrando na prática que AES-CTR não detecta adulteração.

## Suíte criptográfica oficial do firmware

A workflow `.github/workflows/meshtastic-firmware-crypto.yml` faz checkout do código oficial Meshtastic num commit fixo (`8e6a88d06f44cad26f1e8d7cd402939ccacb9b4c`) e executa `pio test -e native -f test_crypto -vv`. A execução [#1](https://github.com/marcelositr/DevMesh/actions/runs/38586528090) terminou com sucesso: 28 casos de teste passaram em aproximadamente cinco minutos.

A workflow atual prepara casos temporários dentro do teste upstream e chama `CryptoEngine::encryptPacket()` com chaves, nonces, mensagens e identificadores sintéticos. Cinco casos comparam o ciphertext byte a byte com OpenSSL AES-128-CTR. A edição ocorre somente no checkout descartável do CI; o repositório upstream não é alterado e o firmware não é incorporado ao produto DevMesh. O resultado mais recente está disponível na [workflow criptográfica](https://github.com/marcelositr/DevMesh/actions/runs/38622597752).

A mesma suíte upstream também executa os testes `test_AES_CCM_AEAD_rejects_tampering`, `test_AES_CCM_AEAD_tamper_sweep`, `test_AES_CCM_AEAD_rejects_wrong_psk`, `test_AES_CCM_AEAD_binds_nonce_inputs` e `test_AES_CCM_AEAD_binds_destination`. Eles verificam que alterações no ciphertext ou na tag, PSK incorreta, identificadores de nonce diferentes e destino alterado são rejeitados no nível de `CryptoEngine`. O teste `test_AES_CCM_rfc3610` ainda compara vetores conhecidos de AES-CCM com resultados esperados. Isso é evidência de testes unitários do código oficial fixado, não uma prova de que o DevMesh habilita ou negocia AEAD: os nós Meshtastic precisam estar configurados de forma compatível, e o teste MQTT atual apenas transporta os bytes recebidos.

**Limites:** a comparação direta confirma que `CryptoEngine::encryptPacket()` e OpenSSL produzem o mesmo ciphertext AES-CTR nos cinco casos sintéticos cobertos. O teste integrado também verifica o percurso desse ciphertext por `ServiceEnvelope` Protobuf e MQTT, com dois assinantes recebendo bytes idênticos. Isso não valida payloads capturados de dispositivos reais, enlaces LoRa, mensagens diretas PKI/AES-CCM, assinaturas ou a segurança geral do sistema. AES-CTR não autentica o conteúdo.

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

**Importante:** esse isolamento é imposto pela ACL do broker MQTT. Não é o mesmo que criptografia de canal Meshtastic. Num canal cifrado real, um nó sem a chave pode receber e retransmitir bytes cifrados, mas não ler o conteúdo. O CI compara o AES-CTR do `CryptoEngine` com OpenSSL em cinco casos sintéticos e integra um ciphertext sintético ao percurso Protobuf/MQTT. A validação com payload capturado de dispositivo real e a integração com hardware continuam pendentes.

## Limitações conhecidas

Os testes não comprovam interoperabilidade integral com hardware, criptografia de payload capturado de dispositivo real, confidencialidade ponta a ponta de todo o percurso, segurança de produção, alcance ou retransmissão LoRa. O teste direto valida AES-CTR no ambiente nativo para uma entrada sintética. Resultados ainda não executados não devem ser descritos como aprovados.


## Integração do ciphertext do firmware com Protobuf e MQTT

A workflow criptográfica também executa `scripts/check_firmware_crypto_protobuf_mqtt.sh` após a suíte oficial. O script recolhe o ciphertext do quinto caso produzido por `CryptoEngine::encryptPacket()`, constrói um `ServiceEnvelope` com o esquema oficial fixado, verifica a decodificação Protobuf e publica o envelope binário num Mosquitto descartável. Dois clientes recebem a mensagem e comparam o envelope recebido byte a byte com o publicado.

Essa verificação liga a saída do código criptográfico do firmware (em teste nativo e com entradas sintéticas) à serialização Protobuf e ao transporte MQTT. Não é uma captura de rádio, não comprova interoperabilidade integral de um dispositivo e não testa ACL nem segurança geral do sistema. O broker anônimo e a mensagem retida existem somente no ambiente descartável do teste.
