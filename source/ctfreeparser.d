module ctfreeparser;

import ctfreegenerator;
import std.traits;

mixin template implTerminalSymbol()
{
	this(string name)
	{
		this.name = name;
	}

	string name;
}

struct TerminalSymbol {}

// automaticly generate specialized visit method for each child of ASTNode
string genVisitMethods()
{
	string codeGen;
	static foreach(memStr; __traits(allMembers, mixin(__MODULE__)))
	{
		static if (isType!(mixin(memStr)) &&
			!__traits(isSame, mixin(memStr), ASTNode) && 
			isImplicitlyConvertible!(mixin(memStr), ASTNode))
		{
			codeGen ~= q{void visit(} ~ memStr ~ q{);};
		}
	}
	return codeGen;
}

mixin template implementVisitor()
{
	override void accept(ASTvisitor v)
	{
		v.visit(this);
	}
}

interface ASTvisitor
{
	mixin(genVisitMethods());
}

interface ASTNode
{ 
	void accept(ASTvisitor);
}

class Phrase : ASTNode
{
	mixin implementVisitor;

	Subject subject;
	Verb verb;
	Complement complement;
	Conjonction conjonction;
}

abstract class Subject : ASTNode {}

@TerminalSymbol
class Noun : Subject 
{
	mixin implTerminalSymbol;
	mixin implementVisitor;
}

class AnimalSubject : Subject
{
	mixin implementVisitor;

	Article article;
	Adjective adjective;
	Animal animal;
}

@TerminalSymbol
class Verb : ASTNode
{
	mixin implTerminalSymbol;
	mixin implementVisitor;
}

abstract class Complement : ASTNode {}

class AdjectiveComplement : Complement
{
	mixin implementVisitor;

	AdjectivePreposition preposition;
	Subject subject;
}

class PlaceComplement : Complement
{
	mixin implementVisitor;

	PlacePreposition preposition;
	Place place;
}

@TerminalSymbol
class Article : ASTNode
{
	mixin implementVisitor;
	mixin implTerminalSymbol;
}

abstract class Conjonction : ASTNode {}

class PhraseConjonction : Conjonction
{
	mixin implementVisitor;

	string conjonctionWord;
	Phrase phrase;
}

class ForConjonction : Conjonction 
{
	mixin implementVisitor;

	Subject subject;
	Verb verb;
	Complement complement;
}

@TerminalSymbol
class Animal : ASTNode 
{
	mixin implTerminalSymbol;
	mixin implementVisitor;
}

@TerminalSymbol
class Adjective : ASTNode 
{
	mixin implTerminalSymbol;
	mixin implementVisitor;
}

@TerminalSymbol
class Place : ASTNode 
{
	mixin implementVisitor;
	mixin implTerminalSymbol;
}

abstract class Preposition : ASTNode {}

@TerminalSymbol
class AdjectivePreposition : Preposition 
{
	mixin implementVisitor;
	mixin implTerminalSymbol;
}

@TerminalSymbol
class PlacePreposition : Preposition 
{
	mixin implementVisitor;
	mixin implTerminalSymbol;
}

class PrintVisitor : ASTvisitor
{
	import std.stdio;

	uint indentLevel = 0;
	
	void printIndent()
	{
		foreach (i; 0 .. indentLevel)
			write(" ");
	}

	void indent()
	{
		indentLevel += 2;
	}

	void print(Args...)(string fmt, Args args)
	{
		printIndent();
		writefln(fmt, args);
	}

	override void visit(Phrase p)
	{
		print("phrase: ");
		indent();
		p.subject.accept(this);
		p.verb.accept(this);
		p.complement.accept(this);
		if (p.conjonction !is null)
			p.conjonction.accept(this);
	}

	override void visit(AnimalSubject s)
	{
		print("AnimalSubject: ");
		indent();
		s.article.accept(this);
		s.adjective.accept(this);
		s.animal.accept(this);
	}

	override void visit(AdjectiveComplement c)
	{
		print("AdjectiveComplement: ");
		indent();
		c.preposition.accept(this);
		c.subject.accept(this);
	}

	override void visit(PlaceComplement c)
	{
		print("PlaceComplement: ");
		indent();
		c.preposition.accept(this);
		c.place.accept(this);
	}

	override void visit(PhraseConjonction c)
	{
		print("phrase conjonction: ");
		print("conjonction word: %s", c.conjonctionWord);
		indent();
		c.phrase.accept(this);
	}

	override void visit(ForConjonction c)
	{
		print("ForConjonction: ");
		indent();
		c.subject.accept(this);
		if (c.verb !is null)
		{
			c.verb.accept(this);
			c.complement.accept(this);
		}
	}

	override void visit(Preposition)
	{
		assert(false, "Preposition is abstract");
	}

	override void visit(Subject)
	{
		assert(false, "Subject is abstract");
	}

	override void visit(Conjonction)
	{
		assert(false, "Conjonction is abstract");
	}

	override void visit(Complement)
	{
		assert(false, "Complement is abstract");
	}

	// generate automagically terminal members
	static foreach(mem; __traits(allMembers, mixin(__MODULE__)))
	{
		static if (hasUDA!(mixin(mem), TerminalSymbol))
		{
			override void visit(mixin(mem) e)
			{
				print(mem ~ ": %s", e.name);
			}
		}
	}
}

class Parser
{
	import std.range;
	import std.algorithm;

	this(string source)
	{
		words = source.split(' ');
	}

	Subject parseSubject()
	{
		auto word = front(words);
		words.popFront();
		if (canFind(nouns, word))
			return new Noun(word);

		auto subject = new AnimalSubject();
		if (!canFind(articles, word))
			throw new Exception(word ~ " is not a correct noun or article !");
		subject.article = new Article(word);

		if (!canFind(adjective, front(words)))
			throw new Exception(front(words) ~ " is not a correct adjective !");
		subject.adjective = new Adjective(front(words));
		words.popFront();

		if (!canFind(animals, front(words)))
			throw new Exception(front(words) ~ " is not a correct animal !");
		subject.animal = new Animal(front(words));
		words.popFront();

		return subject;
	}

	Verb parseVerb()
	{
		auto verb = front(words);
		if (!canFind(verbs, verb))
			throw new Exception(verb ~ " is not a correct verb !");
		words.popFront();
		return new Verb(verb);
	}

	Complement parseComplement()
	{
		if (canFind(adjective_preposition, front(words)))
		{
			auto complement = new AdjectiveComplement();
			complement.preposition = new AdjectivePreposition(front(words));
			words.popFront();
			complement.subject = parseSubject();
			return complement;
		}
		if (canFind(place_preposition, front(words)))
		{
			auto complement = new PlaceComplement();
			complement.preposition = new PlacePreposition(front(words));
			words.popFront();
			if (!canFind(places, front(words)))
				throw new Exception(front(words) ~ " is not a valid place");
			complement.place = new Place(front(words));
			words.popFront();
			return complement;
		}
		throw new Exception("invalid complement : " ~ front(words) ~ " is not a valid preposition starter");
	}

	Conjonction parseConjonction()
	{
		if (canFind(["and", "but"], front(words)))
		{
			auto conjonction = new PhraseConjonction();
			conjonction.conjonctionWord = front(words);
			words.popFront();
			conjonction.phrase = parsePhrase();
			return conjonction;
		}
		if (front(words) == "for")
		{
			auto conjonction = new ForConjonction();
			words.popFront();
			conjonction.subject = parseSubject();
			if (!words.empty)
				conjonction.complement = parseComplement();
			return conjonction;
		}
		throw new Exception("invalid conjonction : " ~ front(words) ~ " is not a valid conjonction starter");
	}

	Phrase parsePhrase()
	{
		auto phrase = new Phrase();
		phrase.subject = parseSubject();
		phrase.verb = parseVerb();
		phrase.complement = parseComplement();
		if (!words.empty)
			phrase.conjonction = parseConjonction();
		return phrase;
	}

	string[] words;
	uint index;
}

unittest
{
	auto phrases = [
		"a hot dragon yell with a strange pig and a heavy squirrel dance with Guillaume",
		"Boris yell with Dark-Vador for Florian",
		"Bryan run with the yellow pig and a strange platypus dance with Boris"
	];
	
	foreach (phrase; phrases)
	{
		auto parser = new Parser(phrase);
		auto ast = parser.parsePhrase();
		auto printer = new PrintVisitor();
		printer.visit(ast);
	}
}