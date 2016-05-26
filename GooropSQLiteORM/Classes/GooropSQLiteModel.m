//
//  GooropSQLiteModel.h
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

#import "GooropSQLiteManager.h"
#import "GooropSQLiteQueryManager.h"
#import "GooropSQLiteQueryBuilder.h"
#import "GooropSQLiteChildren.h"
#import "GooropSQLiteQuery.h"
#import <objc/runtime.h>

#define EXCEPTION_NO_PROPERTIES [NSException raise:@"No properties found" \
format:@"Could not find any properties in class %@", [[self class] tableName]];

@implementation GooropSQLiteModel {
    GooropSQLiteQueryBuilder *queryBuilder;
}

- (instancetype)init {
    if (self = [super init]) {
        queryBuilder = [[GooropSQLiteQueryBuilder alloc] init];
    }

    return self;
}

#pragma mark - 
#pragma mark - Instances methods

- (void)save {
    [self createOrUpdate:self excludeParentModel:nil];
}

- (void)update {
    [self createOrUpdate:self excludeParentModel:nil];
}

- (void)remove {
    if ([self exits]) {
        __weak typeof(self) weakSelf = self;
        FMDatabaseQueue *queue = [[GooropSQLiteManager sharedManager] getDatabaseQueue];
        [queue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"PRAGMA foreign_keys = ON"];
            id primaryKey = [weakSelf valueForKey:[[weakSelf class] primaryKey]];
            NSString *deletingQuery = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                                                                 [[weakSelf class] tableName], [[weakSelf class] primaryKey]];
            [db executeUpdate:deletingQuery withArgumentsInArray:@[primaryKey]];
        }];
    }
}

- (BOOL)exits {
    return [[GooropSQLiteQueryManager sharedManager] doesRowExistInTable:[[self class] tableName]
                                                      withPrimaryKeyName:[[self class] primaryKey]
                                                          withPrimaryKey:[self valueForKey:[[self class] primaryKey]]];
}

- (BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }

    if (![object isMemberOfClass:[self class]]) {
        return NO;
    }

    id objc_primaryValue = [object valueForKey:[[object class] primaryKey]];
    return [[self valueForKey:[[self class] primaryKey]] isEqual:objc_primaryValue];
}

#pragma mark - 
#pragma mark - Static methods

+ (NSString *)primaryKey {
    return @"id";
}

+ (NSMutableArray *)indexed {
    return nil;
}

+ (id)find:(NSString *)primaryKey {
    NSDictionary *result = nil;
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", [self tableName], [self primaryKey]];
    FMDatabase *database = [[GooropSQLiteManager sharedManager] getDatabase];
    if (![database open]) return nil;

    @try {

        FMResultSet *resultSet = [database executeQuery:query withArgumentsInArray:@[primaryKey]];
        if ([resultSet next]) {
            result = [resultSet resultDictionary];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
    }
    @finally {
        [database close];
    }

    if (result) {
        return [self makeModelFromResultSet:result];
    }

    return nil;
}

+ (NSArray *)allObjects {
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@", [self tableName]];
    return [self query:query withArgumentsArray:nil];
}

+ (NSArray *)where:(NSString *)columnName value:(id)value {
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?",
                                                 [self tableName], columnName];
    return [self query:query withArgumentsArray:@[value]];
}

+ (NSArray *)where:(NSArray *)columnNames values:(NSArray *)values {
    NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT * FROM %@ WHERE", [self tableName]];
    for (NSString *columnName in columnNames) {
        [query appendString:[NSString stringWithFormat:@"%@ = ? AND", columnName]];
    }

    return [self query:[query substringToIndex:[query length] - 3] withArgumentsArray:values];
}

+ (NSArray *)query:(NSString *)query withArgumentsArray:(NSArray *)arguments {
    NSMutableArray *resultsArray = [[NSMutableArray alloc] init];
    NSMutableArray *objects = [[NSMutableArray alloc] init];

    FMDatabase *database = [[GooropSQLiteManager sharedManager] getDatabase];
    if (![database open]) return nil;

    @try {

        FMResultSet *resultSet = [database executeQuery:query withArgumentsInArray:arguments];
        while ([resultSet next]) {
            [resultsArray addObject:[resultSet resultDictionary]];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
    }
    @finally {
        [database close];
    }

    for (NSDictionary *result in resultsArray) {
        [objects addObject:[self makeModelFromResultSet:result]];
    }

    return objects;
}

+ (id)makeModelFromResultSet:(NSDictionary *)result {
    id model = [[[self class] alloc] init];

    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);

    if (count <= 0) {
        EXCEPTION_NO_PROPERTIES;
    }

    for (int i = 0; i < count; i++) {
        NSString *columnName = [NSString stringWithUTF8String:property_getName(properties[i])];
        id value = result[columnName];

        if ([value isKindOfClass:[NSNull class]]) {
            value = nil;
        }

        const char *property_type = property_getAttributes(properties[i]);
        NSArray *splittedPropertyAttributes = [[NSString stringWithUTF8String:property_type] componentsSeparatedByString:@"\""];
        if ([splittedPropertyAttributes count] >= 2) {
            NSString *className = [splittedPropertyAttributes[1] componentsSeparatedByString:@"<"][0];
            Class class = NSClassFromString(className);
            if ([class isSubclassOfClass:[GooropSQLiteModel class]]) {
                id primaryKey = result[columnName];
                value = [class find:primaryKey];
            }
            else if ([class isSubclassOfClass:[NSDate class]]) {
                if (value) {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[result[columnName] doubleValue]];
                    value = date;
                }
            }
            else if ([class isSubclassOfClass:[NSArray class]]) {
                id key = [model valueForKey:[[self class] primaryKey]];

                if (value == nil) {
                    value = [self valueOfArrayForColumnName:columnName forKey:key];
                }
                else {
                    value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
                }
            }
            else if ([class isSubclassOfClass:[NSDictionary class]]) {
                value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
            }
        }

        [model setValue:value forKey:columnName];
    }

    free(properties);
    return model;
}

+ (id)valueOfArrayForColumnName:(NSString *)columnName forKey:(id)key {
    id value = nil;
    GooropSQLiteChildren *child = [GooropSQLiteChildren find:[NSString stringWithFormat:@"%@.%@",
                                                                                        NSStringFromClass([self class]), columnName]];
    if (child) {
        __block NSMutableArray *results = [[NSMutableArray alloc] init];
        __weak typeof(results) weakResults = results;

        NSString *currentClassPrimaryKey = [[self class] primaryKey];
        NSString *primaryKeyName = [[NSString stringWithFormat:@"%@_%@_id", child.parentClassName, child.childClassName] lowercaseString];

        [[[GooropSQLiteManager sharedManager] getDatabaseQueue] inDatabase:^(FMDatabase *db) {
            NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?",
                                                         child.inBetweenTableName, currentClassPrimaryKey];
            FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[key]];
            while ([resultSet next]) {
                [weakResults addObject:[resultSet resultDictionary]];
            }
        }];

        if ([results count] > 0) {
            value = [[NSMutableArray alloc] init];

            for (NSDictionary *result in results) {
                NSArray *keys = [result allKeys];

                id keyValue = nil;
                for (id inKey in keys) {
                    if (![inKey isEqualToString:currentClassPrimaryKey] && ![inKey isEqualToString:primaryKeyName]) {
                        keyValue = result[inKey];
                        break;
                    }
                }

                if (keyValue) {
                    Class childClass = NSClassFromString(child.childClassName);
                    [value addObject:[[childClass class] find:keyValue]];
                }
            }
        }
    }

    return value;
}

#pragma mark -
#pragma mark - Private methods

- (void)createOrUpdate:(GooropSQLiteModel *)model excludeParentModel:(id)parentModel {
    GooropSQLiteQuery *query = [queryBuilder buildQueryForModel:self];

    // Save parent queries
    for (id pModel in query.parentQueries) {
        if (parentModel) {
            if (![pModel isEqual:parentModel]) {
                [pModel createOrUpdate:pModel excludeParentModel:nil];
            }
        }
        else {
            [pModel createOrUpdate:pModel excludeParentModel:nil];
        }
    }

    // Insert main part
    [self insertOrUpdate:query
       forPrimaryKeyName:[[self class] primaryKey]
          withPrimaryKey:[self valueForKey:[[self class] primaryKey]]];

    // Save children
    for (NSDictionary *childrenQuery in query.childrenQueries) {
        NSString *className = childrenQuery[@"class_name"];
        NSArray *models = childrenQuery[@"array"];

        // Create in-between table if not exists
        Class childClass = NSClassFromString(className);
        NSString *tableName = [NSString stringWithFormat:@"%@_%@", [[self class] tableName], [childClass tableName]];

        BOOL tableExists = [[GooropSQLiteQueryManager sharedManager] doesExistsTableWithTableName:tableName];
        if (!tableExists) {
            [self createInBetweenTableWithTableName:tableName forChildClass:childClass];
        }

        for (id childModel in models) {
            [childModel createOrUpdate:childModel excludeParentModel:self];

            GooropSQLiteQuery *mQuery = [[GooropSQLiteQuery alloc] init];
            mQuery.tableName = tableName;
            [mQuery.columns addObjectsFromArray:@[[[self class] primaryKey], [childClass primaryKey]]];
            [mQuery.values addObjectsFromArray:@[[self valueForKey:mQuery.columns[0]], [childModel valueForKey:mQuery.columns[1]]]];
            mQuery.primaryKey = [NSString stringWithFormat:@"%@.%@", mQuery.values[0], mQuery.values[1]];

            // Add primary key into columns and values
            [mQuery.columns insertObject:[NSString stringWithFormat:@"%@_id", tableName] atIndex:0];
            [mQuery.values insertObject:mQuery.primaryKey atIndex:0];

            // Insert a row in in-between table
            NSString *primaryKeyName = [NSString stringWithFormat:@"%@_id", tableName];
            [self insertOrUpdate:mQuery forPrimaryKeyName:primaryKeyName withPrimaryKey:mQuery.primaryKey];
        }

        GooropSQLiteChildren *child = [[GooropSQLiteChildren alloc] init];
        child.parentClassName = NSStringFromClass([self class]);
        child.parentColumnName = childrenQuery[@"column_name"];
        child.inBetweenTableName = tableName;
        child.childClassName = className;
        [child save];
    }
}

- (void)insertOrUpdate:(GooropSQLiteQuery *)query forPrimaryKeyName:(NSString *)primaryKeyName withPrimaryKey:(id)primaryKey {
    FMDatabaseQueue *queue = [[GooropSQLiteManager sharedManager] getDatabaseQueue];
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"PRAGMA foreign_keys = ON"];
        BOOL rowExists = [[GooropSQLiteQueryManager sharedManager] doesRowExistInTable:query.tableName
                                                                    withPrimaryKeyName:primaryKeyName
                                                                        withPrimaryKey:primaryKey];
        if (rowExists) {
            // Remove primary key
            [query removePrimaryKey];

            // Update this model object
            NSString *updatingQuery = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?",
                                                                 query.tableName, [query.updatingPlaceHolders componentsJoinedByString:@", "],
                                                                 primaryKeyName];
            [query.values addObject:primaryKey];
            [db executeUpdate:updatingQuery withArgumentsInArray:query.values];
        } else {
            // Save this model object
            NSString *insertionQuery = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
                                                                  query.tableName, [query.columns componentsJoinedByString:@", "],
                                                                  [query.placeHolders componentsJoinedByString:@", "]];
            [db executeUpdate:insertionQuery withArgumentsInArray:query.values];
        }
    }];
}

- (void)createInBetweenTableWithTableName:(NSString *)tableName forChildClass:(Class)childClass {
    GooropSQLiteColumn *parentColumn = [[GooropSQLiteColumn alloc] init];
    parentColumn.name = [[self class] primaryKey];
    parentColumn.type = [[self class] sqliteTypeForProperty:class_getProperty([self class], [parentColumn.name UTF8String])];
    parentColumn.indexed = YES;

    GooropSQLiteColumn *childColumn = [[GooropSQLiteColumn alloc] init];
    childColumn.name = [childClass primaryKey];
    childColumn.type = [childClass sqliteTypeForProperty:class_getProperty(childClass, [childColumn.name UTF8String])];
    childColumn.indexed = YES;

    GooropSQLiteColumn *key = [[GooropSQLiteColumn alloc] init];
    key.name = [NSString stringWithFormat:@"%@_id", tableName];
    key.type = @"TEXT";
    key.primaryKey = YES;

    NSDictionary *parentForeignKey = @{@"column_name" : parentColumn.name,
            @"reference_table_name" : [[self class] tableName],
            @"reference_table_primary_key" : [[self class] primaryKey]};

    NSDictionary *childForeignKey = @{@"column_name" : childColumn.name,
            @"reference_table_name" : [childClass tableName],
            @"reference_table_primary_key" : [childClass primaryKey]};
    // Create in-between table
    [[GooropSQLiteQueryManager sharedManager] createTableWithName:tableName
                                                        ofColumns:@[key, parentColumn, childColumn]
                                                  withForeignKeys:@[parentForeignKey, childForeignKey]];
}

- (void)dealloc {
    queryBuilder = nil;
}

@end
