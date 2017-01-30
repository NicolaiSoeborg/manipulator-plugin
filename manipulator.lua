VERSION = "1.0.0"

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
        --local size = 2
        local size = string.len(v.Buf:Line(c.Loc.Y))
        a, b = c.Loc, Loc(size, c.Y)
    end
    return Loc(a.X, a.Y), Loc(b.X, b.Y)
end

function getText(a, b)
    local txt, buf = {}, CurView().Buf

    -- Add first part of text selection (a.X+1 as Lua is 1-indexed)
    table.insert(txt, buf:Line(a.Y):sub(a.X+1) )

    -- Stuff in the middle
    for lineNo = a.Y+1, b.Y-1 do
        table.insert(txt, buf:Line(lineNo) )
    end

    -- Insert last part of selection, if needed
    if a.Y ~= b.Y then
        table.insert(txt, buf:Line(b.Y):sub(1, b.X) )
    end

    return table.concat(txt, "\n")
end

function manipulate(regex, manipulator)
    local v = CurView()
    local a, b = getTextLoc()

    local newTxt = string.gsub(getText(a,b), regex, manipulator)
    v.Buf:Replace(a, b, newTxt)

    --v.Cursor:Relocate()
    --v.Cursor.LastVisualX = v.Cursor:GetVisualX()
end

function upper() manipulate(".*", string.upper) end
function lower() manipulate(".*", string.lower) end

MakeCommand("upper", "manipulator.upper")
MakeCommand("lower", "manipulator.lower")
AddRuntimeFile("manipulator", "help", "README.md")
