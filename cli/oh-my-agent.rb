class OhMyAgent < Formula
  desc "Portable multi-agent harness for .agents-based skills and workflows"
  homepage "https://github.com/first-fluke/oh-my-agent"
  url "https://registry.npmjs.org/oh-my-agent/-/oh-my-agent-8.5.3.tgz"
  sha256 "e6f41dfbfbbf42d68f9884dd27752ca65bb5bec7ed3e41c27c88156e71f03b6c"
  license "MIT"

  bottle do
    sha256 cellar: :any,                 arm64_tahoe:   "6a1730e625dfeadb17473488f617b3c2873db17b5e440e851f233bf9c3edc694"
    sha256 cellar: :any,                 arm64_sequoia: "efeb3a2acc1440410ecfd2c2d7af88d26dafd9f67da9d6ed0005680731fc4cb6"
    sha256 cellar: :any,                 arm64_sonoma:  "efeb3a2acc1440410ecfd2c2d7af88d26dafd9f67da9d6ed0005680731fc4cb6"
    sha256 cellar: :any,                 sonoma:        "21fd446273da0a6ad1555d7ae110cfd27240353ad4346786c44dd9ddfc56f2c1"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "a628c10c616c111632819ce2b8b4ffddf3f832d61e1a3fec7dcfd26ff0e7ad3a"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "a703f7effdfceb19a21129949b8172627206572bc881143a8fee40d4cc2145ab"
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
