events = require 'events'


class Thing

    constructor: (config) ->

    step: ->


class Agent extends Thing

    constructor: (config) ->
        {@sensors, @actuators, @program} = config
        for type, sensor of @sensors
            sensor.setAgent this
        @sensorEmitter = new events.EventEmitter
        @actuatorsEmitter = new events.EventEmitter
        @program @sensorEmitter, @actuatorsEmitter
        super config

    step: ->
        @sense()

    sense: ->
        data = {}
        for type, sensor of @sensors
            data[type] = sensor.read()
        @sensorEmitter.emit 'data', data


class Reemba extends Agent


class Dirt extends Thing

    constructor: ->
        @difficult = 1

    step: ->
        # After each step dirt becomes more difficult to remove
        @difficult++


class Wall extends Thing


class Sensor extends Thing

    constructor: (@envMan) ->
        @age = 0

    setAgent: (@agent) ->

    read: ->
        throw 'NOT IMPLEMENTED'

    step: ->
        @age++
        # TODO sensors can break with age :)



class LocationSensor extends Sensor

    read: ->
        @envMan.read @agent, 'location'


class DirtSensor extends Sensor

    read: ->
        @envMan.read @agent, 'dirt'

class NegativeDirtSensor extends DirtSensor

    read: ->
       not super()


class Actuator extends Thing

class MoveActuator extends Actuator


class CleanActuator extends Actuator


class EnvironmentManager

    constructor: (@env) ->
        @id = 0
        @things = {}

    read_dirt: (agent) ->
        {id} = agent
        {location: {x, y}} = @things[id]
        # check x, y for Dirt Things
        (@env.get x, y).some (thing) -> thing instanceof Dirt

    read: (who, what) ->
        switch what
            when 'dirt'
                @read_dirt who
            else
                @things[who.id][what]

    add: (thing, properties) ->
        id = "id-#{@id++}"
        thing.id = id
        @things[id] = {}
        for prop, value of properties
            @things[id][prop] = value
        @things[id].thing = thing
        if properties.location?
            @env.add thing, properties.location

    step: ->
        for id, thing of @things
            thing.thing.step()
        null


class Environment
    constructor: (config) ->
        # 2D grid for now
        {@width, @height} = config
        # grid as multidimensional array
        @grid = for x in [0..@width-1]
            for y in [0..@height-1]
                []

    add: (thing, location) ->
        {x, y} = location
        @grid[x][y].push thing

    get: (x, y) ->
        @grid[x][y]

    set: (x, y, fn) ->
        @grid[x][y] = fn @grid[x][y]


myProgram = (sensors, actuators) ->

    # Agent program persistence
    percepts = []

    sensors.on 'data', (data) ->
        percepts.push data

        console.log data

        # make decision based on percepts

        # then act!
        actuators.emit move: 'down'
        #actuators.emit clean: true


room = new Environment width: 10, height: 10
master = new EnvironmentManager room

reemba_A = new Reemba
    sensors:
        location: new LocationSensor master
        dirt: new DirtSensor master
    actuators:
        move: new MoveActuator master
        clean: new CleanActuator master
    program: myProgram


reemba_B = new Reemba
    sensors:
        location: new LocationSensor master
        dirt: new DirtSensor master
    actuators:
        move: new MoveActuator master
        clean: new CleanActuator master
    program: myProgram



dirt = new Dirt


master.add reemba_A,
    location:
        x: 0, y: 0

master.add reemba_B,
    location:
        x: 1, y: 1

master.add dirt,
    location:
        x:1, y: 1

console.log room.grid

for i in [1..10]
    master.step()
