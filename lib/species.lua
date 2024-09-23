-- For keeping track of the current species and all of its associated info
-- like the current sound and image files.
global_species_data = nil


-- Returns true if a species has been selected. 
function species_selected()
  return global_species_data ~= nil
end


-- Called once wav file is ready
local function wav_file_exists_callback(filename)
  -- If the global_species_data.wav_filename has been changed it means that
  -- the user selected another file. For this situation don't need to do
  -- anything here since it will be done by the callback for the new filename.
  if filename ~= global_species_data.wav_filename then return end

  -- Play the wav file
  softcut_setup_stereo(filename, 1, 2)
end


-- Called once png file is ready
local function png_file_exists_callback(filename)
  -- If the global_species_data.png_filename has been changed it means that
  -- the user selected another file. For this situation don't need to do
  -- anything here since it will be done by the callback for the new filename.
  if filename ~= global_species_data.png_filename then return end
    
  -- png file exists so create the image buffer and determine width and height
  global_species_data.image_buffer = screen.load_png(filename)
  global_species_data.width, global_species_data.height = 
    screen.extents(global_species_data.image_buffer)

  -- Start the intro animation, but only if in app mode
  startIntroIfInAppMode()
end


-- Loads in the specified png file and then once it is fully loaded 
-- png_file_exists_callback() will be called to finish processing.
function select_png(png_url, species_name)
  -- Initiate the loading of the PNG file and store the filename
  global_species_data.png_filename = 
    getPng(png_url, global_species_data.speciesName)
  global_species_data.png_url = png_url
  
  -- Need to clear out other related params in global_species_data 
  -- since they are now not proper
  global_species_data.width = nil
  global_species_data.height = nil
  global_species_data.image_buffer = nil
  
  -- Start timer for displaying png file once it is ready
  util.wait(global_species_data.png_filename, png_file_exists_callback, 0.2, 20)
    
  -- Select proper pgn file in the parameter menu image selector
  taweet_params.select_current_image(global_species_data)
end


-- Returns true if the current PNG file for the current species has been fully 
-- loaded and is ready to be displayed. 
function png_ready()
  return global_species_data ~= nil and
    global_species_data.width ~= nil and 
    global_species_data.height ~= nil and
    global_species_data.image_buffer ~= nil
end


-- Selects randomly a png to use for the currently selected species. The currently
-- selected species is specified by global_species_data. 
function select_random_png()
  -- First should make sure that intro is not running. Otherwise could select a new
  -- PNG file while the intro still continues to run, and then the intro will try
  -- to display the new PNG before it is ready.
  haltIntro()
  
  -- Pick random png url for the species
  local image_data_list = global_species_data.imageDataList
  local image_idx = math.random(1, #image_data_list)
  local image_data_tbl = image_data_list[image_idx]
  local png_url = image_data_tbl.imageUrl
  log.debug("Selected random image image_idx="..image_idx.." png_url="..png_url..
    " for species="..global_species_data.speciesName)
  
  select_png(png_url, global_species_data.speciesName)
end


-- Loads in the specified wav file and then once it is fully loaded 
-- xwav_file_exists_callback() will be called to finish processing.
function select_wav(wav_url, species_name)
  global_species_data.wav_filename = getWav(wav_url, species_name)
  global_species_data.wav_url = wav_url

  -- Start timer for playing wav file once it is ready
  util.wait(global_species_data.wav_filename, wav_file_exists_callback, 0.2, 35)
  
  -- Select proper wav file in the parameter menu audio selector
  taweet_params.select_current_audio(global_species_data)
end


-- Selects randomly an audio wav file to use for the currently selected species. The
-- currently selected species is specified by global_species_data. 
function select_random_wav()
  local audio_data_list = global_species_data.audioDataList
  local audio_idx = math.random(1, #audio_data_list)
  local audio_data = audio_data_list[audio_idx]
  local wav_url = audio_data.audioUrl
  log.debug("Selected random audio audio_idx="..audio_idx.." wav_url="..wav_url..
    " for species="..global_species_data.speciesName)
  
  -- Actually select that url
  select_wav(wav_url, global_species_data.speciesName)
end


-- Loads in config for the species and update parameters menu Options
function select_species(species_name)
  log.debug("Initing species via select_species(). species="..species_name)
  
  -- Load in config for the species
  global_species_data = getSpeciesData(species_name)
  
  -- Update the parameters menu
  taweet_params.update_options_for_new_species(global_species_data)
end


-- Selects the species specified. Also picks a PNG file and a WAV file randomly.
-- Stores the current settings in global_species_data.
function select_species_and_random_image_and_audio(species_name)
  log.debug("Initing species and selecting random image and audio. species="..species_name)
  
  -- Load in config for the species and update parameters menu Options
  select_species(species_name)

  -- Pick random png url for the species
  select_random_png()

  -- Pick random wav file url for the species
  select_random_wav()
end


-- Gets list of species and picks one randomely. Then loads in all the info
-- for the species. Returns table containing all of the data associated with the
-- selected species.
function select_random_species()
  log.debug("Determining a random species to use...")
  
  -- Get list of all species
  local species_list = getAllSpeciesList()

  -- Pick a species name by random
  local idx = math.random(1, #species_list)
  local random_species_name = species_list[idx]
  log.debug("Using species "..random_species_name)
  
  select_species_and_random_image_and_audio(random_species_name)
end


