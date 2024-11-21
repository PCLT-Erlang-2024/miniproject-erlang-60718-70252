-module(task1).
-export([start/0, start/2, producer/2, conveyor/1, truck/0]).

start() -> start(10, 10).
start(NLines, NProductions) -> [spawn(?MODULE, producer, [spawn(?MODULE, conveyor, [spawn(?MODULE, truck, [])]), NProductions]) || _ <- lists:seq(1,NLines)].

producer(ConvId, 0) ->
	ConvId ! stop,
	io:format("Producer ~p stopped~n", [self()]);
producer(ConvId, NProductions) ->
	io:format("Producer ~p sending package~n", [self()]),
	ConvId ! package,
	producer(ConvId, NProductions-1).

conveyor(TruckId) ->
	receive
		package ->
			io:format("Conveyor ~p received package~n", [self()]),
			TruckId ! package,
			conveyor(TruckId);
		stop ->
			io:format("Conveyor ~p stopped~n", [self()]),
			TruckId ! stop
	end.

truck() ->
	receive
		package ->
			io:format("Truck ~p received package~n", [self()]),
			truck();
		stop ->
			io:format("Truck ~p stopped~n", [self()])
	end.
