{ ... }: {
  # Remote Login (sshd) を有効化（issue #229）
  # モバイルから mosh 経由で接続するためのブートラップ（mosh は認証に SSH を使う）
  # セキュリティ: 鍵認証のみ（パスワードオフ）、外部は家庭 NAT で保護、主経路は Tailscale
  # 注: systemsetup -setremotelogin は Full Disk Access で弾かれるため使わない。
  #     launchctl load -w で ssh.plist を永続ロード（-w で再起動後も有効）。
  system.activationScripts.sshd.text = ''
    if ! /usr/bin/launchctl list com.openssh.sshd >/dev/null 2>&1; then
      /usr/bin/launchctl load -w /System/Library/LaunchDaemons/ssh.plist
    fi
  '';

  # sshd 強化: 鍵認証のみ、root ログイン完全禁止
  environment.etc."ssh/sshd_config.d/200-hardening.conf".text = ''
    PasswordAuthentication no
    PermitRootLogin no
    ChallengeResponseAuthentication no
  '';

  # SSH 公開鍵
  # ~/.ssh/authorized_keys から移行。nix-darwin が /etc/ssh/nix_authorized_keys.d/happy に配置。
  users.users.happy.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAZvbtt7/YYc4oiHjNdPE6z/LnnZGH2KepnhAiynwOhE" # Moshi (iPhone), issue #229
  ];

  homebrew = {
    taps = [
      {
        name = "rjyo/moshi";
        trusted = true;
      }
    ];

    brews = [
      "moshi-hook"
    ];

    casks = [
      "tailscale-app"
    ];
  };
}
