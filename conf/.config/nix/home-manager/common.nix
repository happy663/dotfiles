
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
    homeDirectory = "/home/${username}";

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
      gcc
      hackgen-font
      hackgen-nf-font
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

    zsh = {
      enable = true;
      initExtra = ''
        # zinit
        if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
          command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
          command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
        fi
        source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
        autoload -Uz _zinit
        if [ -n "$_comps" ]; then
          _comps[zinit]=_zinit
        fi

        # p10k
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        # zinit plugins
        zinit light romkatv/powerlevel10k
        zinit light zsh-users/zsh-syntax-highlighting
        zinit light zsh-users/zsh-autosuggestions
        zinit light mollifier/anyframe
        zinit light zsh-users/zsh-completions

        # コマンド補完
        autoload -Uz compinit && compinit
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        zstyle ':completion:*:default' menu select=1

        # 最近のディレクトリ
        autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
        add-zsh-hook chpwd chpwd_recent_dirs

        # キーバインド
        bindkey '^xb' anyframe-widget-cdr
        bindkey '^xr' anyframe-widget-execute-history
        bindkey '^x^b' anyframe-widget-checkout-git-branch
        bindkey -e

        # mise
        eval "$(mise activate zsh)"
        
        # zoxide
        eval "$(zoxide init zsh)"

        # cdしたらlsする
        case "''${OSTYPE:-darwin}" in
          darwin*)
            export CLICOLOR=1
            function chpwd() { ls -A -G -F }
            ;;
          linux*)
            function chpwd() { ls -A -F --color=auto }
            ;;
        esac

        # プロンプト設定
        _prompt_executing=""
        function __prompt_precmd() {
          local ret="$?"
          if test "$_prompt_executing" != "0"
          then
            _PROMPT_SAVE_PS1="$PS1"
            _PROMPT_SAVE_PS2="$PS2"
            PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
            PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
          fi
          if test "$_prompt_executing" != ""
          then
            printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
          fi
          printf "\033]133;A;cl=m;aid=%s\007" "$$"
          _prompt_executing=0
        }
        function __prompt_preexec() {
          PS1="$_PROMPT_SAVE_PS1"
          PS2="$_PROMPT_SAVE_PS2"
          printf "\033]133;C;\007"
          _prompt_executing=1
        }
        preexec_functions+=(__prompt_preexec)
        precmd_functions+=(__prompt_precmd)

        # 環境変数
        export GOPATH=$HOME/go
        export PATH=$PATH:$HOME/.local/bin
        export PATH=$PATH:$HOME/.config/wezterm
        export PATH="$PATH:/opt/homebrew/bin"
        export PATH="$PATH:/usr/local/bin"
        export PATH=~/.nix-profile/bin:$PATH
        export XDG_CONFIG_HOME="$HOME/.config"
        export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
        export PATH="$PATH:$HOME/src/github.com/wachikun/yaskkserv2/target/release"
        export LIMA_HOME="$HOME/.colima_lima"
        # export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-8.jdk/Contents/Home
        # export PATH="$JAVA_HOME/bin:$PATH"
        eval "$(coursier java --jvm temurin:17 --env)"




        # OS固有の設定
        if [[ "$OSTYPE" == "darwin"* ]]; then
          export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib $LDFLAGS"
          export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include $CPPFLAGS"
          export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
          eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
          export LDFLAGS="-L/home/linuxbrew/.linuxbrew/opt/zlib/lib \
          -L/home/linuxbrew/.linuxbrew/opt/openssl@1.1/lib \
          -L/home/linuxbrew/.linuxbrew/opt/readline/lib \
          -L/home/linuxbrew/.linuxbrew/opt/libffi/lib \
          -L/home/linuxbrew/.linuxbrew/opt/ncurses/lib \
          -L/home/linuxbrew/.linuxbrew/opt/bzip2/lib $LDFLAGS"

          export CPPFLAGS="-I/home/linuxbrew/.linuxbrew/opt/zlib/include \
          -I/home/linuxbrew/.linuxbrew/opt/openssl@1.1/include \
          -I/home/linuxbrew/.linuxbrew/opt/readline/include \
          -I/home/linuxbrew/.linuxbrew/opt/libffi/include \
          -I/home/linuxbrew/.linuxbrew/opt/ncurses/include \
          -I/home/linuxbrew/.linuxbrew/opt/bzip2/include $CPPFLAGS"

          export PKG_CONFIG_PATH="/home/linuxbrew/.linuxbrew/opt/zlib/lib/pkgconfig:\
          /home/linuxbrew/.linuxbrew/opt/openssl@1.1/lib/pkgconfig:\
          /home/linuxbrew/.linuxbrew/opt/readline/lib/pkgconfig:\
          /home/linuxbrew/.linuxbrew/opt/libffi/lib/pkgconfig:\
          /home/linuxbrew/.linuxbrew/opt/ncurses/lib/pkgconfig:\
          /home/linuxbrew/.linuxbrew/opt/bzip2/lib/pkgconfig:\
          $PKG_CONFIG_PATH"

          alias pbcopy='xsel --clipboard --input'
        fi

        # nvim設定
        if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
          alias nvim=nvr -cc split --remote-wait +'set bufhidden=wipe'
          export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
          export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
        fi

        # yazi関数
        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }

        # fkill関数
        function fkill() {
          local pid
          pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
          if [ "x$pid" != "x" ]
          then
            echo $pid | xargs kill -9
          fi
        }

        # ghcr関数
        function ghcr() {
          gh repo create "$@"
          ghq get "git@github.com:happy663/$1.git"
        }

        # movehere関数
        function movehere() {
          local search_dir
          search_dir="''${1:-$HOME/Downloads}"
          mv "$search_dir/$(ls -t -r "$search_dir" | fzf)" .
        }

        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        export AWS_SESSION_TOKEN_TTL=12h
        
        # Load local environment variables
        if [[ -f ~/.config/nix/home-manager/.env ]]; then
          source ~/.config/nix/home-manager/.env
          alias ssm="make -C $SSM_SCRIPT_PATH clean session"
        fi

      '';

      shellAliases = {
        g = "cd $(ghq root)/$(ghq list | peco)";
        # ls = "gls --color=auto";
        cat = "bat";
        find = "fd";
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        ghb = "gh browse";
        ghpc = "gh pr checks";
        ghprc = "gh pr create";
        relogin = "exec $SHELL -l";
        n = "nvim";
        gc = "ghq get";
        po = "poetry";
        py = "python3";
        de = "docker exec -it $(docker ps | peco | cut -d \" \" -f 1) /bin/bash";
        bat = "bat";
        rg = "rg";
        fzf = "fzf";
        alert = "terminal-notifier -message";
      };

      history = {
        size = 1000;
        save = 1000;
        path = "$HOME/.zsh_history";
        ignoreDups = true;
        share = true;
      };
    };

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
    neovim = "latest"
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
