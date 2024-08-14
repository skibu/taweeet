-- For managing the parameters that a user can set
-- Documentation at https://monome.org/docs/norns/reference/params

-- So that don't select a species via the selecctors at startup. 
local initializing = true

local group_timer = nil

-- When Group is the selected option this is called for every change of the encoder
local function group_changed(index)
  util.tprint("group_changed()")
  -- Reset timer so that group_timer_expired() will be called only after 
  -- encoder3 stops being turned. This avoids handling too many updates.
  -- And don't select species through selector callbacks at startup
  if not initializing then group_timer:start() end
end

-- Called when user stop changing the group selector
local function group_timer_expired()
  group_selected = params:string("groups")
  species_list = getSpeciesForGroup(group_selected)

  -- Update the species selector
  local species_param = params:lookup_param("species")
  species_param.options = species_list
  species_param.count = #species_list
  species_param.selected = 1 -- select first species in group
  
  -- Actually get species selector to display new value
  print("group_timer_expired() so doing species_param.bang()")
  species_param:bang()
end


local species_timer = nil

-- When Species is the selected option this is called for every change of the encoder
local function species_changed(index)
  util.tprint("species_changed()")
  -- Reset timer so that species_timer_expired() will be called only after 
  -- encoder3 stops being turned. This avoids handling too many updates.
  -- And don't select species through a selector at startup
  if not initializing then species_timer:start() end
end

-- Called when user stop changing the species selector
local function species_timer_expired()
  -- New species selected. But this will also be called at 
  util.tprint("Species selected is: "..params:string("species"))
  select_species(params:string("species"))
end


function parameters_init()
  print("In params_init()")
  
  -- get rid of standard params so that they are not at the top
  params:clear()
  
  -- Nice to separate out the Taweet params
  params:add_separator("Taweet Parameters")
  
  -- Group selector
  group_timer = metro.init(group_timer_expired, 0.7, 1)
  local groups_list = getGroupsList()
  params:add_option("groups","Group:", groups_list, 1) -- FIXME should set to current group
  params:set_action(params.lookup["groups"], group_changed)
  
  -- Species selector
  species_timer = metro.init(species_timer_expired, 0.7, 1)
  params:add_option("species","Species:", {})
  params:set_action(params.lookup["species"], species_changed)
    
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

