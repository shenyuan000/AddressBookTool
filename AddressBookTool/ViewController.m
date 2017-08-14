//
//  ViewController.m
//  AddressBookTool
//
//  Created by yx on 2017/8/11.
//  Copyright © 2017年 yx. All rights reserved.
//

#import "ViewController.h"
#import "ContactsTool.h"
#import "ContactModel.h"

@interface ViewController ()
@property(nonatomic, strong) ContactsTool *contactsTool;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 弹出页面选择条联系人信息
    self.contactsTool = [[ContactsTool alloc] init];
}
- (IBAction)UIEventClick:(id)sender {
    
    [self.contactsTool getOnePhoneInfoWithUI:self callBack:^(ContactModel *contactModel) {
        NSLog(@"-----------");
        NSLog(@"%@", contactModel.name);
        NSLog(@"%@", contactModel.phoneNum);
    }];
}
- (IBAction)ConentEvent:(id)sender {
    
    // 获取手机全部联系人信息
    NSMutableArray *contactModels = [ContactsTool getAllPhoneInfo];
    [contactModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ContactModel *model = obj;
        NSLog(@"-----------");
        NSLog(@"%@", model.name);
        NSLog(@"%@", model.phoneNum);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
