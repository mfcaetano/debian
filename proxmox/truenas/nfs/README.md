# Proxmox NFS Backup (fstab + systemd)

Este repositório documenta a configuração **estável e recomendada** para utilizar
um compartilhamento **NFS** como destino de **backup** no Proxmox VE, usando
`/etc/fstab` integrado ao `systemd`.

A solução evita scripts customizados e garante:

- boot **sem bloqueio**
- montagem **tardia** (sob demanda)
- desmontagem **prioritária** no shutdown/reboot
- integração limpa com o storage do Proxmox

---

## 🎯 Objetivo

Configurar um storage de backup em NFS no Proxmox VE garantindo que:

- o NFS não cause problemas no boot
- o sistema desmonte o filesystem corretamente no shutdown
- o Proxmox apenas **consuma** o mount (não gerencie NFS diretamente)
- a solução seja simples, previsível e suportada

---

## 📌 Pré-requisitos

- Proxmox VE (host único ou cluster)
- Servidor NFS remoto (ex.: TrueNAS)
- Export NFS funcional
- Resolução de nome ou IP do servidor NFS

Exemplo usado neste README:

| Item | Valor |
|----|----|
| Servidor NFS | `bkp-nfs.mfcaetano.local` |
| Export | `/mnt/vault/backup` |
| Mount local | `/mnt/backup` |

---

## 1️⃣ Criar o diretório de montagem

```bash
mkdir -p /mnt/backup
```

---

## 2️⃣ Configurar o `/etc/fstab`

Edite o arquivo:

```bash
nano /etc/fstab
```

Adicione a linha abaixo:

```fstab
bkp-nfs.mfcaetano.local:/mnt/vault/backup  /mnt/backup  nfs  \
_netdev,nofail,x-systemd.automount, \
x-systemd.after=multi-user.target, \
x-systemd.before=shutdown.target, \
vers=4,proto=tcp,rw,relatime  0  0
```

### 🔍 Explicação das opções

| Opção | Descrição |
|----|----|
| `_netdev` | Indica filesystem de rede proveniente de outro host |
| `nofail` | Não bloqueia o boot caso o NFS esteja indisponível |
| `x-systemd.automount` | Monta o NFS apenas quando acessado |
| `x-systemd.after=multi-user.target` | Garante montagem tardia no boot |
| `x-systemd.before=shutdown.target` | Garante desmontagem antecipada |
| `vers=4` | Utiliza NFSv4 |
| `proto=tcp` | Comunicação via TCP |
| `relatime` | Reduz escrita de metadata |

---

## 3️⃣ Recarregar o systemd

```bash
systemctl daemon-reload
```

---

## 4️⃣ Testar a montagem (sem reboot)

A montagem ocorre **sob demanda**:

```bash
ls /mnt/backup
```

Verificar se montou:

```bash
mount | grep /mnt/backup
```

---

## 5️⃣ Verificar a unit `.mount` gerada automaticamente

O systemd cria automaticamente a unit `mnt-backup.mount` a partir do `fstab`.

```bash
systemctl status mnt-backup.mount
```

Verificar ordem de execução:

```bash
systemctl show mnt-backup.mount -p After -p Before
```

Resultado esperado inclui:

- `After=network-online.target`
- `Before=umount.target`

Isso confirma desmontagem prioritária no shutdown.

---

## 6️⃣ Adicionar o storage no Proxmox

No Proxmox Web UI:

1. **Datacenter → Storage → Add → Directory**
2. Configurar:
   - **ID:** `backup-nfs`
   - **Directory:** `/mnt/backup`
   - **Content:** `Backup`
   - **Enable:** marcado
   - **Shared:** marcado (se aplicável)
3. **Não marcar**:
   - `Allow Snapshots as Volume-Chain`

> ⚠️ O Proxmox **não monta NFS** aqui.  
> Ele apenas utiliza o diretório já montado pelo sistema.

---

## 7️⃣ Comportamento esperado

### 🔺 Boot
- O host inicia normalmente
- O NFS **não monta automaticamente**
- A montagem ocorre apenas quando o diretório é acessado

### 🔻 Shutdown / Reboot
- O systemd desmonta `/mnt/backup`
- A desmontagem ocorre **antes do shutdown real**
- Nenhum serviço fica bloqueado

---

## 🧪 Comandos úteis de diagnóstico

```bash
mount | grep backup
systemctl status mnt-backup.mount
systemctl status mnt-backup.automount
journalctl -b | grep -i nfs
```

---

## ⚠️ Boas práticas

- Não usar scripts de mount/unmount customizados
- Não criar units `.mount` manuais para NFS no Proxmox
- Preferir sempre `fstab + systemd`
- Evitar remover `_netdev` ou `nofail`
- Usar `automount` sempre que possível

---

## 🏁 Conclusão

Essa abordagem utiliza apenas mecanismos nativos do Linux e do Proxmox VE,
resultando em uma configuração:

- simples
- previsível
- robusta
- fácil de manter
- segura em boot e shutdown

É a forma **recomendada** para uso de NFS como destino de backup no Proxmox.
