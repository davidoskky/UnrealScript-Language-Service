parser grammar UCParser;

options { tokenVocab = UCLexer; }

// Class modifier keywords have been commented out, because we are not using them for parsing.
identifier
	: ID
	| 'default'
	| 'self'
	| 'super'
	| 'global'
	| 'class'
	| 'interface'
	| 'within'
	| 'const'
	| 'enum'
	| 'struct'
	| 'var'
	| 'local'
	| 'replication'
	| 'operator'
	| 'preoperator'
	| 'postoperator'
	| 'delegate'
	| 'function'
	| 'event'
	| 'state'
	| 'map'
	| 'defaultproperties'
	| 'structdefaultproperties'
	| 'for'
	| 'foreach'
	| 'return'
	| 'break'
	| 'continue'
	| 'stop'
	| 'case'
	| 'switch'
	| 'until'
	| 'do'
	| 'while'
	| 'else'
	| 'if'
	| 'ignores'
	| 'unreliable'
	| 'reliable'
	| 'cpptext'
	| 'cppstruct'
	| 'structcpptext'
	| 'array'
	| 'byte'
	| 'int'
	| 'float'
	| 'string'
	| 'pointer'
	| 'button'
	| 'bool'
	| 'name'
	| 'true'
	| 'false'
	| 'none'
	| 'extends'
	| 'expands'
	| 'public'
	| 'protected'
	| 'protectedwrite'
	| 'private'
	| 'privatewrite'
	| 'localized'
	| 'out'
	| 'ref'
	| 'optional'
	| 'init'
	| 'skip'
	| 'coerce'
	| 'final'
	| 'latent'
	| 'singular'
	| 'static'
	| 'exec'
	| 'iterator'
	| 'simulated'
	| 'auto'
	| 'noexport'
	| 'noexportheader'
	| 'editconst'
	| 'edfindable'
	| 'editinline'
	| 'editinlinenotify'
	| 'editinlineuse'
	| 'edithide'
	| 'editconstarray'
	| 'editfixedsize'
	| 'editoronly'
	| 'editortextbox'
	| 'noclear'
	| 'noimport'
	| 'nontransactional'
	| 'serializetext'
	| 'config'
	| 'globalconfig'
	| 'intrinsic'
	| 'native'
	// |'nativereplication'
	// |'nativeonly'
	| 'export'
	// |'abstract'
	// |'perobjectconfig'
	// |'perobjectlocalized'
	// |'placeable'
	// |'nousercreate'
	// |'notplaceable'
	// |'safereplace'
	| 'dependson'
	// |'showcategories'
	// |'hidecategories'
	// |'guid'
	| 'long'
	| 'transient'
	// |'nontransient'
	| 'cache'
	| 'interp'
	| 'repretry'
	| 'repnotify'
	| 'notforconsole'
	| 'archetype'
	| 'crosslevelactive'
	| 'crosslevelpassive'
	| 'allowabstract'
	| 'automated'
	| 'travel'
	| 'input'
	// |'cacheexempt'
	// |'hidedropdown'
	| 'instanced'
	| 'databinding'
	| 'duplicatetransient'
	// |'parseconfig'
	// |'editinlinenew'
	// |'noteditinlinenew'
	// |'exportstructs'
	// |'dllbind'
	| 'deprecated'
	| 'strictconfig'
	| 'atomic'
	| 'atomicwhencooked'
	| 'immutable'
	| 'immutablewhencooked'
	| 'virtual'
	| 'server'
	| 'client'
	| 'dllimport'
	| 'demorecording'
	| 'k2call'
	| 'k2pure'
	| 'k2override'
	// |'collapsecategories'
	// |'dontcollapsecategories'
	| 'implements'
	// |'classgroup'
	// |'autoexpandcategories'
	// |'autocollapsecategories'
	// |'dontautocollapsecategories'
	// |'dontsortcategories'
	// |'inherits'
	// |'forcescriptorder'
	| 'begin'
	| 'object'
	| 'end'
	| 'new'
	| 'goto'
	| 'assert'
	| 'vect'
	| 'rot'
	| 'rng'
	;

// Parses the following possiblities.
// Package.Class
// Class.Field
// Class / Field
qualifiedIdentifier: left=identifier (DOT right=identifier)?;

// FIXME: Consumes atleast one token after "#error"
directive
	: SHARP identifier
	{((): boolean => {
			if (!this.currentToken) {
				return true;
			}

			const initialLine = this.currentToken.line;
			while (this.currentToken.line === initialLine) {
				if (this.matchedEOF) {
					break;
				}

				this.consume();
				// FIXME!
				if (!this.currentToken || this.currentToken.text === '<EOF>') {
					break;
				}
			}
			return true;
	})()}?
	;

program: member* EOF;

member
	: classDecl
	| constDecl
	| (enumDecl SEMICOLON)
	| (structDecl SEMICOLON)
	| varDecl
	| cppText
	| replicationBlock
	| functionDecl
	| stateDecl
	| defaultPropertiesBlock
	| directive
	| SEMICOLON
	;

literal
	: boolLiteral
	| intLiteral
	| floatLiteral
	| stringLiteral
	| noneLiteral
	| nameLiteral
	| vectToken
	| rotToken
	| rngToken
	| objectLiteral
	;

floatLiteral: (MINUS | PLUS)? FLOAT;
intLiteral: (MINUS | PLUS)? INTEGER;

numberLiteral: (MINUS | PLUS)? (FLOAT | INTEGER);
stringLiteral: STRING;
nameLiteral: NAME;
boolLiteral
	: 'true'
	| 'false'
	;
noneLiteral: 'none';

// e.g. Class'Engine.Actor'.const.MEMBER or Texture'Textures.Group.Name'.default
objectLiteral: identifier NAME;

classDecl
	: ('class' | 'interface') identifier (extendsClause withinClause?)?
		classModifier*
		SEMICOLON
	;

extendsClause: ('extends' | 'expands') id=qualifiedIdentifier;
withinClause: 'within' id=qualifiedIdentifier;

classModifier
    :
	// in UC3 a class can have a custom native name.
	(KW_NATIVE modifierArgument?)                                                               #nativeModifier
	// | KW_NATIVEREPLICATION
	// | KW_LOCALIZED // UC1
	// | KW_ABSTRACT
	// | KW_PEROBJECTCONFIG
	| KW_TRANSIENT                                                                              #transientModifier
	| KW_EXPORT                                                                                 #exportModifier
	// | KW_NOEXPORT
	// | KW_NOUSERCREATE
	// | KW_SAFEREPLACE
	// | (KW_CONFIG modifierArgument?)
	// // UC2+
	// | KW_PLACEABLE
	// | KW_NOTPLACEABLE
	// | KW_CACHEEXEMPT // UT2004
	// | KW_HIDEDROPDOWN
	// | KW_EXPORTSTRUCTS
	// | KW_INSTANCED
	// | KW_PARSECONFIG
	// | KW_EDITINLINENEW
	// | KW_NOTEDITINLINENEW
	| (KW_DEPENDSON OPEN_PARENS identifierArguments CLOSE_PARENS)                               #dependsOnModifier
	// | (KW_COLLAPSECATEGORIES modifierArguments)
	// | (KW_DONTCOLLAPSECATEGORIES modifierArguments?)
	// | (KW_SHOWCATEGORIES modifierArguments)
	// | (KW_HIDECATEGORIES modifierArguments)
	// | (KW_GUID (LPAREN INTEGER COMMA INTEGER COMMA INTEGER COMMA INTEGER RPAREN))
	// // UC3+
	// | KW_NATIVEONLY
	// | KW_NONTRANSIENT
	// | KW_PEROBJECTLOCALIZED
	// | KW_DEPRECATED
	// | (KW_CLASSREDIRECT modifierArgument)
	// | (KW_DLLBIND modifierArgument)
	| (KW_IMPLEMENTS OPEN_PARENS qualifiedIdentifierArguments CLOSE_PARENS)                     #implementsModifier
	// | (KW_CLASSGROUP modifierArguments)
	// | (KW_AUTOEXPANDCATEGORIES modifierArguments)
	// | (KW_AUTOCOLLAPSECATEGORIES modifierArguments)
	// | (KW_DONTAUTOCOLLAPSECATEGORIES modifierArguments)
	// | (KW_DONTSORTCATEGORIES modifierArguments)
	// | (KW_INHERITS modifierArguments)
	// // true/false only
	// | (KW_FORCESCRIPTORDER modifierArgument)
	// ; //ID (LPARENT ID (COMMA ID)* RPARENT)?
    | (identifier modifierArguments?)                                                           #unidentifiedModifier
    ;

modifierValue
	: identifier
	| numberLiteral
	;

modifierArgument
	: OPEN_PARENS modifierValue? CLOSE_PARENS
	;

modifierArguments
	: OPEN_PARENS (modifierValue COMMA?)* CLOSE_PARENS
	;

identifierArguments
    : (identifier COMMA?)*
    ;

qualifiedIdentifierArguments
    : (qualifiedIdentifier COMMA?)*
    ;

constDecl
	: 'const' identifier (ASSIGNMENT expr=constValue)? SEMICOLON
	;

constValue
	: noneLiteral
	| boolLiteral
	| floatLiteral
	| intLiteral
	| stringLiteral
	| objectLiteral
	| nameLiteral
	| vectToken
	| rotToken
	| rngToken
	| arrayCountToken
	| nameOfToken
	| sizeOfToken
	;

arrayCountToken
    : 'arraycount' (OPEN_PARENS expr=primaryExpression CLOSE_PARENS)
    ;

nameOfToken
    : 'nameof' (OPEN_PARENS expr=primaryExpression CLOSE_PARENS)
    ;

vectToken
	: 'vect' (OPEN_PARENS numberLiteral COMMA numberLiteral COMMA numberLiteral CLOSE_PARENS)
	;

rotToken
	: 'rot' (OPEN_PARENS numberLiteral COMMA numberLiteral COMMA numberLiteral CLOSE_PARENS)
	;

rngToken
	: 'rng' (OPEN_PARENS numberLiteral COMMA numberLiteral CLOSE_PARENS)
	;

sizeOfToken
	: 'sizeof' (OPEN_PARENS identifier CLOSE_PARENS)
	;

enumDecl:
	'enum' identifier metaData?
	OPEN_BRACE
		(enumMember (COMMA enumMember)* COMMA?)?
	CLOSE_BRACE
	;

enumMember
	: identifier metaData? COMMA?
	;

structDecl
	:	'struct' exportBlockText? structModifier* identifier extendsClause?
		OPEN_BRACE
			structMember*
		CLOSE_BRACE
	;

structMember
	: constDecl
	| (enumDecl SEMICOLON)
	| (structDecl SEMICOLON)
	| varDecl
	| structCppText
	| structDefaultPropertiesBlock
	| directive
	| SEMICOLON
	;

structModifier
	// UC2+
	: 'native'
	| 'transient'
	| 'export'
	| 'init'
	| 'long'
	// UC3+
	| 'strictconfig'
	| 'atomic'
	| 'atomicwhencooked'
	| 'immutable'
	| 'immutablewhencooked'
	;

arrayDimRefer
	: INTEGER
	| qualifiedIdentifier // Referres a constant in class scope, or an enum's member.
	;

// var (GROUP)
// MODIFIER TYPE
// VARIABLE, VARIABLE...;
varDecl
	: 'var' (OPEN_PARENS categoryList? CLOSE_PARENS)? varType
	   variable (COMMA variable)* SEMICOLON
	;

// id[5] {DWORD} <Order=1>
variable
	: identifier (OPEN_BRACKET arrayDim=arrayDimRefer? CLOSE_BRACKET)?
	exportBlockText?
	metaData?
	;

// UC3 <UIMin=0.0|UIMax=1.0|Toolip=Hello world!>
metaData
	: LT metaTagList? GT
	;

metaTagList
	: metaTag (BITWISE_OR metaTag)*
	;

metaTag
	: identifier (ASSIGNMENT metaText)?
	;

metaText
	: (~(BITWISE_OR | GT))*
	;

categoryList
	: identifier (COMMA identifier)*
	;

variableModifier
	: ('localized'
	| 'native'
    | 'intrinsic'
	| 'const'
	| 'editconst'
	| 'globalconfig'
	| 'transient'
	| 'travel'
	| 'input'
	// UC2
	| 'export'
	| 'noexport'
	| 'noimport'
	| 'cache'
	| 'automated'
	| 'editinline'
	| 'editinlinenotify'
	| 'editinlineuse'
	| 'editconstarray'
	| 'edfindable'
	// UC3
	| 'init'
	| 'edithide'
	| 'editfixedsize'
	| 'editoronly'
	| 'editortextbox'
	| 'noclear'
	| 'serializetext'
	| 'nontransactional'
	| 'instanced'
	| 'databinding'
	| 'duplicatetransient'
	| 'repretry'
	| 'repnotify'
	| 'interp'
	| 'deprecated'
	| 'notforconsole'
	| 'archetype'
	| 'crosslevelactive'
	| 'crosslevelpassive'
	| 'allowabstract')
	// I have only see this occur in XCOM2, but may possibly be a late UC3+ feature
	| ('config' (OPEN_PARENS identifier CLOSE_PARENS)? )
	| ('public' exportBlockText?)
	| ('protected' exportBlockText?)
	| ('protectedwrite' exportBlockText?)
	| ('private' exportBlockText?)
	| ('privatewrite' exportBlockText?)
	;

primitiveType
	: 'byte'
	| 'int'
	| 'float'
	| 'bool'
	| 'pointer'
	| 'string'
	| 'name'
	| 'button' // alias for a string with an input modifier
	;

typeDecl
	: enumDecl 		// Only allowed as a top-scope member.
	| structDecl 	// Only allowed as a top-scope member.
	| primitiveType
	| classType
	| arrayType
	| delegateType
	| mapType
	| qualifiedIdentifier
	;

varType
	: variableModifier* typeDecl
	;

// Note: inlinedDeclTypes includes another arrayGeneric!
arrayType
	: 'array' (LT varType GT)
	;

classType
	: 'class' (LT identifier GT)?
	;

delegateType
	: 'delegate' (LT qualifiedIdentifier GT)
	; // TODO: qualifiedIdentifier is hardcoded to 2 identifiers MAX.

mapType
	: 'map' exportBlockText
	;

cppText
	: 'cpptext' exportBlockText
	;

structCppText
	: ('structcpptext' | 'cppstruct') exportBlockText
	;

// UnrealScriptBug: Anything WHATSOEVER can be written after this closing brace as long as it's on the same line!
exportBlockText
	: OPEN_BRACE (~(OPEN_BRACE | CLOSE_BRACE)+ | exportBlockText)* CLOSE_BRACE
	;

replicationBlock
	: 'replication'
		OPEN_BRACE
			replicationStatement*
		CLOSE_BRACE
	;

replicationModifier
	: 'reliable'
	| 'unreliable'
	;

replicationStatement
	: replicationModifier? 'if' (OPEN_PARENS expr=expression CLOSE_PARENS)
		identifier (COMMA identifier)* SEMICOLON
	;

/* Parses:
 * public simulated function coerce class<Actor> test(optional int p1, int p2) const;
 */
functionDecl
	: functionSpecifier+ returnParam=functionReturnParam?
	  functionName (OPEN_PARENS params=parameters? CLOSE_PARENS) 'const'?
	  functionBody?
	;

functionReturnParam
	: returnTypeModifier? typeDecl
	;

functionBody
	: SEMICOLON
	| (OPEN_BRACE
		functionMember*
		statement*
	  CLOSE_BRACE)
	;

/* Parses:
 * { local Actor test, test2; return test.Class; }
 */
functionMember
	: constDecl
	| localDecl
	| directive
	| SEMICOLON
	;

functionSpecifier
	: ('function'
	| 'simulated'
	| 'static'
	| 'exec'
	| 'final'
	| 'event'
	| 'delegate'
	| 'preoperator'
	| 'postoperator'
	| 'latent'
	| 'singular'
	| 'iterator'
	// UC3
	| 'const'
	| 'noexport'
	| 'noexportheader'
	| 'virtual'
	| 'reliable'
	| 'unreliable'
	| 'server'
	| 'client'
	| 'dllimport'
	| 'demorecording'
	| 'k2call'
	| 'k2pure'
	| 'k2override')
	| ('native' (OPEN_PARENS nativeToken=INTEGER CLOSE_PARENS)?)
	| ('intrinsic' (OPEN_PARENS nativeToken=INTEGER CLOSE_PARENS)?)
	| ('operator' (OPEN_PARENS operatorPrecedence=INTEGER CLOSE_PARENS))
	| ('public' exportBlockText?)
	| ('protected' exportBlockText?)
	| ('private' exportBlockText?)
	;

functionName: identifier | operatorName;

parameters: paramDecl (COMMA paramDecl)*;
paramDecl: paramModifier* typeDecl variable (ASSIGNMENT expr=expression)?;

returnTypeModifier
	: 'coerce' // UC3+
	;

paramModifier
	: 'out'
	| 'ref'	// XCom or late UC3+ (Seen in other licenseed games).
	| 'optional'
	| 'init'
	| 'skip'
	| 'coerce'
	| 'const'
	;

localDecl
	: 'local' typeDecl variable (COMMA variable)* SEMICOLON
	;

stateDecl
	: stateModifier* 'state' (OPEN_PARENS CLOSE_PARENS)? identifier extendsClause?
		OPEN_BRACE
			stateMember*
			statement*
		CLOSE_BRACE
	;

stateModifier
	: 'auto'
	| 'simulated'
	;

stateMember
	: constDecl
	| localDecl
	| ignoresDecl
	| functionDecl
	| directive
	| SEMICOLON
	;

ignoresDecl
	: 'ignores' (identifier (COMMA identifier)*) SEMICOLON
	;

codeBlockOptional
	: (OPEN_BRACE statement* CLOSE_BRACE)
	| statement
	;

statement
	: SEMICOLON
	| ifStatement
	| forStatement
	| foreachStatement
	| whileStatement
	| doStatement
	| switchStatement

	| breakStatement
	| continueStatement
	| returnStatement
	| gotoStatement

	| labeledStatement
	| assertStatement
	| stopStatement
	| constDecl

	// We must check for expressions after ALL statements so that we don't end up capturing statement keywords as identifiers.
	| expressionStatement
	| directive
	;

expressionStatement: expressionWithAssignment SEMICOLON;

ifStatement
	: 'if' (OPEN_PARENS expr=expression? CLOSE_PARENS)
		codeBlockOptional
	  elseStatement?
	;

elseStatement: 'else' codeBlockOptional;
foreachStatement: 'foreach' expr=primaryExpression codeBlockOptional;

forStatement
	: 'for' (OPEN_PARENS (initExpr=expressionWithAssignment SEMICOLON) (condExpr=expressionWithAssignment SEMICOLON) nextExpr=expressionWithAssignment CLOSE_PARENS)
		codeBlockOptional
	;

whileStatement
	: 'while' (OPEN_PARENS expr=expression? CLOSE_PARENS)
		codeBlockOptional
	;

doStatement
	: 'do'
		codeBlockOptional
	  'until' (OPEN_PARENS expr=expression? CLOSE_PARENS)
	;

switchStatement
	: 'switch' (OPEN_PARENS expr=expression? CLOSE_PARENS)
		// Note: Switch braces are NOT optional
		OPEN_BRACE
			caseClause*
			defaultClause?
		CLOSE_BRACE
	;

caseClause
	: 'case' expr=expression? COLON
		statement*
	;

defaultClause
	: 'default' COLON
		statement*
	;

returnStatement: 'return' expr=expression? SEMICOLON;
breakStatement: 'break' SEMICOLON;
continueStatement: 'continue' SEMICOLON;
stopStatement: 'stop' SEMICOLON;
labeledStatement: identifier COLON;
gotoStatement: 'goto' expr=expression? SEMICOLON;
assertStatement: 'assert' (OPEN_PARENS expr=expression? CLOSE_PARENS) SEMICOLON;

// All valid operator names (for declarations)
operatorName
	: STAR
	| DIV
	| MODULUS
	| PLUS
	| MINUS
	| LSHIFT
	| RSHIFT
	| SHIFT
	| DOLLAR
	| AT
	| SHARP
	| BANG
	| AMP
	| BITWISE_OR
	| CARET
	| INCR
	| DECR
	| TILDE
	| EXP
	| LT
	| GT
	| OR
	| AND
	| EQ
	| NEQ
	| GEQ
	| LEQ
	| IEQ
	| MEQ
	| ASSIGNMENT_INCR
	| ASSIGNMENT_DECR
	| ASSIGNMENT_AT
	| ASSIGNMENT_DOLLAR
	| ASSIGNMENT_AND
	| ASSIGNMENT_OR
	| ASSIGNMENT_STAR
	| ASSIGNMENT_CARET
	| ASSIGNMENT_DIV
	;

expressionWithAssignment
	: assignmentExpression
	| primaryExpression
	;

expression
	: primaryExpression
	;

// Inclusive template argument (will be parsed as a function call)

assignmentExpression
	: left=primaryExpression id=ASSIGNMENT right=primaryExpression
	;

primaryExpression
	: primaryExpression (OPEN_BRACKET arg=expression? CLOSE_BRACKET) 						#elementAccessExpression
	| primaryExpression '.' classPropertyAccessSpecifier '.' identifier						#propertyClassAccessExpression
	| primaryExpression '.' identifier?												        #propertyAccessExpression
	| primaryExpression (OPEN_PARENS arguments? CLOSE_PARENS) 								#callExpression

	| 'new' 		(OPEN_PARENS arguments? CLOSE_PARENS)? expr=primaryExpression			#newExpression
	| 'class' 		(LT identifier GT) (OPEN_PARENS expr=expression CLOSE_PARENS)			#metaClassExpression
	| 'arraycount' 	(OPEN_PARENS expr=primaryExpression CLOSE_PARENS)						#arrayCountExpression
	| 'nameof' 	    (OPEN_PARENS expr=primaryExpression CLOSE_PARENS)						#nameOfExpression
	| 'super' 		(OPEN_PARENS identifier CLOSE_PARENS)?									#superExpression

	| id=INCR right=primaryExpression														#preOperatorExpression
	| id=DECR right=primaryExpression														#preOperatorExpression
	| id=PLUS right=primaryExpression														#preOperatorExpression
	| id=MINUS right=primaryExpression														#preOperatorExpression
	| id=TILDE right=primaryExpression														#preOperatorExpression
	| id=BANG right=primaryExpression														#preOperatorExpression
	| id=MODULUS right=primaryExpression													#preOperatorExpression
	| id=SHARP right=primaryExpression														#preOperatorExpression
	| id=DOLLAR right=primaryExpression														#preOperatorExpression
	| id=AT right=primaryExpression															#preOperatorExpression
	| left=primaryExpression id=INCR 														#postOperatorExpression
	| left=primaryExpression id=DECR 														#postOperatorExpression

	| left=primaryExpression id=(ASSIGNMENT_INCR
		| ASSIGNMENT_DECR
		| ASSIGNMENT_AT
		| ASSIGNMENT_DOLLAR
		| ASSIGNMENT_AND
		| ASSIGNMENT_OR
		| ASSIGNMENT_STAR
		| ASSIGNMENT_CARET
		| ASSIGNMENT_DIV) right=primaryExpression											#binaryOperatorExpression

	| left=primaryExpression id=EXP right=primaryExpression 								#binaryOperatorExpression
	| left=primaryExpression id=(STAR|DIV) right=primaryExpression 							#binaryOperatorExpression
	| left=primaryExpression id=MODULUS right=primaryExpression 							#binaryOperatorExpression
	// Note, checking for ID instead of identifier here,
	// -- so that we don't missmtach 'if, or return' statements
	// -- after a foreach's expression.
	| left=primaryExpression id=ID right=primaryExpression 									#binaryNamedOperatorExpression
	| left=primaryExpression id=(PLUS|MINUS) right=primaryExpression 						#binaryOperatorExpression
	| left=primaryExpression id=(LSHIFT|RSHIFT|SHIFT) right=primaryExpression 				#binaryOperatorExpression
	| left=primaryExpression id=(LT|GT|LEQ|GEQ|EQ|IEQ) right=primaryExpression 				#binaryOperatorExpression
	| left=primaryExpression id=NEQ right=primaryExpression 								#binaryOperatorExpression
	| left=primaryExpression id=(AMP|CARET|BITWISE_OR) right=primaryExpression 				#binaryOperatorExpression
	| left=primaryExpression id=(AND|MEQ) right=primaryExpression 							#binaryOperatorExpression
	| left=primaryExpression id=OR right=primaryExpression 									#binaryOperatorExpression
	| left=primaryExpression id=(DOLLAR|AT) right=primaryExpression 						#binaryOperatorExpression

	| cond=primaryExpression INTERR left=primaryExpression COLON right=primaryExpression	#conditionalExpression

	| 'self'																				#selfReferenceExpression
	| 'default'																				#defaultReferenceExpression
	| 'static'																				#staticAccessExpression
	| 'global'																				#globalAccessExpression

	| literal 																				#literalExpression

	// Note any keyword must preceed identifier!
	| identifier 																			#memberExpression

	// | id=identifier right=primaryExpression													#preNamedOperatorExpression
	// | left=primaryExpression id=identifier													#postNamedOperatorExpression

	| (OPEN_PARENS expr=primaryExpression CLOSE_PARENS) 									#parenthesizedExpression
	;

classPropertyAccessSpecifier
	: 'default'
	| 'static'
	| 'const'
	;

// 	created(, s, test);
argument: COMMA | expression COMMA?;
arguments: argument+;

// (~CLOSE_BRACE { this.notifyErrorListeners('Redundant token!'); })
defaultPropertiesBlock
	:
		'defaultproperties'
		// UnrealScriptBug: Must be on the line after keyword!
		(OPEN_BRACE defaultStatement* CLOSE_BRACE)
	;

structDefaultPropertiesBlock
	:
		'structdefaultproperties'
		// UnrealScriptBug: Must be on the line after keyword!
		(OPEN_BRACE defaultStatement* CLOSE_BRACE)
	;

// TODO: Perhaps do what we do in the directive rule, just skip until we hit a new line or a "|".
defaultStatement
	: objectDecl
	| defaultAssignmentExpression
	| defaultMemberCallExpression

	// "command chaining", e.g. "IntA=1|IntB=2" is valid code,
	// -- but if the | were a space, the second variable will be ignored (by the compiler).
	| BITWISE_OR

	// TODO: Add a warning, from a technical point of view,
	// -- the UC compiler just skips any character till it hits a newline character.
	| SEMICOLON
	;

defaultExpression
	: identifier (OPEN_BRACKET arg=defaultArgument CLOSE_BRACKET)				#defaultElementAccessExpression
	| identifier (OPEN_PARENS arg=defaultArgument CLOSE_PARENS)					#defaultElementAccessExpression
	| identifier																#defaultMemberExpression
	;

// TODO: does UC coerce float here?
defaultArgument
	: intLiteral
	| floatLiteral
	// TODO: Is this possible?
	// | qualifiedIdentifierLiteral
	| identifierLiteral
	;

defaultAssignmentExpression
	: defaultExpression ASSIGNMENT ((OPEN_BRACE defaultLiteral CLOSE_BRACE) | defaultLiteral)
	;

// TODO: (verify) Could the first identifier be a defaultExpression e.g. Array(0).ArrayMember.Add(1)?
defaultMemberCallExpression
	: identifier DOT propId=identifier (OPEN_PARENS arguments? CLOSE_PARENS)?
	;

objectDecl
	:
		// UnrealScriptBug: name= and class= are required to be on the same line as the keyword!
		('begin' 'object') objectAttribute+
			defaultStatement*
		('end' 'object')
	;

objectAttribute
	: id=KW_NAME ASSIGNMENT value=identifier
	| id=KW_CLASS ASSIGNMENT value=identifier
	;

// (variableList)
structLiteral
	: OPEN_PARENS defaultArguments? CLOSE_PARENS
	;

qualifiedIdentifierLiteral
	: identifier (DOT identifier)+
	;

identifierLiteral
	: identifier
	;

// id=literal,* or literal,*
defaultArguments
	: (defaultLiteral (COMMA defaultLiteral)*)
	| (defaultAssignmentExpression (COMMA defaultAssignmentExpression)*)
	;

defaultLiteral
	: structLiteral
	| noneLiteral
	| boolLiteral
	| floatLiteral
	| intLiteral
	| stringLiteral
	| objectLiteral
	| qualifiedIdentifierLiteral
	| identifierLiteral
	;