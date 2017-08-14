//
//  ConstactModel.h
//  AddressBookTool
//
//  Created by yx on 2017/8/11.
//  Copyright © 2017年 yx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactModel : NSObject
/** num */
@property (nonatomic, copy) NSString *phoneNum;
/** 姓名 */
@property (nonatomic, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name phoneNum:(NSString *)num;

@end
