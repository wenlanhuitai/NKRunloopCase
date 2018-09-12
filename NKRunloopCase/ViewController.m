//
//  ViewController.m
//  NKRunloopCase
//
//  Created by 谢印超 on 2018/9/11.
//  Copyright © 2018年 360. All rights reserved.
//

/**runloop 基本原理的应用 附Demo
学习要点：
 1: 掌握Runloop基本原理
 2: 建立简单的通用任务队列，并使用Runloop进行任务处理（子线程同步队列）
 3: 监听runloop状态
 4: 回顾runloop的源码细节
 
 
 作者简书地址：https://www.jianshu.com/u/46cf865d218f
 个人博客：
 凝酷 - 凝聚天下酷物，尝遍业界技术
 http://www.ningcool.com/
 */

#import "ViewController.h"
#import "NKTaskWorkQueue.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UITextView *textF;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)startRunLoopAndApendTask:(id)sender {
    __weak typeof(self) weakSelf = self;
    for (int i = 0; i <= 999; i++) {
        NKTaskWorkParam *param = [NKTaskWorkParam new];
        param.paramText = [NSString stringWithFormat:@"I am is %d",i];
        param.paramDuration = (int)(0 + (arc4random() % (0 - 4 + 1)));
        [[NKTaskWorkQueue sharedWorkQueue] appendTaskWithExecutor:self mark:@"" taskId:i param:param returnBlock:^(NSString *taskMsg) {
            NSLog(@"taskMsg : %@",taskMsg);
        } worker:^(NKTaskWorkParam *param) {
            NSLog(@"worker start excute: %@",param.paramText);
            
            [weakSelf completeTask:i param:(NSString *)param.paramText];
        }];
    }
}

- (IBAction)stopRunloop:(id)sender {
    [[NKTaskWorkQueue sharedWorkQueue] stop];
}


- (void) completeTask:(NSInteger )taskid param:(NSString *)msg {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        sleep(1);
        NSString *str = [NSString stringWithFormat:@"%@\n%@",weakSelf.textF.text,msg];
        
        [weakSelf.textF setText:str];
        [weakSelf.textF scrollRangeToVisible:NSMakeRange(weakSelf.textF.text.length, 1)];
        
        //没有移除task之前，runloop会一直等待。
        [[NKTaskWorkQueue sharedWorkQueue] removeTask:taskid];
        
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
