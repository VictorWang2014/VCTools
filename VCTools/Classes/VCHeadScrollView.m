//
//  VCHeadScrollView.m
//  test
//
//  Created by wangmingquan on 2018/3/20.
//  Copyright © 2018年 wangmingquan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VCHeadScrollView.h"
//#import "NSObject+Category.h"

#define kCollectViewCellSubScrollViewTag 1111

@interface VCHeadScrollView () <UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate> {
    float _currentContentOffsetY;
    float _headerViewHeight;
    float _segmentViewHeight;

    UIView *_headerView;
    UIView *_segmentView;
    UICollectionView *_collectionView;
    UIScrollView *_currentScrollView;
    UIScrollView *_tmpScrollView;
}

@property (nonatomic, strong) NSMutableDictionary *scrollViewOffsetDic;     // 每个滚动的scrollview的offset

@end

@implementation VCHeadScrollView

- (void)dealloc {
    NSLog(@"+++++dealloc");
    @try {
        [_currentScrollView removeObserver:self forKeyPath:@"contentOffset"];
        [_tmpScrollView removeObserver:self forKeyPath:@"contentOffset"];
    } @catch (NSException *exception) {}
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {}
    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview) {
        [self initialView];
    }
}

#pragma mark - private
- (void)initialView {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _headerViewHeight = 0;
    _segmentViewHeight = 0;
    self.currentSelectIndex = -1;
    self.scrollViewOffsetDic = [NSMutableDictionary dictionary];
    
    UICollectionViewFlowLayout *collectionLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    collectionLayout.minimumLineSpacing = 0;
    collectionLayout.minimumInteritemSpacing = 0;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:collectionLayout];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.bounces = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:_collectionView];
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"collectViewDefaultCell"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerView)]) {
        _headerView = [self.delegate headerView];
        _headerViewHeight = _headerView.frame.size.height;
        _headerView.frame = CGRectMake(0, 0, self.frame.size.width, _headerViewHeight);
//        _headerView.backgroundColor = [UIColor randomColor];
        [self addSubview:_headerView];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(segmentView)]) {
        _segmentView = [self.delegate segmentView];
        _segmentViewHeight = _segmentView.frame.size.height;
        _segmentView.frame = CGRectMake(0, _headerViewHeight, self.frame.size.width, _segmentViewHeight);
//        _segmentView.backgroundColor = [UIColor randomColor];
        [self addSubview:_segmentView];
    }
    _currentContentOffsetY = -(_headerViewHeight+_segmentViewHeight);
}

- (void)scrollViewDidEndScroll {
    int tmpIndex = self.currentSelectIndex;
    CGFloat offsetX = _collectionView.contentOffset.x;
    self.currentSelectIndex = offsetX/_collectionView.frame.size.width;
    if (tmpIndex != self.currentSelectIndex) {// 滚动取消的话，不用调用
        if (self.delegate && [self.delegate respondsToSelector:@selector(subScrollView:didShowAtIndex:)]) {
            [self.delegate subScrollView:_currentScrollView didShowAtIndex:self.currentSelectIndex];
        }
    }
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    if (self.hsCellReuseType == HSCellIdentifierTypeSame) {
        identifier = @"collectViewDefaultCell";
    } else {
        if ([self.delegate respondsToSelector:@selector(reuseIdentifierAtIndex:)]) {// reuseType为HSCellIdentifierTypeDiffer 必须实现改方法
            identifier = [self.delegate reuseIdentifierAtIndex:(int)indexPath.row];
        } else {
            NSAssert(![self.delegate respondsToSelector:@selector(reuseIdentifierAtIndex:)], @"Must implement reuseIdentifierAtIndex method，hsCellReuseType");
        }
    }
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    UIScrollView *scrollView = (UIScrollView *)[cell viewWithTag:kCollectViewCellSubScrollViewTag];
    if (scrollView == nil) {
        scrollView = [self.delegate cellOfHeadScrollViewAtIndex:(int)indexPath.row];
        scrollView.frame = cell.bounds;
        scrollView.tag = kCollectViewCellSubScrollViewTag;
        scrollView.contentInset = UIEdgeInsetsMake(_headerViewHeight+_segmentViewHeight, 0, 0, 0);
        [cell addSubview:scrollView];
    }
//    cell.indexPath = indexPath;
//    scrollView.backgroundColor = [UIColor randomColor];
    if (self.delegate && [self.delegate respondsToSelector:@selector(scrollViewReloadData:atIndex:)]) {
        [self.delegate scrollViewReloadData:scrollView atIndex:(int)indexPath.row];
    }
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.delegate numberOfSubHeadScrollView];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.frame.size.width, self.frame.size.height);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    UIScrollView *scrollView = [cell viewWithTag:kCollectViewCellSubScrollViewTag];
    if (scrollView) {
        UIScrollView *scrollView = (UIScrollView *)[cell viewWithTag:kCollectViewCellSubScrollViewTag];
        if (_currentScrollView) {
            [_currentScrollView removeObserver:self forKeyPath:@"contentOffset"];
        } else {
            _currentScrollView = scrollView;
        }
        _tmpScrollView = scrollView;
        // 根据缓存的每一个scrollview的contentoffset.y处理重用的scrollviewcontentoffset.y不是初始化的问题
        if (![self.scrollViewOffsetDic objectForKey:@(indexPath.row)]) {// 不存在
            if (_currentContentOffsetY < -_segmentViewHeight) {// headView还在显示
                scrollView.contentOffset = CGPointMake(0, _currentContentOffsetY);
            } else {// 之前显示的scrollView 第0行不显示，滚动的太往上了
                scrollView.contentOffset = CGPointMake(0, -_segmentViewHeight);
            }
        } else {// 存在
            CGFloat offsetY = [[self.scrollViewOffsetDic objectForKey:@(indexPath.row)] floatValue];
            if (_currentContentOffsetY < -_segmentViewHeight) {// headview有显示
                scrollView.contentOffset = CGPointMake(0, _currentContentOffsetY);
            } else if (_currentContentOffsetY >= -_segmentViewHeight) {// headview隐藏起来了
                if (offsetY < -_segmentViewHeight) {
                    scrollView.contentOffset = CGPointMake(0, -_segmentViewHeight);
                } else {
                    scrollView.contentOffset = CGPointMake(0, offsetY);
                }
            }
        }
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        _currentContentOffsetY = scrollView.contentOffset.y;
        [self.scrollViewOffsetDic setObject:[NSNumber numberWithFloat:_currentContentOffsetY] forKey:@(indexPath.row)];
    }
}

// 解决滑动一点，再取消的问题
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    UIScrollView *scrollView = [cell viewWithTag:kCollectViewCellSubScrollViewTag];
    if (scrollView) {
        UIScrollView *scrollView = (UIScrollView *)[cell viewWithTag:kCollectViewCellSubScrollViewTag];
        if (_tmpScrollView != scrollView) {
            _currentScrollView = _tmpScrollView;
        }
        @try {
            [_tmpScrollView removeObserver:self forKeyPath:@"contentOffset"];
        } @catch (NSException *exception) {}
        [_currentScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        NSLog(@"+++++ %@", NSStringFromSelector(_cmd));
        if (_collectionView == scrollView) {
            [self scrollViewDidEndScroll];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"+++++ %@", NSStringFromSelector(_cmd));
    if (_collectionView == scrollView) {
        [self scrollViewDidEndScroll];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    NSLog(@"+++++ %@", NSStringFromSelector(_cmd));
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"+++++ %@", NSStringFromSelector(_cmd));
}

#pragma mark - KVO
// 滚动视图的同时设置headview和segmentview的位置
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"] && object == _currentScrollView) {
        CGRect frame = _headerView.frame;
        if (_currentScrollView.contentOffset.y < -_segmentViewHeight) {
            frame.origin.y = -(_headerViewHeight+_segmentViewHeight+_currentScrollView.contentOffset.y);
            _headerView.frame = frame;
            frame = _segmentView.frame;
            frame.origin.y = -_currentScrollView.contentOffset.y-_segmentViewHeight;
            _segmentView.frame = frame;
        } else if (frame.origin.y != -_headerViewHeight) {
            frame.origin.y = -_headerViewHeight;
            _headerView.frame = frame;
            frame = _segmentView.frame;
            frame.origin.y = 0;
            _segmentView.frame = frame;
        }
        _currentContentOffsetY = _currentScrollView.contentOffset.y;
        UICollectionViewCell *cell = (UICollectionViewCell *)_currentScrollView.superview;
        if ([cell isKindOfClass:[UICollectionViewCell class]]) {
//            [self.scrollViewOffsetDic setObject:[NSNumber numberWithFloat:_currentContentOffsetY] forKey:@(cell.indexPath.row)];
        }
    }
}

#pragma mark - public
- (void)reloadData {
    [_collectionView reloadData];
}

- (void)resetSubView {
    [self initialView];
}

- (void)registerCollectionViewCellReuseIdentifer:(NSArray *)identifierArray {
    NSSet *set = [NSSet setWithArray:identifierArray];
    [set enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *identifier = obj;
        [self->_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:identifier];
    }];
}

@end

