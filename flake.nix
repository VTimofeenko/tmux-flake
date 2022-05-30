{
  description = "My tmux config flake";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  # Colors
  inputs.base16 = {
    url = "github:SenchoPens/base16.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.color_scheme = {
    url = "github:ajlende/base16-atlas-scheme";
    flake = false;
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 self.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

      # When changing color scheme, needs to be changed here as well
      color_scheme_name = "atlas";
      /* mkSchemeAttrs needs pkgs and a lib. For this context - let's just give one at random. */
      /* We're just creating a file, probably it's OK */
      /* build_pkgs = import nixpkgs { system = "x86_64-linux"; }; */

      /* Function that returns the tmux config. Defined here to keep the code DRY. */
      mkTmuxConf = pkgs:
        let
          rendered_color_scheme = with inputs; (base16.outputs.lib { inherit pkgs; lib = pkgs.lib; }).mkSchemeAttrs "${color_scheme}/${color_scheme_name}.yaml";
        in
        with builtins; ''
          # Main config
          ${readFile ./tmux.conf}
        '' + (with rendered_color_scheme; (
          let
            default_background = "#" + base00;
            default_foreground = "#" + base07;
            /* helper functions */
            mkbg = _: "bg=#" + _;
            mkfg = _: "fg=#" + _;
          in
          builtins.concatStringsSep "\n" (nixpkgs.lib.attrsets.attrValues (nixpkgs.lib.attrsets.mapAttrs (k: v: "set -g ${k} \"${toString v}\"") {
            /* Status (background of the pane) */
            "status-interval" = 1;
            "status" = "on";
            "status-style" = "${mkfg base07},${mkbg base00}";
            "message-style" = mkfg base01 + "," + mkbg base0A;
            "message-command-style" = mkfg base01 + "," + mkbg base0A;
            /* Copy mode */
            "mode-style" = "${mkfg base00},${mkbg base0E}";

            /* Panes */
            "pane-border-style" = "${mkfg base04}";
            "display-panes-colour" = "#${base04}";
            "pane-active-border-style" = "${mkfg base0E}";
            "display-panes-active-colour" = "#${base02}";

            /* The name of the session is here */
            "status-left" = "#[${mkfg base00},${mkbg base0E},bold] #S #[${mkfg base0E},${mkbg base00},nobold]";
            /* The format of the window bars that follow the session name */
            "window-status-format" = "#[${mkfg base00},${mkbg base04}] #[${mkfg base07},${mkbg base04}]#I #[${mkfg base07},${mkbg base04}]#W #F #[${mkfg base04},${mkbg base00}]";
            /* Active window. Symbol helps with additional highlighting. */
            "window-status-current-format" = "#[${mkfg base00},${mkbg base02}] #[${mkfg base07},${mkbg base02}]#I #[${mkfg base00},${mkbg base02}] #[${mkfg base07},${mkbg base02}]#W: #F #[${mkfg base02},${mkbg base00}]";

            /* Clock + hostname */
            "status-right" = "#[${mkfg base04},${mkbg base00}]#[${mkfg base07},${mkbg base04}] %b %-d %R #[${mkfg base0C},${mkbg base04}]#[${mkfg base07},${mkbg base0C}] #H ";
            /* bell */
            "window-status-bell-style" = "${mkfg base01},${mkbg base08}";
          }))
        ));
    in
    {

      /* Build tmux.conf for systems without nix.
        Does not include any plugins */
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          tmux-conf = pkgs.writeTextFile {
            name = "tmux.conf";
            text = mkTmuxConf pkgs;
            destination = "/etc/tmux.conf";
          };
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.tmux-conf);

      nixosModule = import ./tmux.nix mkTmuxConf;

      devShell = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        with pkgs; mkShell {
          buildInputs = [ pre-commit nixpkgs-fmt ];
        });

    };

}
