//
// Copyright 2013 Hiroki Ata
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
