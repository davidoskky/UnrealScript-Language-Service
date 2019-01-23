import * as path from 'path';
import * as fs from 'fs';

import URI from 'vscode-uri';
import {
	createConnection,
	TextDocuments,
	TextDocument,
	ProposedFeatures,
	InitializeParams,
	DidChangeConfigurationNotification,
	CompletionItem,
	CompletionItemKind,
	RemoteWorkspace,
	Hover,
	Location,
	Diagnostic,
	Definition,
	DocumentSymbolParams,
	SymbolInformation,
	ReferenceParams,
	DiagnosticSeverity,
	TextDocumentPositionParams,
	Range
} from 'vscode-languageserver';

import {
	UCPropertySymbol, UCStructSymbol, UCClassSymbol,
	UCFunctionSymbol, UCScriptStructSymbol, UCSymbolRef
} from './UC/symbols/symbols';
import { UCPackage } from "./UC/symbols/UCPackage";
import { DocumentParser } from "./UC/DocumentParser";
import { UCDocument } from "./UC/UCDocument";
import { UCSymbol } from "./UC/symbols/UCSymbol";
import { CORE_PACKAGE } from "./UC/symbols/NativeSymbols";
import { FUNCTION_MODIFIERS, CLASS_DECLARATIONS, PRIMITIVE_TYPE_NAMES, VARIABLE_MODIFIERS, FUNCTION_DECLARATIONS, STRUCT_DECLARATIONS, STRUCT_MODIFIERS } from "./UC/keywords";

let connection = createConnection(ProposedFeatures.all);

let UCFilePaths = new Map<string, string>();

let documents: TextDocuments = new TextDocuments();
let projectDocuments: Map<string, UCDocument> = new Map<string, UCDocument>();

let documentItems: CompletionItem[] = [];
let projectClassTypes: CompletionItem[] = [];

let hasConfigurationCapability: boolean = false;
let hasWorkspaceFolderCapability: boolean = false;

connection.onInitialize((params: InitializeParams) => {
	let capabilities = params.capabilities;

	hasConfigurationCapability = !!(capabilities.workspace && !!capabilities.workspace.configuration);
	hasWorkspaceFolderCapability = !!(capabilities.workspace && !!capabilities.workspace.workspaceFolders);

	return {
		capabilities: {
			textDocumentSync: documents.syncKind,
			hoverProvider: true,
			completionProvider: {
				triggerCharacters: ['.']
			},
			definitionProvider: true,
			documentSymbolProvider: true,
			referencesProvider: true
		}
	};
});

async function scanWorkspaceForClasses(workspace: RemoteWorkspace): Promise<Map<string, string>> {
	function scanPath(filePath: string, cb: (filePath: string) => void): Promise<boolean> {
		let promise = new Promise<boolean>((resolve) => {
			if (!fs.existsSync(filePath)) {
				resolve(false);
				return;
			}

			fs.lstat(filePath, (err, stats) => {
				if (stats.isDirectory()) {
					fs.readdir(filePath, (err, filePaths) => {
						for (let fileName of filePaths) {
							resolve(scanPath(path.join(filePath, fileName), cb));
						}
					});
				} else {
					if (path.extname(filePath) === '.uc') {
						cb(filePath);
					}
					resolve(true);
				}
			});
		});
		return promise;
	}

	let filePaths = new Map<string, string>();
	let folders = await workspace.getWorkspaceFolders();
	for (let folder of folders) {
		let folderPath = URI.parse(folder.uri).fsPath;
		await scanPath(folderPath, (filePath => {
			filePaths.set(path.basename(filePath, '.uc').toLowerCase(), filePath);
		}));
	}
	return filePaths;
}

function initializeClassTypes() {
	projectClassTypes = Array.from(UCFilePaths.values())
		.map(value => {
			return {
				label: path.basename(value, '.uc'),
				kind: CompletionItemKind.Class
			};
		});
}

connection.onInitialized(async () => {
	if (hasConfigurationCapability) {
		connection.client.register(
			DidChangeConfigurationNotification.type,
			undefined
		);
	}
	if (hasWorkspaceFolderCapability) {
		connection.workspace.onDidChangeWorkspaceFolders(async _event => {
			UCFilePaths = await scanWorkspaceForClasses(connection.workspace);
			initializeClassTypes();
		});
	}
});

interface UCSettings {

}

let documentSettings: Map<string, Thenable<UCSettings>> = new Map();

connection.onDidChangeConfiguration(() => {
	if (hasConfigurationCapability) {
		documentSettings.clear();
	}
});

documents.onDidOpen(async e => {
	if (UCFilePaths.size === 0) {
		UCFilePaths = await scanWorkspaceForClasses(connection.workspace);
		initializeClassTypes();
	}
	validateTextDocument(e.document);
});

documents.onDidChangeContent(async e => {
	if (UCFilePaths.size === 0) {
		UCFilePaths = await scanWorkspaceForClasses(connection.workspace);
		initializeClassTypes();
	}

	projectDocuments.delete(e.document.uri);
	validateTextDocument(e.document);
});

documents.onDidClose(e => {
	documentSettings.delete(e.document.uri);
});

var WorkspacePackage = new UCPackage('Workspace');
WorkspacePackage.add(CORE_PACKAGE);

var pendingDocuments = [];

function parsePending() {
	var pending = pendingDocuments.shift();
	if (!pending) {
		return;
	}

	let text = fs.readFileSync(pending.filePath).toString();
	var uri = URI.file(pending.filePath).toString();
	pending.cb(parseDocument(uri, text));

	// setTimeout(parsePending, 400);
}

function parseClassDocument(className: string, cb: (document: UCDocument) => void) {
	className = className.toLowerCase();
	// connection.console.log('Looking for external document ' + className);

	// Try the shorter route first before we scan the entire workspace!
	if (WorkspacePackage) {
		let classSymbol = WorkspacePackage.findSuperSymbol(className, true);
		if (classSymbol && classSymbol instanceof UCClassSymbol) {
			cb(classSymbol.document);
			return;
		}
	}

	let filePath = UCFilePaths.get(className);
	if (!filePath) {
		cb(undefined);
		return;
	}

	// FIXME: may not exist
	if (!fs.existsSync(filePath)) {
		cb(undefined);
		return;
	}

	pendingDocuments.push({ filePath, cb });
	parsePending();
	// setTimeout(parsePending, 50);
}

function parseDocument(uri: string, text: string): UCDocument {
	// TODO: Hash check
	let document = projectDocuments.get(uri);
	if (!document) {
		connection.console.log('Parsing document ' + uri);
		document = new UCDocument(WorkspacePackage, uri);
		document.getDocument = parseClassDocument;
		projectDocuments.set(uri, document);

		const parser = new DocumentParser(text);
		parser.parse(document);
	}
	return document;
}

function validateTextDocument(textDocument: TextDocument): Promise<void> {
	let document: UCDocument;
	try {
		document = parseDocument(textDocument.uri, textDocument.getText());
	} catch (err) {
		connection.sendDiagnostics({
			uri: textDocument.uri,
			diagnostics: [Diagnostic.create(Range.create(0, 0, 0, 0), "Something went wrong while parsing this document! " + err, DiagnosticSeverity.Warning)]
		});
		return;
	}

	if (!document || document.class === null) {
		connection.sendDiagnostics({
			uri: textDocument.uri,
			diagnostics: [Diagnostic.create(Range.create(0, 0, 0, 0), "Couldn't validate document!", DiagnosticSeverity.Warning)]
		});
		return;
	}

	document.link(document);
	diagnoseDocument(document);

	documentItems = []; // reset, never show any items from previous documents.
	for (let container: UCStructSymbol = document.class; container; container = container.super) {
		for (let child = container.children; child; child = child.next) {
			documentItems.push(child.toCompletionItem());
		}
	}
}

function diagnoseDocument(document: UCDocument) {
	const diagnostics: Diagnostic[] = [];
	if (document.nodes && document.nodes.length > 0) {
		let errors: Diagnostic[] = document.nodes
			.map(node => {
				return Diagnostic.create(
					node.getRange(),
					node.toString()
				);
			});

		diagnostics.push(...errors);
	}

	connection.sendDiagnostics({
		uri: document.uri,
		diagnostics: diagnostics
	});
}

function getDocumentPositionSymbol(e: TextDocumentPositionParams): UCSymbol {
	let document = projectDocuments.get(e.textDocument.uri);
	if (!document) {
		return undefined;
	}
	return document.getSymbolAtPosition(e.position);
}

connection.onHover((e): Hover => {
	const symbol = getDocumentPositionSymbol(e);
	if (!symbol) {
		return undefined;
	}

	connection.console.log('Hovering: ' + symbol.getTooltip() + ' at ' + symbol.getIdRange());

	return {
		contents: symbol.getTooltip(),
		range: symbol.getIdRange()
	};
});

connection.onDocumentSymbol((e: DocumentSymbolParams): SymbolInformation[] => {
	let document = projectDocuments.get(e.textDocument.uri);
	if (!document || !document.class) {
		return undefined;
	}

	var contextSymbols = [];
	var buildSymbolsList = (container: UCStructSymbol) => {
		for (let child = container.children; child; child = child.next) {
			contextSymbols.push(child.toSymbolInfo());
			if (child instanceof UCStructSymbol) {
				buildSymbolsList(child as UCStructSymbol);
			}
		}
	};

	buildSymbolsList(document.class);
	return contextSymbols;
});

// Bare implementation to support "go-to-defintion" for variable declarations type references.
connection.onDefinition((e): Definition => {
	const symbol = getDocumentPositionSymbol(e);
	if (!symbol) {
		return undefined;
	}

	if (symbol instanceof UCSymbolRef) {
		let reference = symbol.getReference();
		if (reference instanceof UCSymbol) {
			return Location.create(reference.getUri(), reference.getIdRange());
		}
	}
});

connection.onReferences((e: ReferenceParams): Location[] => {
	const symbol = getDocumentPositionSymbol(e);
	if (!symbol) {
		return undefined;
	}
	return symbol.getReferences();
});

connection.onCompletion((e): CompletionItem[] => {
	const symbol = getDocumentPositionSymbol(e);
	if (!symbol) {
		return undefined;
	}

	const items: CompletionItem[] = [];
	if (symbol instanceof UCClassSymbol) {
		return []
			.concat(CLASS_DECLARATIONS, FUNCTION_MODIFIERS)
			.map(kw => {
				return {
					label: kw,
					kind: CompletionItemKind.Keyword
				} as CompletionItem;
			});
	} else if (symbol instanceof UCPropertySymbol) {
		// document.class.symbols.forEach((symbol) => {
		// 	if (symbol.getKind() !== SymbolKind.Struct && symbol.getKind() !== SymbolKind.Enum) {
		// 		return;
		// 	}
		// 	items.push({
		// 		label: symbol.getName(),
		// 		detail: symbol.getTooltip(),
		// 		documentation: symbol.getDocumentation(),
		// 	});
		// });

		return []
			.concat(VARIABLE_MODIFIERS, PRIMITIVE_TYPE_NAMES)
			.map(type => {
				return {
					label: type,
					kind: CompletionItemKind.Keyword
				} as CompletionItem;
			})
			.concat(projectClassTypes, items);
	}
	else if (symbol instanceof UCFunctionSymbol) {
		// document.class.symbols.forEach((symbol) => {
		// 	if (symbol.getKind() === SymbolKind.Struct) {
		// 		return;
		// 	}
		// 	items.push({
		// 		label: symbol.getName(),
		// 		detail: symbol.getTooltip(),
		// 		documentation: symbol.getDocumentation(),
		// 	});
		// });

		return []
			.concat(FUNCTION_DECLARATIONS, FUNCTION_MODIFIERS, PRIMITIVE_TYPE_NAMES)
			.map(type => {
				return {
					label: type,
					kind: CompletionItemKind.Keyword
				} as CompletionItem;
			})
			.concat(projectClassTypes, items);
	}
	else if (symbol instanceof UCScriptStructSymbol) {
		return []
			.concat(STRUCT_DECLARATIONS, STRUCT_MODIFIERS)
			.map(type => {
				return {
					label: type,
					kind: CompletionItemKind.Keyword
				} as CompletionItem;
			});
	}

	return []
		.concat(STRUCT_DECLARATIONS)
		.map(type => {
			return {
				label: type,
				kind: CompletionItemKind.Keyword
			} as CompletionItem;
		})
		.concat(items, documentItems);
});

documents.listen(connection);
connection.listen();