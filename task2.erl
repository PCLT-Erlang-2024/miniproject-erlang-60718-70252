-module(task2).
-export([start/0, start/3, producer/3, conveyor/1, truck/1, truck/2]).

start() -> start(10, 10, 10).
start(NLines, NProductions, TruckSize) -> [spawn(?MODULE, producer, [spawn(?MODULE, conveyor, [spawn(?MODULE, truck, [TruckSize])]), NProductions, TruckSize]) || _ <- lists:seq(1,NLines)].

producer(ConvId, 0, _) ->
	ConvId ! stop,
	io:format("Producer ~p stopped~n", [self()]);
producer(ConvId, NProductions, MaxSize) ->
	Size = rand:uniform(MaxSize),
	io:format("Producer ~p sending package (~p)~n", [self(), Size]),
	ConvId ! {package, NProductions, Size},
	producer(ConvId, NProductions - 1, MaxSize).

conveyor(TruckId) ->
	receive
		{package, PackNum, Size} ->
			io:format("Conveyor ~p received package (~p)~n", [self(), Size]),
			TruckId ! {package, PackNum, Size},
			conveyor(TruckId);
		stop ->
			io:format("Conveyor ~p stopped~n", [self()]),
			TruckId ! stop
	end.

truck(TruckSize) -> truck(TruckSize, TruckSize).
truck(TruckSize, CurrentSize) ->
	receive
		{package, PackNum, Size} ->
			if 
				Size > CurrentSize -> 
					io:format("Truck ~p departed because package ~p (~p/~p) was too big~n", [self(), PackNum, Size, CurrentSize]),
					truck(TruckSize, TruckSize, {package, PackNum, Size});
				Size < CurrentSize -> 
					io:format("Truck ~p received package (~p/~p)~n", [self(), Size, CurrentSize]),
					truck(TruckSize, CurrentSize - Size);
				Size == CurrentSize -> 
					io:format("Truck ~p received package (~p/~p) and became full~n", [self(), Size, CurrentSize]),
					truck(TruckSize, TruckSize, {package, PackNum, Size})
			end;
		stop ->
			io:format("Truck ~p stopped~n", [self()])
	end.

truck(TruckSize, CurrentSize, {package, PackNum, Size}) ->
	io:format("New Truck ~p has arrived and picked up package ~p (~p/~p)~n", [self(), PackNum, Size, CurrentSize]),
	truck(TruckSize, CurrentSize - Size).