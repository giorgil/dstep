/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Oct 1, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module clang.TranslationUnit;

import std.string;

import clang.c.index;
import clang.Cursor;
import clang.Diagnostic;
import clang.Index;
import clang.UnsavedFile;
import clang.Util;

import dstep.core.io;

struct TranslationUnit
{
	mixin CX;
	
	static TranslationUnit parse (Index index, string sourceFilename, string[] commandLineArgs,
		UnsavedFile[] unsavedFiles = null,
		uint options = CXTranslationUnit_Flags.CXTranslationUnit_None)
	{
		return TranslationUnit(
			clang_parseTranslationUnit(
				index.cx,
				sourceFilename.toStringz,
				strToCArray(commandLineArgs),
				cast(int) commandLineArgs.length,
				toCArray!(CXUnsavedFile)(unsavedFiles),
				cast(uint) unsavedFiles.length,
				options));
	}
	
	private this (CXTranslationUnit cx)
	{
		this.cx = cx;
	}
	
	@property DiagnosticVisitor diagnostics ()
	{
		return DiagnosticVisitor(cx);
	}
	
	@property DeclarationVisitor declarations ()
	{
		return DeclarationVisitor(clang_getTranslationUnitCursor(cx));
	}
}

struct DiagnosticVisitor
{
	private CXTranslationUnit translatoinUnit;
	
	this (CXTranslationUnit translatoinUnit)
	{
		this.translatoinUnit = translatoinUnit;
	}
	
	size_t length ()
	{
		return clang_getNumDiagnostics(translatoinUnit);
	}
	
	int opApply (int delegate (ref Diagnostic) dg)
	{
		int result;
		
		foreach (i ; 0 .. length)
		{
			auto diag = clang_getDiagnostic(translatoinUnit, cast(uint) i);
			result = dg(Diagnostic(diag));

			if (result)
				break;
		}
		
		return result;
	}
}