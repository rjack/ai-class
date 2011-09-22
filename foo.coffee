class Vehicle
    @ids = {}
    constructor: ->
        @constructor.ids[@constructor.name] ?= 0
        @type = @constructor.name
        @id = "#{@constructor.ids[@type]++}-#{@type}"

class Car extends Vehicle

class Truck extends Vehicle

car = new Car
console.log car.id
car = new Car
console.log car.id
truck = new Truck
console.log truck.id
car = new Car
console.log car.id
