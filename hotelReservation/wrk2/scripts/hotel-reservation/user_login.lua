local socket = require("socket")
math.randomseed(socket.gettime()*1000)
math.random(); math.random(); math.random()

local url = "http://localhost:5000"

local function get_user()
  local id = math.random(0, 500)
  local user_name = "Cornell_" .. tostring(id)
  local pass_word = ""
  for i = 0, 9, 1 do 
    pass_word = pass_word .. tostring(id)
  end
  return user_name, pass_word
end

local function user_login()
  local user_name, password = get_user()
  local method = "POST"
  local path = url .. "/user?username=" .. user_name .. "&password=" .. password
  local headers = {}
  -- headers["Content-Type"] = "application/x-www-form-urlencoded"
  return wrk.format(method, path, headers, nil)
end

request = function()
  return user_login(url)
end

function done(summary, latency, requests)
  print(string.format("Total Requests: %d", summary.requests))
  print(string.format("HTTP errors: %d", summary.errors.status))
  print(string.format("Requests timed out: %d", summary.errors.timeout)) 
  print(string.format("Bytes received: %d", summary.bytes))
  print(string.format("Socket connect errors: %d", summary.errors.connect))
  print(string.format("Socket read errors: %d", summary.errors.read))
  print(string.format("Socket write errors: %d", summary.errors.write))
end