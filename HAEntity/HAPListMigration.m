//
//  HAPListMigration.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/19.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HAPListMigration.h"

@implementation HAPListMigration

- (id) initWithVersion:(NSInteger)version
{
    if (self = [super initWithVersion:version]) {
    }
    return self;
}

- (void) addPropertyList:(NSString*)pListPath
{
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:pListPath];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* keyString = key;

        if ([keyString length] >= 2 && [[[keyString substringToIndex:2] lowercaseString] isEqualToString:@"up"]) {
            [self addSQLForEntity:nil upSQL:obj downSQL:nil];
        } else if ([keyString length] >= 4 && [[[keyString substringToIndex:4] lowercaseString] isEqualToString:@"down"]) {
            [self addSQLForEntity:nil upSQL:nil downSQL:obj];
        }
    }];
}

@end
