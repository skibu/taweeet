local json = include "lib/json"


-- Writes table object to a file in json format
function writeToFile(tbl, filename)
  -- When creating the file need to first make sure the associated directory is created
  createDir(filename)

  -- Data to be written
  local json_str = json.encode(tbl)
  
  -- Open the file and write the json to it.
  local file = assert(io.open(filename, "w"))
  file:write(json_str)
  file:close()
end


-- Reads json file and converts the json into a table object and returns it. If the file
-- doesn't exist then returns nil.
function readFromFile(filename)
  -- If file doesn't exist just return nil
  if not util.file_exists(filename) then return nil end
  
  -- Get json contents of file
  local file = io.open(filename, "r")
  local json_str = file:read("*a") -- "*a" means read entire file
  
  -- Convert json to a Lua table
  local tbl = json.decode(json_str)
  
  -- Close file and return results
  file:close()
  return tbl
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
