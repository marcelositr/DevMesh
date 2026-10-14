# Como contribuir com o DevMesh

Obrigado pelo interesse em contribuir com o DevMesh. São bem-vindos relatos de erros, melhorias na documentação, testes, ideias e código.

O DevMesh é um projeto independente e comunitário de infraestrutura MQTT, planejado para dar suporte a redes de rádio compatíveis com Meshtastic e a futuras integrações. Não é um projeto oficial do Meshtastic. Consulte o [README.md](README.md) para conhecer o projeto e [GOVERNANCE.md](GOVERNANCE.md) para entender os papéis e o processo de decisão.

## Antes de contribuir

1. Pesquise as questões e discussões existentes para evitar trabalho duplicado.
2. Antes de uma alteração substancial, abra uma questão ou discussão para que o objetivo e o escopo possam ser debatidos.
3. Mantenha as contribuições focadas. Prefira alterações pequenas e compreensíveis a conjuntos de mudanças sem relação entre si.
4. Não inclua senhas, tokens de acesso, chaves privadas, códigos de recuperação, dados pessoais ou outros segredos em questões, commits, registros ou arquivos de teste.
5. Se suspeitar de uma vulnerabilidade, não publique detalhes técnicos em uma questão pública. Consulte [SECURITY.md](SECURITY.md). Enquanto não houver um canal privado de segurança publicado, peça uma forma privada de contato sem incluir detalhes sensíveis.

## Idioma e convenções

O idioma preferencial da documentação voltada às pessoas é o português brasileiro. Comentários explicativos no código e comentários em arquivos de configuração também devem ser escritos em português brasileiro sempre que possível.

O código-fonte, nomes de variáveis e funções, identificadores de programação, nomes de protocolos, chaves de configuração exigidas por ferramentas e interfaces públicas devem seguir as convenções técnicas do ecossistema correspondente, normalmente em inglês. Não traduza identificadores exigidos por protocolos ou ferramentas. Quando útil, explique seu significado em português na documentação ou em comentários.

## Questões e propostas

Ao relatar um erro, descreva o comportamento observado, o comportamento esperado, os passos para reproduzi-lo e os detalhes relevantes do ambiente. Remova segredos e dados pessoais dos registros antes de compartilhá-los.

Ao propor um recurso, explique o problema que ele resolve, quem se beneficia, as alternativas possíveis e os efeitos sobre privacidade, segurança, tráfego de rede e compatibilidade.

Uma questão ou discussão é uma proposta, não um compromisso de implementação.

## Solicitações de alteração (*pull requests*)

- Explique o que mudou e por quê.
- Relacione questões ou registros de decisão pertinentes, quando houver.
- Atualize a documentação quando o comportamento, a instalação, a configuração ou as expectativas de uso mudarem.
- Inclua testes ou passos reproduzíveis de verificação quando viável. Não afirme que testes passaram se eles não foram executados.
- Identifique limitações conhecidas e comportamentos que ainda precisam ser testados.
- Mantenha cada solicitação focada e fácil de revisar.
- Esteja preparado para revisar a contribuição conforme o retorno da revisão.

Não introduza dependências, mudanças de protocolo, APIs públicas ou alterações incompatíveis sem explicar a necessidade e as alternativas.

## Considerações técnicas e de rede

Como o DevMesh pretende trabalhar com MQTT e redes de rádio, as contribuições devem considerar:

- volume desnecessário de mensagens e possível impacto no tempo de transmissão LoRa;
- formatos de pacotes, compatibilidade e limites da criptografia;
- autenticação e autorização por tópico;
- metadados sensíveis à privacidade e registros de eventos;
- tratamento de falhas, reconexões e mensagens duplicadas.

Esses itens são critérios de revisão, não afirmações de que todos os controles ou projetos técnicos já estejam implementados. O comportamento confirmado será documentado à medida que os testes avançarem.

## Revisão e decisões

As contribuições são avaliadas conforme [GOVERNANCE.md](GOVERNANCE.md). Enviar uma solicitação de alteração não garante sua aceitação. Mantenedores podem pedir ajustes, adiar o trabalho ou encerrar uma proposta com uma explicação.

Decisões técnicas relevantes devem ser registradas em [docs/decisions/](docs/decisions/), com links para a discussão pertinente em vez de repetir seu conteúdo.

Siga o [Código de Conduta](CODE_OF_CONDUCT.md).

## Licença e atribuição

A contribuição deverá ser distribuída sob os termos de licença aplicáveis ao projeto, respeitando os direitos que você possui sobre o material enviado. O arquivo [LICENSE](LICENSE) contém o texto integral da **GNU Affero General Public License, versão 3**, e identifica a opção de licenciamento da versão atual como **versão 3 ou posterior**. A licença não substitui a governança do projeto, e a governança não altera os termos da licença.

Envie apenas material que tenha direito de contribuir e identifique material de terceiros e suas licenças. A licença e a governança do projeto são assuntos distintos. Consulte [LICENSE](LICENSE) e [GOVERNANCE.md](GOVERNANCE.md). Se houver dúvida sobre os termos ou a situação de uma contribuição, pergunte antes de enviá-la.

## Estágio atual do projeto

O DevMesh está na fase inicial de planejamento e validação. Algumas escolhas técnicas, procedimentos de teste e políticas operacionais ainda não são definitivos. Diferencie resultados verificados de suposições e não descreva recursos propostos como se já estivessem implementados.
