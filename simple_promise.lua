simple_promise = simple_promise or {}
local STATE_PENDING = 1
local STATE_FULFILLED = 2
local STATE_REJECTED = 3
local table_insert = table.insert
local setmetatable = setmetatable
local PROMISE_META = {}
PROMISE_META.__index = PROMISE_META
function PROMISE_META:resolve(result)
	if self[1] == STATE_PENDING then
		self[1] = STATE_FULFILLED
		self[2] = result
		for _, callback in ipairs(self[3]) do
			self[2] = callback(result)
		end
	end
end

function PROMISE_META:reject(result)
	if self[1] == STATE_PENDING then
		self[1] = STATE_REJECTED
		self[2] = result
		for _, callback in ipairs(self[4]) do
			self[2] = callback(result)
		end
	end
end

function PROMISE_META:_then(thenFunc)
	if self[1] == STATE_FULFILLED then
		self[2] = thenFunc(self[2])
	elseif self[1] == STATE_PENDING then
		table_insert(self[3], thenFunc)
	end
	return self
end

function PROMISE_META:catch(catchFunc)
	if self[1] == STATE_REJECTED then
		self[2] = catchFunc(self[2])
	elseif self[1] == STATE_PENDING then
		table_insert(self[4], catchFunc)
	end
	return self
end

function simple_promise:new_promise(func)
	local promise = setmetatable({}, PROMISE_META)
	promise[1] = STATE_PENDING
	promise[2] = nil
	promise[3] = {}
	promise[4] = {}
	func(function(result) promise:resolve(result) end, function(result) promise:reject(result) end)
	return promise
end

function simple_promise:promise_all(promises)
	return self:new_promise(function(resolve, reject)
		local results = {}
		local remaining = #promises
		for _, promise in ipairs(promises) do
			promise:_then(function(result)
				table.insert(results, result)
				remaining = remaining - 1
				if remaining == 0 then resolve(results) end
			end):catch(function(error) reject(error) end)
		end
	end)
end