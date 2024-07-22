
-- Wacky function that returns extents of specified image buffer.
-- This was quite difficult to figure out because had to search
-- around to find out about userdata objects and getmetatable(),
-- and then look at the weaver.c source code to find out about
-- what info is available from an image buffer. 
function extents(image_buffer)
  -- Image buffer is of type userdata, which means it is a C object.
  -- But by searching around I found that getmetatable() returns a lua table
  -- that contains information about the C object.
  local meta_table =  getmetatable(image_buffer)
  
  -- By looking at weaver.c can see that one of the things the meta table
  -- contains is __index, which has info about the lua functions that can
  -- be called.
  local __index_subtable = meta_table["__index"]
  
  -- And now can get pointer to the extents() function
  local extents_function = __index_subtable["extents"]
  
  -- Now can just call the extents function on the image buffer and return the results
  return extents_function(image_buffer)
end  


-- For converting a string like a URL to a hash so that it can be used a file name.
-- Not actually used currently, but could be useful.
function hash(str)
    local h = 5381;

    for c in str:gmatch"." do
        h = ((h << 5) + h) + string.byte(c)
    end
    return h
end


-- For encoding a url that has special characters.
-- From https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

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