return {
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      require('lualine').setup {
        options = {
          globalstatus = true,
          sections = {
            lualine_c = {
              {
                'filename',
                file_status = true, -- displays file status (readonly status, modified status)
                path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
              },
            },
          },
        },
      }
    end,
  },
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    opts = {
      options = {
        offsets = {
          {
            filetype = 'neo-tree',
            text = '',
            highlight = 'Directory',
            text_align = 'left',
          },
        },
      },
    },
  },
  {
    'catgoose/nvim-colorizer.lua',
    event = 'BufReadPre',
    opts = {
      user_default_options = {
        names = false,
      },
    },
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    ---@module "ibl"
    ---@type ibl.config
    opts = {
      indent = {
        char = '│',
      },
      scope = {
        enabled = true,
      },
    },
  },
  {
    'kdheepak/lazygit.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    cmd = { 'LazyGit' },
    keys = {
      { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'Toggle Lazygit' },
    },
  },
  {
    'folke/persistence.nvim',
    event = 'BufReadPre', -- this will only start session saving when an actual file was opened
    opts = {},
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    'HiPhish/rainbow-delimiters.nvim',
  },
  { 'alexghergh/nvim-tmux-navigation', lazy = false },
  {
    'fynnfluegge/rocketnotes.nvim',
    dependencies = {
      'OXY2DEV/markview.nvim',
    },
  },
  {
    'gbprod/yanky.nvim',
    opts = {},
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    config = function()
      require('nvim-treesitter.configs').setup {
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['ak'] = { query = '@block.outer', desc = 'around block' },
              ['ik'] = { query = '@block.inner', desc = 'inside block' },
              ['ac'] = { query = '@class.outer', desc = 'around class' },
              ['ic'] = { query = '@class.inner', desc = 'inside class' },
              ['a?'] = { query = '@conditional.outer', desc = 'around conditional' },
              ['i?'] = { query = '@conditional.inner', desc = 'inside conditional' },
              ['af'] = { query = '@function.outer', desc = 'around function ' },
              ['if'] = { query = '@function.inner', desc = 'inside function ' },
              ['ao'] = { query = '@loop.outer', desc = 'around loop' },
              ['io'] = { query = '@loop.inner', desc = 'inside loop' },
              ['aa'] = { query = '@parameter.outer', desc = 'around argument' },
              ['ia'] = { query = '@parameter.inner', desc = 'inside argument' },
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              [']k'] = { query = '@block.outer', desc = 'Next block start' },
              [']f'] = { query = '@function.outer', desc = 'Next function start' },
              [']a'] = { query = '@parameter.inner', desc = 'Next argument start' },
            },
            goto_next_end = {
              [']K'] = { query = '@block.outer', desc = 'Next block end' },
              [']F'] = { query = '@function.outer', desc = 'Next function end' },
              [']A'] = { query = '@parameter.inner', desc = 'Next argument end' },
            },
            goto_previous_start = {
              ['[k'] = { query = '@block.outer', desc = 'Previous block start' },
              ['[f'] = { query = '@function.outer', desc = 'Previous function start' },
              ['[a'] = { query = '@parameter.inner', desc = 'Previous argument start' },
            },
            goto_previous_end = {
              ['[K'] = { query = '@block.outer', desc = 'Previous block end' },
              ['[F'] = { query = '@function.outer', desc = 'Previous function end' },
              ['[A'] = { query = '@parameter.inner', desc = 'Previous argument end' },
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['>K'] = { query = '@block.outer', desc = 'Swap next block' },
              ['>F'] = { query = '@function.outer', desc = 'Swap next function' },
              ['>A'] = { query = '@parameter.inner', desc = 'Swap next argument' },
            },
            swap_previous = {
              ['<K'] = { query = '@block.outer', desc = 'Swap previous block' },
              ['<F'] = { query = '@function.outer', desc = 'Swap previous function' },
              ['<A'] = { query = '@parameter.inner', desc = 'Swap previous argument' },
            },
          },
        },
      }
    end,
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {
      label = {
        uppercase = false,
      },
      modes = {
        char = {
          highlight = {
            backdrop = false,
          },
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
  },
  {
    'sindrets/diffview.nvim',
    event = 'VeryLazy',
    cmd = { 'DiffviewOpen' },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { winbar_info = true },
        file_history = { winbar_info = true },
      },
      hooks = {
        diff_buf_read = function(bufnr)
          vim.b[bufnr].view_activated = false
        end,
      },
    },
    specs = {
      {
        'NeogitOrg/neogit',
        optional = true,
        opts = { integrations = { diffview = true } },
      },
    },
  },
}
