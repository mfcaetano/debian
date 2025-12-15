# Tutorial: Conectando Discos Físicos Diretamente a uma VM TrueNAS no Proxmox

Este tutorial descreve, passo a passo, como conectar **discos rígidos físicos (passthrough)** diretamente a uma **VM do TrueNAS SCALE** rodando em **Proxmox VE**.

Todo o conteúdo abaixo utiliza **exemplos fictícios e coerentes**, apenas para fins de documentação.  
Nenhuma configuração real do ambiente original está exposta.

---

## 🎯 Objetivo

Permitir que o **TrueNAS** tenha **controle direto dos discos físicos**, requisito essencial para o uso correto do **ZFS**, evitando camadas intermediárias do Proxmox.

---

## 🧱 Cenário de Exemplo

- Host: Proxmox VE
- VM ID: `102`
- VM Name: `truenas`
- TrueNAS SCALE instalado em disco virtual separado
- Dois discos físicos de 18 TB dedicados exclusivamente ao TrueNAS

Exemplo de discos:

| Dispositivo | Modelo | Serial |
|------------|-------|--------|
| `/dev/sda` | ST20000NT001 | ABC123XYZ |
| `/dev/sdb` | ST20000NT001 | DEF456UVW |

---

## 🔍 Passo 1: Identificar os discos físicos no host

No host Proxmox, liste os discos conectados:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL
```

Exemplo de saída:

```text
NAME   SIZE   MODEL           SERIAL
sda    18.2T  ST20000NT001    ABC123XYZ
sdb    18.2T  ST20000NT001    DEF456UVW
```

Esse comando permite confirmar:
- tamanho do disco
- modelo
- número de série

Essas informações são essenciais para evitar erros.

---

## 🔗 Passo 2: Mapear discos usando `/dev/disk/by-id`

Nunca utilize `/dev/sda`, `/dev/sdb`, etc.  
Esses nomes podem mudar após reboot.

Liste os identificadores persistentes:

```bash
ls -l /dev/disk/by-id/
```

Exemplo relevante:

```text
ata-ST20000NT001_ABC123XYZ -> ../../sda
ata-ST20000NT001_DEF456UVW -> ../../sdb
```

O sufixo corresponde ao **serial do disco**, garantindo identificação única.

---

## ⚙️ Passo 3: Conectar os discos à VM TrueNAS

Use o comando `qm set` para fazer passthrough dos discos físicos.

### Disco 1:
```bash
qm set 102 -scsi1 /dev/disk/by-id/ata-ST20000NT001_ABC123XYZ,serial=ABC123XYZ
```

### Disco 2:
```bash
qm set 102 -scsi2 /dev/disk/by-id/ata-ST20000NT001_DEF456UVW,serial=DEF456UVW
```

Boas práticas aplicadas:
- uso de `by-id`
- disco inteiro (não partições)
- serial explícito

---

## 🔄 Passo 4: Reiniciar a VM

Para que o TrueNAS reconheça os novos discos:

```bash
qm stop 102
qm start 102
```

---

## 🖥️ Passo 5: Verificar discos no TrueNAS

Acesse a interface web do TrueNAS:

```text
http://IP_DO_TRUENAS
```

Depois:

- **Storage → Disks**
- Os dois discos devem aparecer como **Available**

Neste ponto, os discos estão prontos para:
- criação de pool ZFS
- mirror, RAIDZ1, RAIDZ2, etc.

---

## ⚠️ Alertas Importantes

- ❌ Não adicione esses discos ao storage do Proxmox
- ❌ Não monte esses discos no host
- ❌ Não utilize partições (`-part1`)

✔ Os discos agora pertencem exclusivamente ao TrueNAS

---

## 🧠 Observações Finais

- Essa abordagem é a **recomendada oficialmente** para TrueNAS + Proxmox
- Garante integridade, SMART correto e performance do ZFS
- Escala bem para pools maiores e HBAs dedicados

---

## 📌 Resumo

1. Identificar discos físicos
2. Mapear via `/dev/disk/by-id`
3. Fazer passthrough com `qm set`
4. Reiniciar a VM
5. Gerenciar tudo pelo TrueNAS

---

**Fim do tutorial.**
