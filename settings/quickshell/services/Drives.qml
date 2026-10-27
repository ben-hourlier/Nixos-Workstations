pragma Singleton

import qs.common
import Quickshell
import QtQuick

// Mounted USB partitions, read from lsblk, and their safe unmount.
Singleton {
    id: root

    property var entries: []
    property bool loading: false

    function refresh(): void {
        loading = true;
        Cmd.run(["lsblk", "-J", "-p", "-o", "NAME,SIZE,TRAN,MODEL,LABEL,MOUNTPOINT"], text => {
            let devices = [];
            try {
                devices = JSON.parse(text).blockdevices ?? [];
            } catch (e) {}
            // One entry per key, whatever its number of mounted partitions; a
            // key without a partition table is mounted as the whole disk.
            entries = devices.filter(d => d.tran === "usb").map(disk => {
                const model = disk.model?.trim() ?? "";
                const parts = [disk, ...(disk.children ?? [])].filter(p => p.mountpoint);
                const labels = parts.map(p => p.label).filter(l => l);
                return {
                    text: labels.join(", ") || model || disk.name,
                    detail: [labels.length > 0 ? model : "", disk.size, ...parts.map(p => p.mountpoint)].filter(s => s).join(" · "),
                    search: [model, ...labels, ...parts.map(p => p.mountpoint)].join(" "),
                    icon: "usb",
                    device: disk.name,
                    partitions: parts.map(p => p.name)
                };
            }).filter(e => e.partitions.length > 0);
            loading = false;
        });
    }

    // Flushes pending writes, unmounts every partition, then powers the key
    // off so it can be pulled out. The notification gives udisks' reason
    // when a step fails (e.g. a file still open on the key).
    function eject(entry: var): void {
        Quickshell.execDetached(["sh", "-c", `
            sync
            disk=$1; shift
            for part; do
                err=$(udisksctl unmount -b "$part" 2>&1) || { notify-send --category=system_alert "Error" "Cannot eject the USB key: $err"; exit 1; }
            done
            err=$(udisksctl power-off -b "$disk" 2>&1) || { notify-send --category=system_alert "Error" "Unmounted, but cannot power off the USB key: $err"; exit 1; }
            notify-send --category=system_alert "Success" "USB key safely ejected"
        `, "sh", entry.device, ...entry.partitions]);
    }
}
