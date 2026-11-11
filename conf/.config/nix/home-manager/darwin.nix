{ inputs, lib, config, pkgs,  ... }:

{
  imports = [
    ./common.nix
  ];
  home.homeDirectory = "/Users/${config.home.username}";
  home.packages = with pkgs;[
    terminal-notifier
    # neovim-nightly-overlay 由来 (flake.nix の overlays で適用済み)
    neovim
    # Rex の CLI。本体は Rex.app に同梱されているので、それを呼ぶラッパーを置く
    # （アプリのパスに空白があるため sessionPath ではなくラッパーにする）
    (writeShellScriptBin "rex" ''
      for app in "/Applications/Rex.app" "/Applications/Rex Beta.app"; do
        bin="$app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex"
        if [ -x "$bin" ]; then
          exec "$bin" "$@"
        fi
      done
      echo "rex: Rex.app が /Applications に見つかりません" >&2
      exit 127
    '')
    # Rex のペインを Neovim のウィンドウとして使うフロントエンド（flake input の neorex）
    inputs.neorex.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.file."Library/Fonts/akkurat.ttf".source = ../../fonts/akkurat.ttf;
}
