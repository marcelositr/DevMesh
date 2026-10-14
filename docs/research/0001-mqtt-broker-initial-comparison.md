# Pesquisa técnica: comparação inicial de brokers MQTT

**Data da pesquisa:** 2026-10-13  
**Estado:** levantamento documental inicial; nenhuma implementação ou benchmark foi executado.  
**Objetivo:** identificar opções para uma primeira prova de conceito do DevMesh sem antecipar uma decisão de arquitetura.

## Resumo

Mosquitto e EMQX são candidatos válidos para testes, mas têm perfis e condições de licenciamento diferentes.

- **Eclipse Mosquitto:** broker MQTT descrito pelo projeto como leve, com suporte a MQTT 5.0, 3.1.1 e 3.1. Oferece autenticação por senha, plugins de autenticação, controle de acesso e um plugin de segurança dinâmica. A documentação também descreve persistência de estado e mensagens.
- **EMQX:** plataforma de broker com recursos de autenticação e autorização, integração com fontes externas e ferramentas operacionais adicionais. A partir da versão 5.9.0, o projeto passou a distribuir o EMQX sob a Business Source License (BSL) 1.1. Essa licença tem condições diferentes das licenças open source aprovadas pela OSI e exige análise cuidadosa para qualquer implantação, redistribuição ou oferta como serviço.

**Conclusão provisória:** testar primeiro Mosquitto pode ser a forma mais simples de estabelecer uma linha de base pequena e compreensível. Isso é uma hipótese de trabalho, não uma decisão final nem uma afirmação de superioridade de desempenho. EMQX permanece como candidato caso os testes revelem requisitos que justifiquem sua complexidade e suas condições de licenciamento.

## Comparação inicial

| Critério | Eclipse Mosquitto | EMQX |
|---|---|---|
| Papel principal | Broker MQTT leve e ferramentas de cliente | Broker com recursos adicionais de operação, integração e escala |
| Protocolos MQTT documentados | MQTT 5.0, 3.1.1 e 3.1 | MQTT 3.x e MQTT 5.0 na documentação atual |
| Autenticação | Arquivo de senhas e plugins, incluindo segurança dinâmica | Senha, certificados X.509, JWT, PSK e outros mecanismos, conforme edição e configuração |
| Autorização | ACL por tópico e plugin de segurança dinâmica com clientes, grupos e funções | Regras de autorização internas e integrações externas, conforme implantação |
| Persistência | Persistência integrada; documentação também descreve plugin de persistência SQLite | Opções de persistência dependem da versão e da edição; confirmar na configuração que será testada |
| Operação | Configuração e ferramentas de linha de comando; interfaces adicionais podem exigir componentes externos | Inclui recursos de gestão, API e painel; recursos disponíveis variam por versão e modelo de implantação |
| Licenciamento do projeto | EPL-2.0 ou EDL-1.0 (BSD-3-Clause), conforme os avisos oficiais | Desde 5.9.0, BSL 1.1; verificar o texto e as condições da versão exata antes de usar |
| Principal pergunta para o DevMesh | É suficiente para autenticação, ACLs, persistência e integração pretendidas? | Os recursos extras justificam o custo operacional e as restrições de licença aplicáveis? |

Esta tabela é uma leitura inicial da documentação oficial, não uma comparação de desempenho. A disponibilidade de recursos pode depender da versão, do pacote, dos plugins e do modo de implantação.

## Requisitos que precisamos testar

1. **Conectividade básica:** cliente conecta, publica e recebe mensagens nos tópicos esperados.
2. **Autenticação:** conexão anônima é recusada quando não permitida; credenciais válidas e inválidas produzem os resultados esperados.
3. **Autorização por tópico:** um cliente não consegue publicar ou assinar tópicos fora de suas permissões.
4. **TLS:** conexões protegidas funcionam e clientes com certificados ou configurações inválidas são recusados conforme a política definida.
5. **Reconexão:** o cliente volta a conectar após uma interrupção, sem gerar comportamento inesperado.
6. **Persistência:** verificar quais sessões, inscrições e mensagens sobrevivem a uma reinicialização, conforme a configuração.
7. **Mensagens repetidas e QoS:** documentar o comportamento observado sem prometer entrega exatamente uma vez em todo o sistema.
8. **Recursos do sistema:** medir uso de memória, CPU e comportamento com uma carga de teste declarada; não usar adjetivos como “mais leve” como substituto de medições.
9. **Operação e recuperação:** confirmar como aplicar alterações de configuração, rotacionar credenciais, registrar eventos e recuperar o serviço após falha.
10. **Licença e redistribuição:** revisar a licença da versão e de cada componente adicional antes de publicar imagens, binários ou uma oferta hospedada.

## Limites e cuidados

- MQTT é um transporte de mensagens, não uma garantia de que todos os dados recebidos são seguros, autênticos ou adequados para retransmissão em rádio.
- A autorização do broker deve ser projetada para limitar publicação e assinatura por cliente. Não presumir que autenticação sozinha protege os tópicos.
- O tráfego entre o broker e as integrações não deve ser retransmitido automaticamente para LoRa. É necessário definir filtros, limites, prevenção de loops, limites de taxa e regras para preservar o tempo de transmissão.
- Não armazenar credenciais, certificados privados ou dados pessoais reais nos arquivos de teste ou nos registros públicos.
- A compatibilidade específica com a integração MQTT do Meshtastic ainda precisa ser confirmada em testes; este documento não afirma que a integração já foi validada.

## Próxima etapa proposta

Criar um ambiente de teste reproduzível com Mosquitto e clientes MQTT padrão, sem conectá-lo a uma rede de rádio pública. Validar os requisitos acima, registrar comandos, configurações não secretas, resultados observados e versões exatas. Em seguida, decidir se há justificativa concreta para repetir os mesmos testes com EMQX.

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
