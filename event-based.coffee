events = require 'events'


PERCEPTS =
    location:
        x: 'x coordinate'
        y: 'y coordinate'
    dirt: 'true or false'
    obstacles: 'array of ACTION.MOVE fields'

ACTIONS =
    MOVE:
        LEFT: 'LEFT'
        RIGHT: 'RIGHT'
        UP: 'UP'
        DOWN: 'DOWN'
    CLEAN:
        SUCK: 'SUCK'


class Thing
    @ids = {}
    constructor: (config = properties: {}) ->
        @constructor.ids[@constructor.name] ?= 0
        @type = @constructor.name
        @id = "#{@type}-#{@constructor.ids[@type]++}"

        {@properties} = config

    step: ->
        null

    toString: ->
        '?'


class Agent extends Thing

    constructor: (config) ->
        super config
        {@sensors, @program} = config
        @program = @program()

    step: ->
        super()
        @program @properties


class Reemba extends Agent

    @blocks = true


class Dirt extends Thing

    constructor: (config) ->
        super(config)
        @difficult = 1

    step: ->
        super()
        @difficult++     # now it's more difficult to remove
        null


class Wall extends Thing

    @blocks = true


class Sensor extends Thing

    read: (thing, env) ->
        throw 'NOT IMPLEMENTED'



class LocationSensor extends Sensor

    read: (thing, env) ->
        thing.properties.location


class DirtSensor extends Sensor

    read: (thing, env) ->
        {properties: location: {x, y}} = thing
        things = env.get x, y
        things.some (something) ->
            something instanceof Dirt


class NegativeDirtSensor extends DirtSensor

    read: (thing, env)->
        not super()


class ObstacleSensor extends Sensor

    obstacle_at: (env, x, y) ->
        (env.get x, y).some (something) ->
            'blocks' of something


    read: (thing, env) ->
        obstacles = []
        {properties: location: {x, y}} = thing
        if @obstacle_at env, x + 1, y
            obstacles.push ACTIONS.MOVE.RIGHT
        if @obstacle_at env, x - 1, y
            obstacles.push ACTIONS.MOVE.LEFT
        if @obstacle_at env, x, y + 1
            obstacles.push ACTIONS.MOVE.DOWN
        if @obstacle_at env, x, y - 1
            obstacles.push ACTIONS.MOVE.UP
        obstacles


class EnvironmentManager

    constructor: (@env) ->
        @things = {}

    add: (thing) ->
        id = thing.id
        @things[id] = thing
        @env.add thing

    remove: (thing) ->
        {id} = thing
        @env.remove thing
        delete @things[id]
        null

    move: (thing, direction) ->
        @env.remove thing
        {location} = thing.properties
        switch direction
            when ACTIONS.MOVE.LEFT then location.x--
            when ACTIONS.MOVE.RIGHT then location.x++
            when ACTIONS.MOVE.UP then location.y--
            when ACTIONS.MOVE.DOWN then location.y++
            else
                throw "INVALID DIRECTION #{direction}"
        @env.add thing

    clean: (agent) ->
        {x, y} = agent.properties.location
        dirt_things = @env.get(x, y).filter (something) =>
            something instanceof Dirt
        while dirt_things.length
            @remove dirt_things.pop()

    step: ->
        for id, thing of @things
            # ok, qui devo chiamare i sensor della thing e settare le
            # properties a seconda di quello che ritornano

            if thing instanceof Agent
                {sensors} = thing
                for name, sensor of sensors
                    thing.properties[name] = sensor.read thing, @env

            action = thing.step()
            if action of ACTIONS.MOVE
                @move thing, action
            else if action of ACTIONS.CLEAN
                @clean thing
            else if action isnt null
                throw "INVALID ACTION #{action}"
        null



class Environment
    constructor: (config) ->
        {@width, @height} = config
        # grid as multidimensional array
        @grid = for x in [0..@width-1]
            for y in [0..@height-1]
                []

    add: (thing) ->
        {properties: location: {x, y}} = thing
        @grid[x][y].push thing

    remove: (thing) ->
        {properties: location: {x, y}} = thing
        @grid[x][y] = @grid[x][y].filter (something) ->
            something.id isnt thing.id

    get: (x, y) ->
        @grid[x][y]

    set: (x, y, fn) ->
        @grid[x][y] = fn @grid[x][y]

    draw: ->
        for x in [0..@width-1]
            for y in [0..@height-1]
                # TODO
        null



myProgram =  ->

    moves = for key, value of ACTIONS.MOVE
        value

    (percepts) ->
        {
            location: {x, y},
            dirt,
            obstacles     # TODO
        } = percepts

        console.dir percepts

        if dirt
            action = ACTIONS.CLEAN.SUCK
        else
            possible_moves = moves.filter (el) -> not (el in obstacles)
            i = Math.floor(Math.random() * 100) % possible_moves.length
            action = possible_moves[i]

        console.dir action
        action


width = 10
height = 10
room = new Environment width: width, height: height
master = new EnvironmentManager room


reemba_A = new Reemba
    sensors:
        location: new LocationSensor
        dirt: new DirtSensor
        obstacles: new ObstacleSensor
    program: myProgram
    properties:
        location:
            x: 1, y: 1


reemba_B = new Reemba
    sensors:
        location: new LocationSensor
        dirt: new DirtSensor
        obstacles: new ObstacleSensor
    program: myProgram
    properties:
        location:
            x: 8, y: 8



dirt = new Dirt
    properties:
        location:
            x: 5, y: 5

for x in [0..width-1]
    for y in [0..height-1]
        if x is 0 or x is width-1 or y is 0 or y is height-1
            master.add new Wall
                properties:
                    location:
                        x: x, y: y

master.add reemba_A
master.add reemba_B
master.add dirt

for i in [1..5]
    room.draw()
    master.step()


room.draw()
