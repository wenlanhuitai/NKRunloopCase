//
//  NKTaskWorkQueue.m
//  NKRunloopCase
//
//  Created by 谢印超 on 2018/9/11.
//  Copyright © 2018年 360. All rights reserved.
//

#import "NKTaskWorkQueue.h"

@interface NKTaskWorkQueue()
{
    CFRunLoopRef _runLoopRef;
    CFRunLoopSourceContext _source_context;
    CFRunLoopSourceRef _source;
    bool _shouldStop;
}

@property (atomic,strong) NSMutableArray *taskQueue;
@property (nonatomic,strong) id executor;  //任务执行者
@property (nonatomic,assign) TaskRunState runState;  //任务状态
@property (nonatomic,assign)long taskId;
@property (atomic,strong) NSLock *lockQueue;
@end

@implementation NKTaskWorkQueue

static NKTaskWorkQueue *sNKTaskWorkQueue = nil;
/** 外部接口: 添加任务到 taskQueue 队列中，并唤醒runloop执行
 
 
 */
-(void)appendTaskWithExecutor:(id)sender mark:(NSString*)mark taskId:(long)taskid param:(NKTaskWorkParam *)param returnBlock:(taskEventBlock)resultBlock worker:(TaskWorker)worker {
    NKTaskWork *task = [NKTaskWork new];
    task.executor = sender;
    task.func = worker;
    task.mark = mark;
    task.runState = TaskRunState_NotRun;
    task.resultBlock = resultBlock;
    task.runResult = false;
    task.param = param;
    
    //测试随机执行时长
    task.timeConsuming = (int)(0 + (arc4random() % (0 - 4 + 1)));
    
    //添加到队列中
    [self.lockQueue lock];
    task.taskId = taskid;
    [self.taskQueue addObject:task];
    
    NSString *strExecutor = NSStringFromClass([task.executor class]);
    NSLog(@"task executor : %@",strExecutor);
    task = nil;
    
    [self.lockQueue unlock];
    
    [self awakeRunloop];
}


+(instancetype)sharedWorkQueue{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sNKTaskWorkQueue = [[NKTaskWorkQueue alloc] init];
        sNKTaskWorkQueue.lockQueue = [NSLock new];
        [sNKTaskWorkQueue start];
    });
    
    return sNKTaskWorkQueue;
}
/** 开始队列任务 */
-(void)start
{
    [self.lockQueue lock];
    if ( _taskQueue ) {
        [_taskQueue removeAllObjects];
        _taskQueue = nil;
    }
    _taskQueue = [NSMutableArray new];
    [self.lockQueue unlock];
    //创建任务数组（队列）后，开始创建一个线程，并开始执行 runDefaultLoop 方法。
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(queueThreadRun) object:nil];
    [thread start];
}

/** 结束队列任务 */
-(void)stop
{
    [self performSelector:@selector(stopRunloop) withObject:nil];
    
    [self.lockQueue lock];
    if ( _taskQueue ) {
        [_taskQueue removeAllObjects];
        _taskQueue = nil;
    }
    
    [self.lockQueue unlock];
}

/** 线程方法：任务队列启动，并绑定事件源 */
- (void)queueThreadRun {
    
    NSThread *thread = [NSThread currentThread];
    /** 获取当前线程的 runloop
        注：runloop不能自己创建，只能获取，除了主线程外，子线程的runloop是首次使用的时候才会创建的
     */
    _runLoopRef = CFRunLoopGetCurrent();
    
    /** 自定义事件源，并给runLoop添加事件源，重要的参数 peform ：当前输入源，收到signal后，调用的方法  */
    bzero(&_source_context, sizeof(_source_context));
    _source_context.info = (__bridge void *)(self);
    _source_context.perform = doWork;
    _source = CFRunLoopSourceCreate(NULL, 0, &_source_context);
    CFRunLoopAddSource(_runLoopRef, _source, kCFRunLoopCommonModes);
    
    //////runloop 监听/////
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(), kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopEntry:
                NSLog(@"RunLoop进入");
                break;
            case kCFRunLoopBeforeTimers:
                NSLog(@"RunLoop要处理Timers了");
                break;
            case kCFRunLoopBeforeSources:
                NSLog(@"RunLoop要处理Sources了");
                break;
            case kCFRunLoopBeforeWaiting:
                NSLog(@"RunLoop要休息了");
                break;
            case kCFRunLoopAfterWaiting:
                NSLog(@"RunLoop醒来了");
                break;
            case kCFRunLoopExit:
                NSLog(@"RunLoop退出了");
                break;
                
            default:
                break;
        }
    });
    
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
    //////////////////////
    
    
    _shouldStop = false;
    NSLog(@"=================runloop start=====================");
    while (!_shouldStop) {
        //启动runloop
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 30, NO);
    }
    //workQueue 被外部_shouldStop 字段标记为停止，则停止当前roonloop
    CFRunLoopRemoveSource(_runLoopRef, _source, kCFRunLoopCommonModes);
    CFRelease(observer);
    CFRelease(_source);
    
    _runLoopRef = nil;
    _source = nil;
    NSLog(@"=================runloop end=====================");
    thread = nil;
}
/** 新的事件添加后，通知runloop处理source事件 */
-(void)awakeRunloop
{
    if ( !_runLoopRef ||  !_source ){
        return;
    }
    if (CFRunLoopIsWaiting(_runLoopRef)) {
        CFRunLoopSourceSignal(_source);
        CFRunLoopWakeUp(_runLoopRef);
    }else {
        CFRunLoopSourceSignal(_source);
    }
}
/** 任务队列结束，停止线程的runLoop */
- (void)stopRunloop{
    _shouldStop = YES;
    if (_runLoopRef) {
        CFRunLoopStop(_runLoopRef);
    }
    
}

/** 任务task id执行后 */
static void doWork(void* info )
{
     NKTaskWorkQueue *refToSelf = (__bridge NKTaskWorkQueue*)info;
    
    //source事件源，perform方法为 doWork， 该方法返回(while结束)，是runloop的一次循环
     while ([refToSelf.taskQueue count] > 0 )
     {
         [[refToSelf lockQueue] lock];
         NKTaskWork *task = [refToSelf.taskQueue firstObject];
         [[refToSelf lockQueue] unlock];
         
         if (!task) {
             break;
         }
         //执行过了，移除。这里的移除也可以由业务层来处理，具体根据自己的业务来
         if (task.runState == TaskRunState_Runed) {
             [refToSelf.taskQueue removeObjectAtIndex:0];
             continue;
         }
         if(task.runState == TaskRunState_Running) {
             //不处理，runloop 会进入等待...
             break;
         }
         else if (task.runState == TaskRunState_NotRun) {
             //新任务，执行
             task.runState = TaskRunState_Running;
             if( task.executor && task.func ) {
                 __weak NKTaskWork *weakTask = task;
                 dispatch_async(dispatch_get_global_queue(0, 0), ^{
                     __strong NKTaskWork *strongTask = weakTask;
                     strongTask.startStamp = [[NSDate date] timeIntervalSince1970];
                     //func 为 task执行的具体逻辑，由业务上层定义，比如打开播放器，处理网络请求，以及其他一些耗时操作等
                     strongTask.func(strongTask.param);
                 });
             }
             task = nil;
         }
     }
}

- (void) removeTask:(NSInteger)taskId {
    [self.lockQueue lock];
    if( [_taskQueue count] > 0 ){
        while ( self.taskQueue.count > 0 ){
            NKTaskWork *tmpTask = self.taskQueue[0];
            if ( tmpTask && tmpTask.taskId == taskId && tmpTask.runState == TaskRunState_Running ){
                if ( tmpTask && tmpTask.resultBlock ){
                    tmpTask.resultBlock(@"complete!");
                }
                [self.taskQueue removeObjectAtIndex:0];
            }
            else{
                break;
            }
        }
    }
    [self.lockQueue unlock];
    [self awakeRunloop];
}
@end
