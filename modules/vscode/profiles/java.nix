{ ext, ... }:

{
  extensions = with ext; [
    oracle.oracle-java
    redhat.java
    vscjava.vscode-java-debug
    vscjava.vscode-java-dependency
    vscjava.vscode-java-pack
    vscjava.vscode-java-test
    vscjava.vscode-maven
  ];

  userSettings = {
    "jdk.telemetry.enabled" = false;
  };
}
