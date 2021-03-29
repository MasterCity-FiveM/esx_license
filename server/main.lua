ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function AddLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (@type, @owner)', {
			['@type']  = type,
			['@owner'] = xPlayer.identifier
		}, function(rowsChanged)
			if cb then
				cb()
			end
		end)
	else
		if cb then
			cb()
		end
	end
end

function RemoveLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		MySQL.Async.execute('DELETE FROM user_licenses WHERE type = @type AND owner = @owner', {
			['@type'] = type,
			['@owner'] = xPlayer.identifier
		}, function(rowsChanged)
			if cb then
				cb()
			end
		end)
	else
		if cb then
			cb()
		end
	end
end

function GetLicense(type, cb)
	MySQL.Async.fetchAll('SELECT label FROM licenses WHERE type = @type', {
		['@type'] = type
	}, function(result)
		local data = {
			type  = type,
			label = result[1].label
		}

		cb(data)
	end)
end

function GetLicenses(target, cb)
	local xPlayer = ESX.GetPlayerFromId(target)

	MySQL.Async.fetchAll('SELECT type FROM user_licenses WHERE owner = @owner limit 10', {
		['@owner'] = xPlayer.identifier
	}, function(result)
		local licenses, asyncTasks = {}, {}

		for i=1, #result, 1 do
			local scope = function(type)
				table.insert(asyncTasks, function(cb)
					MySQL.Async.fetchAll('SELECT label FROM licenses WHERE type = @type', {
						['@type'] = type
					}, function(result2)
						table.insert(licenses, {
							type  = type,
							label = result2[1].label
						})

						cb()
					end)
				end)
			end

			scope(result[i].type)
		end

		Async.parallel(asyncTasks, function(results)
			cb(licenses)
		end)
	end)
end

function CheckLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM user_licenses WHERE type = @type AND owner = @owner', {
			['@type'] = type,
			['@owner'] = xPlayer.identifier
		}, function(result)
			if tonumber(result[1].count) > 0 then
				cb(true)
			else
				cb(false)
			end
		end)
	else
		cb(false)
	end
end

function GetLicensesList(cb)
	MySQL.Async.fetchAll('SELECT type, label FROM licenses', {
		['@type'] = type
	}, function(result)
		local licenses = {}

		for i=1, #result, 1 do
			table.insert(licenses, {
				type  = result[i].type,
				label = result[i].label
			})
		end

		cb(licenses)
	end)
end

RegisterNetEvent('esx_license:addLicense')
AddEventHandler('esx_license:addLicense', function(target, type, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_license:addLicense', {target = target, type = type})
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.job.name == "police" or xPlayer.getRank() > 0 then
		return
	end
	
	AddLicense(target, type, cb)
end)

RegisterNetEvent('esx_license:removeLicense')
AddEventHandler('esx_license:removeLicense', function(target, type, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_license:removeLicense', {target = target, type = type})
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.job.name == "police" or xPlayer.getRank() > 0 then
		return
	end
	
	RemoveLicense(target, type, cb)
end)

AddEventHandler('esx_license:getLicense', function(type, cb)
	GetLicense(type, cb)
end)

AddEventHandler('esx_license:getLicenses', function(target, cb)
	GetLicenses(target, cb)
end)

AddEventHandler('esx_license:checkLicense', function(target, type, cb)
	CheckLicense(target, type, cb)
end)

AddEventHandler('esx_license:getLicensesList', function(cb)
	GetLicensesList(cb)
end)

ESX.RegisterServerCallback('esx_license:getLicense', function(source, cb, type)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_license:getLicense', {type = type})
	GetLicense(type, cb)
end)

ESX.RegisterServerCallback('esx_license:getLicenses', function(source, cb, target)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_license:getLicenses', {target = target})
	GetLicenses(target, cb)
end)

ESX.RegisterServerCallback('esx_license:checkLicense', function(source, cb, target, type)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_license:checkLicense', {target = target, type = type})
	CheckLicense(target, type, cb)
end)

ESX.RegisterServerCallback('esx_license:getLicensesList', function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_license:getLicensesList', {})
	GetLicensesList(cb)
end)