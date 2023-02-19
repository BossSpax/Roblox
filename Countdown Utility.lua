--[[

    Authors:    Ziffix, Cha
    Version:    1.1.9 (Semi-stable)
    Date:       23/2/19

]]



local httpService = game:GetService("HttpService")

local countdown = {}
local countdownPrototype = {}

local countdownPrivate = {}



--[[
    @param    condition   boolean   | The result of the condition
    @param    message     string    | The error message to be raised
    @param    level = 1   number?   | The level at which to raise the error
    @return               void

    Implements assert with error's level argument.
]]
local function _assertLevel(condition: boolean, message: string, level: number?)
    assert(condition, "Argument #1 missing or nil.")
    assert(message, "Argument #2 missing or nil.")

    level = (level or 0) + 1

    if condition then
        return condition
    end

    error(message, level)
end


--[[
    @param    self    countdown   | The countdown object
    @return           void

    Handles core countdown process.
]]
local function _countdownStart(self)
    _assertLevel(self, "Argument #1 missing or nil.", 2)

    local private = countdownPrivate[self]

    for secondsLeft = private.duration - 1, 1, -1 do
        task.wait(1)

        if private.active == false then
            coroutine.yield()    
        end
        
        -- Countdown object was destroyed
        if private.tick == nil then
            return
        end

        private.tick:Fire(secondsLeft)
        private.secondsLeft = secondsLeft

        for _, taskInfo in private.intervalTasks do
            if secondsLeft % taskInfo.Interval ~= 0 then
                continue
            end

            if secondsLeft ~= 0 then
                task.spawn(taskInfo.Task)
            end
        end
    end

    -- Countdown object was destroyed
    if private.finished == nil then
        return
    end

    private.finished:Fire()
end


--[[
    @param    duration    number      | The duration of the countdown
    @return               countdown   | The generated countdown object

    Generates a countdown object.
]]
function countdown.new(duration: number)
    _assertLevel(duration, "Argument #1 missing or nil.", 2)
    _assertLevel(duration % 1 == 0, "Expected integer, got decimal.", 2)

    local self = setmetatable({}, countdownPrototype)
    local private = {}

    private.active = false
    private.thread = nil
    private.secondsLeft = duration
    private.intervalTasks = {}

    private.tick = Instance.new("BindableEvent")
    private.finished = Instance.new("BindableEvent")

    self.Tick = private.tick.Event
    self.Finished = private.finished.Event

    countdownPrivate[self] = private

    return self
end


--[[
    @return   void

    Begins synchronous countdown process.
]]
function countdownPrototype:start()
    local private = _assertLevel(cooldownPrivate[self], "Cooldown object is destroyed", 2)
    
    private.active = true
    private.thread = task.spawn(_countdownStart, self)
end


--[[
    @param    interval    number      | The interval at which the callback executes
    @param    callback    function    | The function to be ran at the given interval
    @return               string      | The GUID representing the task

    Compiles interval and callback data into intervalTask repository.
]]
function countdownPrototype:addTask(interval: number, callback: (number) -> ()): string
    _assertLevel(interval, "Argument #1 missing or nil.", 2)
    _assertLevel(callback, "Argument #2 missing or nil.", 2)
    _assertLevel(interval % 1 == 0, "Expected integer, got decimal.", 2)

    local private = _assertLevel(cooldownPrivate[self], "Cooldown object is destroyed", 2)

    local taskInfo = {

        Interval = interval,
        Task = callback,
        TaskId = httpService:GenerateGUID()

    }

    table.insert(private.intervalTasks, taskInfo)

    return taskInfo.TaskId
end


--[[
    @param    taskId    string    | The ID generated by countdown:addTask()
    @return             void

    Removes the associated task from the interval repository.
]]
function countdownPrototype:removeTask(taskId: string)
    _assertLevel(taskId, "Argument #1 missing or nil.", 2)
    
    local private = _assertLevel(cooldownPrivate[self], "Cooldown object is destroyed", 2)

    for index, taskInfo in private.intervalTasks do
        if taskInfo.id ~= taskId then
            continue
        end

        table.remove(private.intervalTasks, index)

        return
    end

    error("Could not find a task by the given ID.", 2)
end


--[[
    @return   void

    Pauses the countdown.
]]
function countdownPrototype:pause()
    local private = _assertLevel(cooldownPrivate[self], "Cooldown object is destroyed", 2)
    
    if coroutine.status(private.thread) == "suspended" then
        warn("Countdown is already paused")
        
        return
    end
    
    private.active = false
end


--[[
    @return   void

    Resumes the countdown.
]]
function countdownPrototype:resume()
    local private = _assertLevel(cooldownPrivate[self], "Cooldown object is destroyed", 2)
    
    if coroutine.status(private.thread) == "running" then
        warn("Countdown is already active")
        
        return
    end
    
    private.active = true
    
    coroutine.resume(private.thread)
end


--[[
    @return   boolean   | The state of the cooldown proccess

    Returns a boolean detailing whether or not the countdown is active.
]]
function countdownPrototype:isPaused(): boolean
    local private = _assertLevel(cooldownPrivate[self], "Cooldown object is destroyed", 2)
    
    return private.active
end


--[[
    @return   number    | The seconds remaining in the countdown

    Returns the seconds remaining in the countdown.
]]
function countdownPrototype:getSecondsLeft(): number
    local private = _assertLevel(cooldownPrivate[self], "Cooldown object is destroyed", 2)

    return private.secondsLeft
end


--[[
    @return   void

    Cleans up object data.
]]
function countdownPrototype:destroy()    
    local private = _assertLevel(cooldownPrivate[self], "Cooldown object is destroyed", 2)

    if coroutine.status(private.thread) == "suspended" then
        coroutine.close(private.thread) 
    end
    
    private.tick:Destroy()
    private.finished:Destroy()

    table.clear(private.intervalTasks)

    cooldownPrivate[self] = nil
end



countdownPrototype.__index = countdownPrototype
countdownPrototype.__newindex = function() end
countdownPrototype.__metatable = "This metatable is locked."

return countdown
