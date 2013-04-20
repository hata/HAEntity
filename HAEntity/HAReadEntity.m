//
//  HAViewEntity.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HAReadEntity.h"

@implementation HAReadEntity

+ (NSString*) tableName
{
    // TODO: Should resolve automatically from classname.
    // or it may be better to call a delegate to convert classname to table name.
    NSString* className = NSStringFromClass([self class]);
    NSString* exceptionReason = [NSString stringWithFormat:@"%@ doesn't override tableName class method to return a table/view name.", className];
    [[NSException exceptionWithName:@"NoTableNameFoundException" reason:exceptionReason userInfo:nil] raise];
    return nil;
}

+ (NSString*) selectPrefix
{
    NSMutableArray* columnNames = [NSMutableArray new];
    [self columns:columnNames columnTypes:nil];
    return [NSString stringWithFormat:@"SELECT %@ FROM %@", [columnNames componentsJoinedByString:@", "], [self tableName]];
}


+ (NSArray*) group_by:(NSString*)group_by
{
    __block NSMutableArray* results = [NSMutableArray new];
    
    [self group_by_each:^(id entity, BOOL* stop){
        [results addObject:entity];
    } group_by:group_by params:nil list:NULL];
    
    return results;
}

+ (NSArray*) group_by:(NSString*)group_by params:(id)params, ...
{
    __block NSMutableArray* results = [NSMutableArray new];

    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        [self group_by_each:^(id entity, BOOL* stop){
            [results addObject:entity];
        } group_by:group_by params:params list:args];
    } else {
        [self group_by_each:^(id entity, BOOL* stop){
            [results addObject:entity];
        } group_by:group_by params:nil list:NULL];
    }

    return results;
}

+ (NSArray*) group_by:(NSString*)group_by params:(id)params list:(va_list)args
{
    __block NSMutableArray* results = [NSMutableArray new];
    
    if (params) {
        [self group_by_each:^(id entity, BOOL* stop){
            [results addObject:entity];
        } group_by:group_by params:params list:args];
    } else {
        [self group_by_each:^(id entity, BOOL* stop){
            [results addObject:entity];
        } group_by:group_by params:nil list:NULL];
    }
    
    return results;
}

+ (void) group_by_each:(HABaseEntityEachHandler)block group_by:(NSString*)group_by
{
    [self group_by_each:block group_by:group_by params:nil list:NULL];
}

+ (void) group_by_each:(HABaseEntityEachHandler)block group_by:(NSString*)group_by params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        [self group_by_each:block group_by:group_by params:params list:args];
    } else {
        [self group_by_each:block group_by:group_by params:nil list:NULL];
    }
}

+ (void) group_by_each:(HABaseEntityEachHandler)block group_by:(NSString*)group_by params:(id)params list:(va_list)args
{
    NSMutableArray* columnNames = [NSMutableArray new];
    [self columns:columnNames columnTypes:nil];
    NSString* columns = [columnNames componentsJoinedByString:@", "];

    // TODO: This should be changed because this is group by and column may not have the correct function.
    
    NSString* fmt = [NSString stringWithFormat:@"%@ FROM %@ GROUP BY %@", columns, [self tableName], group_by];
    [self select_each:block select:fmt params:params list:args];
}

@end
