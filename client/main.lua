local QBCore = exports['qb-core']:GetCoreObject()


local headerShown = false
local sendData = nil

-- Functions

local function sortData(data, skipfirst)
    local header = data[1]
    local tempData = data
    if skipfirst then table.remove(tempData,1) end
    table.sort(tempData, function(a,b) return a.header < b.header end)
    if skipfirst then table.insert(tempData,1,header) end
    return tempData
end

local function openMenu(data, sort, skipFirst)
    if not data or not next(data) then return end
    if sort then data = sortData(data, skipFirst) end
	for _,v in pairs(data) do
		if v["icon"] then
			local img = "ox_inventory/web/images/"
			if QBCore.Shared.Items[tostring(v["icon"])] then
				if not string.find(QBCore.Shared.Items[tostring(v["icon"])].image, "images/") then
					img = img.."images/"
				end
				v["icon"] = img..QBCore.Shared.Items[tostring(v["icon"])].image
			end
		end
	end
    SetNuiFocus(true, true)
    headerShown = false
    sendData = data
    SendNUIMessage({
        action = 'OPEN_MENU',
        data = table.clone(data)
    })
end

local function closeMenu()
    sendData = nil
    headerShown = false
    SetNuiFocus(false)
    SendNUIMessage({
        action = 'CLOSE_MENU'
    })
end

local function showHeader(data)
    if not data or not next(data) then return end
    headerShown = true
    sendData = data
    SendNUIMessage({
        action = 'SHOW_HEADER',
        data = table.clone(data)
    })
end

-- Events

RegisterNetEvent('qb-menu:client:openMenu', function(data, sort, skipFirst)
    openMenu(data, sort, skipFirst)
end)

RegisterNetEvent('qb-menu:client:closeMenu', function()
    closeMenu()
end)

-- NUI Callbacks

RegisterNUICallback('clickedButton', function(option, cb)
    if headerShown then headerShown = false end
    PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', 1)
    SetNuiFocus(false)
    if sendData then
        local data = sendData[tonumber(option)]
        sendData = nil
        if data then
            if data.params.event then
                if data.params.isServer then
                    TriggerServerEvent(data.params.event, data.params.args)
                elseif data.params.isCommand then
                    ExecuteCommand(data.params.event)
                elseif data.params.isQBCommand then
                    TriggerServerEvent('QBCore:CallCommand', data.params.event, data.params.args)
                elseif data.params.isAction then
                    data.params.event(data.params.args)
                else
                    TriggerEvent(data.params.event, data.params.args)
                end
            end
        end
    end
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    headerShown = false
    sendData = nil
    SetNuiFocus(false)
    cb('ok')
    TriggerEvent("qb-menu:client:menuClosed")
end)

-- Command and Keymapping

RegisterCommand('playerfocus', function()
    if headerShown then
        SetNuiFocus(true, true)
    end
end)

RegisterKeyMapping('playerFocus', 'Give Menu Focus', 'keyboard', 'LMENU')

-- Exports

exports('openMenu', openMenu)
exports('closeMenu', closeMenu)
exports('showHeader', showHeader)

-- Test command (临时测试，验证本地化字体/图标后可删除)
RegisterCommand('testmenu', function()
    openMenu({
        { isMenuHeader = true, header = '测试菜单 Test Menu', txt = '中文 + English mixed' },
        { header = '解决方案 Item One', txt = '这是一段中文说明 with English', icon = 'fas fa-bolt',
          params = { event = 'chat:addMessage', args = { color = {0,255,0}, args = {'测试', '点击了第 1 项 (item 1 clicked)'} } } },
        { header = '武器 Weapons', txt = '图标测试：fa-gun', icon = 'fas fa-gun',
          params = { event = 'chat:addMessage', args = { color = {255,165,0}, args = {'测试', 'item 2'} } } },
        { header = '背包 Inventory', txt = '车辆 / 商店 / 任务', icon = 'fas fa-briefcase',
          params = { event = 'chat:addMessage', args = { color = {0,150,255}, args = {'测试', 'item 3'} } } },
        { header = '不可用项 Disabled', txt = '此项被禁用', disabled = true, icon = 'fas fa-ban' },
        { header = '关闭 Close', icon = 'fas fa-xmark',
          params = { event = 'qb-menu:client:closeMenu' } },
    })
end, false)
