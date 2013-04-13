//
//  HAViewEntity.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HAViewEntity.h"

@implementation HAViewEntity

// TODO: This should be resolved by automatically if we can do it.
+ (NSString*) viewName
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
    [buffer appendFormat:@" FROM %@", [self viewName]];
    
    return buffer;
}

@end
