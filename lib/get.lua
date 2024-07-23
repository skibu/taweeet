local json = include "lib/json"


-- Displays info for the specified wav file. Useful for seeing that 
-- the wav file has proper format.
local function print_wav_file_info(file)
  if util.file_exists(file) == true then
    local ch, samples, samplerate = audio.file_info(file)
    local duration = samples/samplerate
    print("loading file: "..file)
    print("  channels:\t"..ch)
    print("  samples:\t"..samples)
    print("  sample rate:\t"..samplerate.."hz")
    print("  duration:\t"..duration.." sec")
  else print "read_wav(): file not found" end
end


-- Hostname of the webserver. At first just using behind the router IP address of 
-- macbook where running the webserver
local hostname = "http://192.168.0.85"
local port = "8080"


-- Returns sound file from cache. If file not already in cache it
-- gets a sound file from the imager website, converts to a wav, stores it, 
-- and returns the full filename where file stored
local function getWavFile(url, dir, filename)
  local full_filename = dir .. "/" .. filename
  
  -- If file doesn't yet exist then get it and store it
  if not util.file_exists(full_filename) then
    print("Creating wav file " .. full_filename)
    
    local cmd = "curl --silent --max-time 10 --insecure --create-dirs " .. 
      "--output " .. filename .. 
      " --output-dir " .. dir .. 
      " " .. hostname .. ":" .. port .. "/wavFile?url=" .. url
      
    print("getWavFile() executing command=" .. cmd)
    util.os_capture(cmd)
  end
  
  -- For debugging
  print_wav_file_info(full_filename)
      
  return full_filename
end


-- Returns directory name where wav and png files are to be stored on the norns.
-- Will be norns.state.data/species/ . Spaces replaced with "_" to make name more 
-- file system friendly
function getDirectory(species)
  return norns.state.data .. species:gsub(" ", "_")
end


-- Gets wav file for the specified species and catalog. First checks cache. The wav 
-- file will be stored at norns.state.data/species/catalog.wav . Converts spaces in species
-- name to "_" so that won't have file system problems.
function getSpeciesWavFile(url, species, catalog)
  return getWavFile(url, getDirectory(species), catalog .. ".wav")
end


-- Returns filename of random png  for the species using the imager website. Doesn't 
-- use cache since want to get new random image each time. Caching is done on imager
-- web server instead. The images are pretty small since they are for Norns.
-- Returns the file name of the random image, along with its width and height in pixels.
function storeRandomPng(species)
  local full_filename = getDirectory(species) .. "/randomForSpecies.png"
  print("For species "..species.." storing random png in file " .. full_filename)
  
  -- Create a more useful query for Google images. 
  -- Of course ebird.org and macaulaylibrary.org have topnotch pics. So limiting
  -- pictures to those from those sites.
  -- Have found that semi "black and white" images can work better for providing pics with 
  -- good contrast. Can include "bird" can be redundant but it avoids strange non-bird pics.
  -- And including "flying" can mean that many of the pics will be of the birds flying,
  -- which are more dynamic and beautiful. But after playing around, only using "flying" 
  -- for now.
  local enhanced_query = urlencode("site:ebird.org OR site:macaulaylibrary.org image "..
    species.." flying")
  print("enhanced_query=" .. enhanced_query)

  -- Do curl command to get the random image and store the output into the appropriate 
  -- file for the species
  local cmd = "curl --silent --max-time 10 --insecure --create-dirs " .. 
    "--output " .. full_filename.. 
    " " .. hostname .. ":" .. port .. "/getImage?q=" .. enhanced_query
  print("storeRandomPng() executing command=" .. cmd)
  util.os_capture(cmd)
  
  -- Determine width and height of png 
  w, h = extents(screen.load_png(full_filename))
  
  return full_filename, w, h
end


-- Returns an image buffer that can be drawn to the Norns screen. 
-- It is thought that keeping the image buffer around would allow for
-- faster screen drawing since wouldn't have to load the PNG from
-- file system everytime.
function getPngBuffer(species)
  local full_filename = getPngFile(species)
  local image_buffer = screen.load_png(full_filename)
  return image_buffer
end


-- Gets JSON from a URL and returns it as a Lua table
local function getJsonTable(url)
  local cmd = "curl --silent --max-time 10 --insecure " ..  url
  print("getJsonTable() executing command=" .. cmd)
  json_str = util.os_capture(cmd)

  return json.decode(json_str)
end


local function isLower(str)
  local firstChar = string.sub(str, 1, 1)
  return "a" <= firstChar and firstChar <= "z"
end

  
local misc_category = "Misc"

-- Take a species name like "yellow bellied-owl" and returns the last word of, such as "owl"
local function getCategory(species)
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


local species_by_category_table_cache = nil
local category_list_cache = nil

-- Gets table of species, but grouped into categories
function getSpeciesByCategoryTable()
  -- If already have it in cache then return it
  if species_by_category_table_cache ~= nil then 
    return species_by_category_table_cache, category_list_cache
  end

  local species_table = getSpeciesTable()
  local by_category = {}
  for _, species in ipairs(species_table) do 
    -- Determine category name for current species
    local category = getCategory(species)

    -- Get or create the species_list for the category
    local species_list = by_category[category]
    if by_category[category] == nil then 
      species_list = {}
      by_category[category] = species_list
    end
    
    table.insert(species_list, species)
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
  category_list = {}
  for category, species_list in pairs(by_category) do
    table.sort(species_list)
    table.insert(category_list, category)
  end
  table.sort(category_list)
  
  -- Remember it in the cache
  species_by_category_table_cache = by_category
  category_list_cache = category_list
  
  -- Return the table
  return by_category, category_list
end


local species_table_cache = nil

-- Does a query to the webserver and returns table containing array of species
function getSpeciesTable()
  -- If already have it in cache then return it
  if species_table_cache ~= nil then return species_table_cache end
  
  -- Get and store in cache
  species_table_cache = getJsonTable(hostname .. ":" .. port .. "/speciesList")
  
  return species_table_cache
end

      