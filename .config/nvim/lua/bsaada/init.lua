vim.loader.enable()
require 'bsaada.core'
require 'bsaada.core.lazy-bootstrap' -- bootstraps folke/lazy
require 'bsaada.user.options'
require 'bsaada.user.keymaps'
require('lazy').setup('bsaada.plugins', require('bsaada.user.lazy').config)
require 'bsaada.user.autocommands'
require 'bsaada.user.number-separators'
