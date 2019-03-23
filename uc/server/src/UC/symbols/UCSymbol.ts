import { Range, SymbolKind, SymbolInformation, CompletionItem, CompletionItemKind, Position } from 'vscode-languageserver-types';

import { ISymbol, ISymbolReference } from './ISymbol';
import { UCStructSymbol, UCPackage } from "./";
import { UCDocumentListener } from "../DocumentListener";
import { ParserRuleContext, CommonTokenStream } from 'antlr4ts';
import { UCGrammarParser } from '../../antlr/UCGrammarParser';

export const COMMENT_TYPES = new Set([UCGrammarParser.LINE_COMMENT, UCGrammarParser.BLOCK_COMMENT]);

export const NO_NAME = '';

/**
 * A symbol that resides in a document, holding an id and range.
 */
export abstract class UCSymbol implements ISymbol {
	public outer?: ISymbol;
	public context?: ParserRuleContext;

	/** Locations that reference this symbol. */
	private refs?: Set<ISymbolReference>;

	constructor(private nameRange: Range) {
	}

	getTypeTooltip(): string | undefined {
		return undefined;
	}

	getTooltip(): string | undefined {
		return this.getName();
	}

	getDocumentation(tokenStream: CommonTokenStream): string | undefined {
		if (!this.context) {
			return undefined;
		}

		const leadingComment = tokenStream
			.getHiddenTokensToRight(this.context.stop.tokenIndex)
			.filter(token => COMMENT_TYPES.has(token.type) && token.charPositionInLine !== 0);

		if (leadingComment && leadingComment.length > 0) {
			return leadingComment.shift().text;
		}

		const headerComment = tokenStream
			.getHiddenTokensToLeft(this.context.start.tokenIndex)
			.filter(token => COMMENT_TYPES.has(token.type) && token.charPositionInLine === 0);

		if (headerComment && headerComment.length > 0) {
			return headerComment.map(comment => comment.text).join('\n');
		}
		return undefined;
	}

	getName(): string {
		return NO_NAME;
	}

	getQualifiedName(): string {
		if (this.outer) {
			return this.outer.getQualifiedName() + '.' + this.getName();
		}
		return this.getName();
	}

	getKind(): SymbolKind {
		return SymbolKind.Field;
	}

	getCompletionItemKind(): CompletionItemKind {
		return CompletionItemKind.Text;
	}

	getNameRange(): Range {
		return this.nameRange;
	}

	getSpanRange(): Range {
		return this.nameRange;
	}

	protected intersectsWithName(position: Position): boolean {
		var range = this.getNameRange();
		return position.line >= range.start.line && position.line <= range.end.line
			&& position.character >= range.start.character && position.character < range.end.character;
	}

	intersectsWith(position: Position): boolean {
		var range = this.getSpanRange();
		if (position.line < range.start.line || position.line > range.end.line) {
			return false;
		}

		if (range.start.line === range.end.line) {
			return position.character >= range.start.character && position.character < range.end.character;
		}

		if (position.line == range.start.line) {
			return position.character >= range.start.character;
		}

		if (position.line == range.end.line) {
			return position.character <= range.end.character;
		}
		return true;
	}

	getSymbolAtPos(position: Position): UCSymbol | undefined {
		if (this.intersectsWithName(position)) {
			const symbol = this.getSubSymbolAtPos(position);
			return symbol || this;
		}
		return undefined;
	}

	protected getSubSymbolAtPos(_position: Position): UCSymbol | undefined {
		return undefined;
	}

	getOuter<T extends ISymbol>(): ISymbol | undefined {
		for (let outer = this.outer; outer; outer = outer.outer) {
			if (<T>(outer)) {
				return outer;
			}
		}
	}

	getCompletionSymbols(_document: UCDocumentListener): UCSymbol[] {
		return [];
	}

	acceptCompletion(_document: UCDocumentListener, _context: UCSymbol): boolean {
		return true;
	}

	link(_document: UCDocumentListener, _context: UCStructSymbol = _document.class) {
	}

	analyze(_document: UCDocumentListener, _context: UCStructSymbol) {

	}

	addReference(ref: ISymbolReference) {
		(this.refs || (this.refs = new Set())).add(ref);
	}

	getReferences(): Set<ISymbolReference> | undefined {
		return this.refs;
	}

	getUri(): string | undefined {
		return this.outer.getUri();
	}

	toSymbolInfo(): SymbolInformation {
		return SymbolInformation.create(this.getName(), this.getKind(), this.getSpanRange(), undefined, this.outer.getName());
	}

	toCompletionItem(document: UCDocumentListener): CompletionItem {
		const item = CompletionItem.create(this.getName());
		item.detail = this.getTooltip();
		if (document.tokenStream) {
			try {
				item.documentation = this.getDocumentation(document.tokenStream);
			} catch (err) {
				// do nothing
			}
		}
		item.kind = this.getCompletionItemKind();
		return item;
	}

	findTypeSymbol(id: string, deepSearch: boolean): ISymbol | undefined {
		if (this.outer instanceof UCSymbol) {
			return this.outer.findTypeSymbol(id, deepSearch);
		} else if (this.outer instanceof UCPackage) {
			return this.outer.findQualifiedSymbol(id, deepSearch);
		}
		return undefined;
	}
}
