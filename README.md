# open-by-http.nvim

A plugin to open files in Neovim via HTTP requests.

## Installation

### Lazy.vim

```lua
{
  "nabekou29/open-by-http.nvim",
  cmd = { "OpenByHttpServerStart", "OpenByHttpServerStop" },
  event = { "FocusLost" },
  opts = {
    -- auto_start = true
    -- port = 8682
  },
}
```

If you start multiple neovim instances, it may be a good idea to limit the server startup.

```lua
-- Only start the server with the `OpenByHttpServerStart` command.
{
  opts = {
    auto_start = false
  }
}

-- Only start the server automatically in node projects.
{
  opts = {
    auto_start = function()
      return #vim.fs.find("package.json", {}) > 0
    end
  }
}
```

## Usage

```sh
curl http://localhost:8682/api/file/{path}:{line}:{column}
# Example
curl http://localhost:8682/api/file/src/index.ts:10:5
```
