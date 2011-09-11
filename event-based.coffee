events = require 'events'

class Sensor extends events.EventEmitter

    constructor: (@agentID) ->
        super()

    write: (data) ->
        data.id = @agentID
        @emit 'data', data

class Actuator extends events.EventEmitter

    constructor: (@agentID) ->
        super()

    write: (data) ->
        data.id = @agentID
        @emit 'data', data


class Agent

    constructor: (@id, @sensor, @actuator, @program) ->
        @program @sensor, @actuator


class ReembaAgent extends Agent
    # Sensor Interface:
    #   location: {x, y}
    #   obstacles: ['left', 'right', 'up', 'down']
    #   dirt: true/false
    #
    # Actuator Interface:
    #   id: agent_id
    #   move: 'up' or 'down' or 'left' or 'right'
    #   clean: true or false


class Environment

    constructor: ->
        @next_id = 0
        @agents = {}
        @things = {}

    handleActuator: (data) ->
        console.log data

    spawnAgent: (type, program) ->
        id = @next_id++
        actuator = new Actuator id
        sensor = new Sensor id
        agent = switch type
            when 'ReembaAgent'
                new ReembaAgent id, sensor, actuator, program
            else
                throw "E0001 UNSUPPORTED AGENT: #{type}"

        @agents[id] = agent

        actuator.on 'data', (data) => @handleActuator data

        sensor.write location:
                x: 0
                y: 0
            obstacles: []
            dirt: false


room = new Environment


drunkReembaProgram = (sensor, actuator) ->
    sensor.on 'data', (data) ->
        all_directions = ['up', 'down', 'left', 'right']
        {
            location: { x, y },
            dirt,
            obstacles
        } = data

        if dirt is true
            actuator.write clean: true
        else
            directions = all_directions.filter (el) -> not (el in obstacles)
            i = Math.floor(Math.random() * 100) % directions.length
            action = directions[i]
            actuator.write motor: action


room.spawnAgent 'ReembaAgent', drunkReembaProgram
room.spawnAgent 'ReembaAgent', drunkReembaProgram
