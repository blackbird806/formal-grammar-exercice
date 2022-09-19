module ctfreegenerator;
import std.random;
import std.range;

/*
	grammar:
	phrase ::= <subject> <verb> <complement> <conjonction?>
	subject ::= <noun> | (<article> <adjective> <animal>)
	complement ::= (<adjective_preposition> <subject>) | (<place_preposition> <places>)
	conjonction ::= <phrase_conjonction> | <for_conjonction>
	phrase_conjonction ::= (and | but) <phrase>
	for_conjonction ::= for <subject> (that <verb> <complement>)?
*/

auto articles = ["the", "a"];

auto animals = ["cat", "dog", "platypus", "bird", "wolf", "dragon", "squirrel", "mouse", "rat", "monkey", "turtle",
 "elephant", "donkey", "giraffe", "sheep", "pig", "fish"];
auto nouns = ["Boris", "Guillaume", "Florian", "Bastien", "Bryan", "Rumen", "Yoda", "Dark-Vador", "The-Rock", "Thanos",
 "Goku"];

auto verbs = ["eat", "laugh", "smoke", "yell", "drink", "sleep", "run", "walk", "jump", "sit", "dance", "fight"];
auto adjective = 
["hot", "cold", "big", "small", "strange", "cute", "red", "yellow", "heavy",
"blue", "dark", "fluffy", "sticky", "fearfull", "hudge", "fat"];

auto adjective_preposition = ["with"];
auto place_preposition = ["in", "inside", "on", "below", "at"];
auto places = ["bridge", "road", "plane", "car", "lake", "city", "house", "boat", "castle"];

bool rnd()
{
	return dice(50, 50) > 0;
}

string maybe(lazy string str)
{
	return rnd() ? str : "";
}

string getVerb()
{
	return verbs.choice();
}

string getAdjective()
{
	return adjective.choice();
}

string getSubject()
{
	return choice([() => () {
		return nouns.choice();
	}, () => () {
		return articles.choice() ~ " " ~ getAdjective() ~ " " ~ animals.choice();
	}])()();
}

string generateComplement()
{
	if (rnd())
		return adjective_preposition.choice() ~ " " ~ getSubject();

	return place_preposition.choice() ~ " " ~ articles.choice() ~ " " ~ places.choice();
}

string generateConjonction()
{
	return choice([() => () {
		return ["and ", "but "].choice() ~ generatePhrase();
	}, () => () {
		return "for " ~ getSubject() ~ " " ~ maybe( "that " ~ getVerb() ~ " " ~ generateComplement());
	}])()();
}

string generatePhrase()
{
	string phrase = getSubject() ~ " " ~ getVerb() ~ " " ~ generateComplement(); 
	if (rnd())
		phrase ~= " " ~ generateConjonction();
	return phrase;
}

unittest
{
	import std.stdio;
	foreach(i; 0 .. 10)
	{
		generatePhrase().writeln;
	}
}