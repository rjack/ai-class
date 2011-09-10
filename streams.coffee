events = require 'events'


class Sensor extends events.EventEmitter
    constructor: (@name) ->


    write: (data) ->
        @emit 'data', data

class Actuator extends events.EventEmitter
    constructor: (@name) ->


    write: (data) ->
        @emit 'data', data


sensor = new Sensor 'sound-sensor'
actuator = new Actuator 'trigger-actuator'


# Sentry Agent Program: detect a sound -> pull the trigger
sensor.on 'data', (data) ->
    if data is 'suspicious noise'
        console.log 'ALERT!'
        actuator.write 'pull trigger'
    else
        console.log 'lol, nvm'

# Environment: when the actuator does something, update environment state
actuator.on 'data', (data) ->
    if data is 'pull trigger'
        console.log 'BANG! YOU KILLED IT!'
    else
        console.log 'LOL WUT?!'

sensor.write 'bird singing'
sensor.write 'suspicious noise'
