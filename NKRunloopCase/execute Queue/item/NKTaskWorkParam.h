//
//  NKTaskWorkParam.h
//  NKRunloopCase
//
//  Created by 谢印超 on 2018/9/11.
//  Copyright © 2018年 360. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 可拓展的任务参数 */
@interface NKTaskWorkParam : NSObject

/** 测试随机时长 */
@property (nonatomic, copy) NSString *paramText;
@property (nonatomic, assign) NSInteger paramDuration;
@end
