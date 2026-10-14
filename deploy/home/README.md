# Instalação doméstica do broker DevMesh

Esta é uma configuração inicial para uma rede doméstica confiável, usando Mosquitto em Docker Compose. Ela requer autenticação, limita a conta do DevMesh ao prefixo MQTT `msh/#` e mantém dados persistentes fora do contêiner.

## Requisitos

- Docker Engine e o plugin Docker Compose.
- Uma máquina na rede local, por exemplo uma Raspberry Pi.
- Nós Meshtastic que possam alcançar o endereço IP local dessa máquina.

## 1. Criar a senha local

Execute a partir da raiz do repositório:

```sh
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  --entrypoint mosquitto_passwd \
  -v "$PWD/deploy/home:/mosquitto/config" \
  eclipse-mosquitto:2.1.2-alpine \
  -c /mosquitto/config/passwordfile devmesh
chmod 644 deploy/home/passwordfile
```

O comando pede a senha interativamente. O arquivo contém hashes de senha, não a senha em texto claro. Ele é ignorado pelo Git e não deve ser enviado ao repositório. O modo de leitura permite que o processo Mosquitto dentro do contêiner leia o arquivo; proteja a conta e o armazenamento do host.

Se precisar trocar a senha, use `mosquitto_passwd` sem `-c`, para atualizar o arquivo existente sem apagar outras contas.

## 2. Iniciar e verificar

Na raiz do repositório:

```sh
docker compose -f deploy/home/compose.yaml config --quiet
docker compose -f deploy/home/compose.yaml up -d
docker compose -f deploy/home/compose.yaml ps
docker compose -f deploy/home/compose.yaml logs --tail=50 mosquitto
```

Para parar o serviço, mantendo os dados:

```sh
docker compose -f deploy/home/compose.yaml down
```

Os dados persistentes ficam em um volume Docker gerenciado pelo Compose. Faça uma cópia de segurança do volume e do arquivo de senhas por um meio seguro. Para exportar os dados, crie uma pasta de backup local e execute a partir da raiz do repositório:

```sh
mkdir -p deploy/home/backups
docker run --rm \\
  -v home_mosquitto_data:/data:ro \\
  -v "$PWD/deploy/home/backups:/backup" \\
  alpine:3.22 \\
  tar -czf /backup/mosquitto-data.tar.gz -C /data .
```

O nome padrão do volume é `home_mosquitto_data` quando os comandos Compose são executados a partir da raiz com este arquivo. Confirme o nome com `docker volume ls` se tiver definido outro nome de projeto. Mantenha os backups fora do Git e não publique nem compartilhe o arquivo de senhas.

## 3. Configurar os nós Meshtastic

Na configuração MQTT de cada nó autorizado:

- **Servidor:** endereço IP local da máquina que executa o broker.
- **Porta:** `1883`.
- **Usuário:** `devmesh`.
- **Senha:** a senha criada no passo 1.
- **Root topic:** `msh`.
- **TLS:** desativado nesta configuração inicial.
- **Encryption enabled:** ativado para encaminhar os pacotes cifrados.
- **JSON enabled:** desativado para evitar o caminho JSON, que não é cifrado pelo Meshtastic.

Habilite uplink/downlink somente nos canais que você realmente pretende encaminhar. Verifique a configuração de cada nó antes de transmitir dados.

## Limites de segurança

- Esta configuração é apenas para uma rede doméstica confiável. MQTT na porta 1883 não usa TLS; credenciais e tráfego podem ser observados por alguém capaz de monitorar a rede local. Para redes não confiáveis, configure TLS ou use uma VPN adequadamente configurada antes de permitir o acesso.
- **Não** encaminhe a porta 1883 no roteador para a internet. Acesso remoto não faz parte desta instalação inicial.
- A conta compartilhada `devmesh` pode ler e publicar em todos os tópicos `msh/#`. Ela não separa nós entre si. A ACL limita o prefixo, não substitui a criptografia dos pacotes nem cria privacidade entre os clientes autorizados.
- A opção Meshtastic **Encryption enabled** precisa estar ativa para encaminhar pacotes cifrados. A chave de canal sozinha não garante que o payload publicado no MQTT permaneça cifrado. Mensagens JSON são um caminho separado e não cifrado.
- Esta instalação ainda não é uma configuração certificada para produção. Antes de oferecer acesso a outras pessoas, defina contas individuais, ACLs adequadas aos tópicos e canais usados, proteção do transporte, atualização, backup e recuperação.

## Referências

- [Configuração MQTT oficial do Meshtastic](https://meshtastic.org/docs/configuration/module/mqtt/)
- [Criptografia Meshtastic](https://meshtastic.org/docs/overview/encryption/)
- [Documentação oficial do Eclipse Mosquitto](https://mosquitto.org/documentation/)
