//
//  GooropSQLiteQueryManager.h
//  goorop-sqlite-orm
//
//  Created by Dushant Singh on 17/08/15.
//  Copyright (c) 2015 Dushant Singh. All rights reserved.
//

// Copyright (c) 2012-2015 Dushant Singh, Tweakers HB.
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to
// do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
// IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "GooropSQLiteQueryManager.h"
#import "GooropSQLiteManager.h"

@implementation GooropSQLiteColumn
@end

@implementation GooropSQLiteQueryManager

#pragma mark -
#pragma mark - Static methods

+ (id)sharedManager {
    static GooropSQLiteQueryManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });

    return sharedMyManager;
}

#pragma mark -
#pragma mark Instance methods

- (BOOL)createTableWithName:(NSString *)tableName ofColumns:(NSArray *)columns withForeignKeys:(NSArray *)foreignKeys {
    BOOL created = NO;
    NSMutableArray *sqlColumns = [[NSMutableArray alloc] initWithCapacity:[columns count]];
    for (GooropSQLiteColumn *column in columns) {
        NSMutableString *sqlColumn = [[NSMutableString alloc] init];
        NSString *appendingString = nil;

        if (column.primaryKey && column.autoIncrement) {
            // Change for auto-increment
            if ([column.type isEqualToString:@"NUMERIC"]) {
                column.type = @"INTEGER";
            }
            else {
                [NSException raise:@"Invalid auto-increment type" format:@"Auto-incremental type in %@ need to be NSNumber", tableName];
            }

            appendingString = @"PRIMARY KEY AUTOINCREMENT ";
        } else if (column.primaryKey && !column.null && !column.autoIncrement) {
            appendingString = @"NOT NULL PRIMARY KEY ";
        } else if (!column.primaryKey && !column.null) {
            appendingString = @"NOT NULL ";
        }

        if (appendingString) {
            [sqlColumn appendString:[NSString stringWithFormat:@"%@ %@ %@", column.name, column.type, appendingString]];
        } else {
            [sqlColumn appendString:[NSString stringWithFormat:@"%@ %@", column.name, column.type]];
        }

        [sqlColumns addObject:sqlColumn];
    }

    NSMutableString *sqlForeignKeyString = [[NSMutableString alloc] initWithCapacity:[foreignKeys count]];
    for (NSDictionary *foreignKey in foreignKeys) {
        NSString *sqlForeignKey = [NSString stringWithFormat:@"FOREIGN KEY (%@) REFERENCES %@(%@) ON DELETE CASCADE,",
                                                             foreignKey[@"column_name"],
                                                             foreignKey[@"reference_table_name"],
                                                             foreignKey[@"reference_table_primary_key"]];
        [sqlForeignKeyString appendString:sqlForeignKey];
    }

    NSString *creationQuery;
    if ([foreignKeys count] > 0) {
        creationQuery = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@, %@) ",
                                                   tableName, [sqlColumns componentsJoinedByString:@", "],
                                                   [sqlForeignKeyString substringToIndex:[sqlForeignKeyString length] - 1]];
    } else {
        creationQuery = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)",
                                                   tableName, [sqlColumns componentsJoinedByString:@", "]];
    }

    NSLog(@"CREATE Query: %@", creationQuery);
    FMDatabase *database = [[GooropSQLiteManager sharedManager] getDatabase];
    if (![database open]) return NO;

    @try {
        // Create table
        [database executeUpdate:creationQuery];

        // Index the given columns
        for (GooropSQLiteColumn *column in columns) {
            if (column.indexed) {
                NSString *indexQuery = [NSString stringWithFormat:@"CREATE INDEX %@_index ON %@(%@)",
                                                                  column.name, tableName, column.name];
                [database executeUpdate:indexQuery];
            }
        }

        created = YES;
    }
    @catch (NSException *exception) {
        NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
    }
    @finally {
        [database close];
    }

    return created;
}

- (BOOL)deleteTableWithName:(NSString *)tableName {
    if (![self doesExistsTableWithTableName:tableName]) {
        NSLog(@"Table %@ does not exists!", tableName);
        return NO;
    }

    BOOL deleted = YES;
    FMDatabase *database = [[GooropSQLiteManager sharedManager] getDatabase];
    if (![database open]) return NO;

    @try {
        // Drop table
        [database closeOpenResultSets];
        [database executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", tableName]];

        deleted = YES;
    }
    @catch (NSException *exception) {
        NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
    }
    @finally {
        [database close];
    }

    return deleted;
}

- (BOOL)doesExistsTableWithTableName:(NSString *)tableName {
    BOOL exists = NO;

    FMDatabase *database = [[GooropSQLiteManager sharedManager] getDatabase];
    if (![database open]) return NO;

    @try {
        FMResultSet *resultSet = [database executeQuery:@"SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
                                                        tableName];
        if ([resultSet next]) {
            exists = YES;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
    }
    @finally {
        [database close];
    }

    return exists;
}

- (BOOL)doesRowExistInTable:(NSString *)tableName withPrimaryKeyName:(NSString *)keyName withPrimaryKey:(id)key {
    BOOL exists = NO;

    if (!key) {
        return NO;
    }

    FMDatabase *database = [[GooropSQLiteManager sharedManager] getDatabase];
    if (![database open]) return NO;

    @try {
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?", keyName, tableName, keyName];
        FMResultSet *resultSet = [database executeQuery:sql withArgumentsInArray:@[key]];
        if ([resultSet next]) {
            exists = YES;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
    }
    @finally {
        [database close];
    }

    return exists;
}


@end
