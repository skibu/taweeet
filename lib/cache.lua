-- For converting a string like a URL to a hash so that it can be used a file name.
-- Returns string that is 10 chars long.
function hash(str)
  local h = 5381;

  for c in str:gmatch"." do
      h = ((h << 5) + h) + string.byte(c)
  end
  
  -- Only return chars 2-11 so don't get possible '-' and only get 10 chars
  return string.sub(tostring(h), 2, 11)
end


-- Returns the identifying part of the file name to be used to cache data associated with a URL.
-- Key thing is that if the URL is for a special cornell.edu asset/catalog item then should
-- use the catalog identifier, something like ML928372. This way can much more easily lookup the
-- original data. But if not a cornell catalog item, use a hash.
function file_identifier(url)
  if string.find(url, 'cornell.edu') ~= -1 and string.find(url, '/asset/') ~= -1 then
    -- Special cornell URL so use the catalog number
    after_asset = string.sub(url, string.find(url, '/asset/')+7, -1)
    return 'ML' .. string.sub(after_asset, 1, string.find(after_asset, '/')-1)
  else
    -- Not cornell URL so just a hash of the url
    return hash(url)
  end
end

  
