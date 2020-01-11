
local lua_list = {}
local buf, dtype, dataoffset, typeconvert, datalength, chars, readdata, i,key, value, keys, properties, otchars, otype, property,tableVIn
local _serialize_key, _read_chars, _read_until, _unknown_type,unserialize,vchars,tableTojson,vtype,stringlength,char,kchars,ktype
local EMPTY_ARRAY={}                                                           
local EMPTY_OBJECT={}
function _read_until(data, offset, stopchar)
  local buf = {}
  local char = string.sub(data, offset + 1, offset + 1)
  local i = 2
  while not (char == stopchar) do
    if i + offset > string.len(data) then
      error('Invalid')
    end
    table.insert(buf, char)
    char = string.sub(data, offset + i, offset + i)
    i = i + 1
  end
  return i - 2, table.concat(buf)
end
function _read_chars(data, offset, length)
  local buf = {}, char
  for i = 0, length -1 do
    char = string.sub(data, offset + i, offset + i)
    table.insert(buf, char)
  end
  return length, table.concat(buf)
end
-- php反序列化
function unserialize(data, offset)
    
  offset = offset or 0
  
  local buf, dtype, dataoffset, typeconvert, datalength, chars, readdata, i,key, value, keys, properties, otchars, otype, property
  buf = {}
  dtype = string.lower(string.sub(data, offset + 1, offset + 1))
  dataoffset = offset + 2
  typeconvert = function(x) return x end
  datalength = 0
  chars = datalength
  if dtype == 'i' or dtype == 'd' then
    typeconvert = function(x) return tonumber(x) end
    chars, readdata = _read_until(data, dataoffset, ';')
    dataoffset = dataoffset + chars + 1
  elseif dtype == 'b' then
    typeconvert = function(x) return tonumber(x) == 1 end
    chars, readdata = _read_until(data, dataoffset, ';')
    dataoffset = dataoffset + chars + 1
  elseif dtype == 'n' then
    readdata = nil
  elseif dtype == 's' then
    chars, stringlength = _read_until(data, dataoffset, ':')
    dataoffset = dataoffset + chars + 2
    chars, readdata = _read_chars(data, dataoffset + 1, tonumber(stringlength))
    dataoffset = dataoffset + chars + 2
    
    if not (chars == tonumber(stringlength)) then
      error('String length mismatch')
    end
  elseif dtype == 'a' then
    readdata = {}
    chars, keys = _read_until(data, dataoffset, ':')
    dataoffset = dataoffset + chars + 2
    for i = 0, tonumber(keys) - 1 do
      key, ktype, kchars = unserialize(data, dataoffset)
      dataoffset = dataoffset + kchars
      value, vtype, vchars = unserialize(data, dataoffset)
      if vtype == 'a' then
        vchars = vchars + 1
      end
      dataoffset = dataoffset + vchars
      readdata[key] = value
    end
  elseif dtype == 'o' then
    readdata = {}
    chars, otchars = _read_until(data, dataoffset, ':')
    dataoffset = dataoffset + chars + 2
    otype = string.sub(data, dataoffset + 1, dataoffset + otchars)
    dataoffset = dataoffset + otchars + 2
    if otype == 'stdClass' then
      chars, properties = _read_until(data, dataoffset, ':')
      dataoffset = dataoffset + chars + 2
      for i = 0, tonumber(properties) - 1 do
        property, ktype, kchars = unserialize(data, dataoffset)
        dataoffset = dataoffset + kchars
        value, vtype, vchars = unserialize(data, dataoffset)
        if vtype == 'a' then
          vchars = vchars + 1
        end
        dataoffset = dataoffset + vchars
        -- Set the list element
        readdata[property] = value
      end
    else
      _unknown_type(dtype)
    end
  else
    _unknown_type(dtype)
  end
  return typeconvert(readdata), dtype, dataoffset - offset
end
-- 错误输出
function _unknown_type(type_)
  error('Unknown / Unhandled data type (' .. type_ .. ')!', 2)
end
-- 表格数据判断
function tableVIn(tbl, value)
  if tbl == nil then
      return false
  end

  for k, v in pairs(tbl) do
      if k == value then
          return true
      end
  end
  return false
end


local is_has,json_info,article_one
local key_nums = table.getn(KEYS)
-- return key_nums
-- 循环处理更多key
local article_list = {}
if next(KEYS) ~= nil then
    for k, key in pairs(KEYS) do
      local new_table = {}
      local article_lua,sertab
      local key_str = string.gsub(key,"article_","");

        -- 获取值
        article_lua =  redis.call('get',key)
        -- 进行序列化转换
         sertab      = unserialize(article_lua)
        --  判断是否创参数
        if next(ARGV) ~= nil then
            for k, agrv in pairs(ARGV) do
              --  进行表格判断数据
              is_has = tableVIn(sertab,agrv)
              if(is_has) 
              then 
                  new_table[agrv] = sertab[agrv] 
                end
            end
            --  格式转换

            article_list[key_str] = new_table
            article_one           = new_table
        else
            --  格式转换
            article_list[key_str] = sertab
            article_one           = sertab
    
        end
    end
    if(key_nums >1)
    then
      json_info =cjson.encode(article_list)
    else
      json_info =cjson.encode(article_one)

    end
    return json_info
else
    return json_info
end


-- local is_has,json_info
-- local new_table = {}
-- local key = KEYS[1]
-- -- 获取值
-- local article_lua =  redis.call('get',key)
-- -- 进行序列化转换
-- local sertab      = unserialize(article_lua)
-- -- 判断是否创参数
-- if next(ARGV) ~= nil then
--   for k, agrv in pairs(ARGV) do
--      --  进行表格判断数据
--      is_has = tableVIn(sertab,agrv)
--      if(is_has) 
--      then 
--         new_table[agrv] = sertab[agrv] 
--       end
--   end
--    --  格式转换
--   json_info = cjson.encode(new_table)
-- else
--    --  格式转换
--   json_info =cjson.encode(sertab)
 
-- end
-- -- 返回数据
-- return json_info

