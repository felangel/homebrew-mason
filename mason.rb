class Mason < Formula
  desc "A template generator which helps teams generate files quickly and consistently."
  homepage "https://pub.dev/packages/mason_cli"
  url "https://github.com/felangel/mason/archive/refs/tags/mason_cli-v0.1.0-dev.15.tar.gz"
  sha256 "746e83d04acd517902f6383c6dbfd9dc6d3ded68392a4e45a109c925fe1df5b1"
  license "MIT"

  depends_on "dart"

  def install
    dart = Formula["dart"].opt_bin

    # Change directories into the mason_cli package directory.
    Dir.chdir('packages/mason_cli')

    pubspec = YAML.safe_load(File.read("pubspec.yaml"))
    version = pubspec["version"]

    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:mason"
    
    system dart/"pub", "get"

    if Hardware::CPU.is_64_bit?
      # Build a native-code executable on 64-bit systems only. 32-bit Dart
      # doesn't support this.
      system dart/"dart2native", "-Dversion=#{version}", "bin/mason.dart",
             "-o", "mason"
      bin.install "mason"
    else
      system dart/"dart",
             "-Dversion=#{version}",
             "--snapshot=mason.dart.app.snapshot",
             "--snapshot-kind=app-jit",
             "bin/mason.dart", "version"
      lib.install "mason.dart.app.snapshot"
    end
  end
end
