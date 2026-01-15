require "yaml"

class Mason < Formula
  desc "A template generator which helps teams generate files quickly and consistently."
  homepage "https://github.com/felangel/mason"
  url "https://github.com/felangel/mason/archive/refs/tags/mason_cli-v0.1.3.tar.gz"
  sha256 "a21a2de3bb340d9811d5fe32608a031a65dcd0499b4b9688784a275a48d471ba"
  license "MIT"

  # Determine architecture and set the Dart SDK resource accordingly
  dart_sdk_version = "3.6.0"
  dart_sdk_url, dart_sdk_sha = if OS.mac? && Hardware::CPU.intel?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/#{dart_sdk_version}/sdk/dartsdk-macos-x64-release.zip",
     "b859b1abd92997b389061be6b301e598a3edcbf7e092cfe5b8d6ce2acdf0732b"]
  elsif OS.mac? && Hardware::CPU.arm?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/#{dart_sdk_version}/sdk/dartsdk-macos-arm64-release.zip",
     "1bdbc6544aaa53673e7cbbf66ad7cde914cb7598936ebbd6a4245e1945a702a0"]
  elsif OS.linux? && Hardware::CPU.intel?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/#{dart_sdk_version}/sdk/dartsdk-linux-x64-release.zip",
     "8e14ff436e1eec72618dabc94f421a97251f2068c9cc9ad2d3bb9d232d6155a3"]
  elsif OS.linux? && Hardware::CPU.arm?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/#{dart_sdk_version}/sdk/dartsdk-linux-arm64-release.zip",
     "0f82f10f808c7003d0d03294ae9220b5e0824ab3d2d19b4929d4fa735254e7bf"]
  end

  resource "dart-sdk" do
    url dart_sdk_url
    sha256 dart_sdk_sha
  end

  def install
    # Resource installation for Dart SDK
    resource("dart-sdk").stage do
      libexec.install Dir["*"] # Assumes Dart SDK zip layout matches what's expected
    end
    
    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:mason_cli"

    # Adjust paths to use the vendored Dart SDK
    dart = libexec/"bin/dart"

    # Change directories into the mason_cli package directory.
    Dir.chdir('packages/mason_cli')

    system dart/"dart", "pub", "get"
  
    if Hardware::CPU.is_64_bit?
      _install_native_executable(dart)
    else
      _install_script_snapshot(dart)
    end

    chmod 0555, "#{bin}/mason"
  end

  private

  def _version
    @_version ||= YAML.safe_load(File.read("pubspec.yaml"))["version"]
  end

  def _install_native_executable(dart)
    system dart, "compile", "exe", "-Dversion=#{_version}",
           "bin/main.dart", "-o", "fvm"
    bin.install "fvm"
  end

  def _install_script_snapshot
    system _dart/"dart", "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-o", "mason.dart.app.snapshot",
           "bin/mason.dart"
    lib.install "mason.dart.app.snapshot"
    
    cp dart, lib

    (bin/"mason").write <<~SH
      #!/bin/sh
      exec "#{lib}/dart" "#{lib}/mason.dart.app.snapshot" "$@"
    SH
  end
end
