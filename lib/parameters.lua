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


-- Jumps from the application screen to the script's Params Edit screen so that user can 
-- easily change app params. For when k1 pressed from within the application. Really nice
-- feature since it makes param changes easier.
function jump_to_edit_params_screen()
  -- Change to menu mode 
  _menu.set_mode(true) 

  -- Get access to the PARAMS menu class
  params_class = require "core/menu/params"

  -- Go to EDIT screen of the PARAMS menu. Needed in case user was at another PARAMS screen, like PSET
  params_class.mode = 1 -- mEDIT screen
    
  -- Set to first settable item, which will be Group:
  params_class.pos = 1
  
  -- Change to PARAMS menu screen
  _menu.set_page("PARAMS")

  -- Initialize the params page
  params_class.init()
end
