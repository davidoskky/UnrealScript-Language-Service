import { UCDocument } from '../document';
import { SymbolWalker } from '../symbolWalker';
import { ContextKind, ISymbol, ModifierFlags, UCObjectSymbol, UCStructSymbol, UCSymbolKind, UCTypeKind } from './';

export class UCScriptStructSymbol extends UCStructSymbol {
    static readonly allowedKindsMask = 1 << UCSymbolKind.Const
        | 1 << UCSymbolKind.ScriptStruct
        | 1 << UCSymbolKind.Property;

    override kind = UCSymbolKind.ScriptStruct;
    override modifiers = ModifierFlags.ReadOnly;

	override getTypeKind() {
		return UCTypeKind.Struct;
	}

    protected override getTypeKeyword(): string | undefined {
		return 'struct';
	}

	override getTooltip(): string {
        const text: Array<string | undefined> = [];
		text.push(this.getTypeHint());
        text.push(this.getTypeKeyword());
        const modifiers = this.buildModifiers();
        if (modifiers.length > 0) {
            text.push(modifiers.join(' '));
        }
        text.push(this.getPath());
        if (this.super) {
            text.push(`extends ${this.super.getPath()}`);
        }
		return text.filter(Boolean).join(' ');
	}

    override buildModifiers(modifiers = this.modifiers): string[] {
		const text: string[] = [];

		if (modifiers & ModifierFlags.Native) {
			text.push('native');
		}

        if (modifiers & ModifierFlags.Transient) {
            text.push('transient');
        }

		return text;
	}

    override getCompletionSymbols<C extends ISymbol>(document: UCDocument, _context: ContextKind, kinds?: UCSymbolKind) {
		const symbols: ISymbol[] = [];
		for (let child = this.children; child; child = child.next) {
			if (typeof kinds !== 'undefined' && ((1 << child.kind) & kinds) === 0) {
				continue;
			}
			if (child.acceptCompletion(document, this)) {
				symbols.push(child);
			}
		}

		for (let parent = this.super; parent; parent = parent.super) {
            if (parent.kind !== UCSymbolKind.ScriptStruct) {
                break;
            }

			for (let child = parent.children; child; child = child.next) {
				if (typeof kinds !== 'undefined' && ((1 << child.kind) & kinds) === 0) {
					continue;
				}
				if (child.acceptCompletion(document, this)) {
					symbols.push(child);
				}
			}
		}
		return symbols as C[];
	}

	override acceptCompletion(_document: UCDocument, context: UCObjectSymbol): boolean {
        return true;
		// return isProperty(context) || isFunction(context);
	}

	override index(document: UCDocument, _context: UCStructSymbol) {
		super.index(document, this);
	}

	override accept<Result>(visitor: SymbolWalker<Result>): Result | void {
		return visitor.visitScriptStruct(this);
	}
}