require "yaml"

class Mason < Formula
  desc "A template generator which helps teams generate files quickly and consistently."
  homepage "https://github.com/felangel/mason"
  url "https://github.com/felangel/mason/archive/refs/tags/mason_cli-v0.1.0-dev.38.tar.gz"
  sha256 "5d52be805566f6866ab75ccd4f86f888d5a6ad10a1213019ad31393581f522ea"
  license "MIT"

  depends_on "dart-lang/dart/dart" => :build

  def install
    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:mason_cli"

    # Change directories into the mason_cli package directory.
    Dir.chdir('packages/mason_cli')

    system _dart/"dart", "pub", "get"
  
    _install_script_snapshot

    chmod 0555, "#{bin}/mason"
  end

  private

  def _dart
    @_dart ||= Formula["dart-lang/dart/dart"].libexec/"bin"
  end

  def _version
    @_version ||= YAML.safe_load(File.read("pubspec.yaml"))["version"]
  end

  def _install_script_snapshot
    system _dart/"dart", "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-o", "mason.dart.app.snapshot",
           "bin/mason.dart"
    lib.install "mason.dart.app.snapshot"
    
    cp _dart/"dart", lib

    (bin/"mason").write <<~SH
      #!/bin/sh
      exec "#{lib}/dart" "#{lib}/mason.dart.app.snapshot" "$@"
    SH
  end
end
