-- For managing the parameters that a user can set
-- Documentation at https://monome.org/docs/norns/reference/params

encoder_timer = nil
local group_selected
local groups = nil

-- When Group is the selected option this is called for every change of the encoder3
function group_changed(selected)
  group_selected = groups[selected]
  
  -- Reset timer so that group_encoder_timer_expired() will be called only after 
  -- encoder3 stops being turned. This avoids handling too many updates.
  encoder_timer:start()
end

-- 
function group_encoder_timer_expired()
  print("group_encoder_timer_expired() Should update species list. group_selected="..group_selected)
  print("Getting species for group...")
  species_list = getSpeciesForGroup(group_selected)
  print("Species for group is:")
  tab.print(species_list)
end


function parameters_init()
  print("In params_init()")
  
  -- get rid of standard params so that they are not at the top
  params:clear()
  
  params:add_separator("Taweet Parameters")
  
  encoder_timer = metro.init(group_encoder_timer_expired, 0.7, 1)
  groups = getGroupsList()
  params:add_option("groups","Group:", groups, 1) -- FIXME should set to current group
  params:set_action(params.lookup["groups"], group_changed) -- FIXME
  
  params:add_number("something1", "something1", 20, 240,88)
  params:add_text("idText2", "", "some text for num 1")
  params:add_number("tempo", "tempo", 20, 240,88)

  -- Add back the standard params, but so that they are at the end of the page
  params:add_text("", "")
  params:add_separator("Standard Parameters")
  -- add back standard audio params like LEVELS, REVERB, COMPRESSOR, and SOFTCUT
  audio.add_params()
  -- add back clock params
  clock.add_params()
end

