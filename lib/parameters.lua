-- For managing the parameters that a user can set
-- Documentation at https://monome.org/docs/norns/reference/params

function parameters_init()
  print("In params_init()")
  
  -- get rid of standard params so that they are not at the top
  params:clear()
  
  groups = getGroupsList()

  params:add_separator("idSep1", "Taweet Parameters")
  params:add_option("groups","Group:", groups, 1) -- FIXME should set to current group

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


function jump_to_edit_params_screen()
  print("In jump_to_edit_params_screen()...")
  print(debug.traceback())
  
  -- Change to menu mode 
  _menu.set_mode(true) 
  
  -- Initialize the params page
  params_class = require "core/menu/params"
  params_class.init()
  
  -- Change to PARAMS menu screen
  _menu.set_page("PARAMS")
  
  -- Go to the Edit Params page by acting like key3 was pressed to 
  -- simulate selecting Edit> from the PARAMS menu.
  -- Wanted to necessary functions directly but they were local to
  -- the params.lua core norns software and therefore not really accessible.
  params_class.key(3, 1)
  
  print("Should now be in Taweet Parameters page")
end
