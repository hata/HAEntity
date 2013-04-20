//
//  HAViewEntity.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HABaseEntity.h"

@interface HAReadEntity : HABaseEntity

+ (NSString*) tableName;

+ (NSArray*) group_by:(NSString*)group_by;
+ (NSArray*) group_by:(NSString*)group_by params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (NSArray*) group_by:(NSString*)group_by params:(id)params list:(va_list)args;
+ (void)     group_by_each:(HABaseEntityEachHandler)block group_by:(NSString*)group_by;
+ (void)     group_by_each:(HABaseEntityEachHandler)block group_by:(NSString*)group_by params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (void)     group_by_each:(HABaseEntityEachHandler)block group_by:(NSString*)group_by params:(id)params list:(va_list)args;

@end
