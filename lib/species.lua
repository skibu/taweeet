global_species_data = nil

-- Called when wav file is ready
local function wav_file_exists_callback(filename)
  -- Play the wav file
  softcut_setup_stereo(filename, 1, 2)
end


-- Called when png file is ready
local function png_file_exists_callback(filename)
  -- png file exists so create the image buffer and determine width and height
  global_species_data.image_buffer = screen.load_png(filename)
  global_species_data.width, global_species_data.height = 
    screen.extents(global_species_data.image_buffer)
    
  -- Start the intro animation
  intro_counter:start()
end


-- Selects randomly a png to use for the currently selected species. The currently
-- selected species is specified by global_species_data. 
function select_random_png()
  -- Pick random png url for the species
  local image_data_list = global_species_data.imageDataList
  local image_idx = math.random(1, #image_data_list)
  local image_data_tbl = image_data_list[image_idx]
  local png_url = image_data_tbl.image_url
  global_species_data.png_filename = getPng(png_url, global_species_data.speciesName)
  
  -- Start timer for displaying png file once it is ready
  util.wait(global_species_data.png_filename, png_file_exists_callback, 0.2, 15)
end


-- Selects randomly an audio wav file to use for the currently selected species. The
-- currently selected species is specified by global_species_data. 
function select_random_wav()
  local audio_data_list = global_species_data.audioDataList
  local audio_idx = math.random(1, #audio_data_list)
  local audio_data = audio_data_list[audio_idx]
  local wav_url = audio_data.audio_url
  global_species_data.wav_filename = getWav(wav_url, global_species_data.speciesName)

  -- Start timer for playing wav file once it is ready
  util.wait(global_species_data.wav_filename, wav_file_exists_callback, 0.4, 20)
end


-- Selects the species specified. Also picks a PNG file and a WAV file randomly.
-- Stores the current settings in global_species_data.
function select_species(species_name)
  print("Initing select_species(species_name) species="..species_name)
  
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


