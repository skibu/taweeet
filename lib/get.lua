include "lib/cache"
include "lib/util"


-- Hostname of the webserver. At first just using behind the router IP address of 
-- macbook where running the webserver
local hostname = "http://taweeet.mywire.org"
local port = "80"
--local hostname = "192.168.4.27"
--local port = "8080"


-- Returns PNG file name for the species. If file not already in cache it
-- gets a PNG file from the Imager website, converts to a wav, stores it, 
-- and returns the full filename where file stored. The getting of the file
-- is only initiated, and it might not actually be available when this
-- function returns.
function getPng(url, species_name)
  local dir = getSpeciesDirectory(species_name)
  local filename = "image_"..file_identifier(url)..".png"
  local full_filename = dir .. "/" .. filename
  
  -- If file doesn't yet exist then get it and store it
  if not util.file_exists(full_filename) then
    log.debug("Obtaining from Imager png file " .. full_filename)
    
    -- Create curl command that gets and stores the wav file. Note that
    -- using "&" to execute command in background so that this function
    -- returns quickly, wihtout waiting for file to be created, downloaded,
    -- and saved. Note: to return quickly must use os.execute() instead of 
    -- something like util.execute_command() that waits for results.
    local cmd = "curl --compressed --silent --max-time 15 --insecure " .. 
      "--create-dirs --output " .. filename .. 
      " --output-dir " .. dir .. 
      " \"" .. hostname .. ":" .. port .. "/pngFile?url=" .. url ..
      "&s=".. util.urlencode(species_name) .. "\" &" 
    os.execute(cmd)
    log.debug("getPng() executed command=" .. cmd)
  end
  
  return full_filename
end


-- Returns sound file name for the species. If file not already in cache it
-- gets a sound file from the Imager website, converts to a wav, stores it, 
-- and returns the full filename where file stored. The getting of the file
-- is only initiated, and it might not actually be available when this
-- function returns.
function getWav(url, species_name)
  local dir = getSpeciesDirectory(species_name)
  local filename = "audio_"..file_identifier(url)..".wav"
  local full_filename = dir .. "/" .. filename

  -- If file doesn't yet exist then get it and store it
  if not util.file_exists(full_filename) then
    log.debug("Obtaining from Imager wav file " .. full_filename)
    
    -- Create curl command that gets and stores the wav file. Note that
    -- using "&" to execute command in background so that this function
    -- returns quickly, wihtout waiting for file to be created, downloaded,
    -- and saved. Note: to return quickly must use os.execute() instead of 
    -- something like util.execute_command() that waits for results.
    local cmd = "curl --compressed --silent --max-time 30 --insecure " .. 
      "--create-dirs --output " .. filename .. 
      " --output-dir " .. dir .. 
      " \"" .. hostname .. ":" .. port .. "/wavFile?url=" .. url ..
      "&s=".. util.urlencode(species_name) .. "\" &"
      
    os.execute(cmd)
    log.debug("getWav() executed command=" .. cmd)
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


-- Executes specified command for the Imager server and returns Lua
-- table made up of the returned JSON.
local function getLuaTableFromImager(command)
  return json.get(hostname .. ":" .. port .. command)
end

  
-- Gets the data associated with the specified species. Includes list of urls for 
-- both images and audio. Uses local file cache.
function getSpeciesData(species_name)
  -- If already have it in file cache then return it
  local cache_filename = getSpeciesDirectory(species_name) .. "/speciesDataCache.json"
  local species_data = json.read(cache_filename)
  if species_data ~= nil then 
    log.debug("Returning species data from file cache for "..species_name)
    return species_data
  end
  
  log.debug("Getting config data from Imager for species "..species_name.."...")
  species_data = getLuaTableFromImager("/dataForSpecies?s="..util.urlencode(species_name))
  
  -- Write data to cache
  json.write(species_data, cache_filename)
  
  log.debug("Done retrieving config data for species "..species_name)
  return species_data
end

  
local _all_species_list_cache = nil

-- Does a query to the webserver and returns table containing array of all species names.
-- Caches the value in both memory for super quick access, and on the file system so that
-- works fast across application restarts.
function getAllSpeciesList()
  -- Use table from memory cache if it is there
  if _all_species_list_cache ~= nil then
    return _all_species_list_cache
  end
  
  -- Determine file name for the cache file
  local cache_filename = getAppDirectory() .. "/allSpeciesList.json"

  -- If already have it in file cache then return it
  local species_list = json.read(cache_filename)
  if species_list ~= nil then 
    -- Store in memory cache
    _all_species_list_cache = species_list
    
    return species_list
  end
  
  -- Get the table
  local species_list = getLuaTableFromImager("/allSpeciesList")

  -- Store table into file system cache
  json.write(species_list, cache_filename)
  
  -- Store in memory cache
  _all_species_list_cache = species_list
  
  -- Return results
  return species_list
end


local _species_by_group_cache = nil

-- Queries Imager webserver for dictionary of species by group, for all groups.
-- Use memory or file cache if possible.
function getSpeciesByGroup()
  -- Use table from memory cache if it is there
  if _species_by_group_cache ~= nil then
    return _species_by_group_cache
  end
  
  -- If already have it in file cache then return it
  local cache_filename = getAppDirectory() .. "/speciesByGroup.json"
  local species_by_group = json.read(cache_filename)
  if species_by_group ~= nil then 
    log.debug("Read speciesByGroup from file cache")
    
    -- Store in memory cache
    _species_by_group_cache = species_by_group
    
    return species_by_group
  end
  
  -- Get the table from imager
  log.debug("Reading speciesByGroup from Imager")
  species_by_group = getLuaTableFromImager("/speciesByGroup")
  
  -- Store in memory and file caches
  _species_by_group_cache = species_by_group
  json.write(species_by_group, cache_filename)
  
  -- Return results
  return species_by_group
end
  
  
local _species_for_group_cache = {}

-- Provides list of species for the specified group name.
-- But will use memory cache if possible.
function getSpeciesForGroup(group)
  -- Use table from memory cache if it is there
  local cached_species_for_group = _species_for_group_cache[group]
  if cached_species_for_group ~= nil then
    return cached_species_for_group
  end
  
  -- Get the table
  local species_for_group_list = getSpeciesByGroup()[group]

  -- Store in memory cache
  _species_for_group_cache[group] = species_for_group_list
  
  return species_for_group_list
end


local _groups_list_cache = nil

-- Does a query to the Imager webserver and returns table containing array of all group names.
-- Caches the value in both memory for super quick access, and on the file system so that
-- works fast across application restarts.
function getGroupsList()
  -- Use table from memory cache if it is there
  if _groups_list_cache ~= nil then
    return _groups_list_cache
  end
  
  -- Determine file name for the cache file
  local cache_filename = getAppDirectory() .. "/groupsList.json"

  -- If already have it in cache then return it
  local groups_list = json.read(cache_filename)
  if groups_list ~= nil then 
    -- Store in memory cache
    _groups_list_cache = groups_list
    
    return groups_list
  end
  
  -- Get the table
  local groups_list = getLuaTableFromImager("/groupsList")

  -- Store table into file system cache
  json.write(groups_list, cache_filename)
  
  -- Store in memory cache
  _groups_list_cache = groups_list
  
  return groups_list
end
