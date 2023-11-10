
-- ------------------------------------------------------------------------
-- math

function mod1(v, m)
  return ((v - 1) % m) + 1
end


-- ------------------------------------------------------------------------
-- strings

function strim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


-- ------------------------------------------------------------------------
-- tables

function tab_sliced(tbl, first, last, step)
  local sliced = {}

  if last ~= nil and last < 0 then
    last = #tbl + last
  end

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

-- remove all element of table without changing its memory pointer
function tempty(t)
  for k, v in pairs(t) do
    t[k] = nil
  end
end

-- replace table value w/ other without changing its memory pointer
function treplace(t, newt)
  tempty(t)
  if newt == nil then
    return
  end
  for k, v in pairs(newt) do
    t[k] = v
  end
end

function tkeys(t)
  local t2 = {}
  for k, _ in pairs(t) do
    table.insert(t2, k)
  end
  return t2
end

function tvals(t)
  local t2 = {}
  for _, v in pairs(t) do
    table.insert(t2, v)
  end
  return t2
end

-- like `table.unpack` but supports maps
function tunpack(t)
  return table.unpack(tvals(t))
end
