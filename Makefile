CC=coffee
CFLAGS=-b
SRC=$(wildcard *.coffee)
OBJ=sim.js event-based.js

.PHONY: all clean


all: $(OBJ)


%.js : %.coffee
	$(CC) $(CFLAGS) --print -c $< > $@


clean:
	rm -f *.js
