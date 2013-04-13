//
//  HATableMigration.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HATableMigration.h"

@implementation HATableMigration

- (id) initWithEntityClasses:(Class) params, ...
{
    if (self = [super init]) {
        _classes = [NSMutableArray new];

        va_list args;
        va_start(args, params);

        Class clazz = params;
        while (clazz) {
            [_classes addObject:clazz];
            clazz = va_arg(args, Class);
        }
        
        va_end(args);
    }
    return self;
}

- (void) up:(FMDatabase*)db
{
    
}

@end
