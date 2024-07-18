local json = include "lib/json"


-- For converting a string like a URL to a hash so that it can be used a file name.
-- Not actually used currently, but could be useful.
local function hash(str)
    local h = 5381;

    for c in str:gmatch"." do
        h = ((h << 5) + h) + string.byte(c)
    end
    return h
end


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
-- Will be norns.state.data/species/ . Spaces replaced with "_" and the
-- the right apostrophy used by Ithaca is removed to make name more file system
-- friendly
function getDirectory(species)
  return norns.state.data .. species:gsub(" ", "_"):gsub("’", "")
end


-- Gets wav file for the specified species and catalog. First checks cache. The wav 
-- file will be stored at norns.state.data/species/catalog.wav . Converts spaces in species
-- name to "_" so that won't have file system problems.
function getSpeciesWavFile(url, species, catalog)
  return getWavFile(url, getDirectory(species), catalog .. ".wav")
end


-- Gets png file for the url using the imager website. Doesn't use cache
-- since want to get new random image each time. Caching is done on imager
-- web server instead. The images are pretty small since they are for Norns.
-- Returns the file name of the resulting image.
function getPngFile(species)
  local full_filename = getDirectory(species) .. "/randomForSpecies.png"
  
  print("Creating png file " .. full_filename)
  
  -- Create a more useful query for Google images. Have found that sort of 
  -- "black and white" images work better for providing pics with good contrast.
  -- Include "bird" can be redundant but it avoids strange non-bird pics. And
  -- including "flying" means that many of the pics will be of the birds flying,
  -- which are more dynamic and beautiful. And substitute %20 for spaces so the query 
  -- can be properly sent as query string. And change any right apostrophies used
  -- by Ithaca bird nerds to a regular apostrophy so that works for sure for query string.
  local enhanced_query = ("black and white "..species.." bird flying")
    :gsub(" ", "%%20"):gsub("’", "'")
  
  local cmd = "curl --silent --max-time 10 --insecure --create-dirs " .. 
    "--output " .. full_filename .. 
    " " .. hostname .. ":" .. port .. "/getImage?q=" .. enhanced_query
      
  print("getPngFile() executing command=" .. cmd)
  util.os_capture(cmd)

  return full_filename
end

-- Returns an image buffer that can be drawn to the Norns screen. 
-- It is thought that keeping the image buffer around would allow for
-- faster screen drawing since wouldn't have to load the PNG from
-- file system everytime.
function getPngBuffer(species)
  local full_filename = getPngFile(species)
  print("getPngBuffer() full_filename="..full_filename)
  local image_buffer = screen.load_png(full_filename)
  print("getPngBuffer() image_buffer=")
  print("image_buffer type=" .. type(image_buffer))
  return image_buffer
end


-- Gets JSON from a URL and returns it as a Lua table object
local function getJsonTable(url)
  local cmd = "curl --silent --max-time 10 --insecure " ..  url
  print("getJsonTable() executing cmd=" .. cmd)
  local ret = util.os_capture(cmd)
  --print("getJsonTable() ret="..ret)
  
  table = json.decode(ret)
  return table
end


-- Does a query to the webserver and returns table containing array of species
function getSpeciesTable()
  return getJsonTable(hostname .. ":" .. port .. "/speciesList")
end

      