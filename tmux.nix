# Nix configuration for system-wide tmux
# It is used by all users and shall stay pretty much identical

# 'mkTmuxConf' is used to generate tmux_conf
# See flake.nix for details
mkTmuxConf: { pkgs, lib, config, ... }:

# Whatever additional plugins are required can be added here
# and added to plugins
let plugins = with pkgs.tmuxPlugins; [
];
in
{
  environment.systemPackages = plugins ++ (with pkgs; [
    tmux
  ]);
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 1;
    extraConfig = ''
      ${mkTmuxConf pkgs}

      # Plugins
      ${lib.concatStrings (map (x: "run-shell ${x.rtp}\n") plugins)}
    '';
  };
}
