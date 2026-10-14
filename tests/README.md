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

## Verificação básica de autenticação

O script `scripts/check_mqtt_auth.sh` inicia um broker descartável com autenticação obrigatória e credenciais temporárias geradas durante a execução.

Execute na raiz do repositório:

```sh
bash scripts/check_mqtt_auth.sh
```

O teste verifica que:

- uma publicação anônima é recusada;
- uma senha inválida é recusada;
- um cliente com credenciais válidas consegue publicar e outro cliente autenticado recebe a mensagem.

## Limitações conhecidas

Os testes atuais **não** comprovam:

- criptografia de canais Meshtastic ou confidencialidade do payload;
- autorização por ACL;
- compatibilidade com Protobufs ou com o protocolo Meshtastic;
- comportamento de rádio LoRa, alcance ou retransmissão;
- segurança de uma configuração de produção.

Resultados ainda não executados não devem ser descritos como aprovados.
