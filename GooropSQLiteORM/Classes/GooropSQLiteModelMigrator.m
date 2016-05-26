//
//  GooropSQLiteModelMigrator.h
//  goorop-sqlite-orm
//
//  Created by Dushant Singh on 17/08/15.
//  Copyright (c) 2015 Dushant Singh. All rights reserved.
//

// Copyright (c) 2012-2015 Dushant Singh, Goorop AB.
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

#import "GooropSQLiteModelMigrator.h"
#import "GooropSQLiteManager.h"
#import "GooropSQLiteQueryManager.h"


@implementation GooropSQLiteModelMigrator

+ (BOOL)truncate {
    BOOL truncated = NO;
    
    FMDatabase *database = [[GooropSQLiteManager sharedManager] getDatabase];
    if (![database open]) return NO;
    
    @try {
        NSString *query = [NSString stringWithFormat:@"DELETE FROM %@", [[self class] tableName]];
        [database executeUpdate:query];
        [database executeUpdate:@"VACUUM"];
        truncated = YES;
    }
    @catch (NSException *exception) {
        NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
    }
    @finally {
        [database close];
    }
    
    return truncated;
}

+ (NSString *)tableName
{
    return [NSStringFromClass([self class]) lowercaseString];
}

+ (BOOL)createTableSchema {
    unsigned int count = 0;
    NSString *tableName = [self tableName];
    
    // Find the properties
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    if (count <= 0) {
        [NSException raise:@"No properties found" format:@"Could not find any properties in class %@", tableName];
    }
    
    NSArray *indexedColumns;
    if ([[self class] instancesRespondToSelector:@selector(indexed)]) {
        indexedColumns = [[self class] indexed];
    }
    
    NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSArray *protocols = [self propertyProtocols:properties[i]];
        
        if (![protocols containsObject:@"Ignore"]) {
            GooropSQLiteColumn *column = [[GooropSQLiteColumn alloc] init];
            column.name = [NSString stringWithUTF8String:property_getName(properties[i])];
            column.type = [self sqliteTypeForProperty:properties[i]];
            
            if (![column.type isEqualToString:@""]) {
                // Check if it is primary key
                if ([column.name isEqualToString:[[self class] primaryKey]]) {
                    column.primaryKey = YES;
                }
                
                if (indexedColumns && [indexedColumns count] > 0) {
                    column.indexed = [indexedColumns indexOfObject:column.name] != NSNotFound;
                }
                
                if ([protocols containsObject:@"Nullable"]) {
                    column.null = YES;
                }
                
                if ([protocols containsObject:@"AutoIncrement"]) {
                    column.autoIncrement = YES;
                }
                
                [columns addObject:column];
            }
        }
    }
    
    // Get all the foreign keys
    NSArray *foreginKeys = [self foreignKeysFromProperties:properties withPropertiesCount:count];
    free(properties);
    
    return [[GooropSQLiteQueryManager sharedManager] createTableWithName:tableName ofColumns:columns withForeignKeys:foreginKeys];
}

+ (BOOL)recreateTableScehma {
    unsigned int count = 0;
    NSString *tableName = [self tableName];
    
    //Find all the properties
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    if (count <= 0) {
        [NSException raise:@"No properties found" format:@"Could not find any properties in class %@", tableName];
    }
    
    NSMutableSet *newColumnNames = [[NSMutableSet alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSString *columnName = [NSString stringWithUTF8String:property_getName(properties[i])];
        [newColumnNames addObject:columnName];
    }
    
    // Retrieve sqlite column names for table
    NSMutableSet *currentColumnNames = [[NSMutableSet alloc] init];
    FMDatabase *database = [[GooropSQLiteManager sharedManager] getDatabase];
    if (![database open]) return NO;
    
    @try {
        // Get column names
        FMResultSet *resultSet = [database executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName]];
        while ([resultSet next]) {
            [currentColumnNames addObject:[resultSet stringForColumn:@"name"]];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
    }
    @finally {
        [database close];
    }
    
    if (currentColumnNames.count <= 0) {
        [NSException raise:@"Table not found" format:@"Could not find the table (%@) in SQLite", tableName];
    }
    
    // Compare two arrays
    if ([newColumnNames isEqualToSet:currentColumnNames]) {
        return NO;
    }
    
    // Drop table
    [[GooropSQLiteQueryManager sharedManager] deleteTableWithName:tableName];
    
    // Create table
    [self createTableSchema];
    return YES;
}

+ (BOOL)updateTableSchemaForVersion:(NSInteger)buildNummer {
    return YES;
}

+ (BOOL)doesModelExistsInDatabase {
    return [[GooropSQLiteQueryManager sharedManager] doesExistsTableWithTableName:[[self class] tableName]];
}

#pragma mark 
#pragma mark - Private methods
+ (NSArray *) propertyProtocols:(objc_property_t) property
{
    NSMutableArray *protocols = [[NSMutableArray alloc] init];
    
    const char *attr = property_getAttributes(property);
    NSString *propertyAttributes = @(attr);
    
    NSScanner *scanner = [NSScanner scannerWithString:propertyAttributes];
    [scanner scanUpToString:@"<" intoString:NULL];
    
    while ([scanner scanString:@"<" intoString:NULL]) {
        NSString *protocolName = nil;
        
        [scanner scanUpToString:@">" intoString:&protocolName];
        [protocols addObject:protocolName];
        
        [scanner scanString:@">" intoString:NULL];
    }
    
    return protocols;
}

+ (NSArray *) getColumnsAndType
{
    NSMutableArray *columns = [[NSMutableArray alloc] init];
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    if (count > 0)
    {
        for (int i = 0; i < count; i++)
        {
            BOOL isForeignKey = NO;
            NSString *columnName = [NSString stringWithUTF8String:property_getName(properties[i])];
            NSString *sqliteType = [self sqliteTypeForProperty:properties[i]];
            
            NSArray *splitedPropertyAttributes = [[NSString stringWithUTF8String:property_getAttributes(properties[i])] componentsSeparatedByString:@"\""];
            if ([splitedPropertyAttributes count] >= 2)
            {
                Class class = NSClassFromString([[[splitedPropertyAttributes objectAtIndex:1] componentsSeparatedByString:@"<"] objectAtIndex:0]);
                if ([class isSubclassOfClass:[GooropSQLiteModel class]]) {
                    isForeignKey = YES;
                }
            }
            
            [columns addObject:@{@"columnName": columnName, @"sqlite_type": sqliteType, @"isForeign": [NSNumber numberWithBool:isForeignKey]}];
        }
    }
    
    free(properties);
    return columns;
}

+ (NSString *) sqliteTypeForProperty: (objc_property_t) property
{
    NSString *typeName = nil;
    
    // Search for primitive values first
    const char *property_type = property_getAttributes(property);
    switch (property_type[1]) {
        case 's':
        case 'i':
        case 'l':
        case 'q':
        case 'I':
        case 'S':
        case 'L':
        case 'N':
        case 'Q':
        case 'B':
            typeName = @"NUMERIC";
            break;
        case 'd':
        case 'f':
            typeName = @"REAL";
            break;
        case 'c':
            typeName = @"NUMERIC";
            break;
        case 'C':
        case '*':
            typeName = @"TEXT";
            break;
        default:
            typeName = @"";
    }
    
    if ([typeName isEqualToString:@""])
    {
        NSArray *splitedPropertyAttributes = [[NSString stringWithUTF8String:property_type] componentsSeparatedByString:@"\""];
        if ([splitedPropertyAttributes count] >= 2)
        {
            NSArray *attributes = [[splitedPropertyAttributes objectAtIndex:1] componentsSeparatedByString:@"<"];
            BOOL hasProtocols = attributes.count > 1;
            
            Class class = NSClassFromString([attributes objectAtIndex:0]);
            if ([class isSubclassOfClass:[NSString class]]) {
                typeName = @"TEXT";
            } else if ([class isSubclassOfClass:[NSNumber class]]) {
                typeName = @"NUMERIC";
            } else if ([class isSubclassOfClass:[NSDate class]]) {
                typeName = @"DATETIME";
            } else if ([class isSubclassOfClass:[GooropSQLiteModel class]]) {
                typeName = [self findPrimaryKeyForModelClass:class forProperty:property];
            } else if ([class isSubclassOfClass:[NSArray class]]) {
                if (!hasProtocols) {
                    typeName = @"TEXT";
                }
                else {
                    typeName = @"";
                }
            } else if ([class isSubclassOfClass:[NSDictionary class]]) {
                typeName = @"BLOB";
            } else {
                [NSException raise:@"Unknow type" format:@"Property %s does not contain a valid type", property_getName(property)];
            }
        }
        else
        {
            [NSException raise:@"Unknow type" format:@"Property %s does not contain a valid type", property_getName(property)];
        }
    }
    
    return typeName;
}

+ (NSArray *) foreignKeysFromProperties: (objc_property_t *) properties withPropertiesCount: (int) count
{
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < count; i++)
    {
        NSString *columnName = [NSString stringWithUTF8String:property_getName(properties[i])];
        
        const char *property_type = property_getAttributes(properties[i]);
        NSArray *splitedPropertyAttributes = [[NSString stringWithUTF8String:property_type] componentsSeparatedByString:@"\""];
        if ([splitedPropertyAttributes count] >= 2)
        {
            Class class = NSClassFromString([[[splitedPropertyAttributes objectAtIndex:1] componentsSeparatedByString:@"<"] objectAtIndex:0]);
            if ([class isSubclassOfClass:[GooropSQLiteModel class]])
            {
                [keys addObject:@{@"column_name": columnName,
                                  @"reference_table_name": [class tableName],
                                  @"reference_table_primary_key": [class primaryKey]}];
            }
        }
    }
    
    return keys;
}

+ (NSString *) findPrimaryKeyForModelClass: (Class) class forProperty: (objc_property_t) property
{
    NSString *primaryKey = [class primaryKey];
    if (primaryKey == nil || [primaryKey length] == 0) {
        [NSException raise:@"No primary key found"
                    format:@"Primary key for property %s was not found! You need to override +(void)primaryKey", property_getName(property)];
    }
    
    unsigned int count = 0;
    int index = -1;
    
    objc_property_t *properties = class_copyPropertyList(class, &count);
    for (int i = 0; i < count; i++) {
        NSString *columname = [NSString stringWithUTF8String:property_getName(properties[i])];
        if ([columname isEqualToString:primaryKey]) {
            index = i;
            break;
        }
    }
    
    if (index == -1) {
        [NSException raise:@"No primary key found"
                    format:@"Primary key for property %s was not found! You need to override +(void)primaryKey", property_getName(property)];
    }
    
    NSString *typeName = [class sqliteTypeForProperty:properties[index]];
    free(properties);
    
    return typeName;
}

@end
