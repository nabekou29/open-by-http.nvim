local M = {}

--- Create server
--- @see https://neovim.io/doc/user/lua.html#lua-loop
local function create_server(host, port, on_connect)
  local server, err = vim.uv.new_tcp()
  if not server then
    error(err)
  end
  server:bind(host, port)
  server:listen(128, function(err)
    assert(not err, err) -- Check for errors.
    local sock, err = vim.uv.new_tcp()
    if not sock then
      error(err)
    end
    server:accept(sock) -- Accept client connection.
    on_connect(sock) -- Start reading messages.
  end)
  return server
end

--- Start server
---@param port number
---@return uv.uv_tcp_t
local function start_server(port)
  return create_server("0.0.0.0", port, function(sock)
    sock:read_start(function(err, chunk)
      assert(not err, err)

      local method, path = string.match(chunk, "(%a+)%s+(/%S+)") --[[@as string, string]]
      local response = ""

      if method and path and method == "GET" and path:match("^/api/file/") then
        local path = path:sub(string.len("/api/file/") + 1)
        local file_path, line, col = unpack(vim.split(path, ":", { plain = true }))
        line = line or "1"
        col = col or "1"

        vim.schedule(function()
          vim.cmd(string.format("n %s", file_path))
          vim.cmd(string.format("call cursor(%s, %s)", line, col))
        end)

        response = "HTTP/1.1 200 OK\r\n"
          .. "Access-Control-Allow-Origin: *\r\n"
          .. "Content-Type: text/plain\r\n"
          .. "\r\n"
          .. "ok"
      else
        response = "HTTP/1.1 400 Not Found\r\n"
          .. "Access-Control-Allow-Origin: *\r\n"
          .. "Content-Type: text/plain\r\n"
          .. "\r\n"
          .. "Not Found: "
          .. chunk
      end

      sock:write(response)
      sock:close()
    end)
  end)
end

--- @type uv.uv_tcp_t|nil
M.server = nil

--- @class OpenByHttpOptions
--- @field port? number
--- @field auto_start? boolean|function (default: true) Start server automatically

--- Setup
---@param opts OpenByHttpOptions
function M.setup(opts)
  opts = opts or {}

  local auto_start = true
  if type(opts.auto_start) == "function" then
    auto_start = opts.auto_start()
  elseif type(opts.auto_start) == "boolean" then
    auto_start = opts.auto_start --[[@as boolean]]
  end

  local port = opts.port or 8682

  if auto_start then
    M.server = start_server(port)
  end

  -- Register command
  vim.api.nvim_create_user_command("OpenByHttpServerStart", function()
    if M.server and M.server:is_active() then
      vim.notify("Server is already running", vim.log.levels.WARN)
      return
    end
    M.server = start_server(port)
  end, {})
  vim.api.nvim_create_user_command("OpenByHttpServerStop", function()
    if M.server then
      M.server:close()
    end
  end, {})
end

return M
