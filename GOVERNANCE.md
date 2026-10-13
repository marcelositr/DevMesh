# Governança do DevMesh

**Status:** política inicial  
**Versão:** 0.1  
**Última atualização:** 2026-10-13

Este documento define como o projeto DevMesh é mantido e como as decisões são tomadas. As etapas técnicas de contribuição estão em [CONTRIBUTING.md](CONTRIBUTING.md), o tratamento de vulnerabilidades está em [SECURITY.md](SECURITY.md), e a licença define os direitos autorais e as permissões de uso do software.

## 1. Missão e escopo

O DevMesh é um projeto independente e comunitário de infraestrutura MQTT, planejado para oferecer suporte a redes de rádio compatíveis com Meshtastic e permitir futuras integrações com APIs, serviços públicos brasileiros e bots.

O DevMesh não é um projeto oficial do Meshtastic e não deve sugerir endosso ou afiliação por parte do Meshtastic ou de terceiros.

## 2. Princípios de governança

A governança do projeto segue estes princípios:

- **Transparência:** decisões relevantes e seus fundamentos são registrados publicamente sempre que isso não expuser informações pessoais ou dados sensíveis à segurança.
- **Participação comunitária:** qualquer pessoa pode propor melhorias, relatar problemas e participar respeitosamente das discussões públicas.
- **Responsabilidade:** mantenedores devem explicar decisões relevantes e administrar conflitos de interesse.
- **Segurança e privacidade:** a participação pública não concede acesso a credenciais, dados privados de usuários, sistemas de produção ou permissões administrativas.
- **Proporcionalidade:** os processos devem proteger o projeto sem criar burocracia desnecessária para tarefas rotineiras.
- **Continuidade:** o conhecimento do projeto, a recuperação de acesso e a sucessão não devem depender exclusivamente de acordos pessoais não documentados.

## 3. Papéis e autoridade

### Fundador e responsável pelo projeto

Na fase inicial, o fundador atua como responsável pelo projeto e coordena sua direção, as versões publicadas, a administração do repositório e a nomeação de outros mantenedores. Decisões relevantes devem ser documentadas e seguir o processo de alteração protegida da Seção 5.

Essa organização inicial não representa um direito permanente de controlar todos os serviços comunitários futuros. À medida que o projeto ganhar mantenedores ativos, as responsabilidades deverão ser delegadas com critérios documentados.

### Mantenedores

Mantenedores são colaboradores de confiança convidados explicitamente a assumir responsabilidades contínuas. O escopo de autoridade deve ser registrado na nomeação, por exemplo: revisão de código, versões, infraestrutura, documentação ou resposta a incidentes de segurança.

Mantenedores devem revisar alterações dentro de suas responsabilidades, declarar conflitos de interesse relevantes e evitar aprovar suas próprias alterações de alto impacto quando uma revisão independente estiver razoavelmente disponível.

### Colaboradores e comunidade

Qualquer pessoa pode contribuir por meio de questões, discussões, documentação, testes ou solicitações de alteração (*pull requests*). Participar não concede automaticamente o status de mantenedor nem acesso administrativo.

## 4. Tomada de decisões

- Alterações rotineiras e reversíveis podem seguir o fluxo normal de contribuição.
- Decisões técnicas ou operacionais relevantes devem registrar seus fundamentos e as alternativas consideradas.
- Decisões que afetem segurança, privacidade, acesso à rede, regras comunitárias ou direção do projeto exigem cuidado adicional e oportunidade de manifestação pública quando a divulgação for segura.
- Os mantenedores devem buscar consenso quando viável. Se não houver consenso, a pessoa responsável pela decisão deverá explicar o resultado e seus fundamentos.
- Ações emergenciais podem ser tomadas para proteger usuários ou infraestrutura. A ação e sua justificativa devem ser documentadas assim que for seguro fazê-lo.

Os registros de decisão ficam em [docs/decisions/](docs/decisions/). Cada registro deve apontar para as discussões relevantes em vez de copiá-las integralmente.

## 5. Alterações protegidas na governança

Alterações neste documento ou nos princípios fundamentais de governança não podem ser incorporadas como edições rotineiras.

Uma proposta deve:

1. Ser anunciada em uma questão ou discussão pública, com a alteração exata e sua justificativa.
2. Permanecer aberta a comentários por pelo menos 14 dias corridos, exceto quando uma alteração urgente e estritamente delimitada for necessária para responder a um risco legal ou de segurança imediato.
3. Resumir objeções relevantes e explicar como foram consideradas.
4. Receber aprovação explícita da pessoa responsável pelo projeto durante a fase liderada pelo fundador.
5. Depois da formalização de um grupo de mantenedores, receber também a aprovação de pelo menos dois terços dos mantenedores ativos, arredondada para cima, além da aprovação da pessoa responsável pelo projeto. Uma exceção emergencial deve ser documentada e revisada posteriormente.

O projeto não deve afirmar que uma alteração foi aprovada pela comunidade se o processo exigido não tiver sido realizado. As permissões do GitHub e as proteções de branch deverão ser configuradas para apoiar esta política quando o plano e as configurações do repositório permitirem.

## 6. Nomeação e remoção de mantenedores

As nomeações devem ser explícitas, aceitas pela pessoa nomeada e documentadas com suas responsabilidades.

Um mantenedor pode deixar a função a qualquer momento. O acesso pode ser suspenso imediatamente quando isso for razoavelmente necessário para conter um incidente de segurança ou evitar danos. Outras remoções devem ter justificativa documentada e, quando for seguro e apropriado, uma oportunidade justa de resposta.

Quando a pessoa envolvida for a responsável pelo projeto, os procedimentos de sucessão e resolução de conflitos devem ser seguidos. A liderança não está isenta de responsabilidade.

## 7. Conflitos de interesse e divergências

Pessoas que participem de decisões devem declarar conflitos de interesse relevantes. Divergências devem se concentrar em evidências, objetivos do projeto e consequências, sem ataques pessoais.

Relatos de conduta inadequada devem ser tratados com discrição e imparcialidade. Relatos de segurança, informações pessoais e acusações sensíveis não devem ser obrigados a passar por questões públicas.

## 8. Continuidade e sucessão

O projeto deve manter um plano de sucessão que contemple:

- recuperação de acesso ao repositório e aos serviços essenciais;
- armazenamento seguro e rotação de credenciais fora do repositório;
- cópias de segurança de configurações e registros essenciais;
- delegação de manutenção emergencial a pessoas de confiança;
- transferência ou recuperação das responsabilidades operacionais caso a liderança fique indisponível.

O procedimento detalhado está em [docs/CONTINUITY.md](docs/CONTINUITY.md).

Este documento não transfere, por si só, a titularidade de uma conta do GitHub, domínio, hospedagem, marca ou outro ativo. Esses recursos exigem procedimentos adequados de acesso e recuperação fora deste documento. Senhas, tokens, chaves privadas e códigos de recuperação nunca devem ser enviados ao repositório.

Até que uma pessoa sucessora ou mantenedora delegada aceite explicitamente a responsabilidade, ninguém deve ser considerado autorizado apenas por ter contribuído para o projeto.

## 9. Relação com as demais políticas

- [README.md](README.md): apresentação pública do projeto.
- [CONTRIBUTING.md](CONTRIBUTING.md): fluxo de contribuição.
- [SECURITY.md](SECURITY.md): comunicação e tratamento de vulnerabilidades.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md): convivência comunitária.
- [TRADEMARKS.md](TRADEMARKS.md): uso do nome e da identidade visual.
- [LICENSE](LICENSE): termos de direitos autorais e licenciamento do software.

Em caso de conflito, os termos legais da licença determinam as permissões de uso do software; questões sensíveis de segurança devem seguir o processo de segurança; e as decisões de governança devem ser interpretadas de forma coerente com este documento e com a legislação aplicável.

## 10. Alterações e revisão

Esta é a política inicial de governança. Ela deve ser revisada após o primeiro protótipo prático, quando novos mantenedores forem nomeados e sempre que os riscos operacionais do projeto mudarem de forma relevante. A revisão não pode ser usada para contornar a Seção 5.
