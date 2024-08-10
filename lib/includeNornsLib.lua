-- For including libs from nornsLib repo. Similar to include(), but downloads 
-- nornsLib if haven’t done so previously to the user's device.
-- @tparam name - just the name of the particulae lib to include. Don't need
-- directory nor the .lua suffix.
function include_norns_lib(name)
  -- Where to find the github github_repo
  local github_repo_owner = "skibu"
  local github_repo = "nornsLib"
  local include_file = github_repo.."/"..name
  
  -- Try to include the lib
  print("Including "..github_repo.." extension file "..include_file)
  if not pcall(function () result = include(include_file) end) then
    -- lib doesnt exist so do a git clone of the normsLib repo to get all the lib files
    command = "git clone https://github.com/"..github_repo_owner.."/"..github_repo..".git ".._path.code..github_repo
    print(github_repo.." not yet loaded so loading it now using: "..command)
    os.execute(command)
    
    -- Now try including the lib again
    return include(include_file)
  end 
end

-- Then can include lib files vie something like:
--include_norns_lib("screenExtensions")
