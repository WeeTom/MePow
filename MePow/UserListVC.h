//
//  UserListVC.h
//  MePow
//
//  Created by Wee Tom on 15/5/28.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserListVC;
@protocol UserListVCDelegate <NSObject>
- (void)userListVC:(UserListVC *)viewController didFinishWithResult:(NSArray *)users;
@end

@interface UserListVC : UITableViewController
@property (strong, nonatomic) NSArray *selectedUsers;
@property (weak, nonatomic) id<UserListVCDelegate> delegate;
@end
