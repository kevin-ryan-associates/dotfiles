-- Use zsh as the shell for :terminal, :!, and toggleterm.
-- macOS path: /bin/zsh
return {
  "AstroNvim/astrocore",
  opts = {
    options = {
      opt = {
        shell = "/bin/zsh",
        shellcmdflag = "-c",
      },
    },
  },
}
