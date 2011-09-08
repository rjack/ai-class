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
        @percepts.push
            location:
                x: x
                y: y
            dirt: dirt

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

    {location: {x, y}, dirt} = percepts[percepts.length - 1]

    console.log 'percepts', x, y, dirt
    if dirt is 'dirt'
        ['suck', '']
    else
        if x is 1
            moves = moves.filter (el) -> el isnt 'left'
        if x is 3
            moves = moves.filter (el) -> el isnt 'right'
        if y is 1
            moves = moves.filter (el) -> el isnt 'up'
        if y is 3
            moves = moves.filter (el) -> el isnt 'down'
        i = Math.floor(Math.random() * 100) % moves.length
        action = ['move', moves[i]]
        console.log action
        action

reemba.set_sensors
    dirt: room.get_dirt_sensor reemba
    location: room.get_location_sensor reemba


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
