# ADR 0002: adoção do Eclipse Mosquitto como broker MQTT inicial

- **Estado:** aceita
- **Data:** 2026-10-13
- **Decisores:** responsável pelo projeto
- **Escopo:** arquitetura inicial do DevMesh

## Contexto

O DevMesh precisa de um broker MQTT para formar a base de uma infraestrutura independente voltada a redes de rádio compatíveis com Meshtastic e a futuras integrações. O projeto está em fase inicial e deve evitar complexidade prematura e dependências operacionais desnecessárias.

A comparação documental inicial de brokers está registrada em [0001: comparação inicial de brokers MQTT](../research/0001-mqtt-broker-initial-comparison.md).

## Decisão

Adotar o **Eclipse Mosquitto** como broker MQTT da arquitetura inicial do DevMesh.

Esta decisão autoriza o uso do Mosquitto como escolha inicial de arquitetura. Não significa que o serviço já esteja implementado, implantado, protegido ou validado em testes.

## Motivos

- Manter a primeira versão simples e compreensível.
- Começar com um broker MQTT dedicado, sem adicionar uma plataforma maior antes de haver necessidade comprovada.
- Permitir que integrações e serviços auxiliares evoluam separadamente do broker.
- Reduzir o número de decisões simultâneas e avançar em etapas pequenas.

## Consequências

- A documentação técnica e os próximos planos de implementação devem usar o Mosquitto como broker de referência.
- O projeto ainda precisará definir configuração, versão, implantação, persistência, monitoramento, atualização e recuperação.
- Autenticação, autorização por tópico, proteção do tráfego administrativo e TLS devem ser planejados antes de disponibilizar o serviço em uma rede não confiável.
- A integração específica com Meshtastic e qualquer retransmissão de mensagens para rádio ainda precisam de definição; a adoção do broker não comprova essa integração.
- APIs de serviços públicos brasileiros e bots permanecem fora do escopo imediato até que a base MQTT esteja definida.

## Segurança e operação

A implementação deverá, no mínimo:

1. Evitar acesso anônimo onde não for explicitamente necessário.
2. Aplicar permissões por tópico com o princípio do menor privilégio.
3. Proteger conexões e credenciais conforme o modelo de implantação.
4. Não expor portas administrativas ou serviços de gestão desnecessariamente.
5. Definir limites de mensagens e regras de retransmissão para evitar loops e tráfego excessivo em LoRa.
6. Manter credenciais e chaves privadas fora do controle de versão.
7. Documentar procedimentos de atualização, cópia de segurança e recuperação.

Estes são requisitos para o trabalho futuro, não controles que já estejam ativos.

## Alternativas consideradas

- **EMQX:** não selecionado para a arquitetura inicial. Seus recursos adicionais não são necessários para a primeira decisão de arquitetura; poderá ser reconsiderado se requisitos futuros justificarem a mudança.
- **Adiar a escolha do broker:** rejeitado para esta etapa, para permitir que o planejamento avance com uma base técnica definida.

## Validação e revisão

Nenhum benchmark ou teste prático é declarado por este registro. A escolha foi tomada como decisão de escopo e simplicidade inicial, não como resultado de uma comparação de desempenho.

Revisar esta decisão se houver requisitos que o Mosquitto não consiga atender de forma adequada, necessidade comprovada de recursos adicionais, ou mudança relevante nas condições de operação, manutenção ou licenciamento.

## Referências

- [Eclipse Mosquitto](https://mosquitto.org/)
- [Documentação oficial do Mosquitto](https://www.mosquitto.org/documentation/)
- [Pesquisa técnica inicial de brokers MQTT](../research/0001-mqtt-broker-initial-comparison.md)
