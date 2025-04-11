return {
  {
    'fynnfluegge/monet.nvim',
    name = 'monet',
    opts = {
      transparent_background = false,
    },
  },
  {
    'goolord/alpha-nvim',
    -- config = function()
    --   require('alpha').setup(require('alpha.themes.dashboard').config)
    -- end,
    config = function()
      local alpha = require 'alpha'
      local dashboard = require 'alpha.themes.dashboard'
      dashboard.section.header.val = {
        '██╗   ██╗██╗███╗   ███╗',
        '██║   ██║██║████╗ ████║',
        '╚██╗ ██╔╝██║██╔████╔██║',
        ' ╚████╔╝ ██║██║╚██╔╝██║',
        '  ╚██╔╝  ██║██║ ╚═╝ ██║',
        '   ╚═╝   ╚═╝╚═╝     ╚═╝',
      }
      alpha.setup(dashboard.config)
    end,
  },
}
