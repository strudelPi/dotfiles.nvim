{inputs}: let
  inherit (inputs.nixpkgs) legacyPackages;
in rec {
  mkCopilotChat = {system}: let
    inherit (pkgs) vimUtils;
    inherit (vimUtils) buildVimPlugin;
    pkgs = legacyPackages.${system};
  in
    buildVimPlugin {
      name = "CopilotChat";
      src = inputs.copilotchat;
    };

  mkVimPlugin = {system}: let
    inherit (pkgs) vimUtils;
    inherit (vimUtils) buildVimPlugin;
    pkgs = legacyPackages.${system};
  in
    buildVimPlugin {
      name = "TheAltF4Stream";
      postInstall = ''
        rm -rf $out/.envrc
        rm -rf $out/.gitignore
        rm -rf $out/LICENSE
        rm -rf $out/README.md
        rm -rf $out/flake.lock
        rm -rf $out/flake.nix
        rm -rf $out/justfile
        rm -rf $out/lib
      '';
      src = ../.;
    };

  mkNeovimPlugins = {system}: let
    inherit (pkgs) vimPlugins;
    CopilotChat-nvim = mkCopilotChat {inherit system;};
    pkgs = legacyPackages.${system};
    TheAltF4Stream-nvim = mkVimPlugin {inherit system;};
  in [
    # languages
    vimPlugins.nvim-lspconfig
    vimPlugins.nvim-treesitter.withAllGrammars
    vimPlugins.rust-tools-nvim
    vimPlugins.vim-just
    vimPlugins.zig-vim

    # telescope
    vimPlugins.plenary-nvim
    vimPlugins.telescope-nvim

    # theme
    vimPlugins.tokyonight-nvim

    # floaterm
    vimPlugins.vim-floaterm

    # extras
    CopilotChat-nvim
    vimPlugins.comment-nvim
    vimPlugins.copilot-lua
    vimPlugins.gitsigns-nvim
    vimPlugins.lualine-nvim
    vimPlugins.noice-nvim
    vimPlugins.nui-nvim
    vimPlugins.nvim-colorizer-lua
    vimPlugins.nvim-notify
    vimPlugins.nvim-treesitter-context
    vimPlugins.nvim-web-devicons
    vimPlugins.rainbow-delimiters-nvim
    vimPlugins.trouble-nvim
    vimPlugins.which-key-nvim
    vimPlugins.undotree

    vimPlugins.obsidian-nvim
    vimPlugins.nvim-cmp # required for obsidian (completion)

    # configuration
    TheAltF4Stream-nvim
  ];

  mkExtraPackages = {system}: let
    inherit (pkgs) nodePackages python3Packages;
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in [
    # language servers
    nodePackages.bash-language-server
    nodePackages.diagnostic-languageserver
    nodePackages.dockerfile-language-server-nodejs
    nodePackages.vscode-langservers-extracted
    nodePackages.yaml-language-server
    pkgs.jsonnet-language-server
    pkgs.lua-language-server
    pkgs.nil
    pkgs.pyright
    pkgs.rust-analyzer

    # formatters
    pkgs.alejandra
    pkgs.gofumpt
    pkgs.golines
    pkgs.rustfmt
    python3Packages.black
  ];

  mkExtraConfig = ''
    lua << EOF
      require 'TheAltF4Stream'.init()
    EOF
  '';

  mkNeovim = {system}: let
    inherit (pkgs) lib neovim;
    extraPackages = mkExtraPackages {inherit system;};
    pkgs = legacyPackages.${system};
    start = mkNeovimPlugins {inherit system;};
  in
    neovim.override {
      configure = {
        customRC = mkExtraConfig;
        packages.main = {inherit start;};
      };
      extraMakeWrapperArgs = ''--suffix PATH : "${lib.makeBinPath extraPackages}"'';
      withNodeJs = true;
      withPython3 = true;
      withRuby = true;
    };

  mkHomeManager = {system}: let
    extraConfig = mkExtraConfig;
    extraPackages = mkExtraPackages {inherit system;};
    plugins = mkNeovimPlugins {inherit system;};
  in {
    inherit extraConfig extraPackages plugins;
    defaultEditor = true;
    enable = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };
}
