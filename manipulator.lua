VERSION = "1.3.1"

-- Returns Loc-tuple w/ current marked text or whole line (begin, end)
function getTextLoc()
    local v = CurView()
    local a, b, c = nil, nil, v.Cursor
    if c:HasSelection() then
        if c.CurSelection[1]:GreaterThan(-c.CurSelection[2]) then
            a, b = c.CurSelection[2], c.CurSelection[1]
        else
            a, b = c.CurSelection[1], c.CurSelection[2]
        end
    else
        local eol = string.len(v.Buf:Line(c.Loc.Y))
        a, b = c.Loc, Loc(eol, c.Y)
    end
    return Loc(a.X, a.Y), Loc(b.X, b.Y)
end

-- Returns the current marked text or whole line
function getText(a, b)
    local txt, buf = {}, CurView().Buf

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
    local v = CurView()
    local a, b = getTextLoc()

    local oldTxt = getText(a,b)

    local newTxt = string.gsub(oldTxt, regex, manipulator, num)
    v.Buf:Replace(a, b, newTxt)

    -- Fix selection, if transformation changes text length (e.g. base64)
    local d = string.len(newTxt) - string.len(oldTxt)
    if d ~= 0 then
        local c = v.Cursor
        if c:HasSelection() then
            if c.CurSelection[1]:GreaterThan(-c.CurSelection[2]) then
                c.CurSelection[1].X = c.CurSelection[1].X - d
            else
                c.CurSelection[2].X = c.CurSelection[2].X + d
            end
        end
    end

    --v.Cursor:Relocate()
    --v.Cursor.LastVisualX = v.Cursor:GetVisualX()
end


--[[ DEFINE FUNCTIONS ]]--

function upper() manipulate("[%a]", string.upper) end
MakeCommand("upper", "manipulator.upper")

function lower() manipulate("[%a]", string.lower) end
MakeCommand("lower", "manipulator.lower")

function reverse() manipulate(".*", string.reverse) end
MakeCommand("reverse", "manipulator.reverse")

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
MakeCommand("rot13", "manipulator.rot13")

function incNum() manipulate("[%d]",
    function (txt) return tonumber(txt)+1 end
) end
MakeCommand("incNum", "manipulator.incNum")

function decNum() manipulate("[%d]",
    function (txt) return tonumber(txt)-1 end
) end
MakeCommand("decNum", "manipulator.decNum")


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
MakeCommand("base64enc", "manipulator.base64enc")

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
MakeCommand("base64dec", "manipulator.base64dec")

-- Thanks marinopposite
function capital() manipulate("[%a]", string.upper, 1) end
MakeCommand("capital", "manipulator.capital")

function brace()   manipulate(".*", "(%1)", 1) end
MakeCommand("brace", "manipulator.brace")

function curly()   manipulate(".*", "{%1}", 1) end
MakeCommand("curly", "manipulator.curly")

function square()  manipulate(".*", "[%1]", 1) end
MakeCommand("square", "manipulator.square")

function dquote()   manipulate(".*", '"%1"', 1) end
MakeCommand("dquote", "manipulator.dquote" )

function squote()  manipulate(".*", "'%1'", 1) end
MakeCommand("squote", "manipulator.squote")

function angle() manipulate(".*", "<%1>", 1) end
MakeCommand("angle", "manipulator.angle")

AddRuntimeFile("manipulator", "help", "README.md")
