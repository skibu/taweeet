--include "lib/json"
json = include "lib/json"

-- For converting a string like a URL to a hash
function hash(str)
    local h = 5381;

    for c in str:gmatch"." do
        h = ((h << 5) + h) + string.byte(c)
    end
    return h
end


-- Returns file name in the data directory. File name is hash 
-- of the url.
function urlToFilename(url, suffix)
  return norns.state.data .. hash(url) .. "." .. suffix
end


-- Gets file for the url and then stores it using a 
-- file name that is a hash of the url
function getFile(url, suffix)
  local fileName = urlToFilename(url, suffix)
  if util.file_exists(fileName) then
    return fileName
  else
    -- Need to load the file
    -- Call the python script that retrieves the url and stores the data into the file
    local cmd = norns.state.path .. "getFile.py -fileType " .. suffix .. " -url " .. url .. " -fileName " .. fileName
    print("getFile() executing cmd=" .. cmd)
    ret = util.os_capture(cmd)
    return fileName
  end
end


-- Gets JSON from a URL and returns it as a Lua table object
function getJsonTable(url)
  local cmd = norns.state.path .. "getJson.py -url " .. url
  print("getJson() executing cmd=" .. cmd)
  local ret = util.os_capture(cmd)
  print("getJson() ret="..ret)
  
  table = json.decode(ret)
  return table
end


-- Hostname of the webserver. At first just using behind the router IP address of 
-- macbook where running the webserver
local hostname = "http://192.168.0.85"
local port = "8080"

-- Does a query to the webserver and returns table containing array of species
function getSpeciesTable()
  return getJsonTable(hostname .. ":" .. port .. "/speciesList")

      