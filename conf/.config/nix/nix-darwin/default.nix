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
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false; # キーリピートを有効にする（長押しの特殊文字入力を無効化）
        InitialKeyRepeat = 15; # キーリピート開始までの時間（デフォルトは25、小さいほど速く開始）
        KeyRepeat = 2; # キーリピートの速度（デフォルトは6、小さいほど速い）
        NSAutomaticCapitalizationEnabled = false; # 自動大文字化を無効
        NSAutomaticDashSubstitutionEnabled = false; # 自動ダッシュ置換を無効
        NSAutomaticPeriodSubstitutionEnabled = false; # 自動ピリオド置換を無効
        NSAutomaticQuoteSubstitutionEnabled = false; # 自動引用符置換を無効
        NSAutomaticSpellingCorrectionEnabled = false; # 自動スペルチェックを無効
        NSNavPanelExpandedStateForSaveMode = true; # 保存ダイアログを拡張表示
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true; # 印刷ダイアログを拡張表示
        PMPrintingExpandedStateForPrint2 = true;
        NSDocumentSaveNewDocumentsToCloud = false; # 新規ドキュメントをiCloudに保存しない
        AppleShowScrollBars = "Always"; # スクロールバーを常に表示
        NSScrollAnimationEnabled = true; # スクロールアニメーションを有効化
        AppleScrollerPagingBehavior = true; # ページ単位スクロールを有効化
        NSTableViewDefaultSizeMode = 2; # サイドバー項目のサイズ
        AppleInterfaceStyleSwitchesAutomatically = false; # 自動ダークモード切替を無効化
      };

      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true; # Finderのタイトルバーにフルパスを表示
        FXDefaultSearchScope = "SCcf"; # 検索時のデフォルトをカレントディレクトリに
        FXEnableExtensionChangeWarning = false; # 拡張子変更時の警告を無効
        QuitMenuItem = true; # Finderの終了メニューを表示
        ShowPathbar = true; # パスバーを表示
        ShowStatusBar = true; # ステータスバーを表示
        FXPreferredViewStyle = "Nlsv"; # リスト表示をデフォルトに設定
        CreateDesktop = true; # デスクトップアイコンを表示
      };

      dock = {
        autohide = true;
        show-recents = false;
        orientation = "bottom";
        tilesize = 60; # Dockアイコンのサイズ
        magnification = false; # マウスオーバー時の拡大を有効
        largesize = 64; # 拡大時のサイズ
        mineffect = "scale"; # 最小化エフェクト
        minimize-to-application = true; # アプリケーションアイコンに最小化
        launchanim = true; # 起動アニメーション
        show-process-indicators = true; # 実行中インジケータを表示
        static-only = false; # 開いているアプリのみ表示
        # persistent-app = [ ]; # 常駐アプリなし
        mru-spaces = false; # 最近使用したスペースを並べ替えない
        expose-animation-duration = 0.1; # Exposéアニメーション速度
        # expose-group-by-app = false; # アプリケーションごとにグループ化しない
        mouse-over-hilite-stack = true; # スタックにカーソルを合わせたときハイライト
        wvous-tl-corner = 2; # 左上ホットコーナー：Mission Control
        wvous-tr-corner = 4; # 右上ホットコーナー：デスクトップ
        wvous-bl-corner = 3; # 左下ホットコーナー：アプリケーションウィンドウ
        wvous-br-corner = 5; # 右下ホットコーナー：スクリーンセーバー
      };

      screencapture = {
        location = "~/Pictures/Screenshots"; # スクリーンショットの保存先
        type = "png"; # スクリーンショットの形式
        disable-shadow = true; # ウィンドウのスクリーンショットで影を表示
        include-date = true; # ファイル名に日付を含める
        show-thumbnail = false; # サムネイルを表示
      };

      trackpad = {
        Clicking = true; # タップでクリック
        TrackpadThreeFingerDrag = true; # 3本指ドラッグ
        TrackpadRightClick = true; # 2本指クリックで右クリック
      };

      menuExtraClock = {
        Show24Hour = true; # 24時間表示
        ShowDate = 1; # 日付を表示
        ShowDayOfWeek = true; # 曜日を表示
        ShowSeconds = false; # 秒を表示しない
        IsAnalog = false; # デジタル表示
      };

      # Safari設定
      # Safari = {
      #   AutoOpenSafeDownloads = false; # 「安全な」ファイルのダウンロード後に自動的に開かない
      #   ShowFullURLInSmartSearchField = true; # スマート検索フィールドにフルURLを表示
      #   HomePage = "about:blank"; # ホームページを空白に設定
      #   AutoFillPasswords = false; # パスワードの自動入力を無効化
      #   AutoFillCreditCardData = false; # クレジットカードの自動入力を無効化
      #   IncludeDevelopMenu = true; # 開発メニューを有効化
      #   WebKitDeveloperExtrasEnabledPreferenceKey = true; # 開発者機能を有効化
      #   WebKitPreferences.developerExtrasEnabled = true;
      #   WebContinuousSpellCheckingEnabled = true; # スペルチェック機能を有効化
      # };

      # コントロールセンター設定
      # ControlCenter = {
      #   BatteryShowPercentage = true; # バッテリー残量をパーセントで表示
      # };
    };

    keyboard = {
      enableKeyMapping = true; # キーマッピングを有効化
      remapCapsLockToControl = true; # CapsキーをControlに変更
    };

    # スクリーンセーバー設定
    # activationSettings = {
    #   askForPassword = true; # スクリーンセーバー後にパスワードを要求
    #   askForPasswordDelay = 5; # パスワード要求までの遅延（秒）
    # };
  };

  # システム全体の設定
  security = {
    # pam.enableSudoTouchIdAuth = true; # TouchIDでのsudo認証を有効化
    pam.services.sudo_local.touchIdAuth = true; # sudoでのTouchID認証を有効化
  };

  # スクリーンセーバー関連の設定
  # システムコマンドを使用して設定する例
  # system.activationScripts.postActivation.text = ''
  #   # スクリーンセーバー後にパスワードを要求
  #   defaults write com.apple.screensaver askForPassword -int 1
  #   # パスワード要求までの遅延（秒）
  #   defaults write com.apple.screensaver askForPasswordDelay -int 5
  # '';

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

  # 環境変数
  environment = {
    variables = {
      LANG = "ja_JP.UTF-8";
    };
  };

  # システムアプリケーション
  launchd.user.agents = {
    # 不要なサービスの無効化など
  };
}
