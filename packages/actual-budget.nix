{ unstable, ... }:

let  
  pname = "actual-budget";
  version = "26.2.1";

  # Fetches the AppImage file directly from the official source.
  # The sha256 hash ensures the file hasn't been tampered with and allows Nix to cache it.
  src = unstable.fetchurl {
    url = "https://github.com/actualbudget/actual/releases/download/v${version}/Actual-linux-x86_64.AppImage";
    sha256 = "sha256:41a2051159934722a17522d45f6942f805e068b0960939051273ceda7cf10c91"; 
  };

  appimageContents = unstable.appimageTools.extractType2 { inherit pname version src; };

  actualBudgetApp = unstable.appimageTools.wrapType2 {
    inherit pname version src;
    
    extraInstallCommands = ''
      # Installs the .desktop file so the app appears in application launchers (like Fuzzel).
      install -m 444 -D ${appimageContents}/actual.desktop -t $out/share/applications
      
      # Fixes the executable path inside the .desktop file.
      substituteInPlace $out/share/applications/actual.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      
      # Copies the application icons to the standard system directory.
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';
  };

in
{
  home.packages = [
    actualBudgetApp
  ];
}
