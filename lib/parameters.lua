-- For managing the parameters that a user can set
-- Documentation at https://monome.org/docs/norns/reference/params

-- So can have separate namespace for all thesee functions
local taweet_params = {}

-- So that don't select a species via the paramset selectors at startup. 
local initializing = true


local group_timer = nil

-- Called when user stops changing the group selector for a bit
local function group_timer_expired()
  local group_selected = params:string("groups")
  local species_list = getSpeciesForGroup(group_selected)

  -- Update the species selector
  local species_param = params:lookup_param("species")
  species_param.options = species_list
  species_param.count = #species_list
  species_param.selected = 1 -- select first species in group
  
  -- Actually get species selector to display new value
  debug.log("group_timer_expired() so doing species_param.bang()")
  species_param:bang()
end


-- When Group is the selected option this is called for every change of the encoder.
-- Simply restarts the group_timer. Parameter index is the index in the parameter's 
-- list that has been selected.
local function group_changed_by_encoder(index)
  debug.log("group_changed_by_encoder() index="..index.." initializing="..tostring(initializing))
  print(debug.traceback()) -- FIXME

  -- Reset timer so that group_timer_expired() will be called only after 
  -- encoder3 stops being turned. This avoids handling too many updates.
  -- And don't select species through selector callbacks at startup
  if not initializing then group_timer:start() end
end


local species_timer = nil

-- Called when user stops changing the species selector for a bit
local function species_timer_expired()
  -- New species selected. 
  debug.log("Species selected is: "..params:string("species"))
  
  -- Update the application with the new species
  select_species(params:string("species"))
end


-- When Species is the selected option this is called for every change of the encoder
-- Simply restarts the species_timer.
local function species_changed_by_encoder(index)
  debug.log("species_changed_by_encoder() index="..index.." initializing="..tostring(initializing))
  -- Reset timer so that species_timer_expired() will be called only after 
  -- encoder3 stops being turned. This avoids handling too many updates.
  -- And don't select species through a selector at startup
  if not initializing then species_timer:start() end
end


-- Called when user selects an image file for the species. Loads and shows that file.
local function image_changed_by_encoder(index)
  -- If haven't been initialized yet don't need to do anything
  if global_species_data == nil then return end
  
  debug.log("image_changed_by_encoder() index="..index)

  local species_name = global_species_data.speciesName
  local image_url = global_species_data.imageDataList[index].imageUrl
  debug.log("Selected image url="..image_url)

  select_png(image_url, species_name)
end


-- Called when user selects an audio file for the species. Loads and plays that file.
local function audio_changed_by_encoder(index)
  -- If haven't been initialized yet don't need to do anything
  if global_species_data == nil then return end
  
  debug.log("audio_changed_by_encoder() index="..index)
  
  local species_name = global_species_data.speciesName
  local wav_url = global_species_data.audioDataList[index].audioUrl
  debug.log("Selected audio url="..wav_url)

  select_wav(wav_url, species_name)
end


-- Select the proper image in the image param selector. This is done by finding 
-- the image selection where the url of the image is the same as 
-- global_species_data.png_filename. This needs to be called only after
-- image URL has been specified.
function taweet_params.select_current_image(species_data)
  debug.log("Setting image menu param to png_url="..species_data.png_url)
  for i, image_data in ipairs(species_data.imageDataList) do
    -- If this is the selected image then set it as the selected item in the param list
    if image_data.imageUrl == species_data.png_url then
      debug.log("Setting image menu param index to "..i)
      local images_param = params:lookup_param("images")
      images_param.selected = i
      return
    end
  end
end


-- Select the proper audio in the audio param selector. This is done by finding 
-- the audio selection where the url of the audio is the same as 
-- global_species_data.wav_filename. This needs to be called only after
-- audio URL has been specified.
function taweet_params.select_current_audio(species_data)
  debug.log("Setting audio menu param to wav_url="..species_data.wav_url)
  for i, audio_data in ipairs(species_data.audioDataList) do
    -- If this is the selected audio then set it as the selected item in the param list
    if audio_data.audioUrl == species_data.wav_url then
      debug.log("Setting audio menu param index to "..i)
      local audio_param = params:lookup_param("audio")
      audio_param.selected = i
      return
    end
  end
end


-- For when species is selected outside of parameters menu, such as when key2 pressed
function taweet_params.update_for_new_species(species_data)
  local group_name = species_data.groupName
  local species_name = species_data.speciesName
  
  debug.log("Updating parameters menu for species="..species_name..
    " group="..group_name)
  
  -- Update group selector to be the group for the specified species
  local groups_param = params:lookup_param("groups")
  for i=1, groups_param.count do
    -- If found the right group, select it
    if groups_param.options[i] == group_name then
      groups_param.selected = i
      break
    end
  end

  -- Need to first populate the species selector with the species for the group
  local species_list = getSpeciesForGroup(group_name)
  local species_param = params:lookup_param("species")
  species_param.options = species_list
  species_param.count = #species_list

  -- Update species selector 
  for i=1, species_param.count do
    -- If found the right species, select it
    if species_param.options[i] == species_name then
      species_param.selected = i
      break
    end
  end
  
  -- Update the image selector
  local images_param = params:lookup_param("images")
  local images_list = {}
  for i, image_data in ipairs(species_data.imageDataList) do
    -- Determine title to use. If title specified in the JSON data then use it
    local title
    if image_data.title then
      title = image_data.title
    else
      -- If should use catalog
      --title = "+"..image_data.rating.." Ebird "..image_data.catalog
      
      -- If should use location. Don't need rating for images since the first
      -- 10 will be +5.
      title = i..") "..image_data.loc
        :gsub("Abbreviate this", "ABV")
        :gsub(", British Columbia", ", BC")
        :gsub(", Russia", ", RUS")
        :gsub(", Israel", ", ISR")
        :gsub(", England", ", GB")
    end
    table.insert(images_list, title)
  end
  
  -- Finish setting up the image parameter list
  images_param.options = images_list
  images_param.count = #images_list

  -- Update the audio selector
  local audio_param = params:lookup_param("audio")
  local audio_list = {}
  for i, audio_data in ipairs(species_data.audioDataList) do
    -- Determine title to use. If title specified in the JSON data then use it
    local title
    if audio_data.title then
      title = audio_data.title
    else
      -- If should use catalog
      --title = "+"..audio_data.rating.." Ebird "..audio_data.catalog
      
      -- If should use location. Prefix with rating since there are some species
      -- where there aren't very many recordings, and some of them might not be that great.
      title = i..") ".."+"..audio_data.rating.." "..audio_data.loc
      :gsub("Abbreviate this", "ABV")
      :gsub(", British Columbia", ", BC")
      :gsub(", Russia", ", RUS")
      :gsub(", Israel", ", ISR")
      :gsub(", England", ", GB")
    end
    table.insert(audio_list, title)
  end
  
  -- Finish setting up the audio parameter list
  audio_param.options = audio_list
  audio_param.count = #audio_list
end


-- For shortening the label strings of parameters so that the value doesn't
-- overlap with the label. Just removing spaces after comma for a slight 
-- improvement.
local function shortener_function(value)
  local result = value:gsub(", ", ","):gsub("%) ", ")")
  return result
end  


-- Initializes the parameters for the Taweeet application.
-- To be called from the applications main init() function.
function taweet_params.init()
  util.tprint("Initializing parameters...")
  
  -- To help eliminate overlap of parameter values with their labels
  set_selector_shortener(shortener_function)
  
  -- I think it looks better if the values are left aligned
  set_left_align_parameter_values(true)
  
  -- get rid of standard params so that they are not at the top
  params:clear()
  
  -- Nice to separate out the Taweet params
  params:add_separator("Taweet Parameters")

  -- Group timer used to not call group_changed() callback until after encoder
  -- has stopped moving for a bit. This greatly reduces the number of callbacks
  group_timer = metro.init(group_timer_expired, 0.7, 1)

  -- Group selector. Since groups_list doesn't change, the selector can be 
  -- fully created
  local groups_list = getGroupsList()
  -- Can use "\u{2009}" for half space or "\u{200A}" for even skinnier 
  -- hair space which is just single pixel
  params:add_option("groups","\u{200A}Group:", groups_list, 1)
  params:set_action(params.lookup["groups"], group_changed_by_encoder)
  
  -- Species timer used to not call species_changed() callback until after encoder
  -- has stopped moving for a bit. This greatly reduces the number of callbacks
  species_timer = metro.init(species_timer_expired, 0.7, 1)

  -- Species selector. Since group not yet selected, cannot set the species list 
  -- for the group yet. Therefore just using empty list for now.
  params:add_option("species","Taxon.:", {})
  params:set_action(params.lookup["species"], species_changed_by_encoder)
  
  -- Image selector. Since don't yet know the species, have to set it to empty list for now
  params:add_option("images","Image:", {})
  params:set_action(params.lookup["images"], image_changed_by_encoder)
  
  -- Audio selector. Since don't yet know the species, have to set it to empty list for now
  params:add_option("audio","\u{200A}\u{200A}\u{200A}Audio:", {})
  params:set_action(params.lookup["audio"], audio_changed_by_encoder)
  
  -- Adding some other params just to play around
  params:add_text("", "") -- A spacer
  params:add_separator("test params, for fun")
  params:add_number("something1", "something1", 20, 240,88)
  params:add_number("tempo", "tempo", 20, 240,88)

  -- Adding easy way to get to PSET screen
  params:add_text("spacerId2", "", "") -- A spacer
  params:add_separator("Presets (PSET)")
  params:add_trigger("pset", "Save, Load, or Delete >") 
  params:set_action("pset", jump_to_pset_screen )
  
  -- Add back the standard params, but so that they are at the end of the page
  params:add_text("spacerId3", "", "") -- A spacer
  params:add_separator("Standard Parameters")
  -- add back standard audio params like LEVELS, REVERB, COMPRESSOR, and SOFTCUT
  audio.add_params()
  -- Add back clock params. Note: this calls parmset.bang() in clock.lua:317 which
  -- means that all the parameters will be "banged" and the corresponding callbacks
  -- will be called indicating that the values have been updated. 
  -- Though params:bang("clock_tempo") is called, not params:bang(). 
  clock.add_params()
  
  -- Load in default paramset if there is one
  --FIXME params:default()
  
  -- Done with initializing so making the group and species selectors active
  initializing = false
  
  util.tprint("Done with params_init()")
end

return taweet_params
