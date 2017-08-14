//
//  ConstactModel.m
//  AddressBookTool
//
//  Created by yx on 2017/8/11.
//  Copyright © 2017年 yx. All rights reserved.
//

#import "ContactModel.h"

@implementation ContactModel

- (instancetype)initWithName:(NSString *)name phoneNum:(NSString *)num
{
    if (self = [super init]) {
        self.name = name;
        self.phoneNum = num;
    }
    
    return self;
}


@end
