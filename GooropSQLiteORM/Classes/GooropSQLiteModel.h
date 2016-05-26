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

#import <Foundation/Foundation.h>
#import "GooropSQLiteModelMigrator.h"

/**
 * Protocol for defining nullable properties for GooropSQLiteModel.
 */
@protocol Nullable
@end

/**
 *  Protocol for defining auto-incremental properties for GooropSQLiteModel.
 */
@protocol AutoIncrement
@end

/**
 * Make all objects Optional compatible to avoid compiler warnings
 *
 * Thank you JSONModel for inspiration.
 */
@interface NSObject (GooropSQLiteModelPropertyCompatibility) <Nullable, AutoIncrement>
@end

@interface GooropSQLiteModel : GooropSQLiteModelMigrator

#pragma mark - CRUD Operations

/**
 *  Saves the current instance of the model into SQLite.
 */
- (void)save;

/**
 *  Updates the current instance of the model with the SQLite version if it exists.
 */
- (void)update;

/**
 *  Deletes the current instance of the model from the SQLite version. It uses
 *  primary key for deleting the instance.
 */
- (void)remove;

/**
 *  Checks if the current instance of the current primary key
 *  exists in database.
 *
 *  @return Returns true if exists else false is returned.
 */
- (BOOL)exits;

#pragma mark - Static methods

/**
 *  Returns the primary key name of the key. This method MUST be overridden
 *  in your class else NSException will be thrown in most of the CRUD
 *  operations
 *
 *  @return Returns primary key name.
 */
+ (NSString *)primaryKey;

/**
 *  Get a list of column names which should be indexed into SQLite.
 *
 *  @return Returns a list of column names
 */
+ (NSArray *)indexed;

/**
 *  Finds the model by the given primary key.
 *
 *  @param primaryKey The primary key of the row.
 *
 *  @return Returns the GooropSQLiteModel
 */
+ (id)find:(id)primaryKey;

/**
 *  Finds all the models where the columns are equal to the values
 *
 *  @param columnNames Name of the columns
 *  @param values      Name of the values
 *
 *  @return Returns an array of models
 */
+ (NSArray *)where:(NSArray *)columnNames values:(NSArray *)values;

/**
 *  Finds all the models where the column is equal to the given value
 *
 *  @param columnName Name of the column
 *  @param value      Value of the column
 *
 *  @return Returns an array of models.
 */
+ (NSArray *)where:(NSString *)columnName value:(id)value;

/**
 *  Finds all the objects that are available in SQLite
 *
 *  @return Returns an array of GooropSQLiteModel.
 */
+ (NSArray *)allObjects;

/**
 *  Finds all the models by the given query.
 *
 *  @param query Defining the search query
 *  @param arguments Arguments which will replace placeholders.
 *
 *  @return Returns an array of GooropSQLiteModel.
 */
+ (NSArray *)query:(NSString *)query withArgumentsArray:(NSArray *)arguments;

@end
