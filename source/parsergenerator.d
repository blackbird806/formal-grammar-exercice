module parsergenerator;

import std.exception;
import std.range;
import std.algorithm;

/*
	meta grammar:
	
	rule_definition ::= '<' rule_name '>' '::=' expression
	expression ::= <rule> <expression?>
	rule ::= '<'rule_name ??'>' 
*/

interface GrammarASTNode { }

class Rule : GrammarASTNode
{
	string name;
	bool isOptionnal;
	bool isTerminal;
}

class Expression : GrammarASTNode
{
	// or list
	Rule[][] rules;
}

class RuleDefinition : GrammarASTNode
{
	string name;
	Expression exp;
}

class GrammarParser
{
	this(string source)
	{
		words = source.replace("\n", " ").replace("\t", "").split(' ');
	}

	bool isRuleName(string str)
	{
		return str[0] == '<';
	}

	bool isOptionnal(string str)
	{
		return canFind(str, '?');
	} 

	string getTerminalName(string str)
	{
		return str.replace('?', ' ');
	}

	string getRuleName(string str)
	{
		if (isOptionnal(str))
			return str[1 .. $-2]; // also trim "?"

		// trim <>
		return str[1 .. $-1];
	}

	Expression parseExpression()
	{
		auto exp = new Expression();
		exp.rules ~= new Rule[0];
		while (!words.empty && front(words) != ";")
		{
			if (front(words) == "|")
			{
				popFront(words);
				exp.rules ~= new Rule[0];
			}

			auto rule = new Rule();
			if (isRuleName(front(words)))
			{
				rule.name = getRuleName(front(words));
			}
			else
			{
				rule.name = getTerminalName(front(words));
				rule.isTerminal = true;
			}
			rule.isOptionnal = isOptionnal(front(words));
			exp.rules.back ~= rule;
			words.popFront();
		}

		if (!words.empty && front(words) == ";")
			words.popFront();

		return exp;
	}

	RuleDefinition parseRuleDefinition()
	{
		auto def = new RuleDefinition();
		def.name = front(words);
		words.popFront();

		enforce(front(words) == "::=", "::= must follow rule name");
		words.popFront();

		def.exp = parseExpression();
		return def;
	}

	GeneratedParser createParser()
	{
		auto parser = new GeneratedParser();
		while (!words.empty)
			parser.rules ~= parseRuleDefinition();
		return parser;
	}

	string[] words;
}

interface GeneratedASTVisitor 
{
	void visit(NonTerminalNode);
	void visit(TerminalNode);
}

abstract class GeneratedASTNode 
{
	this(string name)
	{
		this.name = name;
	}

	void accept(GeneratedASTVisitor);

	string name;
}

class NonTerminalNode : GeneratedASTNode 
{
	this(string name)
	{
		super(name);
	}

	override void accept(GeneratedASTVisitor v)
	{
		v.visit(this);
	}

	GeneratedASTNode[] productions;
}

class TerminalNode : GeneratedASTNode 
{
	this(string name)
	{
		super(name);
	}

	override void accept(GeneratedASTVisitor v)
	{
		v.visit(this);
	}
}

class GeneratedParser
{
	GrammarASTNode[] stack;
	RuleDefinition[] rules;

	string[] words;

	TerminalNode parseTerminal(Rule rule)
	{
		if (!words.empty && rule.name == front(words))
		{
			popFront(words);
			return new TerminalNode(rule.name);
		}
		return null;
	}

	GeneratedASTNode parseRule(Rule rule)
	{
		if (rule.isTerminal)
			return parseTerminal(rule);

		auto ruleDef = find!(a => a.name == rule.name)(rules);
		if (ruleDef.empty)
			return null;
		return parseExpression(rule.name, ruleDef.front.exp);
	}

	auto tryParseRuleList(string name, Rule[] ruleList)
	{
		auto node = new NonTerminalNode(name);
		foreach (rule; ruleList)
		{
			auto prod = parseRule(rule);
			if (prod is null && !rule.isOptionnal)
				return null;
			if (prod !is null)
				node.productions ~= prod;
		}
		return node;
	}

	GeneratedASTNode parseExpression(string name, Expression exp)
	{
		foreach (ruleList; exp.rules)
		{
			// here we should try to parse each occurence of or rule and stop when it works
			// how do I do this ??
			auto node = tryParseRuleList(name, ruleList);
			if (node !is null)
				return node;
		}
		return null;
	}

	GeneratedASTNode parse(string nodeKindName, string src)
	{
		words = src.split(' ');
		auto startRule = find!(a => nodeKindName == a.name)(rules);
		enforce(!startRule.empty, nodeKindName ~ " is not present in grammar");

		return parseExpression(startRule.front.name, startRule.front.exp);
	}
}

class PrinterVisitor : GeneratedASTVisitor
{
	import std.stdio;

	uint indentLevel = 0;

	void indent()
	{
		indentLevel += 2;	
	}

	void deindent()
	{
		indentLevel -= 2;	
	}

	void printIndent()
	{
		foreach (i; 0 .. indentLevel)
			write(' ');
	}

	override void visit(TerminalNode node)
	{
		printIndent();
		writeln("Terminal node: ", node.name);
	}

	override void visit(NonTerminalNode node)
	{
		printIndent();
		writeln("NonTerminal node: ", node.name);
		indent();
		foreach (prod; node.productions)
			prod.accept(this);
		deindent();
	}
}

unittest
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

	test("a dog drink");
	test("Shrek fight on a bridge");
	test("the cat run inside the house");
	test("Yoshi eat below a castle");
	test("Shrek eat on a plane and Snake run with the big cat");
	test("the fluffy sheep dance in a car but Shrek fight with Snake");
	test("a donkey eat for a dragon that sleep in the castle");
}
