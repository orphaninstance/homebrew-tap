cask "kitty-linux" do
  arch arm: "arm64", intel: "x86_64"

  version "0.51.0"
  sha256 arm64_linux:  "2a3eab469c37b548c5ceecff4b500a5b6b5c50f99cc17e0213e06a4c9662d31a",
         x86_64_linux: "c285daaf1b699997614939c8d1cd92dd8b99302ff12f18efcc3f69382aa72b1d"

  url "https://github.com/kovidgoyal/kitty/releases/download/v#{version}/kitty-#{version}-#{arch}.txz"
  name "kitty"
  desc "GPU-based terminal emulator"
  homepage "https://sw.kovidgoyal.net/kitty/"

  livecheck do
    url "https://github.com/kovidgoyal/kitty/releases/latest"
    strategy :github_latest
  end

  depends_on :linux

  binary "bin/kitty"
  binary "bin/kitten"
  artifact "kitty.desktop",
           target: "#{Dir.home}/.local/share/applications/kitty.desktop"
  artifact "share/icons/hicolor/scalable/apps/kitty.svg",
           target: "#{Dir.home}/.local/share/icons/hicolor/scalable/apps/kitty.svg"
  artifact "share/terminfo/x/xterm-kitty",
           target: "#{Dir.home}/.terminfo/x/xterm-kitty"

  preflight_steps do
    write_file "kitty.desktop", <<~EOS
      [Desktop Entry]
      Name=kitty
      Comment=GPU-based terminal emulator
      GenericName=Terminal Emulator
      Exec={{HOMEBREW_PREFIX}}/bin/kitty
      Icon=kitty
      Type=Application
      StartupNotify=false
      StartupWMClass=kitty
      Categories=System;TerminalEmulator;
      MimeType=x-scheme-handler/kitty;
    EOS
  end

  zap trash: [
    "~/.cache/kitty",
    "~/.config/kitty",
    "~/.local/share/applications/kitty.desktop",
    "~/.local/share/icons/hicolor/scalable/apps/kitty.svg",
    "~/.terminfo/x/xterm-kitty",
  ]

  caveats <<~EOS
    Kitty is a GPU-based terminal. Ensure your system has up-to-date OpenGL drivers.

    Terminfo definitions have been installed to ~/.terminfo. This ensures that
    applications like Vim and SSH recognize Kitty's capabilities.

    You can find configuration examples at: https://sw.kovidgoyal.net/kitty/configure/
  EOS
end
