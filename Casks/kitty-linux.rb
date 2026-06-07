cask "kitty-linux" do
  arch arm: "arm64", intel: "x86_64"

  version "0.47.2"
  sha256 arm64_linux:  "600efb979d9188758d89fcfe13155cb43027e037d7c70bedd8afcd743119ae8a",
         x86_64_linux: "5495d99ce8e10e3b5e78be1664e6ab6040f3a7db33fd78981b9f5e3782f5921b"

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
  artifact "kitty.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/kitty.png"
  artifact "share/terminfo/x/xterm-kitty",
           target: "#{Dir.home}/.terminfo/x/xterm-kitty"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons/hicolor/512x512/apps")
    FileUtils.mkdir_p("#{Dir.home}/.terminfo/x")

    # Download the official kitty icon
    system(
      "curl", "-L", "https://github.com/kovidgoyal/kitty/raw/master/logo/kitty.png",
      "-o", "#{staged_path}/kitty.png"
    )

    # Verify icon integrity
    actual_sha = Digest::SHA256.file("#{staged_path}/kitty.png").hexdigest
    expected_sha = "238d24e2730c94e9aaed76d25140bb3e2ade241ec313cc0b29d206e46cbfdabe"
    raise "Icon checksum mismatch! Expected #{expected_sha}, got #{actual_sha}" if actual_sha != expected_sha

    File.write("#{staged_path}/kitty.desktop", <<~EOS)
      [Desktop Entry]
      Name=kitty
      Comment=GPU-based terminal emulator
      GenericName=Terminal Emulator
      Exec=#{HOMEBREW_PREFIX}/bin/kitty
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/kitty.png
      Type=Application
      StartupNotify=false
      StartupWMClass=kitty
      Categories=System;TerminalEmulator;
      MimeType=x-scheme-handler/kitty;
    EOS
  end

  zap trash: [
    "~/.config/kitty",
    "~/.local/share/applications/kitty.desktop",
    "~/.local/share/icons/hicolor/512x512/apps/kitty.png",
    "~/.terminfo/x/xterm-kitty",
  ]

  caveats <<~EOS
    Kitty is a GPU-based terminal. Ensure your system has up-to-date OpenGL drivers.

    Terminfo definitions have been installed to ~/.terminfo. This ensures that
    applications like Vim and SSH recognize Kitty's capabilities.

    You can find configuration examples at: https://sw.kovidgoyal.net/kitty/configure/
  EOS
end
