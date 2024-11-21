-module(task1).
-export([start/0, start/3, producer/2, conveyor/1, truck/1, truck/2]).

start() -> start(10, 10, 10).
start(NLines, NProductions, TruckSize) -> [spawn(?MODULE, producer, [spawn(?MODULE, conveyor, [spawn(?MODULE, truck, [TruckSize])]), NProductions]) || _ <- lists:seq(1,NLines)].

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

truck(TruckSize) -> truck(TruckSize, TruckSize).
truck(TruckSize, CurrentSize) ->
	receive
		{package, PackNum} ->
			if 
				TruckSize < 1 -> 
					io:format("Truck ~p departed because package ~p (1/~p) was too big~n", [self(), PackNum, CurrentSize]),
					truck(TruckSize, TruckSize, {package, PackNum});
				TruckSize > 1 -> 
					io:format("Truck ~p received package (1/~p)~n", [self(), CurrentSize]),
					truck(TruckSize, CurrentSize - 1);
				TruckSize == 1 -> 
					io:format("Truck ~p received package (1/~p) and became full~n", [self(), CurrentSize]),
					truck(TruckSize, TruckSize, {package, PackNum})
			end;
		stop ->
		io:format("Truck ~p stopped~n", [self()])
	end.

truck(TruckSize, CurrentSize, {package, PackNum}) ->
	io:format("New Truck ~p has arrived and picked up package ~p (1/~p)~n", [self(), PackNum, CurrentSize]),
	truck(TruckSize, CurrentSize - 1).