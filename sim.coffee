util = require 'util'

class Environment
    constructor: (@name, @width, @height) ->
        @step = 0
        @cells = ([] for i in [0..@width * @height - 1])
        @things = []

    get_index: (x, y) ->
        x + (@width * y)


    add_thing: (thing, x, y) ->
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
            thing.update(verbose)
        console.log @toString() if verbose
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
        this

    toString: ->
        "Thing #{@name}: position #{@x}, #{@y}"


# An obstacle is the only Thing that can stay at a given x,y position
class Obstacle extends Thing
    constructor: (@name) ->
        @blocks = true
        super()


class Dirt extends Thing

class Agent extends Thing

class ReflexAgent extends Agent
    constructor: (@name, @agent_program) ->
        @percepts = []
        super()

    update: (verbose=false) ->
        dirt = @dirt_sensor.read()
        location = @location_sensor.read()
        @percepts.push "#{location} - #{dirt}"
        @agent_program @percepts


#
# Example use
#

rumba = new Agent 'rumba'
dirt = new Dirt 'dirt'
room = new Environment('my room', 2, 1)
                      .add_thing(rumba, 0, 0)
                      .add_thing(dirt, 1, 0)

steps = 10
room.update(true) while steps--
