local json = include "lib/json"


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
  if not util.file_exists(full_filename) then
    print("Creating wav file " .. full_filename)
    local cmd = "curl --silent --max-time 10 --insecure --create-dirs " .. 
      "--output " .. filename .. 
      " --output-dir " .. dir .. 
      " " .. hostname .. ":" .. port .. "/wavFile?url=" .. url
    print("Executing command=" .. cmd)
    util.os_capture(cmd)
  end
  
  -- For debugging
  print_wav_file_info(full_filename)
      
  return full_filename
end


-- Gets wav file for the specified species and catalog. First checks cache. The wav 
-- file will be stored at norns.state.data/species/catalog.wav . Converts spaces in species
-- name to "_" so that won't have file system problems.
function getSpeciesWavFile(url, species, catalog)
  return getWavFile(url, norns.state.data .. species:gsub(" ", "_"), catalog .. ".wav")
end


-- Gets JSON from a URL and returns it as a Lua table object
local function getJsonTable(url)
  local cmd = "curl --silent --max-time 10 --insecure " ..  url
  print("getJsonTable() executing cmd=" .. cmd)
  local ret = util.os_capture(cmd)
  print("getJsonTable() ret="..ret)
  
  table = json.decode(ret)
  return table
end


-- Does a query to the webserver and returns table containing array of species
function getSpeciesTable()
  return getJsonTable(hostname .. ":" .. port .. "/speciesList")
end

      