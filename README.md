# **Implantar sistema de monitoramento para sua infraestrutura de servidores**

![zabbix-logo](./docs/img/zabbix_logo_255x67.png)   ![grafana-logo](./docs/img/grafana_logo_255x62.png)

- Pode ser implantado em qualquer plataforma que suporte a tecnologia de containers docker

## **Uso rápido**

```shell

# Faça uma cópia do exemplo de inventário
cd ./inventories
cp -rf sample <seu inventário>

# Edite seu invetário com as informações do seu ambiente
vi ./inventorie/<seu inventário>/hosts.yml
```

```yml
---
all:
  vars:
    zabbix_server_ip: "1.2.3.4" # IP do servidor
    zabbix_agent_port: "10050"  # Porta do agente
    mysql_zbx_db_pwd: ""        # Preencha as variáveis mysql_zbx_db_pwd e mysql_root_pwd com uma senha de sua preferência
    mysql_root_pwd: ""          # --^^^
  hosts:
    zabbix-server:              # Hostname do servidor
      ansible_host: 1.2.3.4     # IP do servidor
  children:
    server:
      hosts:
        zabbix-server:          # Servidor zabbix
    agent_linux:
      hosts:
        zabbix-server:          # Host(s) que serão monitorados
    agent_windows:
      hosts:
```

```shell

ansible-playbook -i inventories/<seu inventario>/hosts.yml -u root -k server.yml

```