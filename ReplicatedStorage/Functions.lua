local Functions = {}

local ids = {}

function Functions:getId(iteration)
	local id = string.gsub('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'x', function ()
		return utf8.char(math.random(0,127))
	end)

	if table.find(ids, id) then
		if iteration and iteration > 10 then -- extra fallback for dupe ids
			task.wait()
		end
		return Functions:getId(if iteration then iteration+1 else 1) -- call the function again
	else
		table.insert(ids, id)
		return id
	end
end

return Functions