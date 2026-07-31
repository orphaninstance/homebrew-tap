cask "kitty-linux" do
  arch arm: "arm64", intel: "x86_64"

  version "0.48.2"
  sha256 arm64_linux:  "534b214d407a05e4603da75ef02fffa592ec1bbec20a413c5e0cd3f853c928cb",
         x86_64_linux: "967a1958e7fc67b495d279c0963bcd1a0482097151817ce6506fabc822689af7"

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

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons/hicolor/scalable/apps")
    FileUtils.mkdir_p("#{Dir.home}/.terminfo/x")

    File.write("#{staged_path}/kitty.desktop", <<~EOS)
      [Desktop Entry]
      Name=kitty
      Comment=GPU-based terminal emulator
      GenericName=Terminal Emulator
      Exec=#{HOMEBREW_PREFIX}/bin/kitty
      Icon=#{Dir.home}/.local/share/icons/hicolor/scalable/apps/kitty.svg
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
