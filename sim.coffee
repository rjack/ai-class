util = require 'util'
rl = require('readline').createInterface process.stdin, process.stdout


class Environment
    constructor: (@name, @width, @height) ->
        @available_id = 0
        @step = 0
        @cells = ([] for i in [0..@width * @height - 1])
        @things = []

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
        @things.push thing
        this


    update: (verbose=false) ->
        @step++
        for thing in @things
            action = thing.update(verbose)
            if action?
                switch action
                    when 'suck' then
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
                    @cells[i] = @cells[i].filter (existing_thing) ->
                        existing_thing.id is not thing.id
                    i += move
                    @cells[i].push(thing)
                    [thing.x, thing.y] = @get_coords i


        console.info @toString() if verbose
        this

    toString: ->
        things_listing = @things.reduce ((str, thing) ->
            prefix = ""
            prefix = "#{str}\n" if str
            "#{prefix}#{thing.toString()}"), ''
        "Environment #{@name}: step #{@step}\n#{things_listing}"



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

class ReflexAgent extends Agent
    constructor: (@name, @agent_program) ->
        @percepts = []
        super(@name)

    update: (verbose=false) ->
        dirt = 'clean'       #@dirt_sensor.read()
        location = "#{@x},#{@y}"     #@location_sensor.read()
        @percepts.push "#{location} - #{dirt}"
        action = @agent_program @percepts
        if verbose
            console.info "ReflexAgent #{@name}, percepts: #{@percepts[@percepts.length-1]}, action: #{action}"
        action


#
# Example use
#
rumba = new ReflexAgent 'rumba', (percepts) ->
    last = percepts[percepts.length - 1]
    switch last
        when '0,0 - dirt' then 'suck'
        when '0,0 - clean' then 'right'
        when '1,0 - dirt' then 'suck'
        when '1,0 - clean' then 'left'
        else throw "error, don't know what to do on #{last}"


dirt = new Dirt 'dirt'
room = new Environment('my room', 2, 1)
                      .add_thing(rumba, 0, 0)
                      .add_thing(dirt, 1, 0)

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
rl.setPrompt prompt, prompt.length
rl.prompt()

