{pkgs, ...}:

{
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "trash-restore-search" ''
      #!/usr/bin/env bash
      
      # Get the trash-list and put it through fzf.
      SELECTION=$(trash-list | sort -r | ${pkgs.fzf}/bin/fzf \
      --prompt="Restore >")

      if [ -z "$SELECTION" ]; then
        echo "No selection."
        exit 0
      fi

      # Exctract the path, and use sed to remove space before it.
      FILE_PATH=$(echo "$SELECTION" | awk '{$1=$2=""; print $0}' | sed 's/^[ \t]*//')

      # Use trash-restore to restore the file
      ${pkgs.trash-cli}/bin/trash-restore "$FILE_PATH"
    '')
  ];
}