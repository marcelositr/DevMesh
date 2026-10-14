# Pesquisa técnica: comparação inicial de brokers MQTT

**Data da pesquisa:** 2026-10-13  
**Estado:** levantamento documental inicial; nenhum benchmark foi executado.  
**Objetivo:** comparar opções para orientar a arquitetura inicial do DevMesh, sem confundir critérios de avaliação futura com requisitos imediatos do protótipo.

## Resumo

Mosquitto e EMQX são candidatos válidos, com perfis operacionais e condições de licenciamento diferentes.

- **Eclipse Mosquitto:** broker MQTT descrito pelo projeto como leve, com suporte a MQTT 5.0, 3.1.1 e 3.1. Oferece autenticação, controle de acesso e persistência conforme a versão e a configuração.
- **EMQX:** plataforma de broker com recursos adicionais de autenticação, autorização, integração e operação. A partir da versão 5.9.0, o projeto passou a distribuir o EMQX sob a Business Source License (BSL) 1.1. Verifique a licença e as condições da versão exata antes de usar.

A escolha do Mosquitto para o início está registrada em [ADR 0002](../decisions/0002-adoption-of-eclipse-mosquitto.md). Esta pesquisa não demonstra superioridade de desempenho. O objetivo da primeira etapa é validar o comportamento essencial com o menor custo operacional razoável.

O escopo doméstico inicial e a aplicação proporcional dos controles de segurança estão definidos na [decisão 0003](../decisions/0003-home-first-scope-and-proportionate-security.md).

## Comparação inicial

| Critério | Eclipse Mosquitto | EMQX |
|---|---|---|
| Papel principal | Broker MQTT dedicado | Broker com recursos adicionais de operação, integração e escala |
| Protocolos MQTT documentados | MQTT 5.0, 3.1.1 e 3.1 | MQTT 3.x e MQTT 5.0 na documentação atual |
| Autenticação | Arquivo de senhas e plugins, conforme versão e configuração | Senha, certificados X.509, JWT, PSK e outros mecanismos, conforme edição e configuração |
| Autorização | ACL por tópico e recursos de plugins | Regras internas e integrações externas, conforme implantação |
| Persistência | Persistência integrada; opções adicionais podem variar por versão | Opções dependem da versão e da edição |
| Operação | Configuração e ferramentas de linha de comando | Recursos de gestão e operação adicionais; disponibilidade varia por versão e implantação |
| Licenciamento do projeto | EPL-2.0 ou EDL-1.0 (BSD-3-Clause), conforme avisos oficiais | Desde 5.9.0, BSL 1.1; conferir a versão exata |
| Pergunta para o DevMesh | Atende às necessidades reais com baixa complexidade? | Recursos adicionais justificam o custo operacional e as condições de licença? |

Esta tabela é uma leitura documental inicial, não uma comparação de desempenho. A disponibilidade de recursos pode depender da versão, do pacote, dos plugins e do modo de implantação.

## Plano de validação por etapas

### Etapa inicial: protótipo doméstico

Prioridades para o ambiente de CI com broker efêmero e três clientes simulados:

1. **Conectividade e roteamento:** verificar conexões, publicação, assinatura e entrega nos tópicos esperados.
2. **Isolamento do ambiente de teste:** garantir que o broker de teste seja descartável e não fique exposto como serviço público.
3. **Limites dos resultados:** deixar explícito que o teste de roteamento por tópico não comprova ACL, autenticação, criptografia Meshtastic ou comportamento de rádio.

O teste de CI atual cobre a conectividade e o roteamento básico. A configuração anônima existente é exclusiva do ambiente isolado de teste e não deve ser usada como configuração de implantação.

### Antes de recomendar uma configuração para uso doméstico

1. Habilitar autenticação para clientes de rede e confirmar que credenciais inválidas e conexões não autorizadas são recusadas.
2. Manter o broker fora do acesso direto pela internet por padrão e verificar quais interfaces e portas ficam expostas.
3. Definir e testar ACLs quando for necessário separar clientes ou limitar publicação e assinatura por tópico.
4. Guardar senhas e outros segredos fora do controle de versão.

### Se o escopo passar a incluir redes não confiáveis ou acesso remoto

1. Definir e testar a proteção do transporte, por exemplo TLS ou uma VPN adequadamente configurada.
2. Confirmar permissões por cliente e tópicos, além da autenticação.
3. Testar reconexão, limites de taxa, persistência e comportamento após reinicialização conforme as necessidades do cenário.
4. Avaliar consumo de memória/CPU e carga somente quando houver um requisito concreto a medir.
5. Rever licenças e obrigações de redistribuição de cada versão e componente utilizado.

Esses itens formam um plano progressivo, não uma exigência de implementar todos os mecanismos no primeiro protótipo.

## Limites e cuidados

- MQTT é um transporte de mensagens, não uma garantia de que os dados recebidos são autênticos, privados ou adequados para retransmissão em rádio.
- Autenticação e autorização são controles diferentes. A necessidade de ACLs depende dos clientes, dos tópicos e do modelo de confiança.
- TLS protege o transporte, mas não criptografa automaticamente o conteúdo de ponta a ponta.
- A criptografia de canais Meshtastic é uma camada separada. A compatibilidade com cada tipo de pacote encaminhado via MQTT ainda precisa ser verificada.
- O tráfego entre o broker e futuras integrações não deve ser retransmitido automaticamente para LoRa. Antes disso, definir filtros, limites, prevenção de loops e regras para controlar o tempo de transmissão.
- Não armazenar credenciais, certificados privados ou dados pessoais reais nos arquivos de teste ou nos registros públicos.
- Testes com nós simulados validam o comportamento do software e do broker, não o alcance nem as características físicas de um enlace LoRa.

## Próxima etapa

Manter o teste de CI como linha de base e evoluí-lo apenas para cobrir requisitos acordados para a próxima etapa. Antes de recomendar uma configuração de implantação, verificar a versão exata do Mosquitto, a configuração efetiva, a exposição de portas e os controles realmente habilitados. Não declarar segurança ou prontidão para produção com base somente no teste de conectividade.

## Fontes oficiais consultadas

- [Eclipse Mosquitto: site do projeto](https://mosquitto.org/)
- [Eclipse Mosquitto: documentação](https://www.mosquitto.org/documentation/)
- [Eclipse Mosquitto: autenticação](https://www.mosquitto.org/documentation/authentication-methods/)
- [Eclipse Mosquitto: plugin de segurança dinâmica](https://mosquitto.org/documentation/dynamic-security/)
- [Eclipse Mosquitto: persistência SQLite](https://www.mosquitto.org/documentation/persistence/sqlite/)
- [Eclipse Mosquitto: avisos de licença do repositório](https://github.com/eclipse-mosquitto/mosquitto/blob/master/LICENSE.txt)
- [EMQX: autenticação](https://docs.emqx.com/en/emqx/latest/guides/access-control/authn/authn.html)
- [EMQX: autorização](https://docs.emqx.com/en/cloud/latest/deployments/authz_overview.html)
- [EMQX: perguntas frequentes sobre licenciamento](https://www.emqx.com/en/content/license-faq)
- [EMQX: documentação de licença](https://docs.emqx.com/en/emqx/latest/get-started/deploy/license.html)

**Nota de atualização:** páginas de documentação e condições de licença podem mudar. Antes de uma decisão de implantação, conferir novamente as fontes e registrar a versão exata avaliada.
