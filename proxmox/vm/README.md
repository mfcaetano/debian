# Proxmox VM Template Automation

Este diretório contém dois scripts Bash para **automatizar a obtenção de imagens Debian Cloud** e a **criação de templates de VM no Proxmox**.

Os scripts foram pensados para uso direto no nó Proxmox, com foco em reprodutibilidade, simplicidade e validações explícitas.

---

## Scripts disponíveis

- `get_last_debian.sh`  
  Baixa automaticamente a **última imagem Debian Cloud (RAW)** a partir do repositório oficial.

- `create_template.sh`  
  Cria um **template de VM no Proxmox** a partir de uma imagem cloud (RAW, QCOW2 ou VMDK).

---

## Pré-requisitos

- Executar os scripts **no nó Proxmox**
- Usuário `root`
- Proxmox VE com:
  - `qm`
  - `pvesh`
- Acesso à internet (para download da imagem Debian)
- Storage configurado no Proxmox (ex.: `local-lvm`)

---

## 1. Script `get_last_debian.sh`

### O que ele faz

- Identifica a **última versão disponível** da imagem Debian Cloud
- Faz o download da imagem no formato **RAW**
- Salva o arquivo localmente

Fonte oficial:
```
https://cloud.debian.org/images/cloud/
```

### Como usar

```bash
chmod +x get_last_debian.sh
./get_last_debian.sh
```

---

## 2. Script `create_template.sh`

### O que ele faz

- Cria uma nova VM no Proxmox
- Importa a imagem cloud como disco
- Configura UEFI, VirtIO, Cloud-init, rede e agente
- Redimensiona o disco
- Converte a VM em **template**

### Uso

```bash
./create_template.sh <image_path> [format]
```

O formato é inferido automaticamente pela extensão se não for informado.

---

## Fluxo típico

```bash
./get_last_debian.sh
./create_template.sh debian-13-genericcloud-amd64.raw
```

---

## Observações

- Script preparado para `local-lvm`
- Nome da VM validado como hostname DNS
- Ajustes finos podem ser feitos diretamente no script
