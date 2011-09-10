# TODO: events
#
# Some ideas:
#
# * Agents and Environments can interact by means of events
# * something happens: this is an event
# * a sensor is a device that can perceive that something has happened
# * an agent can read a sensor, so a sensor can be implemented as a
#   ReadableStream
# * each 'data' event is something a sensor perceived
# * so, Environment trigger events on Sensors and Sensors trigger 'data'
#   events on themselves.
# * an actuator is something an agent can write commands to.
# * so implementing an actuator as a WritableStream makes sense
# * Environment listens for 'data' events on actuators, and modifies its state
#   accordingly

# Problems:
# * more difficult to program?
# * bye bye stack traces?
# * performances?

# Awesomeness:
# * reflects real world
# * true incapsulation: agent programs just listen for sensor 'data' events
# * distributed?

util = require 'util'
rl = require('readline').createInterface process.stdin, process.stdout


class Environment
    constructor: (@name, @width, @height) ->
        @available_id = 0
        @step = 0
        @things = {}
        @cells = []
        for x in [0..@width-1]
            @cells[x] = []
            for y in [0..@height-1]
                @cells[x][y] = []
                if x is 0 or x is @width-1 or y is 0 or y is @height-1
                    @add_thing new Obstacle('wall'), x, y

    generate_id: ->
        ++@available_id


    get_coords: (thing) ->
        x = @things[thing.id].x
        y = @things[thing.id].y
        [x, y]


    add_thing: (thing, x, y) ->
        thing.id ?= @generate_id()
        if (x < 0 || x >= @width || y < 0 || y >= @height)
            throw "add_thing error: #{thing} coordinates (#{x},#{y}) out of
 bounds (width = #{@width}, height = #{@height})"
        @cells[x][y].push thing
        @things[thing.id] = thing: thing, x: x, y: y
        this

    move_thing: (thing, x, y) ->
        @del_thing thing
        @add_thing thing, x, y


    del_thing: (thing) ->
        [x, y] = @get_coords thing
        delete @things[thing.id]
        @cells[x][y] = @cells[x][y].filter (something) ->
            something.id isnt thing.id

    obstacle_at: (x, y) ->
        @cells[x][y].some (thing) -> thing instanceof Obstacle


    get_location_sensor: (agent) ->
        =>
            @get_coords agent

    get_dirt_sensor: (agent) ->
        =>
            [x, y] = @get_coords agent
            if (@cells[x][y].some (thing) -> thing instanceof Dirt)
                'dirt'
            else
                'clean'

    get_obstacle_sensor: (agent) ->
        =>
            [x, y] = @get_coords agent
            obstacles = []
            if @obstacle_at x + 1, y
                obstacles.push 'right'
            if @obstacle_at x - 1, y
                obstacles.push 'left'
            if @obstacle_at x, y + 1
                obstacles.push 'down'
            if @obstacle_at x, y - 1
                obstacles.push 'up'
            obstacles

    update: (verbose=false) ->
        @step++
        for id, entry of @things
            {thing, x, y} = entry
            [verb, complement] = thing.update verbose
            switch verb
                when 'nothing' then
                when 'move'
                    switch complement
                        when 'left'
                            move = x--
                        when 'right'
                            move = x++
                        when 'up'
                            move = y--
                        when 'down'
                            move = y++
                        else
                            throw "#{@name}#update error: #{thing.name} invalid direction #{complement}"
                    @move_thing thing, x, y
                when 'suck'
                    for something in @cells[x][y]
                        if something instanceof Dirt
                            @del_thing something
                else
                    throw "#{@name}#update error: #{thing.name} invalid direction #{complement}"


        console.info @toString() if verbose
        this

    toString: ->
        list = for key, entry of @things
            entry.thing.toString()

        "Environment #{@name}: step #{@step}\n#{list.join '\n'}"



class Thing
    constructor: (@name) ->

    update: (verbose=false) ->
        ['nothing', 'nothing']

    toString: ->
        "Thing #{@name}-#{@id}"


# An obstacle is the only Thing that can stay at a given x,y position
class Obstacle extends Thing

class Dirt extends Thing

class Agent extends Thing
    set_sensors: (@sensors) ->

    # TODO pull up methods `update_percepts' and `update'

class ReflexAgent extends Agent
    constructor: (@name, @agent_program) ->
        @percepts = []
        super(@name)

    update_percepts: ->
        dirt = @sensors.dirt()
        [x, y] = @sensors.location()
        obstacles = @sensors.obstacles()
        @percepts.push
            location:
                x: x
                y: y
            dirt: dirt
            obstacles: obstacles

    update: (verbose=false) ->
        @update_percepts()
        action = @agent_program @percepts

        if verbose
            console.info "ReflexAgent #{@name}, action: #{action}"
        action


#
# Example use
#

room = new Environment 'my room', 5, 5

reemba = new ReflexAgent 'reemba', (percepts) ->

    moves = ['up', 'down', 'left', 'right']

    {
        location: { x, y },
        dirt,
        obstacles
    } = percepts[percepts.length - 1]

    console.log 'percepts', x, y, dirt, obstacles
    if dirt is 'dirt'
        ['suck', '']
    else
        moves = moves.filter (el) -> not (el in obstacles)
        i = Math.floor(Math.random() * 100) % moves.length
        action = ['move', moves[i]]
        console.log action
        action

reemba.set_sensors
    dirt: room.get_dirt_sensor reemba
    location: room.get_location_sensor reemba
    obstacles: room.get_obstacle_sensor reemba


dirt = new Dirt 'dirt'

room.add_thing reemba, 1, 1
room.add_thing dirt, 2, 2

#
# User prompt
#
prompt = 'sim> '

rl.on 'line', (line) ->
    room.update true
    rl.setPrompt prompt, prompt.length
    rl.prompt()

rl.on 'close', ->
    console.info 'So long, and thanks for all the fish'
    process.exit 0

console.info 'AIMA Simulator'
console.info room.toString()

rl.setPrompt prompt, prompt.length
rl.prompt()
