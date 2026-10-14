# Decisão 0001: modelo inicial de governança

- **Status:** aceita
- **Data:** 2026-10-13
- **Responsável pela decisão:** pessoa responsável pelo projeto
- **Política relacionada:** [GOVERNANCE.md](../../GOVERNANCE.md)

## Contexto

O DevMesh está em fase inicial. Precisa de responsabilidades claras e de uma forma prática de tomar decisões agora, mantendo espaço para maior participação comunitária conforme crescer.

## Decisão

Adotar inicialmente um modelo híbrido liderado pelo fundador:

- O fundador atua como responsável pelo projeto e responde pelas decisões relevantes.
- Outros mantenedores podem ser nomeados com responsabilidades explícitas e documentadas.
- A comunidade pode participar e propor alterações sem receber automaticamente privilégios administrativos.
- Mudanças fundamentais de governança exigem uma proposta pública, pelo menos 14 dias corridos para comentários, um resumo das objeções relevantes e aprovação explícita conforme as regras de GOVERNANCE.md.
- Depois que um grupo de mantenedores for formalmente estabelecido, mudanças protegidas de governança também exigirão aprovação de pelo menos dois terços dos mantenedores ativos, arredondada para cima.
- Sucessão e recuperação de acesso devem ser planejadas desde o início, não apenas após um incidente.

## Alternativas consideradas

1. **Controle unilateral permanente do fundador:** simples no início, mas cria riscos de continuidade e responsabilidade.
2. **Governança coletiva desde o primeiro dia:** prematura enquanto não houver mantenedores e responsabilidades estabelecidos.
3. **Governança híbrida liderada pelo fundador:** oferece responsabilidade inicial clara e define um caminho para compartilhar responsabilidades.

## Consequências

- O projeto pode tomar decisões iniciais sem fingir que já existe um conselho comunitário.
- Decisões importantes precisam ser documentadas e o processo de governança deve ser seguido na prática.
- Permissões do repositório, procedimentos de recuperação, cópias de segurança e práticas de segurança ainda precisam ser configurados separadamente; este registro não os impõe automaticamente.
- As regras de governança devem ser revisadas após testes práticos e conforme o crescimento do projeto.

## Acompanhamento

- Configurar proteções de branch e requisitos de revisão adequados quando as configurações do repositório e o plano permitirem.
- Manter CONTRIBUTING.md, SECURITY.md e TRADEMARKS.md sem duplicar esta política.
- Estabelecer procedimentos práticos de sucessão e recuperação de credenciais sem armazenar segredos no Git.
