util = require 'util'
rl = require('readline').createInterface process.stdin, process.stdout


class Environment
    constructor: (@name, @width, @height) ->
        @available_id = 0
        @step = 0
        @cells = ([] for i in [0..@width * @height - 1])
        @things = {}

    get_index: (x, y) ->
        x + (@width * y)

    get_coords: (index) ->
        x = index % @width
        y = Math.floor index / @width
        [x, y]

    generate_id: ->
        ++@available_id


    add_thing: (thing, x, y) ->
        thing.id = @generate_id()
        if (x < 0 || x > @width || y < 0 || y > @height)
            throw "add_thing error: #{thing} coordinates (#{x},#{y}) out of
 bounds (width = #{@width}, height = #{@height})"
        i = @get_index(x, y)
        @cells[i].push thing
        thing.set_position x, y
        @things[thing.id] = thing
        this

    del_thing: (thing) ->
        delete @things[thing.id]
        i = @get_index thing.x, thing.y
        @cells[i] = @cells[i].filter (something) ->
            something.id is not thing.id


    get_location_sensor: (agent) ->
        ->
            [agent.x, agent.y]

    get_dirt_sensor: (agent) ->
        =>
            i = @get_index agent.x, agent.y
            if (@cells[i].some (thing) -> thing instanceof Dirt)
                'dirt'
            else
                'clean'

    update: (verbose=false) ->
        @step++
        for id, thing of @things
            action = thing.update verbose
            if action?
                switch action
                    when 'suck'
                        i = @get_index thing.x, thing.y
                        for something in @cells[i]
                            if something instanceof Dirt
                                @del_thing something
                    when 'left'
                        move = -1
                    when 'right'
                        move = 1
                    when 'up'
                        move = -@width
                    when 'down'
                        move = +@width
                    else
                        throw "#{@name}#update error: #{thing.name} invalid action #{action}"

                if move?
                    i = @get_index thing.x, thing.y
                    @cells[i] = @cells[i].filter (something) ->
                        something.id is not thing.id
                    i += move
                    @cells[i].push(thing)
                    [thing.x, thing.y] = @get_coords i


        console.info @toString() if verbose
        this

    toString: ->
        list = for key, thing of @things
            thing.toString()

        "Environment #{@name}: step #{@step}\n#{list.join '\n'}"



class Thing
    constructor: (@name) ->

    set_position: (x, y) ->
        @x = x
        @y = y
        this

    update: (verbose=false) ->

    toString: ->
        "Thing #{@name}-#{@id}: position #{@x}, #{@y}"


# An obstacle is the only Thing that can stay at a given x,y position
class Obstacle extends Thing
    constructor: (@name) ->
        @blocks = true
        super(@name)


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
            console.info "ReflexAgent #{@name}, percepts: #{@percepts[@percepts.length-1]}, action: #{action}"
        action


#
# Example use
#

room = new Environment 'my room', 5, 5

reemba = new ReflexAgent 'reemba', (percepts) ->
    i = percepts.length - 1
    if percepts[i].dirt is 'dirt'
        'suck'



    else throw "error, don't know what to do on #{percept}"

reemba.set_sensors
    dirt: room.get_dirt_sensor reemba
    location: room.get_location_sensor reemba


dirt = new Dirt 'dirt'

room.add_thing reemba, 0, 0
room.add_thing dirt, 1, 0

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
