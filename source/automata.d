module automata;

import std.stdio;
import std.algorithm;
import std.range;
import std.format;
// avoid dstring mutation in algorithm
import std.utf : byCodeUnit;

class State
{
	this(int i)
	{
		id = i;
	}

	this(int i, int[char] p)
	{
		id = i;
		paths = p;
	}

	int id;
	int[char] paths;
}

class Automata
{
	string alphabet = "abe";
	State[int] states;

	State[] startingStates;
	State[] terminalStates;

	this()
	{
		states = [
			1: new State(1,['a':3, 'b':2]),
			2: new State(2,['a':5, 'b':2]),
			3: new State(3,['a':4, 'b':1]),
			4: new State(4,['a':7, 'b':6]),
			5: new State(5,['a':6, 'b':1]),
			6: new State(6,['a':7, 'b':4]),
			7: new State(7,['a':7, 'b':7]),
		];

		startingStates = [states[1]];
		terminalStates = [states[4], states[6]];
	}

	State next(State state, char sym)
	{
		return states[state.paths[sym]];
	}

	bool recognize(string word)
	{
		int i = 0;
		foreach(startState; startingStates)
		{
			State state = startState;
			while (i < word.length)
			{
				state = next(state, word[i++]);
			}

			if (terminalStates.canFind(state))
				return true;
		}

		return false;
	}

	bool isDeterminist()
	{
		if (startingStates.length != 1)
			return false;
		// the current implementation of state with aa doesn't allow multiples transitions with same symbol
		// so isComplete here will work in this specific case but not in a generic one !
		return isComplete();
	}

	bool isComplete()
	{
		foreach (s; states)
		{
			foreach (sym; alphabet)
			{
				if ((sym in s.paths) is null)
					return false;
			}
		}
		return true;
	}

	void complete()
	{
		if (isComplete())
			return;
		
		// trash state only point to itself
		State trashState = new State(int.max);
		foreach(sym; alphabet)
			trashState.paths[sym] = trashState.id;

		states[trashState.id] = trashState;

		foreach (s; states)
		{
			foreach (sym; alphabet)
			{
				// check if path is missing
				if ((sym in s.paths) is null)
				{
					// if path is missing add it toward the trash state
					s.paths[sym] = trashState.id;
				}
			}
		}
	}

	auto validTransitionRange(State s)
	{
		return filter!(e => (e in s.paths) !is null)(alphabet.byCodeUnit);
	}

	string print()
	{
		import std.format;
		State[] visited;
		
		// capture visisted to draw edges only once
		string visitPrint(State s)
		{
			if (visited.canFind(s))
				return "";

			visited ~= s;
			string v;
			foreach (sym; validTransitionRange(s))
				v ~= format!("\t%s -> %s [label=\"%s\"];\n")(s.id, s.paths[sym], sym);
			
			v ~= "\n";
			foreach (sym; validTransitionRange(s))
				v ~= visitPrint(next(s, sym));
			return v;
		}

		string viz = "digraph G {\n";

		// empty node to draw line from empty space
		viz ~= "\tnone [label= \"\", shape=none,height=.0,width=.0]\n";

		foreach (state; startingStates)
			viz ~= format!("\tnone -> %s\n")(state.id);

		foreach (state; terminalStates)
			viz ~= format!("\t%s [shape=doublecircle]\n")(state.id);

		foreach (state; startingStates)
			viz ~= visitPrint(state);

		viz ~= "}";
		
		return viz;
	}

	unittest
	{
		Automata example = new Automata();
		assert(example.recognize("aa"));
		assert(example.recognize("aab"));
		assert(example.recognize("aabb"));
		assert(!example.recognize("bbbb"));
		assert(!example.recognize("aaaa"));
		assert(!example.recognize("bab"));
	}
}
