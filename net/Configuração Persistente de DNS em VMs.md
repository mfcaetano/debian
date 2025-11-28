# Configuração Persistente de DNS em VMs Debian 13 com Cloud-Init e Netplan

## 1. Contexto

Ao criar uma VM Debian 13 (Trixie) no Proxmox usando o recurso Cloud-Init, a configuração de rede é gerada automaticamente pelo Cloud-Init usando o Netplan.
Em sistemas modernos, especialmente nas imagens cloud do Debian 12/13, o Netplan assume o controle da rede, gerando arquivos de configuração para o:

- systemd-networkd (backend)
- systemd-resolved (resolver DNS)

O DHCP fornecido pelo roteador pode entregar corretamente:

- endereço IP  
- gateway  
- máscara  
- servidor DNS  
- domínio DNS  

e mesmo assim o DNS não funciona dentro da VM — resultando em erros como:

```
Temporary failure in name resolution
```

## 2. O Problema

Mesmo quando o comando:

```
networkctl status eth0
```

mostra corretamente:

- `DNS: 192.168.25.1`
- `Gateway: 192.168.25.1`
- `Address: 192.168.25.3` (DHCP)

a resolução DNS falha.

O motivo é que o arquivo temporário:

```
/run/systemd/network/10-netplan-eth0.network
```

gerado pelo Netplan não contém as diretivas necessárias para permitir que o `systemd-networkd` repasse as informações de DNS ao `systemd-resolved`.

Especificamente, faltam as diretivas:

```ini
[DHCP]
UseDNS=yes
UseDomains=yes
```

Sem essas linhas:

- o DHCP entrega DNS → OK  
- o systemd-networkd recebe o DNS → OK  
- mas o systemd-resolved não recebe nenhum DNS upstream  
- o `/etc/resolv.conf` permanece apontando para `127.0.0.53`  
- o resolved fica sem servidores reais  
- qualquer consulta DNS falha

Reiniciar a VM não resolve, porque o arquivo em `/run/` é volátil e sempre regenerado pelo Netplan.

## 3. Por que isso acontece em VMs com Cloud-Init?

O Cloud-Init gera o arquivo Netplan em:

```
/etc/netplan/50-cloud-init.yaml
```

Mas esse YAML padrão não ativa as opções:

```yaml
dhcp4-overrides:
  use-dns: true
  use-domains: true
```

Portanto, mesmo com DHCP funcionando perfeitamente, a cadeia:

```
DHCP → systemd-networkd → systemd-resolved
```

fica quebrada no meio.

Isso afeta:

- Debian 12 (Bookworm) cloud images  
- Debian 13 (Trixie) cloud images  
- Qualquer VM criada com Cloud-Init no Proxmox que use Netplan  

## 4. A Solução Persistente (Netplan)

Para permitir que o DNS entregue via DHCP funcione corretamente,  
é necessário ajustar o arquivo Netplan que o Cloud-Init gera.

Edite o arquivo:

```
/etc/netplan/50-cloud-init.yaml
```

E adicione:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      dhcp4-overrides:
        use-dns: true
        use-domains: true
```

Depois aplique:

```
netplan generate
netplan apply
```

Com isso:

- o Netplan passa a gerar a configuração correta  
- o systemd-networkd entrega o DNS ao resolved  
- o systemd-resolved passa a usar o DNS real  
- `/etc/resolv.conf` (que aponta para 127.0.0.53) passa a funcionar  
- consultas DNS via `.local` ou domínios externos funcionam normalmente

## 5. O que essa solução resolve?

✔ Permite que o DNS entregue via DHCP seja efetivamente usado pelo sistema  
✔ Garante que o Netplan respeite e propague domínios DNS (search domain)  
✔ Corrige o fluxo completo:

```
DHCP → networkd → resolved → aplicações
```

✔ Remove erros de DNS como:

```
Temporary failure in name resolution
```

✔ Resolve problemas onde o DHCP entrega DNS corretamente, mas a VM o “ignora”  
✔ Torna a configuração persistente entre boots  
✔ Funciona em qualquer VM Debian 12/13 criada com Cloud-Init no Proxmox  

## 6. Conclusão

O problema não é o DHCP, nem o Cloud-Init, nem o Proxmox.

O comportamento padrão das imagens de Debian 12/13 com Cloud-Init não habilita as diretivas necessárias para que o DNS recebido via DHCP seja repassado ao `systemd-resolved`.

Adicionar as opções `dhcp4-overrides` no Netplan resolve a lacuna, cria uma configuração consistente e garante que a VM use corretamente:

- IP  
- gateway  
- DNS  
- domínio DNS  
- search domain  