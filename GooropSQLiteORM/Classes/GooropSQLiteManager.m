//
//  GooropSQLiteManager.h
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
#import "GooropSQLiteChildern.h"

@implementation GooropSQLiteManager

+ (id)sharedManager
{
    static GooropSQLiteManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    
    return sharedMyManager;
}

#pragma mark - Public methods
- (void)setDatabaseName:(NSString *)databaseName
{
    self->_databaseName = databaseName;
    [self registerClass:[GooropSQLiteChildern class]];
}

- (FMDatabaseQueue *) getDatabaseQueue
{
    if (self.databaseName == nil) {
        [NSException raise:@"No databasename given" format:@"Have you forgot to give database name?"];
    }
    
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [docPaths objectAtIndex:0];
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:self.databaseName];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    return queue;
}

- (FMDatabase *)getDatabase
{
    if (self.databaseName == nil) {
        [NSException raise:@"No databasename given" format:@"Have you forgot to give database name?"];
    }
    
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [docPaths objectAtIndex:0];
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:self.databaseName];
    
    FMDatabase *database = [FMDatabase databaseWithPath:dbPath];
    return database;
}

- (void)registerClass:(Class)model {
    if (self.databaseName == nil) {
        [NSException raise:@"No databasename given" format:@"Have you forgot to give database name?"];
    }
    
    // Throw invalid class
    if (![model isSubclassOfClass:[GooropSQLiteModel class]])
    {
        [NSException raise:@"Invalid class" format:@"Class is required to extend GooropSQLiteModel"];
    }
    
    if (![model doesModelExistsInDatabase]) {
        [model createTableSchema];
    }
    else {
        NSNumber *buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        if ([model instancesRespondToSelector:@selector(updateTableSchemaForVersion:)]) {
            [model updateTableSchemaForVersion:[buildNumber integerValue]];
        }
    }
}

#pragma mark - Private methods
- (void) createDatabase
{
    __weak typeof(self) weakSelf = self;
    [[self getDatabaseQueue] inDatabase:^(FMDatabase *db) {
        @try {
            [db executeUpdate:@"CREATE DATABASE IF NOT EXISTS ?", weakSelf.databaseName];
        }
        @catch (NSException *exception) {
            NSLog(@"GooropSQLiteException: %@ %@", exception.name, exception.reason);
        }
    }];
}


@end
