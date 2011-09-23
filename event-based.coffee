events = require 'events'


class Thing
    @ids = {}
    constructor: (config) ->
        @constructor.ids[@constructor.name] ?= 0
        @type = @constructor.name
        @id = "#{@type}-#{@constructor.ids[@type]++}"

        for prop, value of properties
            @things[id][prop] = value

    step: ->


class Agent extends Thing

    constructor: (config) ->
        {@sensors, @actuators, @program} = config
        for type, sensor of @sensors
            sensor.setAgent this
        @sensorEmitter = new events.EventEmitter
        @actuatorsEmitter = new events.EventEmitter
        super config
        @program @id, @sensorEmitter, @actuatorsEmitter

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

    constructor: (@em) ->
        @age = 0

    setAgent: (@agent) ->

    read: ->
        throw 'NOT IMPLEMENTED'

    step: ->
        @age++
        # TODO sensors can break with age :)



class LocationSensor extends Sensor

    read: ->
        @em.read @agent, 'location'


class DirtSensor extends Sensor

    read: ->
        @em.read @agent, 'dirt'

class NegativeDirtSensor extends DirtSensor

    read: ->
       not super()


class Actuator extends Thing

class MoveActuator extends Actuator


class CleanActuator extends Actuator


class EnvironmentManager

    constructor: (@env) ->
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

    add: (thing) ->
        id = thing.id
        @things[id] = {}
        @env.add thing

    step: ->
        for id, thing of @things
            thing.thing.step()
        null


class Environment
    constructor: (config) ->
        {@width, @height} = config
        # grid as multidimensional array
        @grid = for x in [0..@width-1]
            for y in [0..@height-1]
                []

    add: (thing) ->
        {location: {x, y}} = location
        @grid[x][y].push thing

    get: (x, y) ->
        @grid[x][y]

    set: (x, y, fn) ->
        @grid[x][y] = fn @grid[x][y]


myProgram = (id, sensors, actuators) ->

    # Agent program persistence
    percepts = []

    sensors.on 'data', (data) ->
        percepts.push data

        console.log id, data

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
    location:
        x: 0, y: 0


reemba_B = new Reemba
    sensors:
        location: new LocationSensor master
        dirt: new DirtSensor master
    actuators:
        move: new MoveActuator master
        clean: new CleanActuator master
    program: myProgram
    location:
        x: 1, y: 1



dirt = new Dirt
    location:
        x:1, y: 1


master.add reemba_A
master.add reemba_B
master.add dirt

console.log room.grid

for i in [1..10]
    master.step()
