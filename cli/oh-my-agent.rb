class OhMyAgent < Formula
  desc "Portable multi-agent harness for .agents-based skills and workflows"
  homepage "https://firstfluke.com/oh-my-agent/"
  url "https://registry.npmjs.org/oh-my-agent/-/oh-my-agent-10.23.0.tgz"
  sha256 "1f10a2ec64bf0aed8e07d8b806eddaed5ed2785e2586acc8b70214a49203c4a0"
  license "MIT"

  bottle do
    sha256 cellar: :any, arm64_tahoe:   "2262cf8b28ae9cf30fba3a21ac293c85969ece5f0f8e3c88552fc76f7f2593d1"
    sha256 cellar: :any, arm64_sequoia: "2262cf8b28ae9cf30fba3a21ac293c85969ece5f0f8e3c88552fc76f7f2593d1"
    sha256 cellar: :any, arm64_sonoma:  "2262cf8b28ae9cf30fba3a21ac293c85969ece5f0f8e3c88552fc76f7f2593d1"
    sha256 cellar: :any, sonoma:        "23cbe012aafbd10a5fd561aa2a8b6d53cca6cffdb7b5c1ead5f90863e0b7acda"
    sha256 cellar: :any, arm64_linux:   "41e5b711bd2777858f761f4bcd55d20c53743ac5f0e1b44d031cfc14f4486f80"
    sha256 cellar: :any, x86_64_linux:  "78ed92b499c22644bb6b68d819214cf41c6090a4c5c8016b825b048961d2a626"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args

    node_modules = libexec/"lib/node_modules/oh-my-agent/node_modules"
    # Remove incompatible pre-built `bare-fs`/`bare-os`/`bare-path`/`bare-url` binaries
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules.glob("{bare-fs,bare-os,bare-path,bare-url}/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }

    bin.install_symlink Dir[libexec/"bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/oh-my-agent --version")

    output = JSON.parse(shell_output("#{bin}/oh-my-agent memory:init --json"))
    assert_empty output["updated"]
    assert_path_exists testpath/".agents/state/memories/orchestrator-session.md"
    assert_path_exists testpath/".agents/state/memories/task-board.md"
  end
end
