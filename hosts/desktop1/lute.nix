{...}:

{
  virtualisation.docker.enable = true; 

  virtualisation.oci-containers = {
    backend = "docker";
    containers.lute3 = {
      image = "jzohrab/lute3:latest";
      ports = [ "5001:5001" ];
      volumes = [
        "/var/lib/lute/data:/lute_data"
        "/var/lib/lute/backup:/lute_backup"
      ];
    };
  };
}