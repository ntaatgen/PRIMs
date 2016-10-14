//
//  Script.swift
//  PRIMs
//
//  Created by Niels Taatgen on 1/5/16.
//  Copyright © 2016 Niels Taatgen. All rights reserved.
//

import Foundation

enum Statement: CustomStringConvertible {
    case assign(Assignment)
    case funcl(Funcall)
    case ifCl(IfClause)
    case whileCl(WhileClause)
    case forCl(ForClause)
    var description: String {
        switch self {
        case .assign(let ass): return "Assignment: \(ass)"
        case .funcl(let funcall): return "Function call: \(funcall)"
        case .ifCl(let ifc): return "If clause: \(ifc)"
        case .whileCl(let whcl): return "While clause \(whcl)"
        case .forCl(let fcl): return "For clause \(fcl)"
        }
    }
}

class Assignment: CustomStringConvertible {
    let lhs: Factor
    let rhs: Expression
    init(lhs: Factor, rhs: Expression) {
        self.lhs = lhs
        self.rhs = rhs
    }
    var description: String {
        return "\(lhs) = \(rhs)"
    }
}

class Funcall: CustomStringConvertible {
    let name: String
    let arglist: [Expression]
    init(name: String, argList: [Expression]) {
        self.name = name
        self.arglist = argList
    }
    var description: String {
        var s = "\(name)("
        for arg in arglist {
            s += "\(arg), "
        }
        return s + ")"
    }
    func eval(_ env: Environment, model: Model) throws -> Factor {
        if let f = scriptFunctions[name] {
            var args: [Factor] = []
            for arg in arglist {
                args.append(try arg.eval(env, model: model))
            }
            let (result, _) = try f(args, model)
            guard result != nil else {throw RunTimeError.errorInFunction("Function does not produce a result") }
            return result!
        } else {
            throw RunTimeError.undefinedFunction(name)
        }

    }
    
}

class IfClause: CustomStringConvertible {
    let test: Expression
    let thenStatements: [Statement]
    let elseStatements: [Statement]
    init(test: Expression, thenStatements: [Statement], elseStatements: [Statement]) {
        self.test = test
        self.thenStatements = thenStatements
        self.elseStatements = elseStatements
    }
    var description: String {
        return "if \(test) { ... } { ... }"
    }
}

class WhileClause: CustomStringConvertible {
    let test: Expression
    let statements: [Statement]
    init(test: Expression, statements: [Statement]) {
        self.test = test
        self.statements = statements
    }
    var description: String {
        return "while \(test)"
    }
}

class ForClause: CustomStringConvertible {
    let loopVar: Factor
    let statements: [Statement]
    let startExpression: Expression
    let endExpression: Expression?
    init(loopVar: Factor, statements: [Statement], startExpression: Expression, endExpression: Expression?) {
        self.loopVar = loopVar
        self.statements = statements
        self.startExpression = startExpression
        self.endExpression = endExpression
    }
    var description: String {
        return "for \(loopVar) in \(startExpression) to \(endExpression) do \n\(statements)"
    }
}

class Expression: CustomStringConvertible {
    let preop: String
    let firstTerm: Term
    let op: String
    let secondTerm: Expression?
    init(preop: String, firstTerm: Term, op: String, secondTerm: Expression?) {
        self.preop = preop
        self.firstTerm = firstTerm
        self.op = op
        self.secondTerm = secondTerm
    }
    var description: String {
        let second = secondTerm == nil ? "" : "\(secondTerm!)"
        return "\(preop)\(firstTerm)\(op)\(second)"
    }
    func eval(_ env: Environment, model: Model) throws -> Factor {
        var term1 = try firstTerm.eval(env, model: model)
        if preop == "-" {
            switch term1 {
            case .intNumber(let number):
                term1 = .intNumber(-number)
            case .realNumber(let number):
                term1 = .realNumber(-number)
            default: throw RunTimeError.nonNumberArgument
            }
        }
        if op == "" {
            return term1
        }
        
        guard secondTerm != nil else { throw RunTimeError.missingSecondArgument }
        var term2 = try secondTerm!.eval(env, model: model)
        
        // If the first argument is a string, concatenate both arguments
        if (term1.type() == "string" && op == "+") {
            return .str(term1.description + "\(term2)")
        }
        
        // If one of the numbers is an Int and the other a Real, covert Int to Real
        switch (term1, term2) {
        case (.intNumber(let num1), .realNumber(_)):
            term1 = Factor.realNumber(Double(num1))
        case (.realNumber(_), .intNumber(let num2)):
            term2 = Factor.realNumber(Double(num2))
        default: break
        }
        
        switch (term1, term2, op) {
        case (.intNumber(let num1),.intNumber(let num2),"+"):
            return .intNumber(num1 + num2)
        case (.intNumber(let num1),.intNumber(let num2),"||"):
            return .intNumber(num1 + num2)
        case (.intNumber(let num1),.intNumber(let num2),"-"):
            return .intNumber(num1 - num2)
        case (.realNumber(let num1), .realNumber(let num2),"+"):
            return .realNumber(num1 + num2)
        case (.realNumber(let num1), .realNumber(let num2), "-"):
            return .realNumber(num1 - num2)
        default: throw RunTimeError.nonNumberArgument
        }
    }
}
    
class Term: CustomStringConvertible {
    let factor: Factor
    let op: String
    let term: Term?
    init(factor: Factor, op: String, term: Term?) {
        self.factor = factor
        self.op = op
        self.term = term
    }
    var description: String {
        let second = term == nil ? "" : "\(term!)"
        return "\(factor)\(op)\(second)"
    }
    func eval(_ env: Environment, model: Model) throws -> Factor {
        var factor1 = try factor.eval(env, model: model)
        if op == "" {
            return factor1
        }
        guard term != nil else { throw RunTimeError.missingSecondArgument }
        var factor2 = try term!.eval(env, model: model)
        switch (factor1, factor2) {
        case (.intNumber(let num1), .realNumber(_)):
            factor1 = Factor.realNumber(Double(num1))
        case (.realNumber(_), .intNumber(let num2)):
            factor2 = Factor.realNumber(Double(num2))
        default: break
        }
        switch (factor1, factor2, op) {
        case (.intNumber(let num1),.intNumber(let num2),"*"):
            return .intNumber(num1 * num2)
        case (.intNumber(let num1),.intNumber(let num2),"&&"):
            return .intNumber(num1 * num2)
        case (.intNumber(let num1),.intNumber(let num2),"/"):
            guard num2 != 0 else { throw RunTimeError.divisionByZero }
            return .intNumber(num1 / num2)
        case (.realNumber(let num1), .realNumber(let num2),"*"):
            return .realNumber(num1 * num2)
        case (.realNumber(let num1), .realNumber(let num2), "/"):
            guard num2 != 0 else { throw RunTimeError.divisionByZero }
            return .realNumber(num1 / num2)
        default: throw RunTimeError.nonNumberArgument
        }
    }
}

class ScriptArray: CustomStringConvertible {
    var elements: [Expression]
    init(elements: [Expression]) {
        self.elements = elements
    }
    
    var description: String {
        if elements.count == 0 { return "[]" }
        var s = "[\(elements[0])"
        for elem in elements.dropFirst() {
            s += ", \(elem)"
        }        
        s += "]"
        return s
    }
    func eval(_ env: Environment, model: Model) throws -> Factor {
        var newElements: [Expression] = []
        for elem in elements {
            let value = try elem.eval(env, model: model)
            newElements.append(Expression(preop: "", firstTerm: Term(factor: value, op: "", term: nil), op: "", secondTerm: nil))
        }
        return Factor.arr(ScriptArray(elements: newElements))
    }
}

class Comparison {
    let lhs: Expression
    let op: String
    let rhs: Expression?
    init(lhs: Expression, op: String, rhs: Expression?) {
        self.lhs = lhs
        self.op = op
        self.rhs = rhs
    }
    func eval(_ env: Environment, model: Model) throws -> Factor {
        var leftArg = try lhs.eval(env, model: model)
        var result: Bool
        if op == "" || op == "!" {
            switch leftArg {
            case .intNumber(let num):
                result = op == "" ? num != 0 : num == 0
            case .realNumber(let num):
                result = op == "" ? num != 0 : num == 0
            case .str(let str):
                result = op == "" ? str != "" : str == ""
            default:
                throw RunTimeError.nonNumberArgument
            }
        } else {
        guard rhs != nil else { throw RunTimeError.missingSecondArgument }
        var rightArg = try rhs!.eval(env, model: model)
        switch (leftArg, rightArg) {
        case (.intNumber(let num1), .realNumber(_)):
            leftArg = Factor.realNumber(Double(num1))
        case (.realNumber(_), .intNumber(let num2)):
            rightArg = Factor.realNumber(Double(num2))
        default: break
        }
        switch  op {
            case "==": result = leftArg == rightArg
            case "!=", "<>": result = leftArg != rightArg
            case ">": result = leftArg > rightArg
            case "<": result = leftArg < rightArg
            case ">=", "=>": result = leftArg >= rightArg
            case "<=", "=<": result = leftArg <= rightArg
        default: throw RunTimeError.unDeclaratedIdentifier(op) // shouldn't happen
        }
        }
        return Factor.intNumber(result ? 1 : 0)

    }
}

enum Factor: CustomStringConvertible  {
    case funcl(Funcall)
    case arr(ScriptArray)
    case realNumber(Double)
    case intNumber(Int)
    case str(String)
    case symbol(String)
    case expr(Expression)
    case arrayElem(IndexedArray)
    case test(Comparison)
    var description: String {
        switch self {
        case .intNumber(let num): return String(num)
        case .realNumber(let num): return String(num)
        case .str(let s): return s
        case .symbol(let s): return s
        case .funcl(let fn): return fn.description
        case .arr(let arr): return "\(arr)"
        case .expr(let ex): return "\(ex)"
        case .arrayElem(let arr): return "\(arr)"
        case .test(let cp): return "\(cp)"
        }
    }
    func eval(_ env: Environment, model: Model) throws -> Factor {
        switch self {
        case .funcl(let funcall):
            return try funcall.eval(env, model: model)
        case .arrayElem(let arr):
            return try arr.eval(env, model: model)
        case .expr(let expr):
            return try expr.eval(env, model: model)
        case .symbol(let sym):
            return try env.lookup(sym)
        case .arr(let arr):
            return try arr.eval(env, model: model)
        case .test(let cp):
            return try cp.eval(env, model: model)
        default:
            return self
        }
    }
    func type() -> String {
        switch self {
        case .funcl(_): return "function"
        case .intNumber(_): return "integer"
        case .realNumber(_): return "real"
        case .str(_): return "string"
        case .symbol(_): return "symbol"
        case .arr(_): return "array"
        case .arrayElem(_): return "indexed-array"
        case .expr(_): return "expression"
        case .test(_): return "comparison"
        }
    }
    func intValue() -> Int? {
        switch self {
        case .intNumber(let num): return num
        default: return nil
        }
    }
    func doubleValue() -> Double? {
        switch self {
        case .intNumber(let num): return Double(num)
        case .realNumber(let num): return num
        default: return nil
        }
    }
}

func == (left: Factor, right: Factor) -> Bool {
    switch (left, right) {
    case (.intNumber(let num1),.intNumber(let num2)):
        return num1 == num2
    case (.realNumber(let num1),.realNumber(let num2)):
        return num1 == num2
    case (.str(let str1),.str(let str2)):
        return str1 == str2
    default:
        return false
    }
}

func != (left: Factor, right: Factor) -> Bool {
    return !( left == right)
}

func > (left: Factor, right: Factor) -> Bool {
    switch (left, right) {
    case (.intNumber(let num1),.intNumber(let num2)):
            return num1 > num2
    case (.realNumber(let num1),.realNumber(let num2)):
        return num1 > num2
    default: return false
    }
}

func < (left: Factor, right: Factor) -> Bool {
    switch (left, right) {
    case (.intNumber(let num1),.intNumber(let num2)):
        return num1 < num2
    case (.realNumber(let num1),.realNumber(let num2)):
        return num1 < num2
    default: return false
    }
}

func >= (left: Factor, right: Factor) -> Bool {
    return left > right || left == right
}

func <= (left: Factor, right: Factor) -> Bool {
    return left < right || left == right
}

func generateFactorExpression(_ f: Factor) -> Expression {
    return Expression(preop: "", firstTerm: Term(factor: f, op: "", term: nil), op: "", secondTerm: nil)
}

class IndexedArray {
    let name: String
    let index: Expression
    init(name: String, index: Expression) {
        self.name = name
        self.index = index
    }
    func eval(_ env: Environment, model: Model) throws -> Factor {
        let ind = try index.eval(env, model: model)
        let arr = try env.lookup(name)
        switch (ind, arr) {
        case (Factor.intNumber(let i),Factor.arr(let a)):
            guard i < a.elements.count else { throw RunTimeError.arrayOutOfBounds }
            let expr = a.elements[i]
            return try expr.eval(env, model: model)
        default: throw RunTimeError.indexingNonArray
        }
    }
}

enum ParsingError: Error {
    case unExpectedEOF
    case expected(String, String)
    case operatorExpected(String, String)
    case invalidAssignmentLHS
}

enum RunTimeError: Error {
    case unDeclaratedIdentifier(String)
    case nonNumberArgument
    case missingSecondArgument
    case divisionByZero
    case indexingNonArray
    case invalidNumberOfArguments
    case errorInFunction(String)
    case undefinedFunction(String)
    case arrayOutOfBounds
}

class Environment: CustomStringConvertible {
    let outer: Environment?
    let level: Int
    var vars: [String : Factor] = [:]
    var pc: Int = 0 // Program Counter
    var statements: [Statement] = []
    var loopCondition: Expression?  // In the case of a while loop, keep the test here
    var description: String {
        return "Statements:\n\(statements)\nBindings:\n\(vars)\n"
    }
    init(outer: Environment?) {
        self.outer = outer
        if outer == nil {
            level = 0
        } else {
            level = outer!.level + 1
        }
    }
    func add(_ symbol: String, value: Factor) { vars[symbol] = value }
    func lookup(_ symbol: String) throws -> Factor {
        if let value = vars[symbol] {
            return value
        } else if outer != nil {
            return try outer!.lookup(symbol)
        } else {
            throw RunTimeError.unDeclaratedIdentifier(symbol)
        }
    }

    func simpleAssign(_ v: String, value: Factor, orgEnv: Environment)  {
        if let _ = vars[v] {
            add(v, value:  value)
        } else if outer != nil {
            outer!.simpleAssign(v, value: value, orgEnv: orgEnv)
        } else {
            orgEnv.add(v, value: value)
        }
    }
    
    func arrayAssign(_ a: String, index: Int, value: Factor) throws {
        let factor = try lookup(a)
        switch factor {
        case .arr(let arr):
            if index < arr.elements.endIndex {
                arr.elements[index] = Expression(preop: "", firstTerm: Term(factor: value, op: "", term: nil), op: "", secondTerm: nil)
            } else {
                while arr.elements.endIndex < index {
                    arr.elements.append(Expression(preop: "", firstTerm: Term(factor: Factor.intNumber(0), op: "", term: nil), op: "", secondTerm: nil))
                }
                arr.elements.append(Expression(preop: "", firstTerm: Term(factor: value, op: "", term: nil), op: "", secondTerm: nil))
            }
        default: throw RunTimeError.indexingNonArray
        }
    }
}


class Script {
    var statements: [Statement] = []
    
    func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var nextIndex = input.startIndex
        while nextIndex != input.endIndex {
            let read = readNextToken(input, startIndex: nextIndex)
            if read.token == nil {
                return tokens  /// May indicate an error, but that is up to the parser
            }
            tokens.append(read.token!)
            nextIndex = read.nextIndex
        }
        return tokens
    }
    
    func getNextChar(_ input: String, nextIndex: String.Index)
        -> String {
        return input.substring(with: nextIndex ..< input.index(after: nextIndex))
    }
            
 //           return input.substring(with: nextIndex..<<#T##String.CharacterView corresponding to `nextIndex`##String.CharacterView#>.index(nextIndex, offsetBy: 1)) }
    
    func a(_ input: String, index: String.Index, char: String) -> Bool {
        return input.substring(from: index).hasPrefix(char)
    }
    
    func readNextToken(_ input :String, startIndex : String.Index) -> (token : String?, nextIndex : String.Index) {
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            if a(input, index: nextIndex, char: " ") || a(input, index: nextIndex, char: "\n") || a(input, index: nextIndex, char: "\t") {
                nextIndex = input.index(after: nextIndex)
            } else {
                break
            }
        }
        if nextIndex == input.endIndex {
            return (nil, nextIndex)
        }
        let nextChar = getNextChar(input, nextIndex: nextIndex)
        switch nextChar {
        case "(", ")", "+", "*", "-", "/", "%", "\\", "{", "}", "[", "]",",":
            return (nextChar, input.index(nextIndex, offsetBy: 1))
        case "!", "<", ">", "=", "|", "&":
            return readOperator(input, startIndex: nextIndex)
        case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
            return readNumber(input, startIndex: nextIndex)
        case "\"":
            return readString(input, startIndex: nextIndex)
        default:
            return readSymbol(input, startIndex: nextIndex)
        }
    }
    
    func readNumber(_ input: String, startIndex: String.Index) -> (token: String?, nextIndex:String.Index) {
        var value = ""
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                value += nextChar
            default:
                return (value, nextIndex)
            }
            nextIndex = input.index(nextIndex, offsetBy: 1)
        }
        return (value, nextIndex)
    }
    
    func readOperator(_ input: String, startIndex: String.Index) -> (token: String?, nextIndex:String.Index) {
        var value = ""
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case "!", ">", "<", "=", "|", "&":
                value += nextChar
            default:
                return (value, nextIndex)
            }
            nextIndex = input.index(nextIndex, offsetBy: 1)
        }
        return (value, nextIndex)
    }
    
    func readSymbol(_ input: String, startIndex: String.Index) -> (token: String?, nextIndex: String.Index) {
        var token = ""
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case " ", ")", "(", "[", "]", "{", "}", ",", "\n", "\t":
                return (token, nextIndex)
            default:
                token += nextChar
            }
            nextIndex = input.index(nextIndex, offsetBy: 1)
        }
        return (token, nextIndex)
    }

    func readString(_ input: String, startIndex: String.Index) -> (token: String?, nextIndex: String.Index) {
        var token = "\""
        var nextIndex = input.index(startIndex, offsetBy: 1)
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case "\"":
                token += nextChar
                return (token, input.index(nextIndex, offsetBy: 1))
            default:
                token += nextChar
            }
            nextIndex = input.index(nextIndex, offsetBy: 1)
        }
        return (token, nextIndex)
    }

    func parse(_ input: String) throws {
        statements = []
        var tokens = tokenize(input)
//        for token in tokens {
//            print(token)
//        }
        tokens.append("EOF")
        var index = tokens.startIndex
        var nextStatement: Statement
        while (index < tokens.endIndex && tokens[index] != "EOF") {
            (nextStatement, index) = try parseStatement(tokens, startIndex: index, endIndex: tokens.endIndex)
            statements.append(nextStatement)
        }
    }

    func lookAhead(_ tokens: [String], index: Int) -> String {
        if (index + 1 < tokens.endIndex) {
            return tokens[index + 1]
        } else {
            return "#"
        }
    }
    
    func nextToken(_ index: Int, endIndex: Int) throws -> Int {
        guard index + 1 < endIndex else { throw ParsingError.unExpectedEOF }
        return index + 1
    }
    
    
    func parseStatement(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (statement: Statement, lastIndex: Int) {
//        print("Parsing Statement at \(tokens[startIndex])")
        guard startIndex < endIndex else { throw ParsingError.unExpectedEOF }
        switch tokens[startIndex] {
        case "if":
            let ifResult = try parseIf(tokens, startIndex: try nextToken(startIndex, endIndex: endIndex), endIndex: endIndex)
            return (Statement.ifCl(ifResult.ifelse), ifResult.lastIndex)
        case "while":
            let whileResult = try parseWhile(tokens, startIndex: try nextToken(startIndex, endIndex: endIndex), endIndex: endIndex)
            return (Statement.whileCl(whileResult.whileRes), whileResult.lastIndex)
        case "for":
            let forResult = try parseFor(tokens, startIndex: try nextToken(startIndex, endIndex: endIndex), endIndex: endIndex)
            return (Statement.forCl(forResult.forRes), forResult.lastIndex)
        default:
            if lookAhead(tokens, index: startIndex) == "(" {
                let funcResult = try parseFunc(tokens, startIndex: startIndex, endIndex: endIndex)
                return (Statement.funcl(funcResult.funcRes), funcResult.lastIndex)
            } else {
                let assignResult = try parseAssign(tokens, startIndex: startIndex, endIndex: endIndex)
                return (Statement.assign(assignResult.asRes), assignResult.lastIndex)
            }
        }
    }
    
    func constructPrior(_ tokens: [String], index: Int) -> String {
        var s: String = ""
        for i in 0...index {
            s += tokens[i] + " "
        }
        return s
    }
    
    func parseIf(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (ifelse: IfClause, lastIndex: Int) {
//        print("Parsing If at \(tokens[startIndex])")
        let test = try parseExpression(tokens, startIndex: startIndex, endIndex: endIndex)
        guard tokens[test.lastIndex] == "{" else {
            throw ParsingError.expected("{",constructPrior(tokens, index: test.lastIndex))
        }
        var thenPart: [Statement] = []
        var index = try nextToken(test.lastIndex, endIndex: endIndex)
        while tokens[index] != "}" {
            let nextStatement = try parseStatement(tokens, startIndex: index, endIndex: endIndex)
            thenPart.append(nextStatement.statement)
            index = nextStatement.lastIndex
        }
        index = try nextToken(index, endIndex: endIndex)
        var elsePart: [Statement] = []
        if tokens[index] == "else" {
            index = try nextToken(index, endIndex: endIndex)
            guard tokens[index] == "{" else { throw ParsingError.expected("{",constructPrior(tokens, index: index)) }
            index = try nextToken(index, endIndex: endIndex)
            while tokens[index] != "}" {
                let nextStatement = try parseStatement(tokens, startIndex: index, endIndex: endIndex)
                elsePart.append(nextStatement.statement)
                index = nextStatement.lastIndex
            }
            index = try nextToken(index, endIndex: endIndex)
        }
        return (IfClause(test: test.expression, thenStatements: thenPart, elseStatements: elsePart), index)
    }
    
    func parseWhile(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (whileRes: WhileClause, lastIndex: Int) {
//        print("Parsing While at \(tokens[startIndex])")
        let test = try parseExpression(tokens, startIndex: startIndex, endIndex: endIndex)
        guard tokens[test.lastIndex] == "{" else {
            throw ParsingError.expected("{",constructPrior(tokens, index: test.lastIndex))
        }
        var loop: [Statement] = []
        var index = try nextToken(test.lastIndex, endIndex: endIndex)
        while tokens[index] != "}" {
            let nextStatement = try parseStatement(tokens, startIndex: index, endIndex: endIndex)
            loop.append(nextStatement.statement)
            index = nextStatement.lastIndex
        }
        index = try nextToken(index, endIndex: endIndex)
        return (WhileClause(test: test.expression, statements: loop), index)
    }
    
    // for i in 1 to n { statements* }
    // for x in array
    
    func parseFor(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (forRes: ForClause, lastIndex: Int) {
//        print("Parsing For at \(tokens[startIndex])")
        let loopVariable = tokens[startIndex]
//        print("Loop variable is \(loopVariable)")
        var index = try nextToken(startIndex, endIndex: endIndex)
        guard tokens[index] == "in" else { throw ParsingError.expected("in", constructPrior(tokens, index: index)) }
        index = try nextToken(index, endIndex: endIndex)
        let arg1 = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
        index = arg1.lastIndex
        var arg2: Expression? = nil
        if tokens[index] != "to" {
            guard arg1.expression.firstTerm.factor.type() == "symbol" || arg1.expression.firstTerm.factor.type() == "array" else { throw ParsingError.expected("a symbol or array", constructPrior(tokens, index: index)) }
        } else {
            index = try nextToken(index, endIndex: endIndex)
            let arg = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            index = arg.lastIndex
            arg2 = arg.expression
        }
        guard tokens[index] == "{" else {
            throw ParsingError.expected("{",constructPrior(tokens, index: index))
        }
        var loop: [Statement] = []
        index = try nextToken(index, endIndex: endIndex)
        while tokens[index] != "}" {
            let nextStatement = try parseStatement(tokens, startIndex: index, endIndex: endIndex)
            loop.append(nextStatement.statement)
            index = nextStatement.lastIndex
        }
        index = try nextToken(index, endIndex: endIndex)
        return (ForClause(loopVar: Factor.symbol(loopVariable), statements: loop, startExpression: arg1.expression, endExpression: arg2),index)
    }
    
    func parseComparison(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (testRes: Comparison, lastIndex: Int) {
//        print("Parsing Comparison at \(tokens[startIndex])")
        var index = startIndex
        var op: String = ""
        if tokens[index] == "!" {
            op = "!"
            index = try nextToken(startIndex, endIndex: endIndex)
        }
        let lhs = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
        var rhs: (expression: Expression, lastIndex: Int)? = nil
        index = lhs.lastIndex
//        print("Parsed \(lhs.expression), now at token \(tokens[index])")
        switch tokens[index] {
        case "==", "!=", "<=", ">=", "=<", "=>", ">", "<", "<>":
            op = tokens[index]
            index = try nextToken(lhs.lastIndex, endIndex: endIndex)
            rhs = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            index = rhs!.lastIndex
        default:
            break
        }
        guard tokens[index] == ")" else { throw ParsingError.expected(")",constructPrior(tokens, index: index)) }
        index = try nextToken(index, endIndex: endIndex)
        return (Comparison(lhs: lhs.expression, op: op, rhs: (rhs != nil ? rhs!.expression : nil)), index)
    }

    func parseExpression(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (expression: Expression, lastIndex: Int) {
//        print("Parsing Expression at \(tokens[startIndex])")
        var preop = ""
        var index = startIndex
        if (tokens[index] == "+") || (tokens[index] == "-") {
            preop = tokens[index]
            index = try nextToken(index, endIndex: endIndex)
        }
        let term = try parseTerm(tokens, startIndex: index, endIndex: endIndex)
//        index = try nextToken(term.lastIndex, endIndex: endIndex)
        index = term.lastIndex
        var op = ""
        var secondTerm: (expression: Expression, lastIndex: Int)? = nil
        if (tokens[index] == "+") || (tokens[index] == "-") || (tokens[index] == "||") {
            op = tokens[index]
            index = try nextToken(index, endIndex: endIndex)
            secondTerm = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            index = secondTerm!.lastIndex
        }
//        print("Next token is \(tokens[index])")
        return (Expression(preop: preop, firstTerm: term.term, op: op, secondTerm: secondTerm != nil ? secondTerm!.expression : nil), index)
    }
    
    func parseTerm(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (term: Term, lastIndex: Int) {
//        print("Parsing Term at \(tokens[startIndex])")
        var index = startIndex
        let factor = try parseFactor(tokens, startIndex: index, endIndex: endIndex)
//        index = try nextToken(factor.lastIndex, endIndex: endIndex)
        index = factor.lastIndex
        var op = ""
        var secondFactor: (term: Term, lastIndex: Int)? = nil
        if (tokens[index] == "*") || (tokens[index] == "/") || (tokens[index] == "&&")  {
            op = tokens[index]
            index = try nextToken(index, endIndex: endIndex)
            secondFactor = try parseTerm(tokens, startIndex: index, endIndex: endIndex)
            index = secondFactor!.lastIndex
        }
        return (Term(factor: factor.factor, op: op, term: secondFactor != nil ? secondFactor!.term : nil), index)
    }
    
    func parseFactor(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (factor: Factor, lastIndex: Int) {
//        print("Parsing Factor at \(tokens[startIndex])")
        var index = startIndex
        let la = lookAhead(tokens, index: index)

        if tokens[index] == "(" { // expression or comparison
            index = try nextToken(index, endIndex: endIndex)
            // It is a comparison if the next token is a "!", or the lookahead is one of the comparison operators
            // Wrong! First half can be an expression. We need to parse the Expression and the check for
            // and operator or a closing parenthesis. Complication: unary operator !
            // Here is the trick: we try parsing a Comparison. If it has no operator, it means it is just an
            // Expression
            let comparison = try parseComparison(tokens, startIndex: index, endIndex: endIndex)
            if (comparison.testRes.op == "") {
                return (Factor.expr(comparison.testRes.lhs), comparison.lastIndex)
            } else {
                return (Factor.test(comparison.testRes), comparison.lastIndex)
            }
            /*
            let la = lookAhead(tokens, index: index)
            if tokens[index] == "!" || la == "==" || la == "!=" || la == "<>" || la == ">" || la == "<" || la == ">=" || la == "<=" || la == "=>" || la == "=<" {
                let comparison = try parseComparison(tokens, startIndex: index, endIndex: endIndex)
                index = comparison.lastIndex
                return (Factor.Test(comparison.testRes), index)
                
            } else {
                let expression = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
                index = expression.lastIndex
                guard tokens[index] == ")" else { throw ParsingError.Expected(")",constructPrior(tokens, index: index)) }
                index = try nextToken(index, endIndex: endIndex)
                return (Factor.Expr(expression.expression), index)
            }
            */
        }
        if tokens[index].hasPrefix("\"") { // String
            let str = String(tokens[index].characters.dropFirst().dropLast())
            index = try nextToken(index, endIndex: endIndex)
            return (Factor.str(str), index)
        }
        if tokens[index] == "[" { // array
            let arr = try parseArray(tokens, startIndex: index, endIndex: endIndex)
            return (Factor.arr(arr.arr),arr.lastIndex)
        }
        if la == "[" { // array element
            let arr = try parseArrayElem(tokens, startIndex: index, endIndex: endIndex)
            return (Factor.arrayElem(arr.arrElem), arr.lastIndex)
        }
        if let value = Int(tokens[index]) { // is it an integer?
            index = try nextToken(index, endIndex: endIndex)
            return (Factor.intNumber(value),index)
        }
        if let value = Double(tokens[index]) { // is a real?
            index = try nextToken(index, endIndex: endIndex)
            return (Factor.realNumber(value),index)
        }
        if la == "(" {  // function call
            let funcResult = try parseFunc(tokens, startIndex: index, endIndex: endIndex)
            return (Factor.funcl(funcResult.funcRes), funcResult.lastIndex)
        }
        // Otherwise, assume it is a symbol
        let symb = tokens[index]
        index = try nextToken(index, endIndex: endIndex)
        return (Factor.symbol(symb),index)
    }
    
    func parseFunc(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (funcRes: Funcall, lastIndex: Int) {
//        print("Parsing Function call at \(tokens[startIndex])")
        var index = startIndex
        let funcName = tokens[index]
        index += 1 // we already know there is "(" there from the check in the call
        index = try nextToken(index, endIndex:  endIndex) // Now we are at the first argument (or the closing parenthesis)
        var args: [Expression] = []
        while tokens[index] != ")" {
            let nextExpression = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            index = nextExpression.lastIndex
            guard tokens[index] == "," || tokens[index] == ")" else { throw ParsingError.expected(",",constructPrior(tokens, index: index)) }
            args.append(nextExpression.expression)
            if tokens[index] == "," {
                index = try nextToken(index, endIndex:  endIndex)
            }
        }
        index = try nextToken(index, endIndex:  endIndex)
        return (Funcall(name: funcName, argList: args), index)
    }
    
    func parseAssign(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (asRes: Assignment, lastIndex: Int) {
//        print("Parsing Assignment at \(tokens[startIndex])")
//        let lhs = tokens[startIndex]
        let lhs = try parseFactor(tokens, startIndex: startIndex, endIndex: endIndex)
        var index = lhs.lastIndex
        switch lhs.factor {
        case .symbol(_), .arrayElem(_): break
        default: throw ParsingError.invalidAssignmentLHS
        }
        guard tokens[index] == "=" else { throw ParsingError.expected("=",constructPrior(tokens, index: index)) }
        index = try nextToken(index, endIndex: endIndex)
        let rhs = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
        return (Assignment(lhs: lhs.factor, rhs: rhs.expression), rhs.lastIndex)
    }
    
    func parseArray(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (arr: ScriptArray, lastIndex: Int) {
//        print("Parsing Array at \(tokens[startIndex])")
        var index = try nextToken(startIndex, endIndex: endIndex)
        var expres: [Expression] = []
        while tokens[index] != "]" {
            let expr = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            expres.append(expr.expression)
            index = expr.lastIndex
            guard tokens[index] == "," || tokens[index] == "]" else { throw ParsingError.expected(",",constructPrior(tokens, index: index)) }
            if tokens[index] == "," {
                index = try nextToken(index, endIndex: endIndex)
            }
        }
        index = try nextToken(index, endIndex: endIndex)
        return (ScriptArray(elements: expres), index)
    }
    
    func parseArrayElem(_ tokens: [String], startIndex: Int, endIndex: Int) throws -> (arrElem: IndexedArray, lastIndex: Int) {
//        print("Parsing Indexed Array at \(tokens[startIndex])")
        let name = tokens[startIndex]
        var index = startIndex + 1 // We already know a "[" is there
        index = try nextToken(index, endIndex: endIndex)
        let expression = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
        index = expression.lastIndex
        guard tokens[index] == "]" else { throw ParsingError.expected("]",constructPrior(tokens, index: index)) }
        index = try nextToken(index, endIndex: endIndex)
        return (IndexedArray(name: name, index: expression.expression), index)
    }
    
    
    /// The next part of the code is used to run the program.
    
    var env = Environment(outer: nil)
    
    func reset() {
        env = Environment(outer: nil)
        env.statements = statements
    }

    func step(_ model: Model) {
        do {
            var stop = false
            var first = true
            while !stop || env.pc >= env.statements.endIndex {
                while env.pc >= env.statements.endIndex {
                    if env.loopCondition != nil {
                        let condition = env.loopCondition!
                        let loopNotEnded = try condition.eval(env, model: model).intValue()
                        if loopNotEnded == 1 {
                            env.pc = 0
                        } else {
                            if env.outer != nil {
                                env = env.outer!
                            } else {
                                model.running = false
                                return
                            }
                        }
                    } else if env.outer != nil {
                        env = env.outer!
                    } else {
                        model.running = false
                        return
                    }
                }
                let cur = env.statements[env.pc]
                env.pc += 1
                switch cur {
                case .assign(let assign):
                    let value = try assign.rhs.eval(env, model: model)
                    switch assign.lhs {
                    case .symbol(let symbol):
                         env.simpleAssign(symbol, value: value, orgEnv: env)
                    case .arrayElem(let arr):
                        let index = try arr.index.eval(env, model: model)
                        switch index {
                        case .intNumber(let i):
                        try env.arrayAssign(arr.name , index: i, value: value)
                        default: throw RunTimeError.nonNumberArgument
                        }
                    default: break // cannot happen, checked during parse
                    }
                case .ifCl(let ifClause):
                    let result = try ifClause.test.eval(env, model: model)
                    env = Environment(outer: env)
                    if result.intValue() == 1 {
                        env.statements = ifClause.thenStatements
                    } else {
                        env.statements = ifClause.elseStatements
                    }
                case .whileCl(let whileCl):
                    if try whileCl.test.eval(env, model: model).intValue() == 1 {
                        env = Environment(outer: env)
                        env.statements = whileCl.statements
                        env.loopCondition = whileCl.test
                    }
                case .forCl(let forCl):
                    env = Environment(outer: env)
                    if forCl.endExpression == nil { // loop over an array
                        let theArray = try forCl.startExpression.eval(env, model: model)
                        guard theArray.type() == "array" else { throw RunTimeError.indexingNonArray }
                        var count: Int
                        switch theArray {
                        case .arr(let ar): count = ar.elements.count
                        default: count = 0 // cannot happen
                        }
                        let loopArrayName = "loopArrayName943" + String(env.level)
                        let loopArrayIndex = "loopArrayIndex724" + String(env.level)
                        let loopArrayIndexFactor = Factor.symbol(loopArrayIndex)
                        env.simpleAssign(loopArrayName, value: theArray, orgEnv: env)
                        env.simpleAssign(loopArrayIndex, value: Factor.intNumber(0), orgEnv: env)
                        let assign = Statement.assign(Assignment(lhs: forCl.loopVar, rhs: generateFactorExpression(Factor.arrayElem(IndexedArray(name: loopArrayName, index: generateFactorExpression(loopArrayIndexFactor))))))
                        let increment = Statement.assign(Assignment(lhs: loopArrayIndexFactor, rhs: Expression(preop: "", firstTerm: Term(factor: loopArrayIndexFactor, op: "", term: nil), op: "+", secondTerm: generateFactorExpression(Factor.intNumber(1)))))
                        env.statements = forCl.statements
                        env.statements.append(increment)
                        env.statements.insert(assign, at: 0)
                        let loopTest = Comparison(lhs: generateFactorExpression(loopArrayIndexFactor), op: "<", rhs: generateFactorExpression(Factor.intNumber(count)))
                        env.loopCondition = generateFactorExpression(Factor.test(loopTest))
                        if try env.loopCondition!.eval(env, model: model).intValue() == 0 {
                            env = env.outer!  /// empty loop
                        }
                    } else {
                        let value = try forCl.startExpression.eval(env, model: model)
                        env.simpleAssign(forCl.loopVar.description, value: value, orgEnv: env)
                        env.statements = forCl.statements
                        let increment = Statement.assign(Assignment(lhs: forCl.loopVar, rhs: Expression(preop: "", firstTerm: Term(factor: forCl.loopVar, op: "", term: nil), op: "+", secondTerm: generateFactorExpression(Factor.intNumber(1)))))
                        env.statements.append(increment)
                        let loopTest = Comparison(lhs: generateFactorExpression(forCl.loopVar), op: "<=", rhs: forCl.endExpression!)
                        env.loopCondition = generateFactorExpression(Factor.test(loopTest))
                        if try env.loopCondition!.eval(env, model: model).intValue() == 0 {
                            env = env.outer!  /// empty loop
                        }
                    }
                case .funcl(let fn):
                    if (fn.name.hasPrefix("run") || fn.name == "trial-end") && !first && !model.fallingThrough {
                        env.pc -= 1
                        stop = true
                    } else {
                        if let f = scriptFunctions[fn.name] {
                            var args: [Factor] = []
                            let argL = fn.arglist
                            for arg in argL {
                                args.append(try arg.eval(env, model: model))
                            }
                            let (_, done) = try f(args, model)
                            if !done {
                                env.pc -= 1
                                stop = true
                            }
                        } else {
                            throw RunTimeError.undefinedFunction(fn.name)
                        }
                    }
                }
            first = false
            }
        
        } catch RunTimeError.divisionByZero {
            model.addToTraceField("Runtime error: division by zero in \(env.statements[env.pc - 1])")
        } catch RunTimeError.unDeclaratedIdentifier(let s) {
            model.addToTraceField("Runtime error: undeclared identifier \(s) in \(env.statements[env.pc - 1])")
        } catch RunTimeError.nonNumberArgument {
            model.addToTraceField("Runtime error: non number argument in \(env.statements[env.pc - 1])")
        } catch RunTimeError.missingSecondArgument {
            model.addToTraceField("Runtime error: missing second argument in \(env.statements[env.pc - 1])")
        } catch RunTimeError.indexingNonArray {
            model.addToTraceField("Runtime error: trying to index a non-array in \(env.statements[env.pc - 1])")
        } catch RunTimeError.invalidNumberOfArguments {
            model.addToTraceField("Runtime error: invalid number of arguments in \(env.statements[env.pc - 1])")
        } catch RunTimeError.errorInFunction(let fn) {
            model.addToTraceField("Runtime error: error in function (\(fn)) in \(env.statements[env.pc - 1])")
        } catch RunTimeError.undefinedFunction(let fn) {
            model.addToTraceField("Runtime error: undefined function \(fn) in \(env.statements[env.pc - 1])")
        } catch RunTimeError.arrayOutOfBounds {
            model.addToTraceField("Runtime error: Array index out of bounds in \(env.statements[env.pc - 1])")
        } catch {
            model.addToTraceField("Unknown runtime error in \(env.statements[env.pc - 1])")
        }
        

    }
    
    func scriptHasEnded() -> Bool {
        return env.outer == nil && env.pc >= env.statements.endIndex
    }
    func scriptHasNotStarted() -> Bool {
        return env.outer == nil && env.pc == 0
    }
    
}


