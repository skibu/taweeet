include "lib/cache"
include "lib/util"
local json = include "lib/json"


-- Hostname of the webserver. At first just using behind the router IP address of 
-- macbook where running the webserver
local hostname = "http://192.168.0.85"
local port = "8080"


-- Returns sound file for the species. If file not already in cache it
-- gets a sound file from the imager website, converts to a wav, stores it, 
-- and returns the full filename where file stored
local function getWavFile(url, species, filename)
  local dir = getSpeciesDirectory(species)
  local full_filename = dir .. "/" .. filename
  
  -- If file doesn't yet exist then get it and store it
  if not util.file_exists(full_filename) then
    tprint("Creating wav file " .. full_filename)
    
    -- Create curl command that gets and stores the wav file. Note that
    -- using "&" to execute command in background so that this function
    -- returns quickly, wihtout waiting for file to be created, downloaded,
    -- and saved.
    local cmd = "curl --compressed --silent --max-time 10 --insecure " .. 
      "--create-dirs --output " .. filename .. 
      " --output-dir " .. dir .. 
      " \"" .. hostname .. ":" .. port .. "/wavFile?url=" .. url ..
      "&s=".. urlencode(species) .. "\" " -- MIGHT WANT TO ADD & TO RUN IN BACKGROUND
      
    tprint("getWavFile() executing command=" .. cmd)
    util.os_capture(cmd)
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


-- Returns proper query for doing bird image search for the species. The query
-- is already encoded.
local function imageQuery(species_name)
  -- Create a more useful query for Google images. 
  -- Of course ebird.org and macaulaylibrary.org have topnotch pics. So limiting
  -- pictures to those from those sites.
  -- Have found that semi "black and white" images can work better for providing pics with 
  -- good contrast. Can include "bird" can be redundant but it avoids strange non-bird pics.
  -- And including "flying" can mean that many of the pics will be of the birds flying,
  -- which are more dynamic and beautiful. But after playing around, only using "flying" 
  -- for now.
  local enhanced_query = urlencode("site:ebird.org OR site:macaulaylibrary.org image "..
    species_name.." flying")
  return enhanced_query
end


-- Returns filename of random png  for the species using the imager website. Doesn't 
-- use cache since want to get new random image each time. Caching is done on imager
-- web server instead. The images are pretty small since they are for Norns.
-- Returns the file name of the random image, along with its width and height in pixels.
function storeRandomPng(species_name)
  local full_filename = getSpeciesDirectory(species_name) .. "/randomImageForSpecies.png"
  print("For species "..species_name.." storing random png in file " .. full_filename)
  
  -- Do curl command to get the random image and store the output into the appropriate 
  -- file for the species
  local cmd = "curl --silent --max-time 10 --insecure --create-dirs " .. 
    "--output \"" .. full_filename .. "\"" ..
    " \"" .. hostname .. ":" .. port .. "/randomImage?q=" .. imageQuery(species_name) .. 
    "&s=" .. urlencode(species_name) .. "\"" 
  print("storeRandomPng() executing command=" .. cmd)
  util.os_capture(cmd)
  
  -- Determine width and height of png 
  w, h = extents(screen.load_png(full_filename))
  
  return full_filename, w, h
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
local function getJsonTable(url)
  local cmd = "curl --silent --max-time 10 --insecure \""  .. url .. "\""
  print("getJsonTable() executing command=" .. cmd)
  local json_str = util.os_capture(cmd)

  -- Turn the json into a Lua table
  return json.decode(json_str)
end


-- Executes specified command for the Imager server and returns Lua
-- table made up of the returned JSON.
local function getJsonTableFromImager(command)
  return getJsonTable(hostname .. ":" .. port .. command)
end

  
-- Gets the image information for the species and return it in a table object
function getImageDataForSpecies(species_name)
  image_data = getJsonTableFromImager("/imageDataForSpecies?s="..urlencode(species_name)..
    "&q="..imageQuery(species_name))

  -- Turn the json into a Lua table
  return image_data
end


-- Gets the audio information for the species and return it in a table object
function getAudioDataForSpecies(species_name)
  audio_data = getJsonTableFromImager("/audioDataForSpecies?s="..urlencode(species_name)..
    "&q="..imageQuery(species_name))

  -- Turn the json into a Lua table
  return audio_data
end

  
local misc_category = "Misc"

-- Take a species name like "yellow bellied-owl" and returns the last word of, such 
-- as "owl". Useful for categorizing all the species into groups.
local function getCategoryName(species)
  local r = species:reverse()
  local spacer = r:find("[%s-]+")
  
  -- If just single word then return misc_category
  if spacer == nill then return misc_category end
  
  -- Return the first word of the reversed string. Need to reverse it again since 
  -- reversed at beginning.
  local category = r:sub(1, spacer-1):reverse()

  -- If category is lower case then it is the end part of a double hyphenated name.
  -- Just return misc_category for this rare situation.
  if isLower(category) then 
    return misc_category 
  end

  return category
end


local _species_by_category_table_cache = nil
local _category_table_cache = nil

-- Returns two tables. First is an associative array keyed by category name and with values
-- that are alphabetized lists of species for the category. Second table is an alphatized list
-- of categories. The reason two separate tables are returned is because with Lua an
-- associative array cannot be sorted by keys. So an alphatized list of categories has to be 
-- provided in a separate array, one that is ordered instead of being associative.
-- Two levels of caching. There is a memory cache so that can always access the values quickly
-- via this function. But the tables are also cached as files so that at startup can just
-- read the info from files instead of getting it from the much slower Imager API.
function getSpeciesByCategoryTable()
  -- If already cached in memory then just return cache values
  if _species_by_category_table_cache ~= nil and _category_table_cache ~= nil then
    return _species_by_category_table_cache, _category_table_cache
  end
  
  -- Determine file names for the cache files
  local species_by_category_cache_filename = getAppDirectory() .. "/speciesByCategory.json"
  local category_cache_filename = getAppDirectory() .. "/category.json"

  -- If already have both tables in cache then return them
  species_by_category_table = readFromFile(species_by_category_cache_filename)
  category_table = readFromFile(category_cache_filename)
  if species_by_category_table ~= nil and category_table ~= nil then
    -- Store the data from the file cache into memory cache
    _species_by_category_table_cache = species_by_category_table
    _category_table_cache = category_table
    
    return species_by_category_table, category_table
  end
  
  local species_table = getSpeciesTable()
  local by_category = {}
  for _, species_name in ipairs(species_table) do 
    -- Determine category name for current species
    local category = getCategoryName(species_name)

    -- Get or create the species_list for the category
    local species_list = by_category[category]
    if by_category[category] == nil then 
      species_list = {}
      by_category[category] = species_list
    end
    
    table.insert(species_list, species_name)
  end
  
  -- Go through the whole by_catagory table and move single species to the Misc category
  for category, species_list in pairs(by_category) do
    if #species_list == 1 then
      -- Move the solitary species to "Misc" category
      local misc_species_list = by_category[misc_category]
      table.insert(misc_species_list, species_list[1])
      
      -- Remove the category that had just the solitary species
      by_category[category] = nil
    end
  end
  
  -- Create the separate alphabetized array of category names. This needs to be
  -- a separate table since want to sort it and Lua associative arrays cannot
  -- be sorted by keys since they are just in a unordered set.
  -- Also, sort all of the categories. Especially important for the Misc one which just 
  -- had elements added to it.
  local category_list = {}
  for category, species_list in pairs(by_category) do
    table.sort(species_list)
    table.insert(category_list, category)
  end
  table.sort(category_list)
  
  -- Store tables into file system cache
  writeToFile(by_category, species_by_category_cache_filename)
  writeToFile(category_list, category_cache_filename)
  
  -- Also, store the data into memory cache
  _species_by_category_table_cache = by_category
  _category_table_cache = category_list

  -- Return the table
  return by_category, category_list
end


local _species_table_cache = nil

-- Does a query to the webserver and returns table containing array of all species names.
-- Caches the value in both memory for super quick access, and on the file system so that
-- works fast across application restarts.
function getSpeciesTable()
  -- Use table from memory cache if it is there
  if _species_table_cache ~= nill then
    return _species_table_cache
  end
  
  -- Determine file name for the cache file
  local cache_filename = getAppDirectory() .. "/species.json"

  -- If already have it in cache then return it
  local species_table = readFromFile(cache_filename)
  if species_table ~= nil then 
    -- Store in memory cache
    _species_table_cache = species_table
    
    return species_table 
  end
  
  -- Get the table
  local species_table = getJsonTableFromImager("/speciesList")
  
  -- Store table into file system cache
  writeToFile(species_table, cache_filename)
  
  -- Store in memory cache
  _species_table_cache = species_table
  
  return species_table
end

      