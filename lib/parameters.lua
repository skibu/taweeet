-- For managing the parameters that a user can set
-- Documentation at https://monome.org/docs/norns/reference/params

-- So that don't select a species via the selecctors at startup. 
local initializing = true


local group_timer = nil

-- Called when user stops changing the group selector for a bit
local function group_timer_expired()
  group_selected = params:string("groups")
  species_list = getSpeciesForGroup(group_selected)

  -- Update the species selector
  local species_param = params:lookup_param("species")
  species_param.options = species_list
  species_param.count = #species_list
  species_param.selected = 1 -- select first species in group
  
  -- Actually get species selector to display new value
  util.debug_tprint("group_timer_expired() so doing species_param.bang()")
  species_param:bang()
end


-- When Group is the selected option this is called for every change of the encoder.
-- Simply restarts the group_timer.
local function group_changed_by_encoder(index)
  util.debug_tprint("group_changed_by_encoder() index="..index)
  -- Reset timer so that group_timer_expired() will be called only after 
  -- encoder3 stops being turned. This avoids handling too many updates.
  -- And don't select species through selector callbacks at startup
  if not initializing then group_timer:start() end
end


local species_timer = nil

-- Called when user stops changing the species selector for a bit
local function species_timer_expired()
  -- New species selected. 
  util.debug_tprint("Species selected is: "..params:string("species"))
  
  -- Update the application with the new species
  select_species(params:string("species"))
end


-- When Species is the selected option this is called for every change of the encoder
-- Simply restarts the species_timer.
local function species_changed_by_encoder(index)
  util.debug_tprint("species_changed_by_encoder() index="..index)
  -- Reset timer so that species_timer_expired() will be called only after 
  -- encoder3 stops being turned. This avoids handling too many updates.
  -- And don't select species through a selector at startup
  if not initializing then species_timer:start() end
end


-- Called when user selects an image file for the species. Loads and shows that file.
local function image_changed_by_encoder(index)
  util.debug_tprint("image_changed_by_encoder() index="..index)
end


-- Called when user selects an audio file for the species. Loads and plays that file.
local function audio_changed_by_encoder(index)
  util.debug_tprint("audio_changed_by_encoder() index="..index)
end


-- For when species is selected outside of parameters menu, such as when key2 pressed
function update_parameters_for_new_species(species_data)
  local group_name = species_data.groupName
  local species_name = species_data.speciesName
  
  util.debug_tprint("Updating parameters for species="..species_name.." group="..group_name)
  
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
  local images_list = {}
  for i, image_data in ipairs(species_data.imageDataList) do
    -- Determine title to use. If title specified in the JSON data then use it
    local title
    if image_data.title then
      title = image_data.title
    else
      -- If should use catalog
      --title = "+"..image_data.rating.." Ebird "..image_data.catalog
      
      -- If should use location. 
      -- Shorten the country name. List of codes is at https://www.iban.com/country-codes .
      -- State ones at https://www.faa.gov/air_traffic/publications/atpubs/cnt_html/appendix_a.html
      title = "+"..image_data.rating.." "..
        image_data.loc:gsub("United States", "USA")
                      :gsub("California", "CA")
                      :gsub("Colorado", "CO")
                      :gsub("Florida", "FL")
                      :gsub("Idaho", "ID")
                      :gsub("Indiana", "IN") -- Needs to be before "India"
                      :gsub("Louisiana", "LA")
                      :gsub("Mississippi", "MS")
                      :gsub("North Carolina", "NC")
                      :gsub("Pennsylvania", "PA")
                      :gsub("Texas", "TX")
                      :gsub("Washington", "WA")
                      
                      :gsub("Brazil", "BRA")
                      
                      :gsub("Canada", "CAN")
                      :gsub("Alberta", "AB")
                      :gsub("Quebec", "QC")
                      
                      :gsub("Germany", "DEU")
                      :gsub("India", "IND")
                      :gsub("Thailand", "THA")
    end
    table.insert(images_list, title)
  end
  local images_param = params:lookup_param("images")
  images_param.options = images_list
  images_param.count = #images_list
  images_param.selected = 1 -- FIXME
  
  -- Update the audio selector
  --FIXME
end


-- Initializes the parameters for the Taweeet application.
-- To be called from the applications main init() function.
function parameters_init()
  print("Initializing parameters...")
  
  -- get rid of standard params so that they are not at the top
  params:clear()
  
  -- Nice to separate out the Taweet params
  params:add_separator("Taweet Parameters")

  -- Group timer used to not call group_changed() callback until after encoder
  -- has stopped moving for a bit. This greatly reduces the number of callbacks
  group_timer = metro.init(group_timer_expired, 1.0, 1)

  -- Group selector. Since groups_list doesn't change, the selector can be 
  -- fully created
  local groups_list = getGroupsList()
  params:add_option("groups","Group:", groups_list, 1) -- FIXME should set to current group
  params:set_action(params.lookup["groups"], group_changed_by_encoder)
  
  -- Species timer used to not call species_changed() callback until after encoder
  -- has stopped moving for a bit. This greatly reduces the number of callbacks
  species_timer = metro.init(species_timer_expired, 1.0, 1)

  -- Species selector. Since group not yet selected, cannot set the species list 
  -- for the group yet. Therefore just using empty list for now.
  params:add_option("species","Species:", {})
  params:set_action(params.lookup["species"], species_changed_by_encoder)
  
  -- Image selector. Since don't yet know the species, have to set it to empty list for now
  params:add_option("images","Image:", {})
  params:set_action(params.lookup["images"], image_changed_by_encoder)
  
  -- Audio selector. Since don't yet know the species, have to set it to empty list for now
  params:add_option("audio","Audio:", {})
  params:set_action(params.lookup["audio"], audio_changed_by_encoder)
  
  -- Adding some other params just to play around
  params:add_separator("test params, for fun")
  params:add_number("something1", "something1", 20, 240,88)
  params:add_number("tempo", "tempo", 20, 240,88)

  -- Add back the standard params, but so that they are at the end of the page
  params:add_text("", "")
  params:add_separator("Standard Parameters")
  -- add back standard audio params like LEVELS, REVERB, COMPRESSOR, and SOFTCUT
  audio.add_params()
  -- add back clock params
  clock.add_params()
  
  -- Done with initializing so making the group and species selectors active
  initializing = false
  util.tprint("Done with params_init()")
end

