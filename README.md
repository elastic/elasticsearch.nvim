# elasticsearch.nvim

Provides a dev console experience similar to [Kibana's dev console](https://www.elastic.co/docs/explore-analyze/query-filter/tools/console) for writing and running Elasticsearch requests in Neovim.

Depends on access to [the `elasticsearch_console` tree-sitter grammar](https://github.com/elastic/tree-sitter-elasticsearch-console) and, optionally, [lsp-elasticsearch-console](https://github.com/elastic/lsp-elasticsearch-console).

## Usage

Create an `.esc` file and write a request:

```
GET _cat/indices
```

To run the request and view the printed response, move your cursor to any position within the request and run:

```
:Elastic run
```

To print a runnable `curl` command:

```
:Elastic curl
```

To print the configured Elasticsearch URL for this buffer:

```
:Elastic url
```

To update the Elasticsearch URL for this buffer:

```
:Elastic url http://localhost:9200
```

`url` can be any valid URL string.

To update the authentication scheme details for this buffer:

```
:Elastic auth your_api_key
```

Or:

```
:Elastic auth your_username your_password
```

## Install

### Neovim plugin

Install the plugin with your preferred package manager:

#### [vim-plug](https://github.com/junegunn/vim-plug)

Install

```vimscript
Plug 'elastic/elasticsearch.nvim'

lua << EOF
  require("elasticsearch_console").setup({
    url = "https://elasticsearch.foo:9200",
    auth = {
      api_key = "foo:bar"
    }
  })
EOF
```

#### [packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "elastic/elasticsearch.nvim",
  config = function()
    require("elasticsearch_console").setup({
      url = "http://localhost:9200",
      auth = {
        username = "elastic",
        password = "changeme"
      }
    })
  end
}
```

#### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
  },
  {
    url = "git@github.com:elastic/elasticsearch.nvim.git",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      url = "http://localhost:9200",
      auth = {
        username = "elastic",
        password = "changeme",
      },
    },
  },
}
```

You may need to restart Neovim and run `:TSUpdate` after installing the plugin to ensure the required tree-sitter grammar is installed.

Passing Elasticsearch configurations during setup is optional.
If you would like to update your config at any point, you can run `:Elastic url <your url>` or `:Elastic auth <your auth>` to update config values for the current buffer.

### LSP server

Until the LSP server is ready to be published to npm, it will need to be built and linked manually.

1. Clone the repository:

   ```sh
   git clone https://github.com/elastic/lsp-elasticsearch-console.git
   ```

1. Compile and link the project:

   ```sh
   npm run compile
   npm link
   ```
