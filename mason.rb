class Mason < Formula
  desc "A template generator which helps teams generate files quickly and consistently."
  homepage "https://pub.dev/packages/mason"
  url "https://github.com/felangel/mason/archive/refs/tags/v0.0.1-dev.48.tar.gz"
  sha256 "50ee2228c0e194cf2c02610b96263927bb36fe51e774f6e682291ceee9e60bde"
  license "MIT"

  depends_on "dart"

  def install
    dart = Formula["dart"].opt_bin

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
