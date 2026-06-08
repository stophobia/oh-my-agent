class OhMyAgent < Formula
  desc "Portable multi-agent harness for .agents-based skills and workflows"
  homepage "https://github.com/first-fluke/oh-my-agent"
  url "https://registry.npmjs.org/oh-my-agent/-/oh-my-agent-8.43.0.tgz"
  sha256 "1edd5c103413aa8b1f513d03e74dd8ec53885f40f3a9704734b58f8d44486269"
  license "MIT"

  bottle do
    sha256 cellar: :any, arm64_tahoe:   "138764edc2f7f903b9dae4fcd4b8bffe54a2943cad0b15bbff65109fb769ac01"
    sha256 cellar: :any, arm64_sequoia: "e08e7f43a728267f2a765b208843a823162895575a30ef310130533e3de3cdd6"
    sha256 cellar: :any, arm64_sonoma:  "e08e7f43a728267f2a765b208843a823162895575a30ef310130533e3de3cdd6"
    sha256 cellar: :any, sonoma:        "6fb5ed7489a309c832457132b84d22732b31b237401a571502ffb83f81c5f0b0"
    sha256 cellar: :any, arm64_linux:   "30abd148058f5b8b26b44043957d2a11cc10b2fac3aee7b36e6a85e646fb2f8e"
    sha256 cellar: :any, x86_64_linux:  "32ea383c5567d73e7db82d7a16d623e4c2868925c545dc7893b21bc4aa9bf53c"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args

    node_modules = libexec/"lib/node_modules/oh-my-agent/node_modules"
    # Remove incompatible pre-built `bare-fs`/`bare-os`/`bare-url` binaries
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules.glob("{bare-fs,bare-os,bare-url}/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }

    bin.install_symlink Dir[libexec/"bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/oh-my-agent --version")

    output = JSON.parse(shell_output("#{bin}/oh-my-agent memory:init --json"))
    assert_empty output["updated"]
    assert_path_exists testpath/".serena/memories/orchestrator-session.md"
    assert_path_exists testpath/".serena/memories/task-board.md"
  end
end
