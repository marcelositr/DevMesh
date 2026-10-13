# Política de Segurança

## Situação do projeto

O DevMesh está em fase inicial. As práticas e a infraestrutura de segurança podem mudar à medida que o projeto evoluir. Não presuma que já exista uma equipe de segurança dedicada, um sistema privado de recebimento de relatos, um programa de recompensa ou um prazo garantido de resposta.

Antes do uso em produção ou de uma divulgação pública mais ampla, os responsáveis pelo projeto devem publicar um canal privado funcional para comunicação de vulnerabilidades e identificar quem ficará responsável por receber e coordenar esses relatos.

## Como comunicar uma vulnerabilidade

Não publique detalhes de uma vulnerabilidade ainda não corrigida em questões, discussões, solicitações de alteração ou canais comunitários públicos.

Use um método privado de contato explicitamente publicado pela pessoa responsável pelo projeto ou por um mantenedor designado, se houver. **Atualmente, este documento não identifica um canal privado específico.** Se nenhum canal tiver sido publicado, não divulgue detalhes técnicos publicamente. Peça à pessoa responsável pelo projeto ou a um mantenedor uma forma de contato privado, sem incluir detalhes sensíveis nesse pedido.

Quando houver um canal privado disponível, forneça apenas as informações necessárias para avaliar o relato:

- Componente, versão, commit ou configuração afetada, se conhecida.
- Descrição concisa do possível impacto de segurança.
- Passos para reproduzir o problema ou uma prova de conceito, quando for seguro e necessário.
- Registros ou evidências pertinentes, sem credenciais, tokens, dados pessoais ou informações irrelevantes.
- Uma forma de contato para esclarecimentos, caso queira fornecê-la.

Não anexe segredos, chaves privadas, tokens de acesso, dados pessoais de usuários reais ou conjuntos completos de dados de produção.

## Testes seguros e autorizados

Teste apenas sistemas, dispositivos, redes e serviços que sejam seus ou para os quais você tenha autorização explícita. Não explore, interrompa, acesse ou modifique sistemas de terceiros ou dispositivos de outras pessoas durante a investigação.

Evite testes que possam causar interferência de radiofrequência, tráfego LoRa desnecessário, interrupção de serviços, exposição de dados ou danos. Sempre que possível, use um ambiente de teste controlado.

## Triagem e divulgação

Quando um relato chegar por um canal privado disponível, a pessoa responsável pelo projeto ou o mantenedor designado deverá:

1. Confirmar o recebimento quando for razoavelmente possível. Nesta fase, não há prazo fixo de resposta.
2. Avaliar a validade, a gravidade, as versões afetadas e o possível impacto.
3. Coordenar a investigação e a mitigação com os mantenedores pertinentes.
4. Limitar os detalhes do relato às pessoas que precisem deles durante o tratamento.
5. Coordenar a divulgação pública após a disponibilização de uma correção ou mitigação, quando viável e apropriado.
6. Publicar orientações de segurança ou um comunicado quando necessário e possível.

O projeto não promete atualmente recompensa por vulnerabilidades, atribuição de CVE ou prazo específico de divulgação. Essas possibilidades poderão ser consideradas no futuro, mas não devem ser tratadas como serviços existentes.

Pesquisadores só serão identificados em um comunicado público quando isso for apropriado e houver consentimento. Não divulgue a identidade de outra pessoa nem detalhes de seu relato sem autorização, exceto quando a divulgação for exigida por lei.

## Escopo e governança

Relatos de segurança são diferentes de relatos sobre conduta na comunidade. Para questões de convivência, consulte o [Código de Conduta](CODE_OF_CONDUCT.md).

As decisões sobre tratamento de segurança e responsabilidades dos mantenedores devem seguir [GOVERNANCE.md](GOVERNANCE.md). Para contribuições gerais, consulte [CONTRIBUTING.md](CONTRIBUTING.md). As informações de licenciamento estão em [LICENSE](LICENSE).

Esta política deve ser revisada conforme o projeto ganhar mantenedores, infraestrutura e experiência operacional.
