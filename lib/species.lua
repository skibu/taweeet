global_species_data = nil

-- Called once wav file is ready
local function wav_file_exists_callback(filename)
  -- Play the wav file
  softcut_setup_stereo(filename, 1, 2)
end


-- Called once png file is ready
local function png_file_exists_callback(filename)
  -- If already created an image buffer then first free the old one
  if global_species_data.image_buffer ~= nil then
    util.debug_tprint("Freeing image buffer "..tostring(global_species_data.image_buffer))
    screen.free(global_species_data.image_buffer)
    global_species_data.image_buffer = nil
  end
    
  -- png file exists so create the image buffer and determine width and height
  global_species_data.image_buffer = screen.load_png(filename)
  global_species_data.width, global_species_data.height = 
    screen.extents(global_species_data.image_buffer)
    
  -- Start the intro animation
  intro_counter:start()
end


-- Loads in the specified png file and then once it is fully loaded 
-- png_file_exists_callback() will be called to finish processing.
function select_png(png_url, species_name)
  global_species_data.png_filename = getPng(png_url, global_species_data.speciesName)
  
  -- Start timer for displaying png file once it is ready
  util.wait(global_species_data.png_filename, png_file_exists_callback, 0.2, 15)
end


-- Selects randomly a png to use for the currently selected species. The currently
-- selected species is specified by global_species_data. 
function select_random_png()
  -- Pick random png url for the species
  local image_data_list = global_species_data.imageDataList
  local image_idx = math.random(1, #image_data_list)
  local image_data_tbl = image_data_list[image_idx]
  local png_url = image_data_tbl.imageUrl
  util.debug_tprint("Selected random image image_idx="..image_idx.." png_url="..png_url.." for species="..global_species_data.speciesName)
  
  select_png(png_url, global_species_data.speciesName)
end


-- Loads in the specified wav file and then once it is fully loaded 
-- xwav_file_exists_callback() will be called to finish processing.
function select_wav(wav_url, species_name)
  global_species_data.wav_filename = getWav(wav_url, species_name)

  -- Start timer for playing wav file once it is ready
  util.wait(global_species_data.wav_filename, wav_file_exists_callback, 0.4, 20)
end


-- Selects randomly an audio wav file to use for the currently selected species. The
-- currently selected species is specified by global_species_data. 
function select_random_wav()
  local audio_data_list = global_species_data.audioDataList
  local audio_idx = math.random(1, #audio_data_list)
  local audio_data = audio_data_list[audio_idx]
  local wav_url = audio_data.audioUrl
  util.debug_tprint("Selected random audio audio_idx="..audio_idx.." wav_url="..wav_url.." for species="..global_species_data.speciesName)
  
  -- Actually select that url
  select_wav(wav_url, global_species_data.speciesName)
end


-- Selects the species specified. Also picks a PNG file and a WAV file randomly.
-- Stores the current settings in global_species_data.
function select_species(species_name)
  util.tprint("Initing select_species(species_name) species="..species_name)
  
  -- Load in config for the species
  global_species_data = getSpeciesData(species_name)

  -- Pick random png url for the species
  select_random_png()

  -- Pick random wav file url for the species
  select_random_wav()
  
  -- Update the parameters menu
  update_parameters_for_new_species(global_species_data)
end


-- Gets list of species and picks one randomely. Then loads in all the info
-- for the species. Returns table containing all of the data associated with the
-- selected species.
function select_random_species()
  print("Determining a random species to use...")
  
  -- Get list of all species
  local species_list = getAllSpeciesList()

  -- Pick a species name by random
  local idx = math.random(1, #species_list)
  local random_species_name = species_list[idx]
  print("Using species "..random_species_name)
  
  select_species(random_species_name)
end

