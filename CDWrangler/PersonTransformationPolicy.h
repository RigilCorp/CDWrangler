//
//  PersonTransformationPolciy.h
//  CDWrangler
//
//  Created by Sean Rada on 2/9/15.
//  Copyright (c) 2015 Rigil. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface PersonTransformationPolicy : NSEntityMigrationPolicy

- (NSString *)firstNameFromName:(NSString *)name;
- (NSString *)lastNameFromName:(NSString *)name;

@end
