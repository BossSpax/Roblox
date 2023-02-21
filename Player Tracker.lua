--[[
Authors:    Ziffix
Version:    1.3.0 (Stable)
Date:       23/2/20
]]



local runService = game:GetService("RunService")
local players = game:GetService("Players")
 
local playerTracker = {}
local playerTrackerPrototype = {}
local playerTrackerPrivate = {}
 
 

--[[
@param    condition   any       | The result of the condition
@param    message     string    | The error message to be raised
@param    level = 1   number?   | The level at which to raise the error
@return               void
Implements assert with error's level argument.
]]
local function _assertLevel(condition: any, message: string, level: number?)
    assert(condition, "Argument #1 missing or nil.")
    assert(message, "Argument #2 missing or nil.")

    level = (level or 0) + 1

    if condition then
        return condition
    end

    error(message, level)
end


--[[
@param    parts   Array<BasePart>               | The array of BaseParts to scan
@return           Dictionary<Player, boolean>   | A dictionary of the players found

Processes array of BaseParts for affiliated Player instances. Filters out dead players.
]]
local function _analyzePartsForPlayers(parts: {BasePart}): {[Player]: boolean}
    local playersFound = {}
 
    for _, part in parts do
        local character = part.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
    
        if humanoid == nil or humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
            continue
        end
    
        local player = players:GetPlayerFromCharacter(character)
    
        if player == nil then
            continue
        end
    
        playersFound[player] = true
    end
 
    return playersFound
end


--[[
@param    playerTracker   PlayerTracker   | The array of BaseParts to scan
@return                   void

Updates the PlayerTracker's internal map of Players, and population.
]]
local function _updatePlayerTracker(playerTracker: PlayerTracker, parts: {BasePart})
    local private = playerTrackerPrivate[playerTracker]
 
    local currentPlayers = private.Players
    local currentPopulation = private.Population
    local capacity = private.Capacity
 
    local newPlayers = _analyzePartsForPlayers(parts)
 
    for player in newPlayers do
        if capacity and private.Population >= capacity then
            break
        end
 
        if currentPlayers[player] then
            continue
        end
 
        private.Population += 1
        private.PopulationChanged:Fire(private.Population)
        private.PlayerEntered:Fire(player)
    end
 
    for player in currentPlayers do
        if newPlayers[player] then
            continue
        end
    
        currentPlayers[player] = nil
 
        private.Population -= 1
        private.PopulationChanged:Fire(private.Population)
        private.PlayerLeft:Fire(player)
    end
end
 
 
--[[
@param    trackingSpace         BasePart          | The BasePart that will be scanned for players
@param    capacity              number?           | The maximum number of players the tracker will process
@param    trackingParameters    OverlapParams?    | The OverlapParams for the tracking query
@return                         PlayerTracker     | The generated PlayerTracker object

Generates a PlayerTracker object.
]]
function playerTracker.new(trackingSpace: BasePart, capacity: number?, trackingParameters: OverlapParams?): PlayerTracker
    local self = {}
    local private = {}
        
    private.IsTracking = false
    private.TrackingSpace = TrackingSpace
    private.TrackingParameters = TrackingParameters
    private.TrackingConnection = nil
 
    private.Players = {}
    private.Population = 0
    private.Capacity = capacity
  
    private.PlayerLeft = Instance.new("BindableEvent")
    private.PlayerEntered = Instance.new("BindableEvent")
    private.PopulationChanged = Instance.new("BindableEvent")
 
    self.PlayerLeft = private.PlayerLeft.Event
    self.PlayerEntered = private.PlayerEntered.Event
    self.PopulationChanged = private.PopulationChanged.Event
  
    playerTrackerPrivate[self] = private
 
    trackingSpace.Destroying:Connect(function()
        self:Destroy()
    end)
 
    return setmetatable(self, playerTrackerPrototype)
end
 


--[[
@return   void

Generates a PlayerTracker object.
]]
function playerTrackerPrototype:StartTracking()
    local private = playerTrackerPrototype[self]
 
    if private.IsTracking then
        warn("PlayerTracker is already tracking.")
    
        return
    end
  
    private.IsTracking = true
        
    local trackingSpace = private.TrackingSpace
    local trackingParameters = private.TrackingParameters
 
    private.TrackingConnection = RunService.Heartbeat:Connect(function()
        _updatePlayerTracker(
            self,
            workspace:GetPartBoundsInBox(trackingSpace.CFrame, trackingSpace.Size, trackingParameters)
        )
    end)
end
 
function playerTrackerPrototype:StopTracking()
    local TrackerData = PlayerTrackerData[self]
    
    TrackerData.SpaceTrackingConnection:Disconnect()
    TrackerData.IsTracking = false
end
 
function playerTrackerPrototype:Destroy()
    if (PlayerTrackerData[self] ~= nil) then
        self:StopTracking()
        
        PlayerTrackerData[self] = nil
    end
end
 
 
function playerTrackerPrototype:GetPlayers()
    local Players = {}
 
    for Player in PlayerTrackerData[self].Players do
        table.insert(Players, Player)
    end
 
    return Players
end
 
function playerTrackerPrototype:GetPopulation()
    return PlayerTrackerData[self].Population
end
 
 
playerTrackerPrototype.__index = playerTrackerPrototype
playerTrackerPrototype.__metatable = "This metatable is locked."

return PlayerTracker