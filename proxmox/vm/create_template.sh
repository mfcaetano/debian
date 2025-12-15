#!/usr/bin/env bash
set -ex

IMAGE="$1"
[[ -f "$IMAGE" ]] || { echo "Image not found: $IMAGE"; exit 1; }

FORMAT="${2:-${IMAGE##*.}}"
FORMAT="${FORMAT,,}"

case "$FORMAT" in
  raw|qcow2|vmdk) ;;
  *)
    echo "Invalid or unsupported format: $FORMAT"
    exit 1
    ;;
esac

CPU_TYPE="host"
MEMORY="512"
CPUS="2"
DISK="32G"
STORAGE="local-lvm"
FILE_STORAGE=false
BRIDGE="vmbr0"
VLAN="8"

declare -A acronyms
acronyms=(["jasnah"]="jsn" ["korra"]="kra" ["stormfather"]="sfr")

host_acronym="${acronyms[$HOSTNAME]}"
base_name=$(basename -- "$IMAGE")
file_name="${base_name%.*}"
vm_name="${file_name}-${host_acronym}"
next_id=$(pvesh get /cluster/nextid)

if [[ -n "${acronyms[$HOSTNAME]}" ]]; then
  vm_name="${file_name}-${acronyms[$HOSTNAME]}"
else
  vm_name="$file_name"
fi
  
if ! [[ "$vm_name" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
  echo "Invalid VM name: $vm_name"
  exit 1
fi

if [ "$FILE_STORAGE" = true ]; then
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
