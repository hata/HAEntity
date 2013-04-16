//
//  HABaseEntity.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <objc/runtime.h>
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "HAEntityManager.h"
#import "HABaseEntity.h"


static NSString* getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            NSData* data = [NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1];
            return [NSString stringWithCString:(const char *)[data bytes] encoding:NSASCIIStringEncoding];
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            return @"id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            NSData* data = [NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4];
            return [NSString stringWithCString:(const char *)[data bytes] encoding:NSASCIIStringEncoding];
        }
    }
    return @"";
}

@implementation HABaseEntity


+ (NSArray*) where:(NSString*) params, ...
{
    va_list args;
    va_start(args,params);
    va_end(args);
    
    __block NSMutableArray* results = [NSMutableArray new];
    [self where_each:^(id entity){
        [results addObject:entity];
    } params:params list:args];
    
    return results;
}

+ (void) where_each:(HABaseEntityEachHandler)handler params:(NSString*)params, ...
{
    va_list args;
    va_start(args,params);
    va_end(args);
    
    [self where_each:^(id entity) {
        handler(entity);
    } params:params list:args];
    
}


+ (int) HA_countParams:(NSString*)params
{
    int paramCount = 0;
    NSUInteger len = [params length];

    for (NSUInteger i = 0;i < len;i++) {
        unichar c = [params characterAtIndex:i];
        // '?' is used for parameter. ':' is named parameter like :name, :value, and so on.
        if (c == '?' || c == ':') {
            paramCount++;
        }
    }

    return paramCount;
}

+ (void) where_each:(HABaseEntityEachHandler)handler params:(NSString*)params list:(va_list)args
{
    NSString* querySql = nil;
    NSMutableArray* paramList = nil;

    if (params) {
        int paramCount = [self HA_countParams:params];

        paramList = [NSMutableArray new];
        NSMutableArray* optionalList = [NSMutableArray new];

        id arg = va_arg(args, id);
        while (arg) {
            if (paramCount <= 0) {
                [optionalList addObject:arg];
            } else {
                [paramList addObject:arg];
                paramCount--;
            }
            arg = va_arg(args, id);
        }

        // optionalList contains order by or having

        BOOL paramFound = FALSE;
        for (id optParam in optionalList) {
            if (paramFound) {
                [paramList addObject:optParam];
            } else if ([optParam isKindOfClass:[NSString class]]) {
                NSString* mayHaving = (NSString*)optParam;
                paramCount = [self HA_countParams:mayHaving];
                if (paramCount > 0) {
                    paramFound = TRUE;
                }
            }
        }

        // optionalList should have order by and having text only..
        // having's parameters are added to paramList.
        [optionalList removeObjectsInArray:paramList];

        NSMutableString* buffer = [NSMutableString stringWithFormat:@"%@ WHERE %@", [self selectPrefix], params];
        for (NSString* optParam in optionalList) {
            [buffer appendFormat:@" %@ ", optParam];
        }
        querySql = buffer;
    } else {
        querySql = [self selectPrefix];
    }

    [[HAEntityManager instanceForEntity:self] accessDatabase:^(FMDatabase *db) {
        FMResultSet* results = [db executeQuery:querySql withArgumentsInArray:paramList];
        while ([results next]) {
            id entity = [[self alloc] initWithResultSet:results];
            [entity setResultSetToProperties:results];
            handler(entity);
        }
        [results close];
    }];

    /*
    // Search sql parameter count.
    // TODO: Do we have more effective way to count characters ??
    int questionCount = 0;
    NSUInteger len = [params length];
    for (NSUInteger i = 0;i < len;i++) {
        if ([params characterAtIndex:i] == '?') {
            questionCount++;
        }
    }
    
    // Get parameters as an array to pass FMDatabase
    NSMutableArray* paramList = [NSMutableArray new];
    
    for (int i = 0;i < questionCount;i++) {
        [paramList addObject:va_arg(args, id)];
    }
    [[HAEntityManager instanceForEntity:self] accessDatabase:^(FMDatabase *db) {
        NSString* querySql = (nil != params) ?
        [NSString stringWithFormat:@"%@ WHERE %@", [self selectPrefix], params] : [self selectPrefix];
        FMResultSet* results = [db executeQuery:querySql withArgumentsInArray:paramList];
        while ([results next]) {
            id entity = [[self alloc] initWithResultSet:results];
            [entity setResultSetToProperties:results];
            handler(entity);
        }
        [results close];
    }];*/
}


+ (NSString*) selectPrefix
{
    return nil;
}


+ (NSArray*) columnNames
{
    NSMutableArray *columnNames = [NSMutableArray arrayWithCapacity:0];
    [self columns:columnNames columnTypes:nil];
    return columnNames;
}

+ (void) columns:(NSMutableArray*)columnNames columnTypes:(NSMutableArray*)columnTypes
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString *propertyName = [NSString stringWithCString:propName encoding:NSASCIIStringEncoding];
            NSString *propertyType = getPropertyType(property);
            [columnNames addObject:[self convertPropertyToColumnName:propertyName]];
            [columnTypes addObject:[self convertPropertyToColumnType:propertyType]];
            // LOG(@" property name is %@ %@", propertyName, propertyType);
        }
    }
    free(properties);
}

+ (NSArray*) propertyNames
{
    NSMutableArray *propertyNames = [NSMutableArray arrayWithCapacity:0];
    [self properties:propertyNames propertyTypes:nil];
    return propertyNames;
}

+ (void) properties:(NSMutableArray*)propertyNames propertyTypes:(NSMutableArray*)propertyTypes
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString *propertyName = [NSString stringWithCString:propName encoding:NSASCIIStringEncoding];
            NSString *propertyType = getPropertyType(property);
            [propertyNames addObject:propertyName];
            [propertyTypes addObject:propertyType];
            // LOG(@" property name is %@ %@", propertyName, propertyType);
        }
    }
    free(properties);
}

+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName
{
    return propertyName;
}

/*
+ (NSString*) convertColumnToPropertyName:(NSString*) columnName
{
    return columnName;
}
*/


/**
 * @see https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
 */
+ (NSString*) convertPropertyToColumnType:(NSString*) propertyType
{
    if ([@"NSString" isEqualToString:propertyType]) {
        return @"TEXT";
    } else if ([@"i" isEqualToString:propertyType] ||
               [@"c" isEqualToString:propertyType] ||
               [@"s" isEqualToString:propertyType] ||
               [@"l" isEqualToString:propertyType] ||
               [@"q" isEqualToString:propertyType] ||
               [@"C" isEqualToString:propertyType] ||
               [@"I" isEqualToString:propertyType] ||
               [@"S" isEqualToString:propertyType] ||
               [@"L" isEqualToString:propertyType] ||
               [@"Q" isEqualToString:propertyType] ||
               [@"B" isEqualToString:propertyType]) {
        return @"NUMERIC";
    } else if ([@"f" isEqualToString:propertyType] ||
               [@"d" isEqualToString:propertyType]) {
        return @"REAL";
    } else if ([@"NSDate" isEqualToString:propertyType]) {
        return @"NUMERIC";
    } else {
        // e.g. NSData
        return @"NONE";
    }
}

// TODO: I don't implement it yet...
// camel class name to underscore plural name and remove prefix text.
+ (NSString*) classNameToTableName:(NSString*) className prefixLength:(NSUInteger)prefixLength
{
    className = [className substringFromIndex:prefixLength]; // remove 'AA' from AABarFoo.
    NSUInteger length = className.length;
    
    // BARFOO => b_a_r_f_o_o . So, the maximum is 2 * length.
    unichar* replaceChars = malloc(sizeof(unichar) * length * 2 + 1);
    NSUInteger replaceIndex = 0;
    
    BOOL uppercase = TRUE;
    for (NSUInteger i = 0;i < length;i++) {
        unichar c = [className characterAtIndex:i];
        if (isupper(c)) {
            if (!uppercase) {
                uppercase = TRUE;
                if (i > 0) {
                    replaceChars[replaceIndex++] = '_';
                }
            }
            replaceChars[replaceIndex++] = tolower(c);
        } else {
            if (uppercase) {
                uppercase = FALSE;
            }
            replaceChars[replaceIndex++] = c;
        }
    }
    replaceChars[replaceIndex] = '\0';
    
    NSMutableString* pluralName = [NSMutableString stringWithCharacters:replaceChars length:replaceIndex];
    free(replaceChars);
    
    // pluralName should be changed to real plural name......
    
    return pluralName;
}




- (id) init
{
    if (self = [super init]) {
    }
    return self;
}

- (id) initWithResultSet:(FMResultSet*)resultSet
{
    if (self = [super init]) {
    }
    return self;
}

- (void) setResultSetToProperties:(FMResultSet*)resultSet
{
    NSMutableArray* propertyNames = [NSMutableArray new];
    NSMutableArray* propertyTypes = [NSMutableArray new];
    Class entityClass = [self class];
    
    [entityClass properties:propertyNames propertyTypes:propertyTypes];
    
    NSUInteger propertyCount = propertyNames.count;
    for (NSUInteger i = 0;i < propertyCount;i++) {
        NSString* propName = [propertyNames objectAtIndex:i];
        NSString* propType = [propertyTypes objectAtIndex:i];
        NSString* columnName = [entityClass convertPropertyToColumnName:propName];
        
        id returnValue = [self convertColumnToPropertyValue:resultSet propertyName:propName propertyType:propType columnName:columnName];
        [self setValue:returnValue forKey:propName];
    }
}

- (id) convertColumnToPropertyValue:(FMResultSet*) resultSet propertyName:(NSString*)propertyName propertyType:(NSString*)propertyType columnName:(NSString*)columnName
{
    if ([@"NSString" isEqualToString:propertyType]) {
        return [resultSet stringForColumn:columnName];
    } else if ([@"i" isEqualToString:propertyType] ||
               [@"s" isEqualToString:propertyType] ||
               [@"c" isEqualToString:propertyType]) {
        return [NSNumber numberWithInt:[resultSet intForColumn:columnName]];
    } else if ([@"l" isEqualToString:propertyType]) {
        return [NSNumber numberWithLong:[resultSet longForColumn:columnName]];
    } else if ([@"q" isEqualToString:propertyType]) {
        return [NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columnName]];
    } else if ([@"C" isEqualToString:propertyType]) {
        return [NSNumber numberWithUnsignedChar:[resultSet intForColumn:columnName]];
    } else if ([@"I" isEqualToString:propertyType]) {
        return [NSNumber numberWithUnsignedInt:[resultSet intForColumn:columnName]];
    } else if ([@"S" isEqualToString:propertyType]) {
        return [NSNumber numberWithUnsignedShort:[resultSet intForColumn:columnName]];
    } else if ([@"L" isEqualToString:propertyType]) {
#ifdef FMDB_UNSIGNED_LONG_LONG_INT_FOR_COLUMN
        return [NSNumber numberWithUnsignedLong:[resultSet unsignedLongLongIntForColumn:columnName]];
#else
        return [NSNumber numberWithUnsignedLong:[resultSet longLongIntForColumn:columnName]];
#endif
    } else if ([@"Q" isEqualToString:propertyType]) {
#ifdef FMDB_UNSIGNED_LONG_LONG_INT_FOR_COLUMN
        return [NSNumber numberWithUnsignedLongLong:[resultSet unsignedLongLongIntForColumn:columnName]];
#else
        return [NSNumber numberWithUnsignedLongLong:[resultSet longLongIntForColumn:columnName]];
#endif
    } else if ([@"f" isEqualToString:propertyType]) {
        return [NSNumber numberWithDouble:[resultSet doubleForColumn:columnName]];
    } else if ([@"d" isEqualToString:propertyType]) {
        return [NSNumber numberWithDouble:[resultSet doubleForColumn:columnName]];
    } else if ([@"B" isEqualToString:propertyType]) {
        return [NSNumber numberWithBool:[resultSet boolForColumn:columnName]];
    } else if ([@"NSDate" isEqualToString:propertyType]) {
        return [resultSet dateForColumn:columnName];
    } else if ([@"NSData" isEqualToString:propertyType]) {
        return [resultSet dataForColumn:columnName];
    } else {
        return [self convertColumnToExtendedPropertyValue:resultSet propertyName:propertyName propertyType:propertyType columnName:columnName];
    }
}

- (id) convertColumnToExtendedPropertyValue:(FMResultSet*) resultSet propertyName:(NSString*)propertyName propertyType:(NSString*)propertyType columnName:(NSString*)columnName
{
    LOG(@"*** Unsupported data type is set. class:%@ propertyName:%@(column:%@) type:%@", [self class], propertyName, columnName, propertyType);
    return nil;
}

@end
