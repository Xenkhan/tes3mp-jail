
tableHelper = require("tableHelper")
require("actionTypes")
require("time")


--[[

jail = require("jail")

on player/base.lua and server.lua

]]--


local Functions = {}
Functions.Data = {}

Functions.Init = function()  --Call on OnServerInit after mymod
	Functions.Data = jsonInterface.load("jail.json")
	
end

Functions.Save = function() --Call OnServerExit after mymod
	jsonInterface.save("jail.json", Functions.Data)

end

Functions.TeleportPlayer = function(pid) 
	local cellName = Functions.Data.jailData.cell
	local x = tonumber(Functions.Data.jailData.posx)
	local y = tonumber(Functions.Data.jailData.posy)
	local z = tonumber(Functions.Data.jailData.posz)
	
	tes3mp.SetCell(pid, cellName)
	tes3mp.SendCell(pid)
	tes3mp.SetPos(pid, x, y, z)
	tes3mp.SendPos(pid)
end

Functions.UnjailPlayer = function(pid)
	local name = Players[pid].name
    
    if Functions.Data.jailed[name] == nil then
    	return
    end

    tes3mp.Resurrect(pid, actionTypes.resurrect.IMPERIAL_SHRINE)
    tes3mp.Jail(pid, tonumber(Functions.Data.jailed[name].jailTime) / Functions.Data.jailRate, true, true, "Spending time in Jail", "You have been unjailed.")

    tes3mp.LogMessage(0, name .. " unjailed \n")


    tes3mp.SendMessage(pid, color.Error ..Functions.Data.jailMessage.onunjail .. color.Default, false)
    Functions.Data.jailed[name] = nil
    jsonInterface.save("jail.json", Functions.Data)
end


--[[

	  elseif jail.ParseCommand(pid, cmd, moderator) == true then
	                
	  else
	     local message = "Not a valid command. Type /help for more info.\n"
	      tes3mp.SendMessage(pid, color.Error..message..color.Default, false)
	  end

  return false -- commands should be hidden
  end
	
	at end of OnPlayerSendMessage

]]--

Functions.ParseCommand = function(pid, cmd, isMod)
	local name = Players[pid].name

	local targetpid = tonumber(cmd[2])
	if Players[targetpid] == nil then
		return false
	end
	

	if cmd[1] == "jail" and cmd[2] ~= nil and cmd[3] ~= nil and tableHelper.containsValue(Functions.Data.jailers, name) == true then
			
		
		if Functions.Data.jailed[name] == nil then
			local jailed = {}
			jailed.startTime = os.time(os.date("!*t"))
			jailed.jailTime = tonumber(cmd[3])
			jail.jailer = Players[pid].name
			
			
			Functions.Data.jailed[name] = jailed
			
			jsonInterface.save("jail.json", Functions.Data)
			
			tes3mp.SendMessage(pid, color.Green .. "User jailed.     \n".. color.Default, false)
			

			

			Functions.TeleportPlayer(targetpid)
			tes3mp.SendMessage(targetpid, color.Error .. Functions.Data.jailMessage.onjail .. color.Default, false)
			
			
		
			Players[pid].unjailTimer = tes3mp.CreateTimerEx("UnjailPlayer", time.seconds(jailed.jailTime), "i", targetpid)
			tes3mp.StartTimer(Players[pid].unjailTimer)


		else
			tes3mp.SendMessage(pid, color.Error .. "User is already jailed. \n".. color.Default, false)
		end
	
	elseif cmd[1] == "addJailer" and cmd[2] ~= nil and isMod then
		table.insert(Functions.Data.jailers, Players[targetpid].name)
		jsonInterface.save("jail.json", Functions.Data)

		tes3mp.SendMessage(pid, color.Green .. "User added to people able to jail.     \n" .. color.Default, false)

	elseif cmd[1] == "removeJailer" and cmd[2] ~= nil and isMod then

		Functions.Data.jailers[Players[targetpid].name] = nil
  		jsonInterface.save("jail.json", Functions.Data)

		tes3mp.SendMessage(pid, color.Green .. "User removed from people able to jail.     \n" .. color.Default, false)
	elseif cmd[1] == "unjail" and cmd[2] ~= nil and tableHelper.containsValue(Functions.Data.jailers, name) == true then
		UnjailPlayer(targetpid)

		tes3mp.SendMessage(pid, color.Green .. "User unjailed.     \n" .. color.Default, false)

		
	else
		return false
	end
	
	return true
end

Functions.CheckCellChange = function(pid) --OnPlayerCellChange after mymod
	local name = Players[pid].name
	
	if Functions.Data.jailed[name] ~= nil and Players[pid].loggedIn then

		local cellName = tes3mp.GetCell(pid)
		
		tes3mp.LogMessage(0, cellName .. " " .. Functions.Data.jailData.cell)

		if cellName ~= Functions.Data.jailData.cell then

		

			Functions.TeleportPlayer(pid)
			tes3mp.SendMessage(pid, color.Error .. Functions.Data.jailMessage.onleave .. color.Default, false)

		end
	end
end

Functions.JailedRejoin = function(pid) -- player/base.lua line 156
	local name = Players[pid].name

	if Functions.Data.jailed[name] ~= nil then
		local currentTime = os.time(os.date("!*t"))
		local startTime = tonumber(Functions.Data.jailed[name].startTime)
		
		local jailTime = tonumber(Functions.Data.jailed[name].jailTime)
		local elapsedTime = startTime - currentTime
		
	

		if startTime < jailTime + currentTime then
			UnjailPlayer(pid)
			
			return
		end
		
		Players[pid].unjailTimer = tes3mp.CreateTimerEx("UnjailPlayer", time.seconds(jailTime), "i", pid)
		tes3mp.StartTimer(Players[pid].unjailTimer)
	end
end



return Functions