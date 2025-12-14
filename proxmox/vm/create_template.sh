#!/usr/bin/env bash
set -ex

IMAGE="$1"
[[ -f "$IMAGE" ]] || exit 1

FORMAT="$2"

CPU_TYPE="x86-64-v2-AES"
MEMORY="512"
CPUS="2"
DISK="32G"
STORAGE="local-lvm"
FILE_STORAGE=false
BRIDGE="vmbr0"
VLAN="3"

declare -A acronyms
acronyms=(["jasnah"]="jsn" ["korra"]="kra" ["stormfather"]="sfr")

host_acronym="${acronyms[$HOSTNAME]}"
base_name=$(basename -- "$IMAGE")
file_name="${base_name%.*}"
vm_name="${file_name}-${host_acronym}"
next_id=$(pvesh get /cluster/nextid)

if [ "$FILE_STORAGE" = true]; then
    disk_path="${next_id}/vm-${next_id}-disk-0.${FORMAT}"
else
    disk_path="vm-${next_id}-disk-0"
fi

qm create "$next_id" --name "$vm_name"

qm disk import "$next_id" "$IMAGE" "$STORAGE" --format "$FORMAT"

qm set "$next_id" \
  --cores "$CPUS" --memory "$MEMORY" \
  --machine "q35" \
  --bios "ovmf" \
  --cpu "$CPU_TYPE" \
  --scsihw "virtio-scsi-single" \
  --scsi0 "${STORAGE}:cloudinit,media=cdrom" \
  --scsi1 "${STORAGE}:${disk_path},iothread=1,ssd=1,discard=on" \
  --efidisk0 "${STORAGE}:1" \
  --net0 "virtio,bridge=${BRIDGE},tag=${VLAN}" \
  --boot "c" \
  --bootdisk "scsi1" \
  --serial0 "socket" \
  --ipconfig0 "ip=dhcp" \
  --vga "serial0" \
  --ostype "l26" \
  --agent "1"

qm resize "$next_id" scsi1 "$DISK"

qm template "$next_id"
