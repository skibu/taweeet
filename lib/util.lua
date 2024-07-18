
-- Wacky function that returns extents of specified image buffer.
-- This was quite difficult to figure out because had to search
-- around to find out about userdata objects and getmetatable(),
-- and then look at the weaver.c source code to find out about
-- what info is available from an image buffer. 
function extents(image_buffer)
  -- Image buffer is of type userdata, which means it is a C object.
  -- But by searching around I found that getmetatable() returns a lua table
  -- that contains information about the C object.
  local meta_table =  getmetatable(image_buffer)
  
  -- By looking at weaver.c can see that one of the things the meta table
  -- contains is __index, which has info about the lua functions that can
  -- be called.
  local __index_subtable = meta_table["__index"]
  
  -- And now can get pointer to the extents() function
  local extents_function = __index_subtable["extents"]
  
  -- Now can just call the extents function on the image buffer and return the results
  return extents_function(image_buffer)
end  