//
//  ViewController.m
//  JKPopupView
//
//  Created by byRong on 2018/11/19.
//  Copyright © 2018 byRong. All rights reserved.
//

#import "ViewController.h"
#import "JKPopupView/JKPopupView.h"
#import <QuartzCore/QuartzCore.h>


typedef NS_ENUM(NSInteger, FieldTag) {
    FieldTagHorizontalLayout = 1001,
    FieldTagVerticalLayout,
    FieldTagMaskType,
    FieldTagShowType,
    FieldTagDismissType,
    FieldTagBackgroundDismiss,
    FieldTagContentDismiss,
    FieldTagTimedDismiss,
};


typedef NS_ENUM(NSInteger, CellType) {
    CellTypeNormal = 0,
    CellTypeSwitch,
};

#pragma mark - Categories
@interface UIColor (JKPopupView)
+ (UIColor*)JKLightGreenColor;
+ (UIColor*)JKGreenColor;
@end

@implementation UIColor (JKPopupView)

+ (UIColor *)JKLightGreenColor
{
    return [UIColor colorWithRed:(185.0/255.0) green:(203.0/255.0) blue:(132.0/255.0) alpha:1.0];
}

+ (UIColor *)JKGreenColor
{
    return [UIColor colorWithRed:(0.0/255.0) green:(214.0/255.0) blue:(214.0/255.0) alpha:1.0];
}
@end

@interface UIView (JKPopupView)
- (UITableViewCell *)parentCell;
@end

@implementation UIView (JKPopupView)

- (UITableViewCell *)parentCell
{
    // Iterate over superviews until you find a UITableViewCell
    UIView *view = self;
    while (view != nil) {
        if ([view isKindOfClass:[UITableViewCell class]]) {
            return (UITableViewCell *)view;
        } else {
            view = [view superview];
        }
    }
    return nil;
}
@end

@interface ViewController ()
@property (nonatomic, copy) NSArray *fields;
@property (nonatomic, copy) NSDictionary *namesForFields;
    
@property (nonatomic, copy) NSArray *horizontalLayouts;
@property (nonatomic, copy) NSArray *verticalLayouts;
@property (nonatomic, copy) NSArray *maskTypes;
@property (nonatomic, copy) NSArray *showTypes;
@property (nonatomic, copy) NSArray *dismissTypes;
    
@property (nonatomic, copy) NSDictionary *namesForHorizontalLayouts;
@property (nonatomic, copy) NSDictionary *namesForVerticalLayouts;
@property (nonatomic, copy) NSDictionary *namesForMaskTypes;
@property (nonatomic, copy) NSDictionary *namesForShowTypes;
@property (nonatomic, copy) NSDictionary *namesForDismissTypes;
    
@property (nonatomic, assign) NSInteger selectedRowInHorizontalField;
@property (nonatomic, assign) NSInteger selectedRowInVerticalField;
@property (nonatomic, assign) NSInteger selectedRowInMaskField;
@property (nonatomic, assign) NSInteger selectedRowInShowField;
@property (nonatomic, assign) NSInteger selectedRowInDismissField;
@property (nonatomic, assign) BOOL shouldDismissOnBackgroundTouch;
@property (nonatomic, assign) BOOL shouldDismissOnContentTouch;
@property (nonatomic, assign) BOOL shouldDismissAfterDelay;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) JKPopupView *popup;
// Private
- (void)updateFieldTableView:(UITableView *)tableView;
- (NSInteger)valueForRow:(NSInteger)row inFieldWithTag:(NSInteger)tag;
- (NSInteger)selectedRowForFieldWithTag:(NSInteger)tag;
- (NSString *)nameForValue:(NSInteger)value inFieldWithTag:(NSInteger)tag;
- (CellType)cellTypeForFieldWithTag:(NSInteger)tag;

// Event handlers
- (void)toggleValueDidChange:(id)sender;
- (void)showButtonPressed:(id)sender;
- (void)dismissButtonPressed:(id)sender;
- (void)fieldCancelButtonPressed:(id)sender;

@end

@implementation ViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"JKPopupView";
        // MAIN LIST
         self.fields = @[@(FieldTagHorizontalLayout),
                    @(FieldTagVerticalLayout),
                    @(FieldTagMaskType),
                    @(FieldTagShowType),
                    @(FieldTagDismissType),
                    @(FieldTagBackgroundDismiss),
                    @(FieldTagContentDismiss),
                    @(FieldTagTimedDismiss)];
        
         self.namesForFields = @{@(FieldTagHorizontalLayout) : @"Horizontal layout",
                            @(FieldTagVerticalLayout) : @"Vertical layout",
                            @(FieldTagMaskType) : @"Background mask",
                            @(FieldTagShowType) : @"Show type",
                            @(FieldTagDismissType) : @"Dismiss type",
                            @(FieldTagBackgroundDismiss) : @"Dismiss on background touch",
                            @(FieldTagContentDismiss) : @"Dismiss on content touch",
                            @(FieldTagTimedDismiss) : @"Dismiss after delay"};
        // FIELD SUB-LISTS
         self.horizontalLayouts = @[@(JKPopupHorizontalLayoutLeft),
                               @(JKPopupHorizontalLayoutLeftOfCenter),
                               @(JKPopupHorizontalLayoutCenter),
                               @(JKPopupHorizontalLayoutRightOfCenter),
                               @(JKPopupHorizontalLayoutRight)];
        
         self.namesForHorizontalLayouts = @{@(JKPopupHorizontalLayoutLeft) : @"Left",
                                       @(JKPopupHorizontalLayoutLeftOfCenter) : @"Left of Center",
                                       @(JKPopupHorizontalLayoutCenter) : @"Center",
                                       @(JKPopupHorizontalLayoutRightOfCenter) : @"Right of Center",
                                       @(JKPopupHorizontalLayoutRight) : @"Right"};
        
         self.verticalLayouts = @[@(JKPopupVerticalLayoutTop),
                             @(JKPopupVerticalLayoutAboveCenter),
                             @(JKPopupVerticalLayoutCenter),
                             @(JKPopupVerticalLayoutBelowCenter),
                             @(JKPopupVerticalLayoutBottom)];
        
         self.namesForVerticalLayouts = @{@(JKPopupVerticalLayoutTop) : @"Top",
                                     @(JKPopupVerticalLayoutAboveCenter) : @"Above Center",
                                     @(JKPopupVerticalLayoutCenter) : @"Center",
                                     @(JKPopupVerticalLayoutBelowCenter) : @"Below Center",
                                     @(JKPopupVerticalLayoutBottom) : @"Bottom"};
        
         self.maskTypes = @[@(JKPopupMaskTypeNone),
                       @(JKPopupMaskTypeClear),
                       @(JKPopupMaskTypeDimmed)];
        
         self.namesForMaskTypes = @{@(JKPopupMaskTypeNone) : @"None",
                               @(JKPopupMaskTypeClear) : @"Clear",
                               @(JKPopupMaskTypeDimmed) : @"Dimmed"};
        
         self.showTypes = @[@(JKPopupShowTypeNone),
                       @(JKPopupShowTypeFadeIn),
                       @(JKPopupShowTypeGrowIn),
                       @(JKPopupShowTypeShrinkIn),
                       @(JKPopupShowTypeSlideInFromTop),
                       @(JKPopupShowTypeSlideInFromBottom),
                       @(JKPopupShowTypeSlideInFromLeft),
                       @(JKPopupShowTypeSlideInFromRight),
                       @(JKPopupShowTypeBounceIn),
                       @(JKPopupShowTypeBounceInFromTop),
                       @(JKPopupShowTypeBounceInFromBottom),
                       @(JKPopupShowTypeBounceInFromLeft),
                       @(JKPopupShowTypeBounceInFromRight)];
        
         self.namesForShowTypes = @{@(JKPopupShowTypeNone) : @"None",
                               @(JKPopupShowTypeFadeIn) : @"Fade in",
                               @(JKPopupShowTypeGrowIn) : @"Grow in",
                               @(JKPopupShowTypeShrinkIn) : @"Shrink in",
                               @(JKPopupShowTypeSlideInFromTop) : @"Slide from Top",
                               @(JKPopupShowTypeSlideInFromBottom) : @"Slide from Bottom",
                               @(JKPopupShowTypeSlideInFromLeft) : @"Slide from Left",
                               @(JKPopupShowTypeSlideInFromRight) : @"Slide from Right",
                               @(JKPopupShowTypeBounceIn) : @"Bounce in",
                               @(JKPopupShowTypeBounceInFromTop) : @"Bounce from Top",
                               @(JKPopupShowTypeBounceInFromBottom) : @"Bounce from Bottom",
                               @(JKPopupShowTypeBounceInFromLeft) : @"Bounce from Left",
                               @(JKPopupShowTypeBounceInFromRight) : @"Bounce from Right"};
        
         self.dismissTypes = @[@(JKPopupDismissTypeNone),
                          @(JKPopupDismissTypeFadeOut),
                          @(JKPopupDismissTypeGrowOut),
                          @(JKPopupDismissTypeShrinkOut),
                          @(JKPopupDismissTypeSlideOutToTop),
                          @(JKPopupDismissTypeSlideOutToBottom),
                          @(JKPopupDismissTypeSlideOutToLeft),
                          @(JKPopupDismissTypeSlideOutToRight),
                          @(JKPopupDismissTypeBounceOut),
                          @(JKPopupDismissTypeBounceOutToTop),
                          @(JKPopupDismissTypeBounceOutToBottom),
                          @(JKPopupDismissTypeBounceOutToLeft),
                          @(JKPopupDismissTypeBounceOutToRight)];
        
         self.namesForDismissTypes = @{@(JKPopupDismissTypeNone) : @"None",
                                  @(JKPopupDismissTypeFadeOut) : @"Fade out",
                                  @(JKPopupDismissTypeGrowOut) : @"Grow out",
                                  @(JKPopupDismissTypeShrinkOut) : @"Shrink out",
                                  @(JKPopupDismissTypeSlideOutToTop) : @"Slide to Top",
                                  @(JKPopupDismissTypeSlideOutToBottom) : @"Slide to Bottom",
                                  @(JKPopupDismissTypeSlideOutToLeft) : @"Slide to Left",
                                  @(JKPopupDismissTypeSlideOutToRight) : @"Slide to Right",
                                  @(JKPopupDismissTypeBounceOut) : @"Bounce out",
                                  @(JKPopupDismissTypeBounceOutToTop) : @"Bounce to Top",
                                  @(JKPopupDismissTypeBounceOutToBottom) : @"Bounce to Bottom",
                                  @(JKPopupDismissTypeBounceOutToLeft) : @"Bounce to Left",
                                  @(JKPopupDismissTypeBounceOutToRight) : @"Bounce to Right"};
        
        // DEFAULTS
         self.selectedRowInHorizontalField = [ self.horizontalLayouts indexOfObject:@(JKPopupHorizontalLayoutCenter)];
         self.selectedRowInVerticalField = [ self.verticalLayouts indexOfObject:@(JKPopupVerticalLayoutCenter)];
         self.selectedRowInMaskField = [ self.maskTypes indexOfObject:@(JKPopupMaskTypeDimmed)];
         self.selectedRowInShowField = [ self.showTypes indexOfObject:@(JKPopupShowTypeBounceInFromTop)];
         self.selectedRowInDismissField = [ self.dismissTypes indexOfObject:@(JKPopupDismissTypeBounceOutToBottom)];
         self.shouldDismissOnBackgroundTouch = YES;
         self.shouldDismissOnContentTouch = NO;
         self.shouldDismissAfterDelay = NO;
    }
    return self;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.delaysContentTouches = NO;
    }
    return _tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor redColor];
    
    [self.view addSubview:self.tableView];
    UITableView *tableView = self.tableView;
    NSDictionary *views = NSDictionaryOfVariableBindings(tableView);
    NSDictionary *metrics = nil;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    
    // FOOTER
    UIView *footerView = [[UIView alloc] init];
    
    UIButton *showButton = [UIButton buttonWithType:UIButtonTypeCustom];
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    showButton.contentEdgeInsets = UIEdgeInsetsMake(14, 28, 14, 28);
    [showButton setTitle:@"Show it!" forState:UIControlStateNormal];
    showButton.backgroundColor = [UIColor lightGrayColor];
    [showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [showButton setTitleColor:[[showButton titleColorForState:UIControlStateNormal] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    showButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    [showButton.layer setCornerRadius:8.0];
    [showButton addTarget:self action:@selector(showButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:showButton];
    
    CGFloat topMargin = 12.0;
    CGFloat bottomMargin = 12.0;
    
    views = NSDictionaryOfVariableBindings(showButton);
    metrics = @{@"topMargin" : @(topMargin),
                @"bottomMargin" : @(bottomMargin)};
    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(topMargin)-[showButton]-(bottomMargin)-|"
                                                                       options:0
                                                                       metrics:metrics
                                                                         views:views]];
    
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:showButton
                                                           attribute:NSLayoutAttributeCenterX
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:showButton.superview
                                                           attribute:NSLayoutAttributeCenterX
                                                          multiplier:1.0
                                                            constant:0.0]];
    
    CGRect footerFrame = CGRectZero;
    footerFrame.size = [showButton systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    footerFrame.size.height += topMargin + bottomMargin;
    footerView.frame = footerFrame;
    self.tableView.tableFooterView = footerView;
}

#pragma mark - Event Handlers

- (void)toggleValueDidChange:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *toggle = (UISwitch*)sender;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:[toggle parentCell]];
        id obj = [ self.fields objectAtIndex:indexPath.row];
        if ([obj isKindOfClass:[NSNumber class]]) {
            
            NSInteger fieldTag = [(NSNumber*)obj integerValue];
            if (fieldTag == FieldTagBackgroundDismiss) {
                 self.shouldDismissOnBackgroundTouch = toggle.on;
                
            } else if (fieldTag == FieldTagContentDismiss) {
                 self.shouldDismissOnContentTouch = toggle.on;
                
            } else if (fieldTag == FieldTagTimedDismiss) {
                 self.shouldDismissAfterDelay = toggle.on;
            }
        }
    }
}

- (void)showButtonPressed:(id)sender
{
    // Generate content view to present
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.backgroundColor = [UIColor JKLightGreenColor];
    contentView.layer.cornerRadius = 12.0;
    
    UILabel *dismissLabel = [[UILabel alloc] init];
    dismissLabel.translatesAutoresizingMaskIntoConstraints = NO;
    dismissLabel.backgroundColor = [UIColor clearColor];
    dismissLabel.textColor = [UIColor whiteColor];
    dismissLabel.font = [UIFont boldSystemFontOfSize:72.0];
    dismissLabel.text = @"OK.";
    
    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    dismissButton.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20);
    dismissButton.backgroundColor = [UIColor JKGreenColor];
    [dismissButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [dismissButton setTitleColor:[[dismissButton titleColorForState:UIControlStateNormal] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    dismissButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [dismissButton setTitle:@"Miss" forState:UIControlStateNormal];
    dismissButton.layer.cornerRadius = 6.0;
    [dismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [contentView addSubview:dismissLabel];
    [contentView addSubview:dismissButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView, dismissButton, dismissLabel);
    
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(16)-[dismissLabel]-(10)-[dismissButton]-(24)-|"
                                                                         options:NSLayoutFormatAlignAllCenterX
                                                                         metrics:nil
                                                                           views:views]];
    
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(36)-[dismissLabel]-(36)-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:views]];
    
    // Show in popup
    JKPopupLayout *layout = [JKPopupLayout JKPopupLayoutMakeHorizontal:(JKPopupHorizontalLayout)[self valueForRow: self.selectedRowInHorizontalField inFieldWithTag:FieldTagHorizontalLayout] vertical:(JKPopupVerticalLayout)[self valueForRow: self.selectedRowInVerticalField inFieldWithTag:FieldTagVerticalLayout]];
    JKPopupView *popup = [JKPopupView popupWithContentView:contentView
                                                  showType:(JKPopupShowType)[self valueForRow: self.selectedRowInShowField inFieldWithTag:FieldTagShowType]
                                               dismissType:(JKPopupDismissType)[self valueForRow: self.selectedRowInDismissField inFieldWithTag:FieldTagDismissType]
                                                  maskType:(JKPopupMaskType)[self valueForRow: self.selectedRowInMaskField inFieldWithTag:FieldTagMaskType]
                                  dismissOnBackgroundTouch:self.shouldDismissOnBackgroundTouch dismissOnContentTouch:self.shouldDismissOnContentTouch];
    if ( self.shouldDismissAfterDelay) {
        [popup showWithLayout:layout duration:2.0];
    } else {
        [popup showWithLayout:layout];
    }
    self.popup = popup;
}


- (void)dismissButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIView class]]) {
        [self.popup dismiss:YES];
        self.popup = nil;
    }
}


- (void)fieldCancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - Private

- (void)updateFieldTableView:(UITableView*)tableView
{
    if (tableView != nil) {
        NSInteger fieldTag = tableView.tag;
        NSInteger selectedRow = [self selectedRowForFieldWithTag:fieldTag];
        for (NSIndexPath *indexPath in [tableView indexPathsForVisibleRows]) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (cell != nil) {
                if (indexPath.row == selectedRow) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
        }
    }
}


- (NSInteger)valueForRow:(NSInteger)row inFieldWithTag:(NSInteger)tag
{
    NSArray *listForField = nil;
    if (tag == FieldTagHorizontalLayout) {
        listForField =  self.horizontalLayouts;
        
    } else if (tag == FieldTagVerticalLayout) {
        listForField =  self.verticalLayouts;
        
    } else if (tag == FieldTagMaskType) {
        listForField =  self.maskTypes;
        
    } else if (tag == FieldTagShowType) {
        listForField =  self.showTypes;
        
    } else if (tag == FieldTagDismissType) {
        listForField =  self.dismissTypes;
    }
    
    // If row is out of bounds, try using first row.
    if (row >= listForField.count) {
        row = 0;
    }
    if (row < listForField.count) {
        id obj = [listForField objectAtIndex:row];
        if ([obj isKindOfClass:[NSNumber class]]) {
            return [(NSNumber*)obj integerValue];
        }
    }
    return 0;
}


- (NSInteger)selectedRowForFieldWithTag:(NSInteger)tag
{
    if (tag == FieldTagHorizontalLayout) {
        return  self.selectedRowInHorizontalField;
        
    } else if (tag == FieldTagVerticalLayout) {
        return  self.selectedRowInVerticalField;
        
    } else if (tag == FieldTagMaskType) {
        return  self.selectedRowInMaskField;
        
    } else if (tag == FieldTagShowType) {
        return  self.selectedRowInShowField;
        
    } else if (tag == FieldTagDismissType) {
        return  self.selectedRowInDismissField;
    }
    return NSNotFound;
}


- (NSString*)nameForValue:(NSInteger)value inFieldWithTag:(NSInteger)tag
{
    
    NSDictionary *namesForField = nil;
    if (tag == FieldTagHorizontalLayout) {
        namesForField =  self.namesForHorizontalLayouts;
        
    } else if (tag == FieldTagVerticalLayout) {
        namesForField =  self.namesForVerticalLayouts;
        
    } else if (tag == FieldTagMaskType) {
        namesForField =  self.namesForMaskTypes;
        
    } else if (tag == FieldTagShowType) {
        namesForField =  self.namesForShowTypes;
        
    } else if (tag == FieldTagDismissType) {
        namesForField =  self.namesForDismissTypes;
    }
    
    if (namesForField != nil) {
        return [namesForField objectForKey:@(value)];
    }
    return nil;
}


- (CellType)cellTypeForFieldWithTag:(NSInteger)tag
{
    CellType cellType;
    switch (tag) {
        case FieldTagHorizontalLayout:
            cellType = CellTypeNormal;
            break;
        case FieldTagVerticalLayout:
            cellType = CellTypeNormal;
            break;
        case FieldTagMaskType:
            cellType = CellTypeNormal;
            break;
        case FieldTagShowType:
            cellType = CellTypeNormal;
            break;
        case FieldTagDismissType:
            cellType = CellTypeNormal;
            break;
        case FieldTagBackgroundDismiss:
            cellType = CellTypeSwitch;
            break;
        case FieldTagContentDismiss:
            cellType = CellTypeSwitch;
            break;
        case FieldTagTimedDismiss:
            cellType = CellTypeSwitch;
            break;
        default:
            cellType = CellTypeNormal;
            break;
    }
    return cellType;
}


#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // MAIN TABLE
    if (tableView == self.tableView) {
        return  self.fields.count;
    }
    // FIELD TABLES
    else {
        if (tableView.tag == FieldTagHorizontalLayout) {
            return  self.horizontalLayouts.count;
            
        } else if (tableView.tag == FieldTagVerticalLayout) {
            return  self.verticalLayouts.count;
            
        } else if (tableView.tag == FieldTagMaskType) {
            return  self.maskTypes.count;
            
        } else if (tableView.tag == FieldTagShowType) {
            return  self.showTypes.count;
            
        } else if (tableView.tag == FieldTagDismissType) {
            return  self.dismissTypes.count;
        }
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // MAIN TABLE
    if (tableView == self.tableView) {
        
        id obj = [ self.fields objectAtIndex:indexPath.row];
        if ([obj isKindOfClass:[NSNumber class]]) {
            FieldTag fieldTag = [(NSNumber*)obj integerValue];
            
            UITableViewCell *cell = nil;
            CellType cellType = [self cellTypeForFieldWithTag:fieldTag];
            
            NSString *identifier = @"";
            if (cellType == CellTypeNormal) {
                identifier = @"normal";
            } else if (cellType == CellTypeSwitch) {
                identifier = @"switch";
            }
            
            cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            
            if (nil == cell) {
                UITableViewCellStyle style = UITableViewCellStyleValue1;
                cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:identifier];
                UIEdgeInsets newSeparatorInset = cell.separatorInset;
                newSeparatorInset.right = newSeparatorInset.left;
                cell.separatorInset = newSeparatorInset;
                
                if (cellType == CellTypeNormal) {
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    
                } else if (cellType == CellTypeSwitch) {
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    UISwitch *toggle = [[UISwitch alloc] init];
                    toggle.onTintColor = [UIColor lightGrayColor];
                    [toggle addTarget:self action:@selector(toggleValueDidChange:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = toggle;
                }
            }
            
            cell.textLabel.text = [ self.namesForFields objectForKey:@(fieldTag)];
            
            // populate Normal cell
            if (cellType == CellTypeNormal) {
                NSInteger selectedRowInField = [self selectedRowForFieldWithTag:fieldTag];
                if (selectedRowInField != NSNotFound) {
                    cell.detailTextLabel.text = [self nameForValue:[self valueForRow:selectedRowInField inFieldWithTag:fieldTag] inFieldWithTag:fieldTag];
                }
            }
            // populate Switch cell
            else if (cellType == CellTypeSwitch) {
                if ([cell.accessoryView isKindOfClass:[UISwitch class]]) {
                    BOOL on = NO;
                    if (fieldTag == FieldTagBackgroundDismiss) {
                        on =  self.shouldDismissOnBackgroundTouch;
                    } else if (fieldTag == FieldTagContentDismiss) {
                        on =  self.shouldDismissOnContentTouch;
                    } else if (fieldTag == FieldTagTimedDismiss) {
                        on =  self.shouldDismissAfterDelay;
                    }
                    [(UISwitch*)cell.accessoryView setOn:on];
                }
            }
            
            return cell;
        }
    }
    
    // FIELD TABLES
    else {
        
        UITableViewCell *cell = nil;
        
        Class cellClass = [UITableViewCell class];
        NSString *identifier = NSStringFromClass(cellClass);
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (nil == cell) {
            UITableViewCellStyle style = UITableViewCellStyleDefault;
            cell = [[cellClass alloc] initWithStyle:style reuseIdentifier:identifier];
            UIEdgeInsets newSeparatorInset = cell.separatorInset;
            newSeparatorInset.right = newSeparatorInset.left;
            cell.separatorInset = newSeparatorInset;
        }
        
        NSInteger fieldTag = tableView.tag;
        
        cell.textLabel.text = [self nameForValue:[self valueForRow:indexPath.row inFieldWithTag:fieldTag] inFieldWithTag:fieldTag];
        
        if (indexPath.row == [self selectedRowForFieldWithTag:fieldTag]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        return cell;
    }
    
    return nil;
}


#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // MAIN TABLE
    if (tableView == self.tableView) {
        
        id obj = [ self.fields objectAtIndex:indexPath.row];
        if ([obj isKindOfClass:[NSNumber class]]) {
            NSInteger fieldTag = [(NSNumber*)obj integerValue];
            
            if ([self cellTypeForFieldWithTag:fieldTag] == CellTypeNormal) {
                
                UIViewController *fieldController = [[UIViewController alloc] init];
                
                UITableView *fieldTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
                fieldTableView.delegate = self;
                fieldTableView.dataSource = self;
                fieldTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
                fieldTableView.tag = fieldTag;
                fieldController.view = fieldTableView;
                
                // IPAD
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    
                    // Present in a popover
                    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:fieldController];
                    popover.delegate = self;
                    self.popover = popover;
                    
                    // Set KVO so we can adjust the popover's size to fit the table's content once it's populated.
                    [fieldTableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
                    
                    CGRect senderFrameInView = [self.tableView convertRect:[self.tableView rectForRowAtIndexPath:indexPath] toView:self.view];
                    [popover presentPopoverFromRect:senderFrameInView inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                }
                
                // IPHONE
                else {
                    
                    // Present in a modal
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    fieldController.title = cell.textLabel.text;
                    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(fieldCancelButtonPressed:)];
                    fieldController.navigationItem.rightBarButtonItem = cancelButton;
                    
                    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:fieldController];
                    navigationController.delegate = self;
                    [self presentViewController:navigationController animated:YES completion:NULL];
                }
            }
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    // FIELD TABLES
    else {
        
        if (tableView.tag == FieldTagHorizontalLayout) {
             self.selectedRowInHorizontalField = indexPath.row;
            
        } else if (tableView.tag == FieldTagVerticalLayout) {
             self.selectedRowInVerticalField = indexPath.row;
            
        } else if (tableView.tag == FieldTagMaskType) {
             self.selectedRowInMaskField = indexPath.row;
            
        } else if (tableView.tag == FieldTagShowType) {
             self.selectedRowInShowField = indexPath.row;
            
        } else if (tableView.tag == FieldTagDismissType) {
             self.selectedRowInDismissField = indexPath.row;
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [self updateFieldTableView:tableView];
        
        [self.tableView reloadData];
        
        // IPAD
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self.popover dismissPopoverAnimated:YES];
        }
        // IPHONE
        else {
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
    }
}

#pragma mark - <UINavigationControllerDelegate>

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    // If this is a field table, make sure the selected row is scrolled into view when it appears.
    if ((navigationController == self.presentedViewController) && [viewController.view isKindOfClass:[UITableView class]]) {
        
        UITableView *fieldTableView = (UITableView*)viewController.view;
        
        NSInteger selectedRow = [self selectedRowForFieldWithTag:fieldTableView.tag];
        if ([fieldTableView numberOfRowsInSection:0] > selectedRow) {
            [fieldTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
    }
}


#pragma mark - <UIPopoverControllerDelegate>

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    
    // Cleanup by removing KVO and reference to popover
    UIView *view = popoverController.contentViewController.view;
    if ([view isKindOfClass:[UITableView class]]) {
        [(UITableView*)view removeObserver:self forKeyPath:@"contentSize"];
    }
    
    self.popover = nil;
}


#pragma mark - <NSKeyValueObserving>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"contentSize"]) {
        
        if ([object isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView*)object;
            if (self.popover != nil) {
                [self.popover setPopoverContentSize:tableView.contentSize animated:NO];
            }
            // Make sure the selected row is scrolled into view when it appears
            NSInteger fieldTag = tableView.tag;
            NSInteger selectedRow = [self selectedRowForFieldWithTag:fieldTag];
            
            if ([tableView numberOfRowsInSection:0] > selectedRow) {
                [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
            }
        }
    }
}
@end





