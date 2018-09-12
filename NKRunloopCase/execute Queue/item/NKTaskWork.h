//
//  NKTaskWork.h
//  NKRunloopCase
//
//  Created by 谢印超 on 2018/9/11.
//  Copyright © 2018年 360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKTaskWorkParam.h"

typedef void(^taskEventBlock) (NSString *taskMsg);
typedef void(^TaskWorker) (NKTaskWorkParam *param);

typedef enum _SmartPlayerTaskRunState{
    TaskRunState_NotRun,  //没有执行
    TaskRunState_Running, //执行中
    TaskRunState_Runed,   //执行完毕
    TaskRunState_discard  //丢弃
}TaskRunState;



@interface NKTaskWork : NSObject
/** NKTaskWork 为workQueue队列子项，一个TaskWork代表一个任务 */
@property (nonatomic,copy) TaskWorker func;
@property (nonatomic,strong)id executor;
@property (nonatomic,strong) NSString *mark;
@property (nonatomic,assign) TaskRunState runState;
@property (nonatomic,assign) BOOL runResult;
@property (nonatomic,assign) long long startStamp;
@property (nonatomic,assign) long taskId;
@property (nonatomic,copy) taskEventBlock resultBlock;
@property (nonatomic,strong) NKTaskWorkParam *param;

/** 该参数为测试 runloop，随机分配的 每一个任务执行时长的随机时间，用到业务上删除即可 */
@property (nonatomic,assign) NSInteger timeConsuming;

-(void)printTask;
@end
