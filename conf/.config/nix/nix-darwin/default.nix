{ pkgs, ... }: {

  # nix自体の設定
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
  };
  # services.nix-daemon.enable = true;

  # システムの設定（nix-darwinが効いているかのテスト）
  system = {
    stateVersion = 6;

    defaults = {
      NSGlobalDomain.AppleShowAllExtensions = true;
      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
      };
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "bottom";
        # magnification = true;  # dockのアイコンをホバー時に拡大
        # magnification-level = 1.5;  # 拡大レベル（1.0-3.0）
        # static-only = true;    # 開いているアプリケーションのみを表示
        # mru-spaces = false;    # 最近使用したスペースを表示しない
        # show-process-indicators = true;  # 実行中のアプリケーションのインジケータを表示
        # showhidden = true;     # 非表示のアプリケーションを表示
        # show-recents = false;  # 最近使用したアプリケーションを表示しない
        # minimize-to-application = true;  # ウィンドウを最小化する際にアプリケーションアイコンに格納
        # launchanim = true;     # アプリケーション起動時のアニメーション
        # mineffect = "genie";   # 最小化エフェクト（genie, scale, suck）
        # persistent-apps = [];  # 常に表示するアプリケーションのリスト
        # tilesize = 48;        # dockのアイコンサイズ（16-128）
      };
    };
  };



  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      # cleanup = "zap";
    };
    taps = [
      "homebrew/bundle"
      "homebrew/cask-fonts"
    ];
    casks = [
      "alacritty"
      "aerospace"
      "alt-tab"
      "figma"
      "visual-studio-code"
      "wezterm"
      "discord"
      "font-hack-nerd-font"
      "font-hackgen"
      "font-hackgen-nerd"
      "raycast"
      "slack"
      "google-chrome"
      "gyazo"
      "macskk"
      "postman"
      "scroll-reverser"
    ];
  };

  fonts = {
    packages = with pkgs;[
      hackgen-font
      hackgen-nf-font
    ];

  };

}
