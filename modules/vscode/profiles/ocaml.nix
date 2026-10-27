{ ext, pkgs, ... }:

{
  extensions = with ext; [
    ocamllabs.ocaml-platform

    # Extensions missing from nixpkgs come straight from the marketplace.
    # Get the hash by leaving it empty: the rebuild error prints the right one.
    # (pkgs.vscode-utils.extensionFromVscodeMarketplace {
    #   name = "vscode-ocaml-expect-inline";
    #   publisher = "release-candidate";
    #   version = "0.7.2";
    #   hash = "sha256-pg2LPTnZ+j66zdxZ0e7nMaX2xk1pW1hqgfRmZXzIq6k=";
    # })
  ];
}
