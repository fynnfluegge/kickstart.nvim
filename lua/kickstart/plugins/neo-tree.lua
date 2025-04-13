-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '<leader>e', ':Neotree toggle<CR>', desc = 'NeoTree toggle', silent = true },
  },
  opts = {
    close_if_last_window = true,
    sources = { 'filesystem', 'buffers', 'git_status' },
    source_selector = {
      winbar = false,
    },
    window = {
      width = 48,
      mappings = {
        ['<space>'] = false, -- disable space until we figure out which-key disabling
        h = 'close_node',
        l = 'open',
      },
    },
    filesystem = {
      window = {
        mappings = {
          ['<leader>e'] = 'close_window',
        },
      },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = true,
      },
      hijack_netrw_behavior = 'open_current',
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = false, -- when true, they will just be displayed differently than normal items
        hide_dotfiles = false,
        hide_gitignored = true,
      },
    },
    default_component_configs = {
      file_size = {
        enabled = false,
      },
    },
  },
}
