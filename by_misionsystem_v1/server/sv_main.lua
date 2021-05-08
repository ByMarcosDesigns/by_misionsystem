ESX = nil 

Misions = {} 

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) 

RegisterServerEvent("by_missionsystem:savemission_sv")
AddEventHandler("by_missionsystem:savemission_sv", function(name, bytype, checkpoints)
    for _, checkpoint in pairs(checkpoints) do
        checkpoint.blip = nil
        checkpoint.coords = {x = checkpoint.coords.x, y = checkpoint.coords.y, z = checkpoint.coords.z}
        --print('{"x":'.. checkpoint.coords.x .. ', "y":' .. checkpoint.coords.y .. ', "z":' .. checkpoint.coords.z .. '}')
        --local coords = '{x = '.. checkpoint.coords.x .. ', y = ' .. checkpoint.coords.y .. ', z = ' .. checkpoint.coords.z .. '}'
        --local coords = '{"x":'.. checkpoint.coords.x .. ', "y":' .. checkpoint.coords.y .. ', "z":' .. checkpoint.coords.z .. '}'
        local coords = {["x"] = checkpoint.coords.x, ["y"] = checkpoint.coords.y, ["z"] = checkpoint.coords.z}

        print(name, coords, bytype)

        addMission(json.encode(bytype), json.encode(name), json.encode(coords))

    end
    --print(name)
end)

RegisterCommand('misiones', function(source, group)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    --print(group)
    TriggerClientEvent("by:OpenNui",source,group)
end, false)

ESX.RegisterServerCallback('by_missionsystem:getpeds', function(source, cb, name)
    MySQL.Async.fetchAll('SELECT * FROM by_missionsystem_npcs', {
    }, function(result)
        local resulth = {}
        print(result)
        if result ~= nil then 
            for i = 1, #result, 1 do
                table.insert(resulth, {['coords'] = json.decode(result[i]['coords']), ['bytype'] = json.decode(result[i]['bytype'])})
            end 
            cb(resulth)
        end
    end)
end)

ESX.RegisterServerCallback('by_missionsystem:getcoords', function(source, cb, name)
    MySQL.Async.fetchAll('SELECT * FROM by_missionsystem', {
    }, function(result)
        local resulth = {}
        print(result)
        if result ~= nil then 
            for i = 1, #result, 1 do
                table.insert(resulth, {['coords'] = json.decode(result[i]['coords']), ['name'] = json.decode(result[i]['name'])})
            end 
            cb(resulth)
        end
    end)
end)

RegisterServerEvent('by_missionsystem:rewardCam')
AddEventHandler('by_missionsystem:rewardCam', function()
    local _source = source 
    local xPlayer = ESX.GetPlayerFromId(_source)
    local reward = Config.Money.moneyCamionero

	xPlayer.addMoney(reward)
end)

RegisterServerEvent('by_missionsystem:rewardPil')
AddEventHandler('by_missionsystem:rewardPil', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local reward = Config.Money.moneyPiloto

	xPlayer.addMoney(reward)
end)

RegisterServerEvent('by_missionsystem:rewardMar')
AddEventHandler('by_missionsystem:rewardMar', function()
    local _source = source 
    local xPlayer = ESX.GetPlayerFromId(_source)
    local reward = Config.Money.moneyMaritimo

	xPlayer.addMoney(reward)
end)

ESX.RegisterServerCallback('by_missionsystem:getname', function(source, cb, pedname)
    print(pedname)
    local pedname = pedname
    MySQL.Async.fetchAll('SELECT * FROM by_missionsystem', {
        ['@name'] = name,
        ['@bytype'] = bytype,
    }, function(result)
        local resultname = {}
        print(result)
        if result ~= nil then
            for i = 1, #result, 1 do
                local typeped = json.decode(result[i]['bytype'])
                if typeped == pedname then
                    table.insert(resultname, {['name'] = json.decode(result[i]['name']), ['bytype'] = json.decode(result[i]['bytype']), typeped})
                end
            end 
            cb(resultname)
        end
    end)
end)

function addMission(bytype, name, coords)
    MySQL.Async.execute('INSERT INTO by_missionsystem (id, coords, name, bytype) VALUES (@id, @coords, @name, @bytype)', {
        ["@coords"] = coords,
        ["@bytype"] = bytype,
        ["@name"] = name

    })
end

function addNpc(bytype, coords)
    MySQL.Async.execute('INSERT INTO by_missionsystem_npcs (id, coords, bytype) VALUES (@id, @coords, @bytype)', {
        ["@coords"] = coords,
        ["@bytype"] = bytype,
    })
end
