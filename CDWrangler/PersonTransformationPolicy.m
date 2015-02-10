//
//  PersonTransformationPolciy.m
//  CDWrangler
//
//  Created by Sean Rada on 2/9/15.
//  Copyright (c) 2015 Rigil. All rights reserved.
//

#import "PersonTransformationPolicy.h"

@implementation PersonTransformationPolicy

- (NSString *)firstNameFromName:(NSString *)name
{
    NSArray *names = [name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSLog(@"PersonTransformationPolicy - first name from name");
    NSLog(@"names:%@",names);
    NSLog(@"return string: %@", [NSString stringWithString:[names firstObject]]);
    return [NSString stringWithString:[names firstObject]];
}

- (NSString *)lastNameFromName:(NSString *)name
{
    NSArray *names = [name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSLog(@"PersonTransformationPolicy - last name from name");
    NSLog(@"names:%@",names);
    NSLog(@"return string: %@", [NSString stringWithString:[names lastObject]]);
    return [NSString stringWithString:[names lastObject]];
}

@end
