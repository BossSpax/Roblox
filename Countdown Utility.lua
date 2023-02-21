--[[
Authors:    Ziffix, Cha
Version:    1.2.1 (Stable)
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
@param    self    countdown   | The countdown object
@return           void

Handles core countdown process.
]]
local function _countdownStart(self)
    _assertLevel(self, "Argument #1 missing or nil.", 1)

    local private = countdownPrivate[self]

    for secondsLeft = private.duration - 1, 0, -1 do
        task.wait(1)

        if secondsLeft == 0 then
            break
        end

        -- Countdown object was destroyed
        if private.tick == nil then
            return
        end

        private.tick:Fire(secondsLeft)
        private.secondsLeft = secondsLeft

        for _ in private.taskRemovalQueue do
            table.remove(private.tasks, table.remove(private.taskRemovalQueue, 1))
        end

        for _, taskInfo in private.tasks do
            if secondsLeft % taskInfo.Interval ~= 0 then
                continue
            end

            task.spawn(taskInfo.Task, secondsLeft)
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
function countdown.new(duration: number): Countdown
    _assertLevel(duration, "Argument #1 missing or nil.", 1)
    _assertLevel(duration % 1 == 0, "Expected integer, got decimal.", 1)

    local self = {}
    local private = {}
    
    private.duration = duration
    private.secondsLeft = duration

    private.tasks = {}
    private.taskRemovalQueue = {}

    private.tick = Instance.new("BindableEvent")
    private.finished = Instance.new("BindableEvent")

    self.tick = private.tick.Event
    self.finished = private.finished.Event

    countdownPrivate[self] = private

    return setmetatable(self, countdownPrototype)
end


--[[
@return   void

Begins synchronous countdown process.
]]
function countdownPrototype:start()
    local private = _assertLevel(countdownPrivate[self], "Cooldown object is destroyed", 1)
    
    task.spawn(_countdownStart, self)
end


--[[
@param    interval    number      | The interval at which the callback executes
@param    callback    function    | The function to be ran at the given interval
@return               string      | The GUID representing the task

Compiles interval and callback data into intervalTask repository.
]]
function countdownPrototype:addTask(interval: number, callback: (number) -> ()): string
    _assertLevel(interval, "Argument #1 missing or nil.", 1)
    _assertLevel(callback, "Argument #2 missing or nil.", 1)
    _assertLevel(interval % 1 == 0, "Expected integer, got decimal.", 1)

    local private = _assertLevel(countdownPrivate[self], "Cooldown object is destroyed", 1)

    local taskInfo = {

        Interval = interval,
        Task = callback,
        Id = httpService:GenerateGUID()

    }

    table.insert(private.tasks, taskInfo)

    return taskInfo.Id
end


--[[
@param    taskId    string    | The ID generated by countdown:addTask()
@return             void

Queues the associated task to be removed from the task repository.
]]
function countdownPrototype:removeTask(taskId: string)
    _assertLevel(taskId, "Argument #1 missing or nil.", 1)

    local private = _assertLevel(countdownPrivate[self], "Cooldown object is destroyed", 1)

    for index, taskInfo in private.tasks do
        if taskInfo.Id ~= taskId then
            continue
        end

        table.insert(private.taskRemovalQueue, index)

        return
    end

    error("Could not find a task by the given ID.", 2)
end


--[[
@return   number    | The seconds remaining in the countdown

Returns the seconds remaining in the countdown.
]]
function countdownPrototype:getSecondsLeft(): number
    local private = _assertLevel(countdownPrivate[self], "Cooldown object is destroyed", 1)

    return private.secondsLeft
end


--[[
@return   number    | The duration of the countdown

Returns the duration of the countdown.
]]
function countdownPrototype:getDuration(): number
    local private = _assertLevel(countdownPrivate[self], "Cooldown object is destroyed", 1)

    return private.duration
end


--[[
@return   void

Cleans up object data.
]]
function countdownPrototype:destroy()
    local private = _assertLevel(countdownPrivate[self], "Cooldown object is destroyed", 1)

    private.tick:Destroy()
    private.finished:Destroy()

    table.clear(private.tasks)

    countdownPrivate[self] = nil
end



countdownPrototype.__index = countdownPrototype
countdownPrototype.__newindex = function() end
countdownPrototype.__metatable = "This metatable is locked."

export type Countdown = typeof(countdown.new(0))

return countdown
