# Documentação do DevMesh

Esta pasta reúne a documentação técnica, as pesquisas, os registros de decisões e os procedimentos de continuidade do DevMesh.

## Documentos

- [Continuidade e sucessão](CONTINUITY.md): continuidade das responsabilidades, recuperação de acesso e transição de liderança.
- [Registros de decisões](decisions/README.md): decisões aprovadas, seus fundamentos e como registrar revisões.
- [Comparação inicial de brokers MQTT](research/0001-mqtt-broker-initial-comparison.md): pesquisa documental e requisitos técnicos, com distinção entre prioridades iniciais e verificações futuras.
- [Levantamento de equipamento Meshtastic](research/0002-meshtastic-device-inventory-and-traffic-survey.md): inventário de hardware, firmware, interfaces e observações de tráfego ainda incompletas.
- [Validação do downlink MQTT Meshtastic](research/0003-mqtt-downlink-validation.md): comportamento do firmware, testes de transporte e gerador local de envelope cifrado para canal privado.
- [Auditoria de compatibilidade dos dados Meshtastic](research/0004-meshtastic-data-compatibility-audit.md): localização, telemetria, metadados, privacidade, versões e plano de validação cruzada.
- [Contexto para ferramentas de IA](ai/README.md): orientações para retomar o trabalho sem confundir decisões aprovadas com hipóteses.

## Escopo e estado das informações

A primeira etapa prioriza uma instalação doméstica simples, com Mosquitto e três nós simulados. O acesso remoto pela internet e integrações adicionais estão fora do escopo inicial. Os controles de segurança serão aplicados conforme o risco e o modelo de confiança, sem confundir a configuração isolada de testes com uma configuração de implantação.

A [decisão sobre escopo doméstico e segurança proporcional](decisions/0003-home-first-scope-and-proportionate-security.md) registra esse acordo e define quando o projeto deve ampliar os controles.

## Princípios de documentação

- Escrever em português brasileiro, de forma objetiva e sem repetir conteúdo que já tenha um documento próprio.
- Linkar para a fonte principal em vez de copiar políticas inteiras para outros arquivos.
- Identificar o que foi decidido, o que está em avaliação e o que foi realmente testado.
- Não registrar segredos, credenciais, dados pessoais desnecessários ou informações privadas.
- Atualizar a documentação quando uma decisão ou comportamento confirmado mudar.

A apresentação geral do projeto fica no [README.md da raiz](../README.md). As regras de contribuição estão em [CONTRIBUTING.md](../CONTRIBUTING.md), e as decisões de governança ficam em [GOVERNANCE.md](../GOVERNANCE.md).
