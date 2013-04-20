//
//  HAPListMigration.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/19.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HASQLMigration.h"

/**
 * plist format is NSDictionay and key should start 'up' or 'down'.
 * If one of the both words is found, then value is used as sql statement.
 * e.g.
 * up_1 -> CREATE TABLE test_table(val NUMERIC);
 * down_1 -> DROP TABLE test_table;
 */
@interface HAPListMigration : HASQLMigration

- (id) initWithVersion:(NSInteger)version;

- (void) addPropertyList:(NSString*)pListPath;

@end
