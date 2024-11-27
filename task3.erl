-module(task3).
-export([start/0, start/3, producer/3, conveyor/2, truck/1, truck/2]).

start() -> start(10, 10, 10).
start(NLines, NProductions, TruckSize) -> [spawn(?MODULE, producer, [spawn(?MODULE, conveyor, [spawn(?MODULE, truck, [TruckSize]), go]), NProductions, TruckSize]) || _ <- lists:seq(1,NLines)].

producer(ConvId, 0, _) ->
	ConvId ! stop,
	io:format("Producer ~p stopped~n", [self()]);
producer(ConvId, NProductions, MaxSize) ->
	Size = rand:uniform(MaxSize),
	io:format("Producer ~p sending package (~p)~n", [self(), Size]),
	ConvId ! {package, NProductions, Size},
	producer(ConvId, NProductions - 1, MaxSize).

conveyor(TruckId, sent) ->
	receive
		wait -> conveyor(TruckId, wait);
		received ->
			io:format("The truck ~p has received the package~n", [TruckId]),
			conveyor(TruckId, go)
	end;
conveyor(TruckId, wait) ->
	receive
		replaced ->
			io:format("New truck ~p has arrived at Conveyor ~p~n", [TruckId, self()]),
			conveyor(TruckId, go)
	end;
conveyor(TruckId, go) ->
	receive
		wait -> conveyor(TruckId, wait);
		{package, PackNum, Size} ->
			io:format("Conveyor ~p received package (~p)~n", [self(), Size]),
			TruckId ! {package, PackNum, Size, self()},
			conveyor(TruckId, sent);
		stop ->
			io:format("Conveyor ~p stopped~n", [self()]),
			TruckId ! stop
	end.

truck(TruckSize) -> truck(TruckSize, TruckSize).
truck(TruckSize, CurrentSize) ->
	receive
		{package, PackNum, Size, ConvId} ->
			if 
				Size > CurrentSize -> 
					ConvId ! wait,
					io:format("Truck ~p departed because package ~p (~p/~p) was too big~n", [self(), PackNum, Size, CurrentSize]),
					truck(TruckSize, TruckSize, {package, PackNum, Size, ConvId});
				Size < CurrentSize -> 
					ConvId ! received,
					io:format("Truck ~p received package (~p/~p)~n", [self(), Size, CurrentSize]),
					truck(TruckSize, CurrentSize - Size);
				Size == CurrentSize ->
					ConvId ! wait,
					io:format("Truck ~p departed because received package (~p/~p) made this truck become full~n", [self(), Size, CurrentSize]),
					truck(TruckSize, TruckSize, {no_package, ConvId})
			end;
		stop ->
			io:format("Truck ~p stopped~n", [self()])
	end.

truck(TruckSize, CurrentSize, {package, PackNum, Size, ConvId}) ->
	receive
	after 
		(rand:uniform(10) * 1000) -> true
	end,

	io:format("New Truck ~p has arrived and picked up package ~p (~p/~p)~n", [self(), PackNum, Size, CurrentSize]),
	ConvId ! replaced,
	truck(TruckSize, CurrentSize - Size);

truck(TruckSize, CurrentSize, {no_package, ConvId}) ->
	receive
	after 
		(rand:uniform(10) * 1000) -> true
	end,

	io:format("New Truck ~p has arrived (~p)~n", [self(), CurrentSize]),
	ConvId ! replaced,
	truck(TruckSize, CurrentSize).