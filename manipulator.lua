VERSION = "1.4.1"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")

-- Returns Loc-tuple w/ current marked text or whole line (begin, end)
function getTextLoc(c)
    local v = micro.CurPane()
    local a, b = nil, nil
    if c:HasSelection() then
        if c.CurSelection[1]:GreaterThan(-c.CurSelection[2]) then
            a, b = c.CurSelection[2], c.CurSelection[1]
        else
            a, b = c.CurSelection[1], c.CurSelection[2]
        end
    else
        local eol = string.len(v.Buf:Line(c.Loc.Y))
        a, b = c.Loc, buffer.Loc(eol, c.Y)
    end
    return buffer.Loc(a.X, a.Y), buffer.Loc(b.X, b.Y)
end

-- Returns the current marked text or whole line
function getText(a, b)
    local txt, buf = {}, micro.CurPane().Buf

    -- Editing a single line?
    if a.Y == b.Y then
        return buf:Line(a.Y):sub(a.X+1, b.X)
    end

    -- Add first part of text selection (a.X+1 as Lua is 1-indexed)
    table.insert(txt, buf:Line(a.Y):sub(a.X+1))

    -- Stuff in the middle
    for lineNo = a.Y+1, b.Y-1 do
        table.insert(txt, buf:Line(lineNo))
    end

    -- Insert last part of selection
    table.insert(txt, buf:Line(b.Y):sub(1, b.X))

    return table.concat(txt, "\n")
end

-- Calls 'manipulator'-function on text matching 'regex'
function manipulate(regex, manipulator, num)
  local num = math.inf or num
  local v = micro.CurPane()
  -- perform the replacement for each cursor
  local cs = v.Buf:GetCursors()
  for i=1, #cs do
    local c = cs[i]
    local a, b = getTextLoc(c)
    local oldTxt = getText(a,b)
    local newTxt = string.gsub(oldTxt, regex, manipulator, num)

    v.Buf:Replace(a, b, newTxt)

    -- Fix selection, if transformation changes text length (e.g. base64)
    local d = string.len(newTxt) - string.len(oldTxt)
    if d ~= 0 then
        if c:HasSelection() then
            if c.CurSelection[1]:GreaterThan(-c.CurSelection[2]) then
                c.CurSelection[1].X = c.CurSelection[1].X - d
            else
                c.CurSelection[2].X = c.CurSelection[2].X + d
            end
        end
      end
      --c:Relocate()
      --c.LastVisualX = v.Cursor:GetVisualX()
  end
end


--[[ DEFINE FUNCTIONS ]]--

function rot13() manipulate("[%a]",
    function (txt)
        local result, lower, upper = {}, string.byte('a'), string.byte('A')
        for c in txt:gmatch(".") do
            local offset = string.lower(c) == c and lower or upper
            local p = ((c:byte() - offset + 13) % 26) + offset
            table.insert(result, string.char(p))
        end
        return table.concat(result, "")
    end
) end

function incNum() manipulate("[%d]",
    function (txt) return tonumber(txt)+1 end
) end

function decNum() manipulate("[%d]",
    function (txt) return tonumber(txt)-1 end
) end

-- Credit: http://lua-users.org/wiki/BaseSixtyFour
function base64enc() manipulate(".*",
    function (data)
        local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        return ((data:gsub('.', function(x)
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return b:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
    end
) end

function base64dec() manipulate(".*",
    function (data)
        local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end
) end

-- Credit: http://lua-users.org/wiki/StringRecipes
function capital() manipulate("(%a)([%w_']*)",
    function (first, rest)
        return first:upper() .. rest:lower()
    end
) end

function title() manipulate(".*",
    function (data)
        return data:gsub("%a+", function(char) return char:sub(1, 1):upper() .. char:sub(2) end)
    end

) end

function pascal() manipulate(".*",
    function (data)
        return data:gsub("^%a", string.upper):gsub("[_%s]+%a", string.upper):gsub("[_%s]","")
    end
) end

function camel() manipulate(".*",
    function (data)
        return data:gsub("[_%s]+%a", string.upper):gsub("[_%s]",""):gsub("^%a", string.lower)
    end
) end

function kebab() manipulate(".*",
    function (data)
        local function parseChar(char)
            if char:match("%u") then return "-"..char:lower() end
            if char:match("%s") then return "" end
            return char:lower()
        end

        return data:gsub("^%a", string.lower):gsub(".", parseChar):gsub("%s", "-"):gsub("_", "-")
    end
) end

function snake() manipulate(".*",
    function (data)
        local function parseChar(char)
            if char:match("%u") then return "_"..char:lower() end
            if char:match("%s") then return "" end
            return char:lower()
        end

        return data:gsub("^%a", string.lower):gsub(".", parseChar):gsub("%s", "_")
    end
) end

function screamingSnake() manipulate(".*",
    function (data)
        local function parseChar(char)
            if char:match("%u") then return "_"..char:upper() end
            if char:match("%s") then return "" end
            return char:upper()
        end

        return data:gsub("^%a", string.lower):gsub(".", parseChar):gsub("%s", "_")
    end
) end

function init()
    config.MakeCommand("capital", capital, config.NoComplete)
    -- Thanks marinopposite
    config.MakeCommand("brace", function() manipulate(".*", "(%1)", 1) end, config.NoComplete)
    config.MakeCommand("curly", function() manipulate(".*", "{%1}", 1) end, config.NoComplete)
    config.MakeCommand("square", function() manipulate(".*", "[%1]", 1) end, config.NoComplete)
    config.MakeCommand("dquote", function() manipulate(".*", '"%1"', 1) end, config.NoComplete)
    config.MakeCommand("squote", function() manipulate(".*", "'%1'", 1) end, config.NoComplete)
    config.MakeCommand("angle", function() manipulate(".*", "<%1>", 1) end, config.NoComplete)
    config.MakeCommand("backtick", function() manipulate(".*", "`%1`", 1) end, config.NoComplete)
    config.MakeCommand("base64dec", base64dec, config.NoComplete)
    config.MakeCommand("base64enc", base64enc, config.NoComplete)
    config.MakeCommand("decNum", decNum, config.NoComplete)
    config.MakeCommand("incNum", incNum, config.NoComplete)
    config.MakeCommand("rot13", rot13, config.NoComplete)
    config.MakeCommand("upper", function() manipulate("[%a]", string.upper) end, config.NoComplete)
    config.MakeCommand("lower", function() manipulate("[%a]", string.lower) end, config.NoComplete)
    config.MakeCommand("reverse", function() manipulate(".*", string.reverse) end, config.NoComplete)
    config.MakeCommand("title", title, config.NoComplete)
    config.MakeCommand("pascal", pascal, config.NoComplete)
    config.MakeCommand("camel", camel, config.NoComplete)
    config.MakeCommand("kebab", kebab, config.NoComplete)
    config.MakeCommand("snake", snake, config.NoComplete)
    config.MakeCommand("screamingSnake", screamingSnake, config.NoComplete)


    config.AddRuntimeFile("manipulator", config.RTHelp, "help/manipulator.md")
end
