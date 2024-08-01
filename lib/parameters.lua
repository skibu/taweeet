-- For managing the parameters that a user can set
-- Documentation at https://monome.org/docs/norns/reference/params

function parameters_init()
  print("In params_init()")
  
  groups = getGroupsList()
  tab.print(groups) -- FIXME
  
  for k,v in ipairs(groups) do
    print("v="..v)
    if string.len(v) > 30 then -- Use 22 if use "GroupL" in line with choices
      groups[k] = string.sub(v, 1, 30)
    end
  end
  
  params:add_text("idBlank", "", "")
  params:add_separator("idSep1", "Taweet Parameters")
  params:add_text("idText1", "Group:", "")
  params:add_option("groups","", groups, 1) -- FIXME should set to current group
  
  params:add_number("something1", "something1", 20, 240,88)
  params:add_text("idText2", "", "some text for num 1")
  params:add_number("tempo", "tempo", 20, 240,88)
end

