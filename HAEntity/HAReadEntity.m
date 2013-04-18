//
//  HAViewEntity.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HAReadEntity.h"

@implementation HAReadEntity

// TODO: This should be resolved by automatically if we can do it.
+ (NSString*) tableName
{
    return nil;
}

+ (NSString*) selectPrefix
{
    NSMutableString* buffer = [NSMutableString new];
    [buffer appendFormat:@"SELECT "];
    
    NSMutableArray* columnNames = [NSMutableArray new];
    [self columns:columnNames columnTypes:nil];

    // TODO: Check Array method.
    BOOL firstColumn = TRUE;
    for (NSString* column in columnNames) {
        [buffer appendFormat:(firstColumn ? @"%@" : @", %@"), column];
        firstColumn = FALSE;
    }
    [buffer appendFormat:@" FROM %@", [self tableName]];
    
    return buffer;
}

+ (NSArray*) group_by:(NSString *)group_by
{
    __block NSMutableArray* results = [NSMutableArray new];
    
    [self group_by:^(id entity, BOOL* stop){
        [results addObject:entity];
    } group_by:group_by];
    
    return results;
}

+ (void) group_by:(HABaseEntityEachHandler)block group_by:(NSString*)group_by
{
    [self group_by:block group_by:group_by params:nil list:NULL];
}

+ (void) group_by:(HABaseEntityEachHandler)block group_by:(NSString*)group_by params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        [self group_by:block group_by:group_by params:params list:args];
    } else {
        [self group_by:block group_by:group_by params:nil list:NULL];
    }
}

+ (void) group_by:(HABaseEntityEachHandler)block group_by:(NSString*)group_by params:(id)params list:(va_list)args
{
    NSMutableArray* columnNames = [NSMutableArray new];
    [self columns:columnNames columnTypes:nil];
    NSString* columns = [columnNames componentsJoinedByString:@", "];

    // TODO: This should be changed because this is group by and column may not have the correct function.
    
    NSString* fmt = [NSString stringWithFormat:@"%@ FROM %@ GROUP BY %@", columns, [self tableName], group_by];
    [self select:block select:fmt params:params list:args];
}

@end
