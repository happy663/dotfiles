{ inputs, lib, config, pkgs, phps, ... }:


let
  username = "happy";
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = username;

    packages = with pkgs; [
      # CLI tools
      bat
      fd
      ripgrep
      tree
      fzf
      gh
      ghq
      peco
      mise
      coreutils
      zoxide
      delta
      cargo
      uv
      docker
      docker-compose
      colima
      awscli
      fastfetch
      neovim-remote
      firefox
      neofetch
      # Development tools
      (lazygit.overrideAttrs (oldAttrs: {
        version = "0.40.2";
        src = fetchFromGitHub {

          owner = "jesseduffield";
          repo = "lazygit";
          rev = "v0.40.2";
          hash = "sha256-xj5WKAduaJWA3NhWuMsF5EXF91+NTGAXkbdhpeFqLxE=";
        };
      }))
      deno
      phps.packages.${pkgs.system}.php74
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
      GOPATH = "$HOME/go";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.config/wezterm"
      "/opt/homebrew/bin"
      "$GOPATH/bin"
    ];

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.05";
  };

  # home.file.".xsessionrc" = {
  #   text = ''
  #     xset r rate 150 50
  #   '';
  #   excutable = true;
  # };

  # home.file.".xprofile" = {
  #   text = ''
  #     xset r rate 150 50
  #   '';
  # };



  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      userName = "happy663";
      userEmail = "tatu2425@gmail.com";
      delta.enable = true;
      includes = [
        # 別ディレクトリ用の設定を読み込む
        {
          condition = "gitdir:~/src/github.com/ppha3260-web/";
          path = "~/.config/git/gitconfig_sub";
        }
      ];
      extraConfig = {
        core = {
          editor = "nvim";
          excludesfile = "~/.config/git/ignore";
        };
        credential = {
          helper = "!aws codecommit credential-helper $@";
          UseHttpPath = true;
        };

        ghq = {
          root = [
            "~/src"
          ];
        };
        http.postBuffer = 524288000;
        pull.rebase = false;
        pager = {
          diff = "delta";
          log = "delta";
          reflog = "delta";
          show = "delta";
        };
        delta = {
          plus-style = "syntax #012800";
          minus-style = "syntax #340001";
          syntax-theme = "Monokai Extended";
          navigate = true;
          side-by-side = true;
        };
        # interactive.diffFilter = lib.mkForce "delta --color-only";
        # "filter \"clean_ipynb\"" = {
        #   clean = "jq --indent 1 --monochrome-output '. + if .metadata.git.suppress_outputs | not then { cells: [.cells[] | . + if .cell_type == \"code\" then { outputs: [], 　execution_count: null } else {} end ] } else {} end'";
        #   smudge = "cat";
        # };
        alias.ac = "!git add -A && aicommits -a";
      };
    };

    # zsh = {
    #   enable = true;
    #   initContent = ''
    #     # Load zsh configuration from dotfiles
    #     [[ -f ~/.zshrc ]] && source ~/.zshrc
    #   '';
    # };

    tmux = {
      enable = true;
      extraConfig = ''
        source-file ~/.config/tmux/tmux-wezterm.conf
      '';
      # shell = "${pkgs.zsh}/bin/zsh";
      # terminal = "screen-256color";
      # prefix = "C-q";
      # baseIndex = 1;
      # mouse = true;
      # escapeTime = 0;
      # extraConfig = ''
      #   # ステータスバーをトップに配置する
      #   set-option -g status-position top
      #
      #   # ステータスバーの長さを設定
      #   set-option -g status-left-length 90
      #   set-option -g status-right-length 90
      #
      #   # ステータスバーの表示
      #   set-option -g status-left '#H:[#P]'
      #   set-option -g status-right '[%Y-%m-%d(%a) %H:%M]'
      #   set-option -g status-interval 1
      #   set-option -g status-justify centre
      #
      #   # ステータスバーの色設定
      #   set-option -g status-bg "colour238"
      #   set-option -g status-fg "colour255"
      #
      #   # vim keybindings
      #   bind h select-pane -L
      #   bind j select-pane -D
      #   bind k select-pane -U
      #   bind l select-pane -R
      #
      #   bind -r H resize-pane -L 5
      #   bind -r J resize-pane -D 5
      #   bind -r K resize-pane -U 5
      #   bind -r L resize-pane -R 5
      #
      #   # split windows
      #   bind | split-window -h
      #   bind - split-window -v
      #
      #   # copy mode
      #   setw -g mode-keys vi
      #   bind -T copy-mode-vi v send -X begin-selection
      #   bind -T copy-mode-vi V send -X select-line
      #   bind -T copy-mode-vi C-v send -X rectangle-toggle
      #   bind -T copy-mode-vi y send -X copy-selection
      #   bind -T copy-mode-vi Y send -X copy-line
      #   bind-key C-p paste-buffer
      # '';
    };

  };

  # mise config
  xdg.configFile."mise/config.toml".text = ''
    [tools]
    go = '1.21.5'
    node = "latest"
    python = "3.12.2"
    yarn = "1.22.19"
    neovim = "0.11.3"
    ghc = "9.6.5"
    deno = "latest"
    pnpm = "latest"
    rust = "nightly"
  '';

  # gitattributes config
  xdg.configFile."git/attributes".text = ''
    **/SKK-JISYO.L linguist-vendored
  '';

  # gitignore config
  xdg.configFile."git/ignore".text = ''
    # macOS
    .DS_Store
    .AppleDouble
    .LSOverride
    ._*
    
    # Thumbnails
    ._*
    
    # Files that might appear in the root of a volume
    .DocumentRevisions-V100
    .fseventsd
    .Spotlight-V100
    .TemporaryItems
    .Trashes
    .VolumeIcon.icns
    .com.apple.timemachine.donotpresent
    
    # Directories potentially created on remote AFP share
    .AppleDB
    .AppleDesktop
    Network Trash Folder
    Temporary Items
    .apdisk
    
    # Node
    node_modules
    npm-debug.log
    
    # Python
    __pycache__/
    *.py[cod]
    *$py.class
    .pytest_cache/
    .coverage
    htmlcov/
    
    # IDE
    .idea/
    .vscode/
    *.swp
    *.swo
    
    # Env
    .env
    .env.local
    .env.development.local
    .env.test.local
    .env.production.local
    
    # Build
    dist/
    build/
    *.egg-info/
  '';

  # gitignore_globalを削除する
  home.file.".gitignore_global".enable = false;
}


