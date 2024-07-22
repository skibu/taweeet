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
  
  -- Create a more useful query for Google images. Have found that semi 
  -- "black and white" images can work better for providing pics with good contrast.
  -- Include "bird" can be redundant but it avoids strange non-bird pics. And
  -- including "flying" means that many of the pics will be of the birds flying,
  -- which are more dynamic and beautiful. And substitute %20 for spaces so the query 
  -- can be properly sent as query string. And change any right apostrophies used
  -- by Ithaca bird nerds to a regular apostrophy so that works for sure for query string.
  -- Actually, for now just use "flying" to see if that provides better pics.
  --local enhanced_query = ("black and white "..species.." bird flying")
  local enhanced_query = urlencode(species.." flying")
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


-- Does a query to the webserver and returns table containing array of species
function getSpeciesTable()
  return getJsonTable(hostname .. ":" .. port .. "/speciesList")
end

      