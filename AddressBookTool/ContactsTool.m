//
//  ContactsHelp.m
//  AddressBookTool
//
//  Created by yx on 2017/8/11.
//  Copyright © 2017年 yx. All rights reserved.
//

#import "ContactsTool.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f)


@interface ContactsTool ()<CNContactPickerDelegate, ABPeoplePickerNavigationControllerDelegate>
@property(nonatomic, strong) ContactModel *contactModel;
@property(nonatomic, copy) ContactBlock myBlock;
@end

@implementation ContactsTool
+ (NSMutableArray *)getAllPhoneInfo {
    return iOS9Later ? [self getContactsFromContactsAll] : [self getContactsFromAddressBookAll];
}

- (void)getOnePhoneInfoWithUI:(UIViewController *)target callBack:(ContactBlock)block
{
    if (iOS9Later) {
        [self getContactsFromContactUI:target];
    } else {
        [self getContactsFromAddressBookUI:target];
    }
    self.myBlock = block;
}

#pragma mark - AddressBookUI
- (void)getContactsFromAddressBookUI:(UIViewController *)target {
    ABPeoplePickerNavigationController *pickerVC = [[ABPeoplePickerNavigationController alloc] init];
    pickerVC.peoplePickerDelegate = self;
    [target presentViewController:pickerVC animated:YES completion:nil];
}

/**
 *  当用户选择某一个联系人的某一个属性的时候会执行该方法
 *
 *  @param person       选中的联系人
 *  @param property     选中的联系人的属性
 *  @param identifier   每一个属性都有一个对应的表示
 */

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person {
    
    
    // 将CoreFoundation框架的对象转成Foundation框架对象,那么可以通过桥接的方式
    // 如果是CoreFoundation框架中的对象,如果是通过copy或者create或者retain,必须对应有一个release
    /*
     __bridge type: 通过该桥接方式,那么CoreFoundation对应的对象需要手动来释放,Foundation框架的对象如果是在ARC环境下面,则不需手动释放
     __bridge_transfer type: 通过该桥接方式,那么CoreFoundation对应的对象表示已经交给Foundation对象进行管理,如果是在ARC环境下面,不需要释放任何一个对象
     */
    
    ABMultiValueRef phonesRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
    if (!phonesRef) { return; }
    NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phonesRef, 0);
    
    CFStringRef lastNameRef = ABRecordCopyValue(person, kABPersonLastNameProperty);
    CFStringRef firstNameRef = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastname = (__bridge_transfer NSString *)(lastNameRef);
    NSString *firstname = (__bridge_transfer NSString *)(firstNameRef);
    NSString *name = [NSString stringWithFormat:@"%@%@", lastname == NULL ? @"" : lastname, firstname == NULL ? @"" : firstname];
    NSLog(@"姓名: %@", name);
    
    ContactModel *model = [[ContactModel alloc] initWithName:name phoneNum:phoneValue];
    NSLog(@"电话号码: %@", phoneValue);
    
    CFRelease(phonesRef);
    if (self.myBlock) self.myBlock(model);
}

#pragma mark - ContactsUI
- (void)getContactsFromContactUI:(UIViewController *)target {
    CNContactPickerViewController *pickerVC = [[CNContactPickerViewController alloc] init];
    pickerVC.delegate = self;
    [target presentViewController:pickerVC animated:YES completion:nil];
}

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact {
    NSString *name = [NSString stringWithFormat:@"%@%@", contact.familyName == NULL ? @"" : contact.familyName, contact.givenName == NULL ? @"" : contact.givenName];
    NSLog(@"姓名: %@", name);
    
    CNPhoneNumber *phoneNumber = [contact.phoneNumbers[0] value];
    ContactModel *model = [[ContactModel alloc] initWithName:name phoneNum:[NSString stringWithFormat:@"%@", phoneNumber.stringValue]];
    NSLog(@"电话号码: %@", phoneNumber.stringValue);
    
    if (self.myBlock) self.myBlock(model);
}

#pragma mark - AddressBook
+ (NSMutableArray *)getContactsFromAddressBookAll {
    //取得通讯录访问授权状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    CFErrorRef myError = NULL;
    // ABAddressBookRef 代表通讯对象
    //调用ABAddressBookCreateWithOptions()方法创建通讯录对象ABAddressBookRef
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &myError);
    if (myError) {
        [self showErrorAlert];
        if (addressBook) CFRelease(addressBook);
        return nil;
    }
    
    /*
     
     kABAuthorizationStatusNotDetermined = 0, 没有决定是否授权
     
     kABAuthorizationStatusRestricted,  受限制
     
     kABAuthorizationStatusDenied,  拒绝
     
     kABAuthorizationStatusAuthorized  授权
     
     */
    
    __block NSMutableArray *contactModels = [NSMutableArray array];
    if (status == kABAuthorizationStatusNotDetermined) {  // 用户还没有决定是否授权你的程序进行访问
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) { //授权成功
                contactModels = [self getAddressBookInfo:addressBook];
            } else {
                [self showErrorAlert];
                if (addressBook) CFRelease(addressBook);
            }
        });
        // 用户已拒绝 或 iOS设备上的家长控制或其它一些许可配置阻止程序与通讯录数据库进行交互
    } else if (status == kABAuthorizationStatusDenied || status == kABAuthorizationStatusRestricted) {
        [self showErrorAlert];
        if (addressBook) CFRelease(addressBook);
    } else if (status == kABAuthorizationStatusAuthorized) {  // 用户已授权
        contactModels = [self getAddressBookInfo:addressBook];
    }
    return contactModels;
}

/*
 
 桥接有三种方式：
 
 (__bridge type)（expression) : 只是让NSFoundation框架暂时使用CF框架对象，注意需要手动释放 Core Foundation 对象，用CFRelease( )函数。
 (__bridge_transfer type)（expression) / CFBridgingRelease（expression) : CF框架移交对象的管理权给NSFoundation框架，不需要手动释放对象
 前两种是将CF对象转NSFoundation，最后一个是NSFoundation转 CF对象，不常用
 (__bridge_retained )()
  
 */

+ (NSMutableArray *)getAddressBookInfo:(ABAddressBookRef)addressBook {
    CFArrayRef peopleArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSInteger peopleCount = CFArrayGetCount(peopleArray);
    NSMutableArray *contactModels = [NSMutableArray array];
    
    for (int i = 0; i < peopleCount; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(peopleArray, i);
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        if (phones) {
            NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
            NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
            NSString *name = [NSString stringWithFormat:@"%@%@", lastName == NULL ? @"" : lastName, firstName == NULL ? @"" : firstName];
            NSLog(@"姓名: %@", name);
            
            CFIndex phoneCount = ABMultiValueGetCount(phones);
            for (int j = 0; j < phoneCount; j++) {
                NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, j);
                NSLog(@"电话号码: %@", phoneValue);
                ContactModel *model = [[ContactModel alloc] initWithName:name phoneNum:phoneValue];
                [contactModels addObject:model];
            }
        }
        CFRelease(phones);
    }
    
    if (addressBook) CFRelease(addressBook);
    if (peopleArray) CFRelease(peopleArray);
    
    return contactModels;
}


#pragma mark - Contacts
+ (NSMutableArray *)getContactsFromContactsAll {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    CNContactStore *store = [[CNContactStore alloc] init];
    __block NSMutableArray *contactModels = [NSMutableArray array];
    
    if (status == CNAuthorizationStatusNotDetermined) { // 用户还没有决定是否授权你的程序进行访问
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                contactModels = [self getContactsInfo:store];
            } else {
                [self showErrorAlert];
            }
        }];
        // 用户已拒绝 或 iOS设备上的家长控制或其它一些许可配置阻止程序与通讯录数据库进行交互
    } else if (status == CNAuthorizationStatusDenied || status == CNAuthorizationStatusRestricted) {
        [self showErrorAlert];
    } else if (status == CNAuthorizationStatusAuthorized) { // 用户已授权
        contactModels = [self getContactsInfo:store];
    }
    
    return contactModels;
}

+ (NSMutableArray *)getContactsInfo:(CNContactStore *)store {
    NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    NSMutableArray *contactModels = [NSMutableArray array];
    
    [store enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        NSString *name = [NSString stringWithFormat:@"%@%@", contact.familyName == NULL ? @"" : contact.familyName, contact.givenName == NULL ? @"" : contact.givenName];
        NSLog(@"姓名: %@", name);
        
        for (CNLabeledValue *labeledValue in contact.phoneNumbers) {
            CNPhoneNumber *phoneNumber = labeledValue.value;
            NSLog(@"电话号码: %@", phoneNumber.stringValue);
            ContactModel *model = [[ContactModel alloc] initWithName:name phoneNum:phoneNumber.stringValue];
            [contactModels addObject:model];
        }
    }];
    
    return contactModels;
}

#pragma mark - Error
+ (void)showErrorAlert {
    NSLog(@"授权失败, 请允许app访问您的通讯录, 在手机的”设置-隐私-通讯录“选项中设置允许");
}

@end

