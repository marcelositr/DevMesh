# DevMesh

Infraestrutura comunitária e independente de comunicação por MQTT, com foco em redes de rádio compatíveis com Meshtastic, interoperabilidade e futuras integrações com serviços públicos brasileiros.

O DevMesh está em fase inicial de planejamento e validação. As escolhas técnicas e os recursos ainda precisam ser avaliados por meio de pesquisa e testes. Este repositório não deve ser interpretado como evidência de funcionalidades que ainda não foram implementadas.

O DevMesh não é um projeto oficial do Meshtastic e não deve sugerir afiliação ou endosso oficial.

## Escopo inicial

A primeira etapa valida uma base simples para uso doméstico, inclusive numa Raspberry Pi. O cenário inicial usa Mosquitto e três nós simulados, sem depender de hardware de rádio nem expor o broker à internet.

O CI verifica conectividade MQTT, roteamento por tópico, autenticação básica e ACLs num broker descartável. Também simula o nó A publicando um fixture binário Meshtastic sintético que os nós B e C recebem sem alteração. A validação estrutural usa `protoc` com as definições oficiais Meshtastic fixadas numa versão específica, decodifica o `ServiceEnvelope`, verifica campos esperados e confirma o ciclo de recodificação. Isso valida a estrutura do fixture e o transporte MQTT, não interoperabilidade integral com firmware ou rádio LoRa.

A workflow criptográfica compila a suíte oficial `test_crypto` do firmware fixado no commit `8e6a88d06f44cad26f1e8d7cd402939ccacb9b4c` e injeta testes temporários de interoperabilidade no checkout descartável do CI. Cinco casos chamam `CryptoEngine::encryptPacket()` com chave, nonce e mensagens sintéticos e comparam o ciphertext byte a byte com OpenSSL AES-128-CTR. Um teste separado demonstra que alterar um bit no ciphertext AES-CTR altera o plaintext correspondente sem detecção de autenticação, pois CTR isolado não autentica os dados. A mesma suíte upstream executa testes AES-CCM/AEAD para rejeição de adulteração, tag inválida, chave incorreta e alterações nos parâmetros autenticados. Um teste integrado leva ciphertext sintético do firmware a um `ServiceEnvelope`, valida a codificação e decodificação com o esquema Protobuf oficial fixado e verifica que dois assinantes MQTT recebem os bytes idênticos. O código do firmware é usado somente no CI, não incorporado ao produto DevMesh. Nada disso substitui testes com hardware ou dados capturados de rádio físico.

**Criptografia Meshtastic e ACL MQTT são coisas diferentes.** O teste de ACL impede que o nó C acesse um tópico restrito no broker. O teste de transporte mostra que os assinantes recebem os mesmos bytes, sem validar por si só a autenticidade criptográfica desses bytes. AES-CTR não fornece autenticação; AES-CCM/AEAD pode detectar adulteração quando é realmente usado e validado pelo destinatário. A configuração do módulo MQTT e o modo criptográfico dos nós precisam ser verificados separadamente: a chave de canal, sozinha, não garante que o payload publicado no broker continue cifrado.

A configuração anônima usada em alguns testes existe somente para brokers efêmeros de CI e não deve ser reutilizada numa instalação real. As credenciais do teste de autenticação são temporárias. A configuração doméstica deve evitar exposição pública do broker e prever autenticação para clientes de rede. ACLs e proteção do transporte serão aplicadas conforme o modelo de confiança e antes de qualquer acesso por redes não confiáveis. O acesso remoto não faz parte do escopo inicial.

Consulte a [decisão sobre escopo doméstico e segurança proporcional](docs/decisions/0003-home-first-scope-and-proportionate-security.md) para os limites e os critérios de evolução.

## Documentação

- [Índice da documentação técnica](docs/README.md): organização dos documentos, pesquisas e decisões.
- [Como contribuir](CONTRIBUTING.md): propostas, alterações e revisões.
- [Código de Conduta](CODE_OF_CONDUCT.md): convivência com a comunidade.
- [Política de Segurança](SECURITY.md): comunicação e tratamento de vulnerabilidades.
- [Nome e identidade visual](TRADEMARKS.md): uso da marca e prevenção de confusão.
- [Continuidade e sucessão](docs/CONTINUITY.md): responsabilidades, acesso e sucessão.
- [Registros de decisões](docs/decisions/): decisões relevantes e seus fundamentos.
- [Licença](LICENSE): termos de licenciamento do software.

## Idioma do projeto

A documentação voltada às pessoas, os comentários explicativos no código e os comentários em arquivos de configuração devem ser escritos em português brasileiro sempre que possível. O código, os identificadores técnicos e as interfaces de programação seguem as convenções técnicas adotadas pelo projeto, normalmente em inglês.

## Situação atual

O projeto ainda não deve ser considerado pronto para produção. As decisões técnicas serão tomadas depois de pesquisa, testes reproduzíveis e registro dos resultados. A aprovação de testes isolados no CI não significa que todos os controles de segurança ou a integração com Meshtastic estejam implementados ou validados.
