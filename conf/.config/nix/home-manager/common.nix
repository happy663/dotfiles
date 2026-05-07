{ inputs, lib, config, pkgs, ... }:


let
  username = "happy";

  # npmパッケージをNixで管理
  nodeTools = pkgs.importNpmLock.buildNodeModules {
    npmRoot = ../node-pkgs;
    nodejs = pkgs.nodejs_24;
  };
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
      imagemagick
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
      coreutils-prefixed
      zoxide
      delta
      cargo
      uv
      docker
      docker-compose
      colima
      awscli2
      fastfetch
      neovim-remote
      fastfetch
      nodejs_24
      # Node.js tools managed by Nix
      nodeTools
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
      tmux
      deno
      bun
      php84Extensions.xdebug
      rtk
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
      GOPATH = "$HOME/go";
      # Additional environment variables
      DOTFILES_DIR = "$HOME/src/github.com/happy663/dotfiles";
      CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
      LIMA_HOME = "$HOME/.colima_lima";
      AWS_SESSION_TOKEN_TTL = "24h";
      AWS_ASSUME_ROLE_TTL = "12h";
      COLIMA_HOME = "$HOME/.local/share/colima";
      DOCKER_HOST = "unix://$HOME/.local/share/colima/default/docker.sock";
    };

    # ~/.nix-profile/etc/profile.d/hm-session-vars.shにPATHが生成されるのでそれを.zshrcで読み込む必要がある
    sessionPath = [
      "$HOME/.local/bin"
      "${nodeTools}/node_modules/.bin"
      "$HOME/.config/wezterm"
      "/opt/homebrew/bin"
      "/usr/local/bin"
      "$GOPATH/bin"
      "$HOME/src/github.com/wachikun/yaskkserv2/target/release"
    ];

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.05";

    activation.myScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="$HOME/src/github.com/wachikun/yaskkserv2/target/release:$PATH"
      sh $HOME/src/github.com/happy663/dotfiles/scripts/skkserv.sh
    '';

    activation.installTpm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
        ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
      fi
    '';


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
    delta.enable = true;
    git = {
      enable = true;
      includes = [
        # 別ディレクトリ用の設定を読み込む
        {
          condition = "gitdir:~/src/github.com/ppha3260-web/";
          path = "~/.config/git/gitconfig_sub";
        }
      ];
      settings = {
        user = {
          name = "happy663";
          email = "tatu2425@gmail.com";
        };
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

  };


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


