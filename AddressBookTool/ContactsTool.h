//
//  ContactsHelp.h
//  AddressBookTool
//
//  Created by yx on 2017/8/11.
//  Copyright © 2017年 yx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ContactModel.h"
typedef void(^ContactBlock)(ContactModel *contactsModel);

@interface ContactsTool : NSObject
+ (NSMutableArray *)getAllPhoneInfo;

- (void)getOnePhoneInfoWithUI:(UIViewController *)target callBack:(ContactBlock)block;

@end
