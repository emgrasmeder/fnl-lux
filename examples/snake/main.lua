local function add_fennel_path()
  local base = ".deps/rocks/fennel"
  if not love.filesystem.getInfo(base) then
    error("fennel rock missing — run `deps` and `deps --lua-version 5.1 --no-prompt` in examples/snake first")
  end
  for _, version in ipairs(love.filesystem.getDirectoryItems(base)) do
    for _, luaver in ipairs({ "5.1", "5.4" }) do
      local root = base .. "/" .. version .. "/share/lua/" .. luaver
      if love.filesystem.getInfo(root .. "/fennel.lua") then
        package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
        return
      end
    end
  end
  error("fennel rock missing — run `deps --lua-version 5.1 --no-prompt` in examples/snake first")
end

add_fennel_path()

if not table.unpack and unpack then
  table.unpack = unpack
end

local function lux_fennel_paths()
  return "../../src/?.fnl;../../src/?/init.fnl"
end

local fennel = require("fennel")
-- Keep in sync with PRODUCTION-FENNEL-PATH in examples/shared/testing/startup.fnl
fennel.install({
  path = "./?.fnl;../?.fnl;" .. lux_fennel_paths(),
  macroPath = "./?.fnlm",
})

table.insert(package.loaders, function(filename)
  if love.filesystem.getInfo(filename) then
    return function(...)
      return fennel.eval(love.filesystem.read(filename), { env = _G, filename = filename }, ...), filename
    end
  end
end)

fennel.dofile("main.fnl", { env = _G, filename = "main.fnl" })
