//
//  QueryParameterType.swift
//  MySQL
//
//  Created by Yusuke Ito on 12/28/15.
//  Copyright © 2015 Yusuke Ito. All rights reserved.
//

import SQLFormatter

public protocol QueryParameter {
    func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType
}

public protocol QueryParameterDictionaryType: QueryParameter {
    func queryParameter() throws -> QueryDictionary
}

public extension QueryParameterDictionaryType {
    func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        return try queryParameter().queryParameter(option: option)
    }
}

public protocol QueryParameterOptionType {
}


public struct QueryParameterNull: QueryParameter, NilLiteralConvertible {
    
    public init() {
        
    }
    public init(nilLiteral: ()) {
        
    }
    public func queryParameter(option option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( "NULL" )
    }
}

public struct QueryDictionary: QueryParameter {
    let dict: [String: QueryParameter?]
    public init(_ dict: [String: QueryParameter?]) {
        self.dict = dict
    }
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        var keyVals: [String] = []
        for (k, v) in dict {
            keyVals.append("\(SQLString.escapeId(k)) = \(try QueryOptional(v).queryParameter(option: option).escapedValue())")
        }
        return QueryParameterWrap( keyVals.joined(separator:  ", ") )
    }
}

/*
public protocol QueryDictionaryType: QueryParameterType {
    var dict: [String: Self?] { get }
}

public extension QueryDictionaryType {
    func escapedValue(option option: Self.OT) throws -> String {
        var keyVals: [String] = []
        for (k, v) in dict {
            keyVals.append("\(SQLString.escapeId(k)) = \(try QueryOptional(v).escapedValue(option: option))")
        }
        return keyVals.joined(separator:  ", ")
    }
}
*/

//extension Dictionary: where Value: QueryParameter, Key: StringLiteralConvertible { }
// not yet supported
// extension Array:QueryParameter where Element: QueryParameter { }


protocol QueryArrayType: QueryParameter {
    
}

public struct QueryArray: QueryParameter, QueryArrayType {
    let arr: [QueryParameter?]
    public init(_ arr: [QueryParameter?]) {
        self.arr = arr
    }
    public init(_ arr: [QueryParameter]) {
        self.arr = arr.map { Optional($0) }
    }
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        return QueryParameterWrap( try arr.map({
            if let val = $0 as? QueryArrayType {
                return "(" + (try val.queryParameter(option: option).escapedValue()) + ")"
            }
            return try QueryOptional($0).queryParameter(option: option).escapedValue()
        }).joined(separator: ", ") )
    }
}



extension Optional: QueryParameter {
    
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        guard let value = self else {
            return QueryParameterNull().queryParameter(option: option)
        }
        guard let val = value as? QueryParameter else {
            throw QueryFormatError.CastError(actual: "\(value.self)", expected: "QueryParameter", key: "")
        }
        return try val.queryParameter(option: option)
    }
}


struct QueryOptional: QueryParameter {
    let val: QueryParameter?
    init(_ val: QueryParameter?) {
        self.val = val
    }
    func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        guard let val = self.val else {
            return QueryParameterNull().queryParameter(option: option)
        }
        return try val.queryParameter(option: option)
    }
}



/*
protocol QueryParameterOptionalType: QueryParameterType {
    var val: Self? { get }
}

extension QueryParameterOptionalType {
    func escapedValue(option option: Self.OT) throws -> String {
        guard let val = self.val else {
            //return QueryParameterNullType().escapedValue(option: option)
            return Self.nullValue
        }
        return try val.escapedValue(option: option)
    }
}*/

struct QueryParameterWrap: QueryParameterType {
    let val: String
    init(_ val: String) {
        self.val = val
    }
    func escapedValue() -> String {
        return val
    }
}

extension String: QueryParameterType {
    public func escapedValue() -> String {
        return SQLString.escape(self)
    }
}

extension String: QueryParameter {
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        return QueryParameterWrap( SQLString.escape(self) )
    }
}

extension Int: QueryParameter {
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Int64: QueryParameter {
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Double: QueryParameter {
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Float: QueryParameter {
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Bool: QueryParameter {
    public func queryParameter(option option: QueryParameterOption) throws -> QueryParameterType {
        return QueryParameterWrap( self ? "true" : "false" )
    }
}