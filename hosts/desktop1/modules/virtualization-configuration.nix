{ pkgs, ... }:

{
  # =============================================================================
  # --- Virtualization Infrastructure (KVM/QEMU) ---
  # =============================================================================

  environment.systemPackages = with pkgs; [
    virt-manager
    virtiofsd
  ];

  environment.sessionVariables = {
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        # Software TPM emulator implementation.
        # This is a strict cryptographic requirement for Windows 11 to boot and update.
        swtpm.enable = true;
        package = pkgs.qemu_kvm;

        verbatimConfig = ''
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
          "/dev/input/by-id/usb-Logitech_Gaming_Mouse_G502_197D385D3638-event-mouse",
          "/dev/input/by-id/usb-SteelSeries_SteelSeries_Apex_7-event-kbd"
        ]
      '';
      };
    };
    
    # Enables USB redirection protocols.
    # Allows hot-plugging physical USB devices (mice, keyboards, drives) into the VM.
    spiceUSBRedirection.enable = true;
  };

  services.qemuGuest.enable = true;

  # =============================================================================
  # --- Hardware Isolation (VFIO Passthrough) ---
  # =============================================================================

  boot = {

    # 'intel_iommu=on' enables the Input-Output Memory Management Unit at boot.
    # 'iommu=pt' (Passthrough) optimizes host performance by only translating
    # memory addresses for devices explicitly assigned to virtual machines.
    kernelParams = [ "intel_iommu=on" "iommu=pt" ];

    # Injects the Virtual Function I/O framework into the initial ramdisk.
    # This guarantees VFIO claims the hardware before the standard host OS video 
    # drivers (nouveau/nvidia) can attach to it.
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];

    # Explicitly binds all four endpoints of the NVIDIA GTX 1660 SUPER 
    # (Video, Audio, USB, and Serial bus) to the vfio-pci stub driver.
    # Failing to isolate the entire group will cause the passthrough to abort.
    extraModprobeConfig = ''
      options vfio-pci ids=10de:21c4,10de:1aeb,10de:1aec,10de:1aed
    '';
  };
}