import { ParserRuleContext, Token, TokenStream } from 'antlr4ts';
import { Hover, Location, MarkupKind, Position, Range } from 'vscode-languageserver';
import { DocumentUri } from 'vscode-languageserver-textdocument';

import { UCLexer } from './antlr/generated/UCLexer';
import { UCDocument } from './document';
import { getDocumentById, getDocumentByURI } from './indexer';
import {
    getOuter,
    hasModifiers,
    isField,
    ISymbol,
    ModifierFlags,
    supportsRef,
    UCClassSymbol,
    UCObjectSymbol,
    UCSymbolKind,
} from './Symbols';

export const VALID_ID_REGEXP = RegExp(/^([a-zA-Z_][a-zA-Z_0-9]*)$/);

export function rangeAtStopFromBound(token: Token): Range {
    const length = token.stopIndex - token.startIndex + 1;
    const line = token.line - 1;
    const position: Position = {
        line,
        character: token.charPositionInLine + length
    };

    return {
        start: position,
        end: position
    };
}

export function rangeFromBound(token: Token): Range {
    const length = token.stopIndex - token.startIndex + 1;
    const line = token.line - 1;
    if (length === 0) {
        const position: Position = {
            line,
            character: token.charPositionInLine + length
        };

        return {
            start: position,
            end: position
        };
    }
    const start: Position = {
        line,
        character: token.charPositionInLine
    };
    const end: Position = {
        line,
        character: token.charPositionInLine + length
    };

    return { start, end };
}

export function rangeFromBounds(startToken: Token, stopToken: Token = startToken): Range {
    const length = stopToken.stopIndex - stopToken.startIndex + 1;
    const start: Position = {
        line: startToken.line - 1,
        character: startToken.charPositionInLine
    };
    const end: Position = {
        line: stopToken.line - 1,
        character: stopToken.charPositionInLine + length
    };

    return { start, end };
}

export function rangeFromCtx(ctx: ParserRuleContext): Range {
    const length = ctx.stop!.stopIndex - ctx.stop!.startIndex + 1;
    const start = {
        line: ctx.start.line - 1,
        character: ctx.start.charPositionInLine
    };
    const end: Position = {
        line: ctx.stop!.line - 1,
        character: ctx.stop!.charPositionInLine + length
    };

    return { start, end };
}

export function intersectsWith(range: Range, position: Position): boolean {
    if (position.line < range.start.line || position.line > range.end.line) {
        return false;
    }

    if (range.start.line === range.end.line) {
        return position.character >= range.start.character && position.character <= range.end.character;
    }

    if (position.line === range.start.line) {
        return position.character >= range.start.character;
    }

    if (position.line === range.end.line) {
        return position.character <= range.end.character;
    }

    return true;
}

export function intersectsWithRange(position: Position, range: Range): boolean {
    return position.line >= range.start.line
        && position.line <= range.end.line
        && position.character >= range.start.character
        && position.character <= range.end.character;
}

export function getDocumentSymbol(document: UCDocument, position: Position): ISymbol | undefined {
    const symbols = document.enumerateSymbols();
    for (const symbol of symbols) {
        const child = symbol.getSymbolAtPos(position);
        if (child) {
            return child;
        }
    }

    return undefined;
}

/**
 * Returns the deepest UCStructSymbol that is intersecting with @param position
 **/
export function getDocumentContext(document: UCDocument, position: Position): ISymbol | undefined {
    const symbols = document.enumerateSymbols();
    for (const symbol of symbols) {
        if (isField(symbol)) {
            const child = symbol.getCompletionContext(position);
            if (child) {
                return child;
            }
        }
    }

    return undefined;
}

export async function getDocumentTooltip(document: UCDocument, position: Position): Promise<Hover | undefined> {
    const symbol = getDocumentSymbol(document, position);
    if (!symbol) {
        return undefined;
    }

    const tooltip = getSymbolTooltip(symbol);
    if (!tooltip) {
        return undefined;
    }

    const docs = getSymbolDocumentation(symbol);
    return {
        contents: {
            kind: MarkupKind.Markdown,
            value: [
                `\`\`\`unrealscript`,
                tooltip,
                docs,
                `\`\`\``
            ].filter(Boolean).join('\n')
        },
        range: symbol.id.range
    };
}

export function getSymbolTooltip(symbol: ISymbol): string | undefined {
    const symbolRef = resolveSymbolToRef(symbol);
    const tooltipText = symbolRef?.getTooltip();
    return tooltipText;
}

export function getSymbolDocumentation(symbol: ISymbol): string | undefined {
    if (symbol instanceof UCObjectSymbol) {
        const documentation = symbol.getDocumentation();
        return documentation;
    }

    return undefined;
}

/** 
 * Returns a location that represents the definition at a given position within the document. 
 * 
 * If a symbol is found at the position, then the symbol's definition location will be returned instead.
 **/
export function getDocumentDefinition(document: UCDocument, position: Position): Location | undefined {
    const symbol = getDocumentSymbol(document, position);
    if (!symbol) {
        return undefined;
    }

    const symbolRef = resolveSymbolToRef(symbol);
    if (!symbolRef) {
        return undefined;
    }

    const externalDocument = getSymbolDocument(symbolRef);
    return externalDocument?.uri
        ? Location.create(externalDocument.uri, symbolRef.id.range)
        : undefined;
}

export function getSymbolDefinition(uri: DocumentUri, position: Position): ISymbol | undefined {
    const symbol = getSymbol(uri, position);
    return symbol && resolveSymbolToRef(symbol);
}

/** 
 * Resolves to the symbol's contained reference if the symbol kind supports it.
 * e.g. A symbol that implements the interface ITypeSymbol.
 */
export function resolveSymbolToRef(symbol: ISymbol): ISymbol | undefined {
    return supportsRef(symbol)
        ? symbol.getRef()
        : symbol;
}

export function getSymbol(uri: DocumentUri, position: Position): ISymbol | undefined {
    const document = getDocumentByURI(uri);
    return document && getDocumentSymbol(document, position);
}

export function getSymbolDocument(symbol: ISymbol): UCDocument | undefined {
    const documentClass = symbol && (symbol.kind === UCSymbolKind.Class
        ? (symbol as UCClassSymbol)
        : getOuter<UCClassSymbol>(symbol, UCSymbolKind.Class));

    const document = documentClass && getDocumentById(documentClass.id.name);
    return document;
}

export function getIntersectingContext(context: ParserRuleContext, position: Position): ParserRuleContext | undefined {
    if (!intersectsWith(rangeFromCtx(context), position)) {
        return undefined;
    }

    if (context.children) for (const child of context.children) {
        if (child instanceof ParserRuleContext) {
            const ctx = getIntersectingContext(child, position);
            if (ctx) {
                return ctx;
            }
        }
    }

    return context;
}

export function getCaretTokenFromStream(stream: TokenStream, caret: Position): Token | undefined {
    // ANTLR lines begin at 1
    const carretLine = caret.line + 1;
    const carretColumn = caret.character > 0 ? caret.character - 1 : 0;
    let i = 0;
    let token: Token | undefined = undefined;
    while (i < stream.size && (token = stream.get(i))) {
        if (carretLine === token.line
            && token.charPositionInLine <= carretColumn
            && token.charPositionInLine + (token.stopIndex - token.startIndex) >= carretColumn) {
            return token;
        }
        ++i;
    }

    return undefined;
}

export function backtrackFirstToken(stream: TokenStream, startTokenIndex: number): Token | undefined {
    if (startTokenIndex >= stream.size) {
        return undefined;
    }

    let i = startTokenIndex;
    while (--i) {
        const token = stream.get(i);
        if (token.channel !== UCLexer.DEFAULT_TOKEN_CHANNEL) {
            continue;
        }
        return token;
    }

    return undefined;
}

export function backtrackFirstTokenOfType(stream: TokenStream, type: number, startTokenIndex: number): Token | undefined {
    if (startTokenIndex >= stream.size) {
        return undefined;
    }

    let i = startTokenIndex + 1;
    while (--i) {
        const token = stream.get(i);
        if (token.type <= UCLexer.ID) {
            continue;
        }

        if (token.type !== type) {
            return undefined;
        }

        return token;
    }

    return undefined;
}

export function isSymbolDefined(symbol: ISymbol): boolean {
    // Exclude generated symbols
    if (hasModifiers(symbol) && (symbol.modifiers & ModifierFlags.Generated) != 0) {
        return false;
    }

    return true;
}