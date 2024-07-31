include "lib/cache"
include "lib/util"
local json = include "lib/json"


-- Hostname of the webserver. At first just using behind the router IP address of 
-- macbook where running the webserver
local hostname = "http://192.168.0.85"
local port = "8080"


function getPng(url, species_name)
  local dir = getSpeciesDirectory(species_name)
  local filename = "image_"..hash(url)..".png"
  local full_filename = dir .. "/" .. filename
  
  -- If file doesn't yet exist then get it and store it
  if not util.file_exists(full_filename) then
    tprint("Creating png file " .. full_filename)
    
    -- Create curl command that gets and stores the wav file. Note that
    -- using "&" to execute command in background so that this function
    -- returns quickly, wihtout waiting for file to be created, downloaded,
    -- and saved.
    local cmd = "curl --compressed --silent --max-time 10 --insecure " .. 
      "--create-dirs --output " .. filename .. 
      " --output-dir " .. dir .. 
      " \"" .. hostname .. ":" .. port .. "/pngFile?url=" .. url ..
      "&s=".. urlencode(species_name) .. "\"" 
      
    util.os_capture(cmd)
    tprint("getPng() executed command=" .. cmd)
  end
  
  return full_filename
end


-- Returns sound file for the species. If file not already in cache it
-- gets a sound file from the imager website, converts to a wav, stores it, 
-- and returns the full filename where file stored
function getWav(url, species_name)
  local dir = getSpeciesDirectory(species_name)
  local filename = "audio_"..hash(url)..".wav"
  local full_filename = dir .. "/" .. filename

  -- If file doesn't yet exist then get it and store it
  if not util.file_exists(full_filename) then
    tprint("Creating wav file " .. full_filename)
    
    -- Create curl command that gets and stores the wav file. Note that
    -- using "&" to execute command in background so that this function
    -- returns quickly, wihtout waiting for file to be created, downloaded,
    -- and saved. 
    -- Note: thought could speed up response by adding '&' to end of command 
    -- so that it would run in backgroiund and therefore return immediately.
    -- But timing showed that this did not speed things up at all.
    local cmd = "curl --compressed --silent --max-time 10 --insecure " .. 
      "--create-dirs --output " .. filename .. 
      " --output-dir " .. dir .. 
      " \"" .. hostname .. ":" .. port .. "/wavFile?url=" .. url ..
      "&s=".. urlencode(species_name) .. "\" " 
      
    util.os_capture(cmd)
    tprint("getWavFile() executed command=" .. cmd)
  end

  return full_filename
end


-- Returns directory name where wav and png files are to be stored on the norns.
-- Will be norns.state.data/species/ . Spaces replaced with "_" and "'' removed
-- to make name more file system friendly.
function getSpeciesDirectory(species_name)
  return norns.state.data .. species_name:gsub(" ", "_"):gsub("'", "")
end


-- Returns the main data directory for the app
function getAppDirectory()
  return norns.state.data
end


-- Gets wav file for the specified species and catalog. First checks cache. The wav 
-- file will be stored at norns.state.data/species/catalog.wav . Converts spaces in species
-- name to "_" so that won't have file system problems.
function getSpeciesWavFile(url, species, catalog)
  return getWavFile(url, species, catalog .. ".wav")
end


-- Returns an image buffer that can be drawn to the Norns screen. 
-- It is thought that keeping the image buffer around would allow for
-- faster screen drawing since wouldn't have to load the PNG from
-- file system everytime. But currently displaying buffers on the screen
-- is not reliable.
function getPngBuffer(species)
  local full_filename = getPngFile(species)
  local image_buffer = screen.load_png(full_filename)
  return image_buffer
end


-- Gets JSON from a URL and returns it as a Lua table
local function getLuaTable(url)
  local cmd = "curl --silent --max-time 10 --insecure \""  .. url .. "\""
  local json_str = util.os_capture(cmd)

  -- Turn the json into a Lua table
  lua_table = json.decode(json_str)
  return lua_table
end


-- Executes specified command for the Imager server and returns Lua
-- table made up of the returned JSON.
local function getLuaTableFromImager(command)
  lua_table = getLuaTable(hostname .. ":" .. port .. command)
  return lua_table
end

  
-- Gets the data associated with the specified species. Includes list urls for 
-- both images and audio.  
function getSpeciesData(species_name)
  local species_data = getLuaTableFromImager("/dataForSpecies?s="..urlencode(species_name))
  -- Turn the json into a Lua table
  return species_data
end

  
local _species_list_cache = nil

-- Does a query to the webserver and returns table containing array of all species names.
-- Caches the value in both memory for super quick access, and on the file system so that
-- works fast across application restarts.
function getSpeciesList()
  -- Use table from memory cache if it is there
  if _species_list_cache ~= nil then
    return _species_list_cache
  end
  
  -- Determine file name for the cache file
  local cache_filename = getAppDirectory() .. "/speciesList.json"

  -- If already have it in cache then return it
  readFromFile(cache_filename)
  local species_list = readFromFile(cache_filename)
  if species_list ~= nil then 
    -- Store in memory cache
    _species_list_cache = species_list
    
    return species_list
  end
  
  -- Get the table
  local species_list = getLuaTableFromImager("/speciesList")

  -- Store table into file system cache
  writeToFile(species_list, cache_filename)
  
  -- Store in memory cache
  _species_list_cache = species_list
  
  return species_list
end

      