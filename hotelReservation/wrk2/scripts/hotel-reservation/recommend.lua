local socket = require("socket")
math.randomseed(socket.gettime()*1000)
math.random(); math.random(); math.random()

local url = "http://localhost:5000"

local function recommend()
  local coin = math.random()
  local req_param = ""
  if coin < 0.33 then
    req_param = "dis"
  elseif coin < 0.66 then
    req_param = "rate"
  else
    req_param = "price"
  end

  local lat = 38.0235 + (math.random(0, 481) - 240.5)/1000.0
  local lon = -122.095 + (math.random(0, 325) - 157.0)/1000.0

  local method = "GET"
  local path = url .. "/recommendations?require=" .. req_param .. 
    "&lat=" .. tostring(lat) .. "&lon=" .. tostring(lon)
  local headers = {}
  -- headers["Content-Type"] = "application/x-www-form-urlencoded"
  return wrk.format(method, path, headers, nil)
end

request = function()
  return recommend(url)
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