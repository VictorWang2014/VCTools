//
//  VCHeadScrollView.h
//  test
//
//  Created by wangmingquan on 2018/3/20.
//  Copyright © 2018年 wangmingquan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VCHeadScrollViewDelegate <NSObject>

// collectionViewCell上每一个页view
- (UIScrollView *)cellOfHeadScrollViewAtIndex:(int)index;

// collectionViewCell的数量
- (int)numberOfSubHeadScrollView;

// 数据加载，非数据请求（数据请求在subScrollView:didShowAtIndex:）
- (void)scrollViewReloadData:(UIScrollView *)scrollView atIndex:(int)index;

@optional

// 头部view
- (UIView *)headerView;

// segment view
- (UIView *)segmentView;

// 当前滚动显示的第几页
- (void)subScrollView:(UIScrollView *)scrollView didShowAtIndex:(int)index;

// 当cell的类型为多种时必须实现改代理方法
- (NSString *)reuseIdentifierAtIndex:(int)index;

@end


typedef NS_ENUM(NSInteger, HSCellIdentifierType) {
    HSCellIdentifierTypeSame,                                               // cell的类型为一种
    HSCellIdentifierTypeDiffer,                                             // cell的类型为多种的 必须实现@selector(reuseIdentifierAtIndex:)代理方法
};


//
@interface VCHeadScrollView : UIView

@property (nonatomic, assign) HSCellIdentifierType hsCellReuseType;         // collectionViewcell重用类型，只有一个类型的cell和存在多种类型的cell

@property (nonatomic, weak) id<VCHeadScrollViewDelegate>delegate;           // 代理

@property (nonatomic, assign) int currentSelectIndex;                       // 当前显示的第几页

// 重用cell标识符注册，如果hsCellReuseType是不同的不需要调用该方法，用默认的
- (void)registerCollectionViewCellReuseIdentifer:(NSArray *)identifierArray;

// 重置整个headScrollView
- (void)resetSubView;

// 加载view
- (void)reloadData;

@end
