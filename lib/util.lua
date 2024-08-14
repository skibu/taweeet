
-- Returns true if first char of string is lower case
function isLower(str)
  local firstChar = string.sub(str, 1, 1)
  return "a" <= firstChar and firstChar <= "z"
end

