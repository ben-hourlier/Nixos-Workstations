{ ext, ... }:

{
  extensions = with ext; [
    ms-vscode.cpptools
    ms-vscode.cpptools-extension-pack
    llvm-vs-code-extensions.vscode-clangd
  ];

  userSettings = {
    # clangd handles C/C++ completion and diagnostics; cpptools stays for debugging
    "C_Cpp.intelliSenseEngine" = "disabled";
    # Files without a compile_commands.json (e.g. drill exercises) default to C++20
    "clangd.fallbackFlags" = [ "-std=c++20" ];
  };
}
