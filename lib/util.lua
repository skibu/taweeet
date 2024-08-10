

-- Returns true if first char of string is lower case
function isLower(str)
  local firstChar = string.sub(str, 1, 1)
  return "a" <= firstChar and firstChar <= "z"
end


-- Just like print() but also displays time in seconds since app started, and with
-- a very high resolution. Useful for seeing at a glance how long something took.
function tprint(obj)
  if obj == nil then obj = "nil" end
  
  print(clock.get_beats() .. " - " .. obj)
end


-- For finding the directory of a file. Useful for creating file in a directory that
-- doesn't already exist
function getDir(full_filename)
    local last_slash = (full_filename:reverse()):find("/")
    return (full_filename:sub(1, -last_slash))
end


-- If it doesn't already exist, creates directory for a file that is about to be written
function createDir(full_filename) 
  -- Determine directory that needs to exist
  local dir = getDir(full_filename)
  
  -- If directory already exists then don't need to create it
  if util.file_exists(dir) then return end
  
  -- Directory didn't exist so create it
  os.execute("mkdir "..dir)
end


-- From https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

-- For encoding a url that has special characters.
function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

local hex_to_char = function(x)
  return string.char(tonumber(x, 16))
end

urldecode = function(url)
  if url == nil then
    return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", hex_to_char)
  return url
end
