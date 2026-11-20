{ ext, pkgs, ... }:

let
  # On startup, vscode-java-debug 0.59 creates a folder inside its own
  # install directory, which is read-only in the Nix store: activation
  # fails and "Run" answers "command 'java.debug.runJavaFile' not found".
  # Move that folder to /tmp. --replace-fail breaks the build if a new
  # version changes this code: then check whether the fix is still needed.
  javaDebug = ext.vscjava.vscode-java-debug.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace dist/extension.js \
        --replace-fail 'o.join(t,".noConfigDebugAdapterEndpoints")' \
                       'o.join(require("os").tmpdir(),"vscode-java-debug-endpoints")'
    '';
  });
in
{
  extensions = with ext; [
    redhat.java
    javaDebug
    vscjava.vscode-java-dependency
    vscjava.vscode-java-pack
    vscjava.vscode-java-test
    vscjava.vscode-maven
  ];

  userSettings = {
    # JDK running the Red Hat language server (25 or newer)
    "java.jdt.ls.java.home" = "${pkgs.jdk25}/lib/openjdk";

    # JDKs used to compile and run projects
    "java.configuration.runtimes" = [
      { name = "JavaSE-21"; path = "${pkgs.jdk21_headless}/lib/openjdk"; default = true; }
      # older project:
      # { name = "JavaSE-11"; path = "${pkgs.jdk11}/lib/openjdk"; }
    ];
  };
}
