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

    constructor: (@env) ->
        @age = 0

    setAgent: (@agent) ->

    read: ->
        throw 'NOT IMPLEMENTED'

    step: ->
        @age++
        # TODO sensors can break with age :)



class LocationSensor extends Sensor

    read: ->
        @env.read @agent, 'location'


class DirtSensor extends Sensor

    read: ->
        @env.read @agent, 'dirt'

class NegativeDirtSensor extends DirtSensor

    read: ->
        -1 * super()


class Actuator extends Thing

class MoveActuator extends Actuator

class CleanActuator extends Actuator


class Environment

    constructor: ->
        @id = 0
        @things = {}

    read_dirt: (agent) ->
        {id} = agent
        {x, y} = @things[id]
        # TODO: check grid[x][y] for Dirt Things
        Math.floor (Math.random() * 100)

    read: (who, what) ->
        #debugger
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

    step: ->
        for id, thing of @things
            thing.thing.step()
        null

class Room extends Environment



myProgram = (sensors, actuators) ->

    # Agent program persistence
    percepts = []

    sensors.on 'data', (data) ->
        #debugger
        percepts.push data

        console.log data

        # make decision based on percepts

        # then act!
        actuators.emit move: 'down'
        #actuators.emit clean: true


room = new Room width: 10, height: 10

reemba_A = new Reemba
    sensors:
        location: new LocationSensor room
        dirt: new DirtSensor room
    actuators:
        move: new MoveActuator room
        clean: new CleanActuator room
    program: myProgram


reemba_B = new Reemba
    sensors:
        location: new LocationSensor room
        dirt: new NegativeDirtSensor room
    actuators:
        move: new MoveActuator room
        clean: new CleanActuator room
    program: myProgram



dirt = new Dirt


room.add reemba_A,
    location:
        x: 0, y: 0

room.add reemba_B,
    location:
        x: 1, y: 1

room.add dirt,
    location:
        x:1, y: 1


for i in [1..10]
    room.step()
