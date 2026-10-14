# Decisão 0003: escopo inicial doméstico e segurança proporcional

- **Estado:** aceita
- **Data:** 2026-10-13
- **Responsável pela decisão:** pessoa responsável pelo projeto
- **Relacionada a:** [ADR 0002: adoção do Mosquitto](0002-adoption-of-eclipse-mosquitto.md), [pesquisa inicial de brokers MQTT](../research/0001-mqtt-broker-initial-comparison.md)

## Contexto

O DevMesh deve começar como uma solução compreensível para uma pessoa que executa o broker em casa, por exemplo numa Raspberry Pi. O projeto não precisa implementar desde o primeiro protótipo todos os mecanismos que poderiam ser úteis numa instalação pública ou de maior escala.

A segurança continua sendo necessária. O objetivo é evitar tanto a exposição desprotegida quanto a complexidade prematura, deixando explícito quais riscos cada etapa cobre.

## Decisão

O escopo inicial será uma instalação doméstica com Mosquitto, três nós simulados e testes reproduzíveis. O acesso remoto pela internet, a operação pública multiusuário e integrações de serviços públicos ficam fora do escopo inicial.

A evolução seguirá estas etapas:

1. **Protótipo e CI:** testar conectividade e roteamento MQTT, transporte binário de um fixture sintético, um modelo independente AES-CTR, autenticação básica e ACLs por tópico num broker efêmero. O fixture é uma amostra estática, não um pacote capturado de um dispositivo real. A validação estrutural usa as definições oficiais Protobuf do Meshtastic numa versão fixada, mas não valida criptografia real nem interoperabilidade integral com firmware.
2. **Configuração doméstica:** não expor o broker diretamente à internet. Ao preparar uma configuração de uso real, habilitar autenticação para clientes de rede e manter credenciais fora do controle de versão.
3. **Permissões por tópico:** aplicar regras de ACL adequadas ao modelo de confiança para separar clientes e limitar publicação/assinatura. O teste atual cobre somente o cenário mínimo de três nós; regras de uma instalação real devem ser definidas para os clientes e tópicos efetivamente usados.
4. **Acesso por redes não confiáveis:** não oferecer acesso remoto direto como parte da primeira versão. Se esse cenário for adicionado, definir e testar a proteção do transporte, preferencialmente com TLS ou uma VPN adequadamente configurada, além das permissões de acesso necessárias.

## Limites de segurança e compatibilidade

- Autenticação identifica o cliente; ACLs restringem o que ele pode publicar ou assinar. Uma não substitui a outra.
- **ACL de broker e criptografia de canal são controles diferentes.** A ACL atual bloqueia o nó C no tópico MQTT de teste. Isso não representa, por si só, um canal privado Meshtastic: numa malha com criptografia de canal, um nó sem a chave ainda pode receber e retransmitir bytes cifrados, mas não consegue decifrar a mensagem.
- O teste de autenticação comprova apenas o comportamento básico do broker descartável com credenciais de teste. Não valida o armazenamento de segredos nem a configuração de uma instalação doméstica.
- O teste de ACL verifica permissões de publicação e assinatura no cenário simulado de tópicos públicos e privados. Não certifica uma política de ACL de produção nem cobre todas as convenções de tópicos do Meshtastic.
- O teste MQTT binário verifica que o broker transporta bytes sem alterá-los no tópico escolhido e que dois assinantes recebem o mesmo fixture sintético. O teste AES-CTR confere dois vetores de referência usados no teste oficial do firmware fixado e verifica a codificação do nonce de canal. Isso melhora a conferência do primitivo e do formato, mas continua sendo um modelo com OpenSSL: não executa `CryptoEngine.cpp`, não usa um payload gerado por dispositivo e não prova interoperabilidade integral. O teste Protobuf valida a estrutura do fixture contra as definições oficiais fixadas e confirma a recodificação dos mesmos bytes.
- A opção de criptografia do módulo MQTT do Meshtastic influencia se os pacotes enviados ao broker são cifrados ou enviados em forma decifrada. Não presumir que a chave configurada no canal, sozinha, garanta que o conteúdo encaminhado ao MQTT continue cifrado. A integração deverá verificar explicitamente essa configuração e o tipo de payload.
- TLS protege o transporte entre os pontos da conexão, mas não transforma por si só o payload em conteúdo criptografado de ponta a ponta.
- A criptografia de canais Meshtastic é uma camada separada. O DevMesh não deve prometer confidencialidade ou compatibilidade sem testes específicos do tipo de pacote e do encaminhamento MQTT.
- Testes com nós simulados validam o comportamento do software e do broker, não o alcance, a qualidade do sinal ou o comportamento físico de um enlace LoRa.

## Critérios para ampliar o escopo

Próximo passo de protocolo: executar ou adaptar um teste de referência que use o próprio código criptográfico do firmware fixado numa versão e comparar o resultado com o modelo independente. Se isso exigir incorporar ou derivar código do firmware, avaliar antes a licença GPL-3.0 e as consequências para a distribuição do DevMesh. Até lá, não descrever o modelo como execução real do firmware.

Adicionar autenticação avançada, regras de ACL mais detalhadas, TLS, acesso remoto ou serviços auxiliares somente quando houver um cenário de uso claro. Cada ampliação deve explicar o risco ou a necessidade que atende e incluir testes proporcionais.

Antes de declarar uma configuração pronta para uso real, revisar a configuração efetiva do Mosquitto, as portas expostas, o armazenamento de credenciais, as permissões por cliente e os resultados dos testes relevantes. A aprovação do CI do protótipo não constitui certificação de segurança nem prontidão para produção.

## Consequências

- O protótipo continua pequeno e adequado a uma Raspberry Pi.
- Os testes verificam conectividade, roteamento, transporte binário de um fixture, validação estrutural Protobuf, modelo independente AES-CTR, autenticação básica e ACLs em ambientes descartáveis, sem afirmar controles que não testam.
- Segurança avançada não será implementada sem necessidade demonstrável; requisitos necessários para uma exposição futura não serão esquecidos.
- A documentação deve distinguir sempre entre planejado, implementado e verificado.

## Revisão

Revisar esta decisão quando o projeto introduzir uma configuração de implantação real, acesso remoto, clientes não confiáveis ou integrações que alterem o modelo de segurança.
