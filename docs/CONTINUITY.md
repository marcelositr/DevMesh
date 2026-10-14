# Continuidade e sucessão do projeto

## Objetivo

Este documento descreve como o DevMesh pode continuar funcionando se a pessoa responsável pelo projeto ou um mantenedor ficar indisponível, perder acesso ou deixar a função. Ele complementa [GOVERNANCE.md](../GOVERNANCE.md); não substitui os procedimentos de recuperação de conta do GitHub nem concede acesso a qualquer conta.

## Princípios

As decisões de continuidade devem proteger o projeto e a comunidade, preservando transparência, segurança e os termos da licença aplicável.

- Sempre que razoavelmente possível, não concentre todo o conhecimento essencial ou todas as instruções operacionais em uma única pessoa.
- Nunca armazene senhas, códigos de recuperação, tokens de acesso, chaves privadas ou outras credenciais neste repositório.
- Conceda acesso apenas a quem precisa dele, com o menor nível de permissão disponível.
- Registre transferências relevantes de responsabilidade sem publicar detalhes confidenciais de segurança ou informações pessoais.
- Não presuma que o GitHub ou outro serviço conseguirá recuperar o acesso a uma conta.

## Responsabilidades planejadas

Inicialmente, a pessoa responsável pelo projeto coordena a direção, a governança e a administração dos acessos. Conforme forem nomeados mantenedores, as responsabilidades devem ser divididas e documentadas, incluindo quem pode manter o código, publicar versões, tratar relatos de segurança e administrar serviços essenciais.

O projeto deve manter um registro atualizado e não sensível de:

- Papéis e responsabilidades atribuídos.
- Serviços essenciais e seus responsáveis operacionais.
- Localização das instruções operacionais oficiais.
- Responsabilidades que ainda dependem de uma única pessoa e precisam de um plano de continuidade.

Não publique contatos privados nem informações sensíveis sobre a infraestrutura sem necessidade clara e autorização.

## Indisponibilidade temporária

Se a pessoa responsável pelo projeto estiver temporariamente indisponível, os mantenedores podem continuar tarefas rotineiras e reversíveis dentro de suas responsabilidades. Devem adiar grandes mudanças de governança, transferências de titularidade e outras decisões irreversíveis, exceto quando uma ação urgente for necessária para evitar dano significativo.

Em incidentes urgentes de segurança ou de serviço, os mantenedores disponíveis podem tomar medidas proporcionais de proteção dentro dos acessos e da autoridade que já possuem. Quando for seguro, devem documentar a ação e sua justificativa.

## Saída ou indisponibilidade permanente

Se a pessoa responsável pelo projeto deixar a função ou ficar permanentemente indisponível:

1. Identifique quais mantenedores estão disponíveis e dispostos a assumir responsabilidades.
2. Consulte as regras de governança vigentes e os procedimentos de sucessão já registrados.
3. Escolha uma liderança interina entre mantenedores de confiança que aceitem a função, por meio de uma decisão documentada.
4. Comunique a mudança publicamente quando for apropriado e seguro.
5. Revise as responsabilidades pelo repositório, serviços, versões e relatos de segurança; transfira os acessos usando os mecanismos oficiais das plataformas envolvidas.
6. Registre a decisão e os riscos ainda não resolvidos, sem expor credenciais ou informações pessoais sensíveis.

Se não houver um mantenedor adequado disponível, o projeto deve declarar que a liderança está indefinida, em vez de sugerir que alguém foi nomeado sucessor. As atividades rotineiras podem ser pausadas até que seja possível estabelecer uma liderança responsável.

Mudanças permanentes na governança ou no modelo de liderança devem seguir [GOVERNANCE.md](../GOVERNANCE.md), incluindo o processo reforçado para alterações protegidas.

## Recuperação de contas e serviços

A recuperação deve usar os mecanismos oficiais de recuperação de conta e gerenciamento de acesso de cada provedor. Não tente contornar controles de acesso nem assumir a conta de outra pessoa.

Quando houver suporte, o projeto deve:

- Manter mais de uma pessoa devidamente autorizada como administradora de recursos compartilhados críticos.
- Usar contas individuais, em vez de compartilhar credenciais pessoais.
- Ativar as proteções de segurança disponíveis nas contas.
- Guardar instruções de recuperação em local com acesso controlado, fora deste repositório público.
- Verificar periodicamente se os mantenedores designados conseguem executar tarefas administrativas necessárias.
- Remover ou ajustar acessos prontamente quando alguém deixar sua função, preservando a continuidade legítima do projeto.

O repositório não deve conter códigos de recuperação, segredos, chaves privadas, documentos pessoais de identidade ou instruções que exponham contas e serviços a comprometimento.

## Divergências e salvaguardas

Uma decisão de sucessão deve ser documentada e seguir o processo de governança. Pessoas com conflito de interesse direto devem declará-lo e, quando viável, evitar atuar como única pessoa decisora.

Nenhum documento de continuidade pode garantir acesso a uma conta pessoal, provedor de hospedagem, domínio ou serviço externo. O projeto deve reduzir dependências de uma única pessoa ao longo do tempo e ser transparente sobre as limitações ainda não resolvidas.

## Revisão

Revise este documento quando forem nomeados mantenedores, serviços críticos forem introduzidos, os acessos mudarem ou ocorrer uma sucessão. Consulte também [GOVERNANCE.md](../GOVERNANCE.md), [SECURITY.md](../SECURITY.md) e [CONTRIBUTING.md](../CONTRIBUTING.md).
