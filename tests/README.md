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

## Limitações conhecidas

Este é somente um teste de conectividade e roteamento MQTT. Ele **não** comprova:

- criptografia de canais Meshtastic ou confidencialidade do payload;
- autenticação MQTT ou autorização por ACL;
- compatibilidade com Protobufs ou com o protocolo Meshtastic;
- comportamento de rádio LoRa, alcance ou retransmissão;
- segurança de uma configuração de produção.

Essas verificações serão implementadas separadamente, depois de definidos os critérios técnicos correspondentes. Resultados ainda não executados não devem ser descritos como aprovados.
