local QBCore = exports[Config.CoreName]:GetCoreObject()

QBCore.Functions.CreateCallback('PackageDeliverReward', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local money = Config.PackageDeliverReward
	Player.Functions.AddMoney('cash', money)
    cb(money)
end)

RegisterServerEvent("glx-weedruns:server:Packedweedadd", function()
    local src = source 
    local Player =  QBCore.Functions.GetPlayer(src)
    Player.Functions.AddItem('packaged_weed', 1)
end)

RegisterServerEvent("glx-weedruns:server:Packedweedremove", function()
    local src = source 
    local Player =  QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem('packaged_weed', 1)
end)