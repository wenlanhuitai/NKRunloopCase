//
//  NKTaskWorkQueue.h
//  NKRunloopCase
//
//  Created by 谢印超 on 2018/9/11.
//  Copyright © 2018年 360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKTaskWorkParam.h"
#import "NKTaskWork.h"


@interface NKTaskWorkQueue : NSObject
+(instancetype)sharedWorkQueue;
/** 添加任务到子线程runloop，任务
 sender: 任务执行者
 mark: 标记
 taskId: 任务唯一标志
 param: 任务参数
 resultBlock: task执行后回调给业务
 worker: 任务执行的回调
 */
-(void) appendTaskWithExecutor:(id)sender mark:(NSString*)mark taskId:(long) taskid param:(NKTaskWorkParam *)param returnBlock:(taskEventBlock)resultBlock worker:(TaskWorker)worker;
- (void) removeTask:(NSInteger)taskId;
-(void)stop;
@end
