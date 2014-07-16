//
//  BSDPTest.m
//  BSDPatchExample
//
//  Created by Travis Henspeter on 7/15/14.
//  Copyright (c) 2014 birdSound LLC. All rights reserved.
//

#import "BSDPTest.h"
#import "BSDCreate.h"

@interface BSDPTest ()

@property (nonatomic)double significanceLevel;
@property (nonatomic)double zscore;
@property (nonatomic)NSUInteger bufferSize;
@property (nonatomic,strong)BSDSubtract *subtractInputFromAvg;
@property (nonatomic,strong)BSDAverage *average;
@property (nonatomic,strong)BSDStdDev *stdDev;
@property (nonatomic,strong)BSDDivide *divideDiffByStdDev;
@property (nonatomic,strong)BSDEqualGreater *compareToSigLevel;
@property (nonatomic,strong)BSDAbs *absoluteValue;

@end

@implementation BSDPTest


- (id)initWithSignificanceLevel:(double)significanceLevel bufferSize:(NSUInteger)bufferSize
{
    NSDictionary *args = @{@"significance": @(significanceLevel),
                           @"buffer":@(bufferSize)
                           };
    return [super initWithArguments:args];
}

- (id)initWithSignificanceLevel:(double)significanceLevel
{
    NSDictionary *args = @{@"significance": @(significanceLevel)};
    return [super initWithArguments:args];
}

- (NSNumber *)criticalValueForSignificance:(double)significance
{
    if (significance >= 0.99) {
        return @(2.58);
    }else if (significance >= 0.95){
        return @(1.96);
    }else if (significance >= 0.9){
        return @(1.645);
    }else{
        return @(1.96);
    }
}

- (void)setupWithArguments:(id)arguments
{
    self.name = @"p-test";
    NSDictionary *args = (NSDictionary *)arguments;
    
    if (!args) {
        self.significanceLevel = 0.95;
        self.bufferSize = 0;
    }else {
        if ([args.allKeys containsObject:@"significance"]){
        self.significanceLevel = [args[@"significance"]doubleValue];
        }
        
        if ([args.allKeys containsObject:@"buffer"]) {
            self.bufferSize = [args[@"buffer"]integerValue];
            self.average = [[BSDAverage alloc]initWithBufferSize:self.bufferSize];
            self.stdDev = [[BSDStdDev alloc]initWithBufferSize:self.bufferSize];
        }else{
            self.bufferSize = 0;
            self.average = [BSDCreate average];
            self.stdDev = [BSDCreate standardDeviation];
        }
    }
    
    BSDOutlet *avgOutlet = [[BSDOutlet alloc]init];
    avgOutlet.name = self.average.name;
    [self addOutlet:avgOutlet named:avgOutlet.name];
    
    BSDOutlet *stdDevOutlet = [[BSDOutlet alloc]init];
    stdDevOutlet.name = self.stdDev.name;
    [self addOutlet:stdDevOutlet named:stdDevOutlet.name];
    
    self.compareToSigLevel = [BSDCreate equalOrGreater];
    self.absoluteValue = [BSDCreate absoluteValue];
    [self.compareToSigLevel cold:[self criticalValueForSignificance:self.significanceLevel]];

    self.subtractInputFromAvg = [BSDCreate subtract];
    self.divideDiffByStdDev = [BSDCreate divide];
    [self.stdDev connect:self.divideDiffByStdDev.coldInlet];
    [self.average connect:self.subtractInputFromAvg.coldInlet];
    [self.subtractInputFromAvg connect:self.divideDiffByStdDev.hotInlet];
    [self.divideDiffByStdDev connect:self.absoluteValue.hotInlet];
    [self.absoluteValue connect:self.compareToSigLevel.hotInlet];
    
}

- (void)reset
{
    [self.average reset];
    [self.stdDev reset];
}

- (id)calculateOutputValue
{
    [self.stdDev hot:self.hotInlet.value];
    [self.average hot:self.hotInlet.value];
    [self.subtractInputFromAvg hot:self.hotInlet.value];
    [self sendOutputValue:self.average.mainOutlet.value toOutletNamed:self.average.name];
    [self sendOutputValue:self.stdDev.mainOutlet.value toOutletNamed:self.stdDev.name];

    return self.compareToSigLevel.mainOutlet.value;
}

@end