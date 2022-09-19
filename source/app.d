import std.stdio;

import parsergenerator;

void main()
{
	import std.stdio;

	string grammar = 
	"phrase ::= <subject> <verb> <complement?> <conjonction?> ;
	subject ::= <article> <adjective?> <name> | <proper_name> ;
	complement ::= <place_preposition> <article> <place> | <adjective_complement> ;
	conjonction ::= <for_conjonction> | <phrase_conjonction> ;
	for_conjonction ::= for <subject> <that_complement> ;
	adjective_complement ::= with <subject> ;
	conjonction_article ::= and | but ;
	phrase_conjonction ::= <conjonction_article> <phrase> ;
	that_complement ::= that <verb> <complement> ;
	adjective ::= hot | cold | fat | big | small | tiny | fluffy ;
	place_preposition ::= in | inside | on | below | at ;
	place ::= bridge | road | plane | car | lake | city | house | boat | castle ;
	verb ::= eat | run | drink | fight | sit | dance | sleep ;
	article ::= the | a ;
	name ::= cat | dog | sheep | dragon | donkey | monkey | turtle | rat | elephant ;
	proper_name ::= Shrek | Snake | Yoshi";

	auto gp = new GrammarParser(grammar);
	auto parser = gp.createParser();

	void test(string str)
	{
		auto node = parser.parse("phrase", str);
		assert(node !is null);

		auto printer = new PrinterVisitor();
		node.accept(printer);
		writeln("=================================");
	}

	test("a donkey eat for a dragon that sleep in the castle");
}
