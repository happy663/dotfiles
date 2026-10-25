{ ... }: {
  # 仕事用Mac固有の nix-darwin 設定をここに追加する。
  homebrew.brews = [
    "aws-vault"
    "newrelic-cli"
    "snowflake-cli"
  ];
}
