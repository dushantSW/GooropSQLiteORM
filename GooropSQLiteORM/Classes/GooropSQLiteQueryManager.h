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

#import <Foundation/Foundation.h>

/**
 *  GooropSQLiteColumn is a DTO class which implements all the properties
 *  which are requried for creating SQLite table.
 */
@interface GooropSQLiteColumn : NSObject

/**
 *  Name of the column
 */
@property(nonatomic, strong) NSString *name;

/**
 *  Type of the column
 */
@property(nonatomic, strong) NSString *type;

/**
 *  Should column be indexed?
 */
@property(nonatomic, assign) BOOL indexed;

/**
 *  Is this column primary key in the table?
 */
@property(nonatomic, assign) BOOL primaryKey;

/**
 *  Shall this column be autoincremental
 */
@property(nonatomic, assign) BOOL autoIncrement;

/**
 *  Can this column be null?
 */
@property(nonatomic, assign) BOOL null;

@end

@interface GooropSQLiteQueryManager : NSObject

/**
 *  Returns current valid instance of GooropSQLiteQueryManager
 *
 *  @return Returns GooropSQLiteQueryManager
 */
+ (id)sharedManager;

/**
 *  Checks with the SQLite database if the table with the given table
 *  name exists
 *
 *  @param tableName Name of the table
 *
 *  @return Returns YES if the table exists else NO is returned
 */
- (BOOL)doesExistsTableWithTableName:(NSString *)tableName;

/**
 *  Creates a new table with the given table name. It doesn´t 
 *  checks if the table has been created or not.
 *
 *  @param tableName   Name of the table
 *  @param columns     An array of GooropSQLiteColumn defining all the columns and type
 *  @param foreignKeys An array of foreign keys
 *
 *  @return Returns YES if table is created else NO is returned.
 */
- (BOOL)createTableWithName:(NSString *)tableName ofColumns:(NSArray *)columns withForeignKeys:(NSArray *)foreignKeys;

/**
 *  Removes all the data and schema of the given table
 *
 *  @param tableName Name of the table
 *
 *  @return YES if the table was deleted else NO
 *
 *  @since 1.0
 */
- (BOOL)deleteTableWithName:(NSString *)tableName;

/**
 *  Checks if the row of the given primary key exists in the table.
 *
 *  @param tableName Name of the table
 *  @param keyName   Name of the primary key
 *  @param key       Value of the primary key
 *
 *  @return Returns YES if row exists else NO is returned.
 */
- (BOOL)doesRowExistInTable:(NSString *)tableName withPrimaryKeyName:(NSString *)keyName withPrimaryKey:(id)key;

@end
