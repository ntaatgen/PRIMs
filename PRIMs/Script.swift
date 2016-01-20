//
//  Script.swift
//  PRIMs
//
//  Created by Niels Taatgen on 1/5/16.
//  Copyright © 2016 Niels Taatgen. All rights reserved.
//

import Foundation

enum Statement: CustomStringConvertible {
    case Assign(Assignment)
    case Func(Funcall)
    case IfCl(IfClause)
    case WhileCl(WhileClause)
    var description: String {
        switch self {
        case .Assign(let ass): return "Assignment: \(ass)"
        case .Func(let funcall): return "Function call: \(funcall)"
        case .IfCl(let ifc): return "If clause: \(ifc)"
        case .WhileCl(let whcl): return "While clause \(whcl)"
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
    func eval(env: Environment) throws -> Factor {
        if let f = scriptFunctions[name] {
            var args: [Factor] = []
            for arg in arglist {
                args.append(try arg.eval(env))
            }
            let (result, _, _) = try f(args, nil)
            guard result != nil else {throw RunTimeError.errorInFunction("Function does not produce a result") }
            return result!
        } else {
            throw RunTimeError.undefinedFunction(name)
        }

    }
    
}

class IfClause: CustomStringConvertible {
    let test: Comparison
    let thenStatements: [Statement]
    let elseStatements: [Statement]
    init(test: Comparison, thenStatements: [Statement], elseStatements: [Statement]) {
        self.test = test
        self.thenStatements = thenStatements
        self.elseStatements = elseStatements
    }
    var description: String {
        return "if \(test) { ... } { ... }"
    }
}

class WhileClause: CustomStringConvertible {
    let test: Comparison
    let statements: [Statement]
    init(test: Comparison, statements: [Statement]) {
        self.test = test
        self.statements = statements
    }
    var description: String {
        return "while \(test)"
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
    func eval(env: Environment) throws -> Factor {
        var term1 = try firstTerm.eval(env)
        if preop == "-" {
            switch term1 {
            case .IntNumber(let number):
                term1 = .IntNumber(-number)
            case .RealNumber(let number):
                term1 = .RealNumber(-number)
            default: RunTimeError.nonNumberArgument
            }
        }
        if op == "" {
            return term1
        }
        guard secondTerm != nil else { throw RunTimeError.missingSecondArgument }
        var term2 = try secondTerm!.eval(env)
        // If one of the numbers is an Int and the other a Real, covert Int to Real
        switch (term1, term2) {
        case (.IntNumber(let num1), .RealNumber(_)):
            term1 = Factor.RealNumber(Double(num1))
        case (.RealNumber(_), .IntNumber(let num2)):
            term2 = Factor.RealNumber(Double(num2))
        default: break
        }
        switch (term1, term2, op) {
        case (.IntNumber(let num1),.IntNumber(let num2),"+"):
            return .IntNumber(num1 + num2)
        case (.IntNumber(let num1),.IntNumber(let num2),"-"):
            return .IntNumber(num1 - num2)
        case (.RealNumber(let num1), .RealNumber(let num2),"+"):
            return .RealNumber(num1 + num2)
        case (.RealNumber(let num1), .RealNumber(let num2), "-"):
            return .RealNumber(num1 - num2)
        default: RunTimeError.nonNumberArgument
        }
        return Factor.Str("This should never happen")
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
    func eval(env: Environment) throws -> Factor {
        var factor1 = try factor.eval(env)
        if op == "" {
            return factor1
        }
        guard term != nil else { throw RunTimeError.missingSecondArgument }
        var factor2 = try term!.eval(env)
        switch (factor1, factor2) {
        case (.IntNumber(let num1), .RealNumber(_)):
            factor1 = Factor.RealNumber(Double(num1))
        case (.RealNumber(_), .IntNumber(let num2)):
            factor2 = Factor.RealNumber(Double(num2))
        default: break
        }
        switch (factor1, factor2, op) {
        case (.IntNumber(let num1),.IntNumber(let num2),"*"):
            return .IntNumber(num1 * num2)
        case (.IntNumber(let num1),.IntNumber(let num2),"/"):
            guard num2 != 0 else { throw RunTimeError.divisionByZero }
            return .IntNumber(num1 / num2)
        case (.RealNumber(let num1), .RealNumber(let num2),"*"):
            return .RealNumber(num1 * num2)
        case (.RealNumber(let num1), .RealNumber(let num2), "/"):
            guard num2 != 0 else { throw RunTimeError.divisionByZero }
            return .RealNumber(num1 / num2)
        default: RunTimeError.nonNumberArgument
        }
        return Factor.Str("This should never happen")
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
    func eval(env: Environment) throws -> Factor {
        var newElements: [Expression] = []
        for elem in elements {
            let value = try elem.eval(env)
            newElements.append(Expression(preop: "", firstTerm: Term(factor: value, op: "", term: nil), op: "", secondTerm: nil))
        }
        return Factor.Arr(ScriptArray(elements: newElements))
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
    func eval(env: Environment) throws -> Bool {
        var leftArg = try lhs.eval(env)
        if op == "" || op == "!" {
            switch leftArg {
            case .IntNumber(let num):
                return op == "" ? num != 0 : num == 0
            case .RealNumber(let num):
                return op == "" ? num != 0 : num == 0
            case .Str(let str):
                return op == "" ? str != "" : str == ""
            default:
                throw RunTimeError.nonNumberArgument
            }
        }
        guard rhs != nil else { throw RunTimeError.missingSecondArgument }
        var rightArg = try rhs!.eval(env)
        switch (leftArg, rightArg) {
        case (.IntNumber(let num1), .RealNumber(_)):
            leftArg = Factor.RealNumber(Double(num1))
        case (.RealNumber(_), .IntNumber(let num2)):
            rightArg = Factor.RealNumber(Double(num2))
        default: break
        }
        switch  op {
            case "==": return leftArg == rightArg
            case "!=", "<>": return leftArg != rightArg
            case ">": return leftArg > rightArg
            case "<": return leftArg < rightArg
            case ">=", "=>": return leftArg >= rightArg
            case "<=", "=<": return leftArg <= rightArg
        default: throw RunTimeError.unDeclaratedIdentifier(op) // shouldn't happen
        }
    }
}

enum Factor: CustomStringConvertible  {
    case Func(Funcall)
    case Arr(ScriptArray)
    case RealNumber(Double)
    case IntNumber(Int)
    case Str(String)
    case Symbol(String)
    case Expr(Expression)
    case ArrayElem(IndexedArray)
    var description: String {
        switch self {
        case .IntNumber(let num): return String(num)
        case .RealNumber(let num): return String(num)
        case .Str(let s): return s
        case .Symbol(let s): return s
        case .Func(let fn): return fn.description
        case .Arr(let arr): return "\(arr)"
        case .Expr(let ex): return "\(ex)"
        case .ArrayElem(let arr): return "\(arr)"
        }
    }
    func eval(env: Environment) throws -> Factor {
        switch self {
        case .Func(let funcall):
            return try funcall.eval(env)
//        case .Arr(let arr):
//            return try arr.eval(env)
        case .ArrayElem(let arr):
            return try arr.eval(env)
        case .Expr(let expr):
            return try expr.eval(env)
        case .Symbol(let sym):
            return try env.lookup(sym)
        case .Arr(let arr):
            return try arr.eval(env)
        default:
            return self
        }
    }
}

func == (left: Factor, right: Factor) -> Bool {
    switch (left, right) {
    case (.IntNumber(let num1),.IntNumber(let num2)):
        return num1 == num2
    case (.RealNumber(let num1),.RealNumber(let num2)):
        return num1 == num2
    case (.Str(let str1),.Str(let str2)):
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
    case (.IntNumber(let num1),.IntNumber(let num2)):
            return num1 > num2
    case (.RealNumber(let num1),.RealNumber(let num2)):
        return num1 > num2
    default: return false
    }
}

func < (left: Factor, right: Factor) -> Bool {
    switch (left, right) {
    case (.IntNumber(let num1),.IntNumber(let num2)):
        return num1 < num2
    case (.RealNumber(let num1),.RealNumber(let num2)):
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

class IndexedArray {
    let name: String
    let index: Expression
    init(name: String, index: Expression) {
        self.name = name
        self.index = index
    }
    func eval(env: Environment) throws -> Factor {
        let ind = try index.eval(env)
        let arr = try env.lookup(name)
        switch (ind, arr) {
        case (Factor.IntNumber(let i),Factor.Arr(let a)):
            let expr = a.elements[i]
            return try expr.eval(env)
        default: throw RunTimeError.indexingNonArray
        }
    }
}

enum ParsingError: ErrorType {
    case UnExpectedEOF
    case Expected(String, String)
    case OperatorExpected(String, String)
    case InvalidAssignmentLHS
}

enum RunTimeError: ErrorType {
    case unDeclaratedIdentifier(String)
    case nonNumberArgument
    case missingSecondArgument
    case divisionByZero
    case indexingNonArray
    case invalidNumberOfArguments
    case errorInFunction(String)
    case undefinedFunction(String)
}

class Environment {
    let outer: Environment?
    var vars: [String : Factor] = [:]
    var pc: Int = 0 // Program Counter
    var statements: [Statement] = []
    var loopCondition: Comparison?  // In the case of a while loop, keep the test here
    init(outer: Environment?) { self.outer = outer }
    func add(symbol: String, value: Factor) { vars[symbol] = value }
    func lookup(symbol: String) throws -> Factor {
        if let value = vars[symbol] {
            return value
        } else if outer != nil {
            return try outer!.lookup(symbol)
        } else {
            throw RunTimeError.unDeclaratedIdentifier(symbol)
        }
    }

    func simpleAssign(v: String, value: Factor, orgEnv: Environment)  {
        if let _ = vars[v] {
            add(v, value:  value)
        } else if outer != nil {
            outer!.simpleAssign(v, value: value, orgEnv: orgEnv)
        } else {
            orgEnv.add(v, value: value)
        }
    }
    
    func arrayAssign(a: String, index: Int, value: Factor) throws {
        let factor = try lookup(a)
        switch factor {
        case .Arr(let arr):
            if index < arr.elements.endIndex {
                arr.elements[index] = Expression(preop: "", firstTerm: Term(factor: value, op: "", term: nil), op: "", secondTerm: nil)
            } else {
                while arr.elements.endIndex < index {
                    arr.elements.append(Expression(preop: "", firstTerm: Term(factor: Factor.IntNumber(0), op: "", term: nil), op: "", secondTerm: nil))
                }
                arr.elements.append(Expression(preop: "", firstTerm: Term(factor: value, op: "", term: nil), op: "", secondTerm: nil))
            }
        default: RunTimeError.indexingNonArray
        }
    }
}


class Script {
    var statements: [Statement] = []
    
    func tokenize(input: String) -> [String] {
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
    
    func getNextChar(input: String, nextIndex: String.Index)
        -> String { return input.substringWithRange(nextIndex..<nextIndex.advancedBy(1)) }
    
    func a(input: String, index: String.Index, char: String) -> Bool {
        return input.substringFromIndex(index).hasPrefix(char)
    }
    
    func readNextToken(input :String, startIndex : String.Index) -> (token : String?, nextIndex : String.Index) {
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            if a(input, index: nextIndex, char: " ") || a(input, index: nextIndex, char: "\n") || a(input, index: nextIndex, char: "\t") {
                nextIndex++
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
            return (nextChar, nextIndex.advancedBy(1))
        case "!", "<", ">", "=":
            return readOperator(input, startIndex: nextIndex)
        case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
            return readNumber(input, startIndex: nextIndex)
        case "\"":
            return readString(input, startIndex: nextIndex)
        default:
            return readSymbol(input, startIndex: nextIndex)
        }
    }
    
    func readNumber(input: String, startIndex: String.Index) -> (token: String?, nextIndex:String.Index) {
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
            nextIndex = nextIndex.advancedBy(1)
        }
        return (value, nextIndex)
    }
    
    func readOperator(input: String, startIndex: String.Index) -> (token: String?, nextIndex:String.Index) {
        var value = ""
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case "!", ">", "<", "=":
                value += nextChar
            default:
                return (value, nextIndex)
            }
            nextIndex = nextIndex.advancedBy(1)
        }
        return (value, nextIndex)
    }
    
    func readSymbol(input: String, startIndex: String.Index) -> (token: String?, nextIndex: String.Index) {
        var token = ""
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case " ", ")", "(", "[", "]", "{", "}", ",":
                return (token, nextIndex)
            default:
                token += nextChar
            }
            nextIndex = nextIndex.advancedBy(1)
        }
        return (token, nextIndex)
    }

    func readString(input: String, startIndex: String.Index) -> (token: String?, nextIndex: String.Index) {
        var token = "\""
        var nextIndex = startIndex.advancedBy(1)
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case "\"":
                token += nextChar
                return (token, nextIndex.advancedBy(1))
            default:
                token += nextChar
            }
            nextIndex = nextIndex.advancedBy(1)
        }
        return (token, nextIndex)
    }

    func parse(input: String) throws {
        statements = []
        var tokens = tokenize(input)
        for token in tokens {
            print(token)
        }
        tokens.append("EOF")
        var index = tokens.startIndex
        var nextStatement: Statement
        while (index < tokens.endIndex && tokens[index] != "EOF") {
            (nextStatement, index) = try parseStatement(tokens, startIndex: index, endIndex: tokens.endIndex)
            statements.append(nextStatement)
        }
    }

    func lookAhead(tokens: [String], index: Int) -> String {
        if (index + 1 < tokens.endIndex) {
            return tokens[index + 1]
        } else {
            return "#"
        }
    }
    
    func nextToken(index: Int, endIndex: Int) throws -> Int {
        guard index + 1 < endIndex else { throw ParsingError.UnExpectedEOF }
        return index + 1
    }
    
    
    func parseStatement(tokens: [String], startIndex: Int, endIndex: Int) throws -> (statement: Statement, lastIndex: Int) {
        print("Parsing Statement at \(tokens[startIndex])")
        guard startIndex < endIndex else { throw ParsingError.UnExpectedEOF }
        switch tokens[startIndex] {
        case "if":
            let ifResult = try parseIf(tokens, startIndex: try nextToken(startIndex, endIndex: endIndex), endIndex: endIndex)
            return (Statement.IfCl(ifResult.ifelse), ifResult.lastIndex)
        case "while":
            let whileResult = try parseWhile(tokens, startIndex: try nextToken(startIndex, endIndex: endIndex), endIndex: endIndex)
            return (Statement.WhileCl(whileResult.whileRes), whileResult.lastIndex)
        default:
            if lookAhead(tokens, index: startIndex) == "(" {
                let funcResult = try parseFunc(tokens, startIndex: startIndex, endIndex: endIndex)
                return (Statement.Func(funcResult.funcRes), funcResult.lastIndex)
            } else {
                let assignResult = try parseAssign(tokens, startIndex: startIndex, endIndex: endIndex)
                return (Statement.Assign(assignResult.asRes), assignResult.lastIndex)
            }
        }
    }
    
    func constructPrior(tokens: [String], index: Int) -> String {
        var s: String = ""
        for i in 0...index {
            s += tokens[i] + " "
        }
        return s
    }
    
    func parseIf(tokens: [String], startIndex: Int, endIndex: Int) throws -> (ifelse: IfClause, lastIndex: Int) {
        print("Parsing If at \(tokens[startIndex])")
        let test = try parseComparison(tokens, startIndex: startIndex, endIndex: endIndex)
        guard tokens[test.lastIndex] == "{" else {
            throw ParsingError.Expected("{",constructPrior(tokens, index: test.lastIndex))
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
            guard tokens[index] == "{" else { throw ParsingError.Expected("{",constructPrior(tokens, index: index)) }
            index = try nextToken(index, endIndex: endIndex)
            while tokens[index] != "}" {
                let nextStatement = try parseStatement(tokens, startIndex: index, endIndex: endIndex)
                elsePart.append(nextStatement.statement)
                index = nextStatement.lastIndex
            }
            index = try nextToken(index, endIndex: endIndex)
        }
        return (IfClause(test: test.testRes, thenStatements: thenPart, elseStatements: elsePart), index)
    }
    
    func parseWhile(tokens: [String], startIndex: Int, endIndex: Int) throws -> (whileRes: WhileClause, lastIndex: Int) {
        print("Parsing While at \(tokens[startIndex])")
        let test = try parseComparison(tokens, startIndex: startIndex, endIndex: endIndex)
        guard tokens[test.lastIndex] == "{" else {
            throw ParsingError.Expected("{",constructPrior(tokens, index: test.lastIndex))
        }
        var loop: [Statement] = []
        var index = try nextToken(test.lastIndex, endIndex: endIndex)
        while tokens[index] != "}" {
            let nextStatement = try parseStatement(tokens, startIndex: index, endIndex: endIndex)
            loop.append(nextStatement.statement)
            index = nextStatement.lastIndex
        }
        index = try nextToken(index, endIndex: endIndex)
        return (WhileClause(test: test.testRes, statements: loop), index)
    }
    
    func parseComparison(tokens: [String], startIndex: Int, endIndex: Int) throws -> (testRes: Comparison, lastIndex: Int) {
        print("Parsing Comparison at \(tokens[startIndex])")
        guard tokens[startIndex] == "(" else { throw ParsingError.Expected("(",constructPrior(tokens, index: startIndex)) }
        var index = try nextToken(startIndex, endIndex: endIndex)
        var op: String = ""
        if tokens[index] == "!" {
            op = "!"
            index = try nextToken(startIndex, endIndex: endIndex)
        }
        let lhs = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
        var rhs: (expression: Expression, lastIndex: Int)? = nil
        index = lhs.lastIndex
        switch tokens[index] {
        case "==", "!=", "<=", ">=", "=<", "=>", ">", "<", "<>":
            op = tokens[index]
            index = try nextToken(lhs.lastIndex, endIndex: endIndex)
            rhs = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            index = rhs!.lastIndex
        default:
            break
        }
        guard tokens[index] == ")" else { throw ParsingError.Expected(")",constructPrior(tokens, index: index)) }
        index = try nextToken(index, endIndex: endIndex)
        return (Comparison(lhs: lhs.expression, op: op, rhs: (rhs != nil ? rhs!.expression : nil)), index)
    }

    func parseExpression(tokens: [String], startIndex: Int, endIndex: Int) throws -> (expression: Expression, lastIndex: Int) {
        print("Parsing Expession at \(tokens[startIndex])")
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
        if (tokens[index] == "+") || (tokens[index] == "-") {
            op = tokens[index]
            index = try nextToken(index, endIndex: endIndex)
            secondTerm = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            index = secondTerm!.lastIndex
        }
        print("Next token is \(tokens[index])")
        return (Expression(preop: preop, firstTerm: term.term, op: op, secondTerm: secondTerm != nil ? secondTerm!.expression : nil), index)
    }
    
    func parseTerm(tokens: [String], startIndex: Int, endIndex: Int) throws -> (term: Term, lastIndex: Int) {
        print("Parsing Term at \(tokens[startIndex])")
        var index = startIndex
        let factor = try parseFactor(tokens, startIndex: index, endIndex: endIndex)
//        index = try nextToken(factor.lastIndex, endIndex: endIndex)
        index = factor.lastIndex
        var op = ""
        var secondFactor: (term: Term, lastIndex: Int)? = nil
        if (tokens[index] == "*") || (tokens[index] == "/") {
            op = tokens[index]
            index = try nextToken(index, endIndex: endIndex)
            secondFactor = try parseTerm(tokens, startIndex: index, endIndex: endIndex)
            index = secondFactor!.lastIndex
        }
        return (Term(factor: factor.factor, op: op, term: secondFactor != nil ? secondFactor!.term : nil), index)
    }
    
    func parseFactor(tokens: [String], startIndex: Int, endIndex: Int) throws -> (factor: Factor, lastIndex: Int) {
        print("Parsing Factor at \(tokens[startIndex])")
        var index = startIndex
        let la = lookAhead(tokens, index: index)
        if la == "(" {  // function call
            let funcResult = try parseFunc(tokens, startIndex: index, endIndex: endIndex)
            return (Factor.Func(funcResult.funcRes), funcResult.lastIndex)
        }
        if tokens[index] == "(" { // expression
            index = try nextToken(index, endIndex: endIndex)
            let expression = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            index = expression.lastIndex
            guard tokens[index] == ")" else { throw ParsingError.Expected(")",constructPrior(tokens, index: index)) }
            index = try nextToken(index, endIndex: endIndex)
            return (Factor.Expr(expression.expression), index)
        }
        if tokens[index].hasPrefix("\"") { // String
            let str = String(tokens[index].characters.dropFirst().dropLast())
            index = try nextToken(index, endIndex: endIndex)
            return (Factor.Str(str), index)
        }
        if tokens[index] == "[" { // array
            let arr = try parseArray(tokens, startIndex: index, endIndex: endIndex)
            return (Factor.Arr(arr.arr),arr.lastIndex)
        }
        if la == "[" { // array element
            let arr = try parseArrayElem(tokens, startIndex: index, endIndex: endIndex)
            return (Factor.ArrayElem(arr.arrElem), arr.lastIndex)
        }
        if let value = Int(tokens[index]) { // is it an integer?
            index = try nextToken(index, endIndex: endIndex)
            return (Factor.IntNumber(value),index)
        }
        if let value = Double(tokens[index]) { // is a real?
            index = try nextToken(index, endIndex: endIndex)
            return (Factor.RealNumber(value),index)
        }
        // Otherwise, assume it is a symbol
        let symb = tokens[index]
        index = try nextToken(index, endIndex: endIndex)
        return (Factor.Symbol(symb),index)
    }
    
    func parseFunc(tokens: [String], startIndex: Int, endIndex: Int) throws -> (funcRes: Funcall, lastIndex: Int) {
        print("Parsing Function call at \(tokens[startIndex])")
        var index = startIndex
        let funcName = tokens[index]
        index++ // we already know there is "(" there from the check in the call
        index = try nextToken(index, endIndex:  endIndex) // Now we are at the first argument (or the closing parenthesis)
        var args: [Expression] = []
        while tokens[index] != ")" {
            let nextExpression = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            index = nextExpression.lastIndex
            guard tokens[index] == "," || tokens[index] == ")" else { throw ParsingError.Expected(",",constructPrior(tokens, index: index)) }
            args.append(nextExpression.expression)
            if tokens[index] == "," {
                index = try nextToken(index, endIndex:  endIndex)
            }
        }
        index = try nextToken(index, endIndex:  endIndex)
        return (Funcall(name: funcName, argList: args), index)
    }
    
    func parseAssign(tokens: [String], startIndex: Int, endIndex: Int) throws -> (asRes: Assignment, lastIndex: Int) {
        print("Parsing Assignment at \(tokens[startIndex])")
//        let lhs = tokens[startIndex]
        let lhs = try parseFactor(tokens, startIndex: startIndex, endIndex: endIndex)
        var index = lhs.lastIndex
        switch lhs.factor {
        case .Symbol(_), .ArrayElem(_): break
        default: throw ParsingError.InvalidAssignmentLHS
        }
        guard tokens[index] == "=" else { throw ParsingError.Expected("=",constructPrior(tokens, index: index)) }
        index = try nextToken(index, endIndex: endIndex)
        let rhs = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
        return (Assignment(lhs: lhs.factor, rhs: rhs.expression), rhs.lastIndex)
    }
    
    func parseArray(tokens: [String], startIndex: Int, endIndex: Int) throws -> (arr: ScriptArray, lastIndex: Int) {
        print("Parsing Array at \(tokens[startIndex])")
        var index = try nextToken(startIndex, endIndex: endIndex)
        var expres: [Expression] = []
        while tokens[index] != "]" {
            let expr = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
            expres.append(expr.expression)
            index = expr.lastIndex
            guard tokens[index] == "," || tokens[index] == "]" else { throw ParsingError.Expected(",",constructPrior(tokens, index: index)) }
            if tokens[index] == "," {
                index = try nextToken(index, endIndex: endIndex)
            }
        }
        index = try nextToken(index, endIndex: endIndex)
        return (ScriptArray(elements: expres), index)
    }
    
    func parseArrayElem(tokens: [String], startIndex: Int, endIndex: Int) throws -> (arrElem: IndexedArray, lastIndex: Int) {
        print("Parsing Indexed Array at \(tokens[startIndex])")
        let name = tokens[startIndex]
        var index = startIndex + 1 // We already know a "[" is there
        index = try nextToken(index, endIndex: endIndex)
        let expression = try parseExpression(tokens, startIndex: index, endIndex: endIndex)
        index = expression.lastIndex
        guard tokens[index] == "]" else { throw ParsingError.Expected("]",constructPrior(tokens, index: index)) }
        index = try nextToken(index, endIndex: endIndex)
        return (IndexedArray(name: name, index: expression.expression), index)
    }
    
    
    /// The next part of the code is used to run the program.
    
    var env = Environment(outer: nil)
    
    func reset() {
        env = Environment(outer: nil)
        env.statements = statements
    }

    func step(model: Model) {
        do {
            var stop = false
            while !stop || env.pc >= env.statements.endIndex {
                while env.pc >= env.statements.endIndex {
                    if env.loopCondition != nil {
                        let condition = env.loopCondition!
                        let loopNotEnded = try condition.eval(env)
                        if loopNotEnded {
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
                let cur = env.statements[env.pc++]
                switch cur {
                case .Assign(let assign):
                    let value = try assign.rhs.eval(env)
                    switch assign.lhs {
                    case .Symbol(let symbol):
                         env.simpleAssign(symbol, value: value, orgEnv: env)
                    case .ArrayElem(let arr):
                        let index = try arr.index.eval(env)
                        switch index {
                        case .IntNumber(let i):
                        try env.arrayAssign(arr.name , index: i, value: value)
                        default: throw RunTimeError.nonNumberArgument
                        }
                    default: break // cannot happen, checked during parse
                    }
                case .IfCl(let ifClause):
                    let result = try ifClause.test.eval(env)
                    env = Environment(outer: env)
                    if result {
                        env.statements = ifClause.thenStatements
                    } else {
                        env.statements = ifClause.elseStatements
                    }
                case .WhileCl(let whileCl):
                    if try whileCl.test.eval(env) {
                        env = Environment(outer: env)
                        env.statements = whileCl.statements
                        env.loopCondition = whileCl.test
                    }
                case .Func(let fn):
                    if let f = scriptFunctions[fn.name] {
                        var args: [Factor] = []
                        let argL = fn.arglist
                        for arg in argL {
                            args.append(try arg.eval(env))
                        }
                        let (_, done, cont) = try f(args, model)
                        if !done {
                            env.pc--
                        }
                        stop = !cont
                    } else {
                        throw RunTimeError.undefinedFunction(fn.name)
                    }
                }
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


