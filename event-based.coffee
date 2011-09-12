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


class Actuator extends Thing

class MoveActuator extends Actuator

class CleanActuator extends Actuator


class Environment

    constructor: ->
        @id = 0
        @things = {}

    read: (who, what) ->
        prop = @things[who.id][what]
        if typeof prop is 'function'
            prop who  # TODO: for example, 'dirt' must be computed
        else
            prop

    add: (thing, properties) ->
        id = @id++
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
        percepts.push data

        # make decision based on percepts

        # then act!
        actuators.emit move: 'down'
        #actuators.emit clean: true


room = new Room width: 10, height: 10

locationSensor = new LocationSensor room
dirtSensor = new DirtSensor room

moveActuator = new MoveActuator room
cleanActuator = new CleanActuator room


reemba = new Reemba
    sensors:
        location: locationSensor
        dirt: dirtSensor
    actuators:
        move: moveActuator
        clean: cleanActuator
    program: myProgram


dirt = new Dirt


room.add reemba, x: 0, y: 0
room.add dirt, x:1, y: 1


for i in [1..10]
    room.step()
