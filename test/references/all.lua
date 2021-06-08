local core  = require 'core.reference'
local files = require 'files'

local function catch_target(script)
    local list = {}
    local cur = 1
    while true do
        local start, finish  = script:find('<[!?].-[!?]>', cur)
        if not start then
            break
        end
        list[#list+1] = { start + 2, finish - 2 }
        cur = finish + 1
    end
    return list
end

local function founded(targets, results)
    if #targets ~= #results then
        return false
    end
    for _, target in ipairs(targets) do
        for _, result in ipairs(results) do
            if target[1] == result[1] and target[2] == result[2] then
                goto NEXT
            end
        end
        do return false end
        ::NEXT::
    end
    return true
end

function TEST(script)
    files.removeAll()
    local expect = catch_target(script)
    local start  = script:find('<[?~]')
    local finish = script:find('[?~]>')
    local pos = (start + finish) // 2 + 1
    local new_script = script:gsub('<[!?~]', '  '):gsub('[!?~]>', '  ')
    files.setText('', new_script)

    local results = core('', pos)
    if results then
        local positions = {}
        for i, result in ipairs(results) do
            positions[i] = { result.target.start, result.target.finish }
        end
        assert(founded(expect, positions))
    else
        assert(#expect == 0)
    end
end

TEST [[
---@class A
local a = {}
a.<?x?> = 1

---@return A
local function f() end

local b = f()
return b.<!x!>
]]

TEST [[
---@class A
local a = {}
a.<?x?> = 1

---@return table
---@return A
local function f() end

local a, b = f()
return a.x, b.<!x!>
]]