//
//  ViewController.m
//  iHubMobile
//
//  Created by 王竞然 on 2026/3/16.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

typedef void (^IHActionHandler)(void);

static UIColor *IHColor(NSUInteger hexValue, CGFloat alpha) {
    CGFloat red = ((hexValue >> 16) & 0xFF) / 255.0;
    CGFloat green = ((hexValue >> 8) & 0xFF) / 255.0;
    CGFloat blue = (hexValue & 0xFF) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

static UIFont *IHRoundedFont(CGFloat size, UIFontWeight weight) {
    UIFont *baseFont = [UIFont systemFontOfSize:size weight:weight];
    UIFontDescriptor *roundedDescriptor = [baseFont.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    if (roundedDescriptor != nil) {
        return [UIFont fontWithDescriptor:roundedDescriptor size:size];
    }
    return baseFont;
}

static UILabel *IHLabel(NSString *text, UIFont *font, UIColor *color, NSInteger lines) {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    return label;
}

static UIStackView *IHStack(UILayoutConstraintAxis axis, CGFloat spacing) {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = axis;
    stack.spacing = spacing;
    return stack;
}

static UIImageView *IHIconView(NSString *symbolName, CGFloat pointSize, UIColor *tintColor) {
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:pointSize weight:UIImageSymbolWeightSemibold];
    UIImage *image = [UIImage systemImageNamed:symbolName withConfiguration:configuration];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.tintColor = tintColor;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

static void IHApplyCardStyle(UIView *view) {
    view.layer.cornerRadius = 28.0;
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.12].CGColor;
    view.layer.shadowOpacity = 1.0;
    view.layer.shadowRadius = 24.0;
    view.layer.shadowOffset = CGSizeMake(0.0, 12.0);
}

@interface IHGradientView : UIView

- (instancetype)initWithColors:(NSArray<UIColor *> *)colors startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;

@property (nonatomic, copy) NSArray<UIColor *> *colors;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint endPoint;

@end

@implementation IHGradientView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (instancetype)initWithColors:(NSArray<UIColor *> *)colors startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.colors = colors;
        self.startPoint = startPoint;
        self.endPoint = endPoint;
        self.layer.cornerRadius = 32.0;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.masksToBounds = YES;
        [self refreshGradient];
    }
    return self;
}

- (void)setColors:(NSArray<UIColor *> *)colors {
    _colors = [colors copy];
    [self refreshGradient];
}

- (void)refreshGradient {
    CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:self.colors.count];
    for (UIColor *color in self.colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    gradientLayer.colors = cgColors;
    gradientLayer.startPoint = self.startPoint;
    gradientLayer.endPoint = self.endPoint;
}

@end

@interface IHubPageViewController : UIViewController

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;

- (UIView *)sectionHeaderWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
- (UIView *)cardView;
- (UIView *)pillViewWithTitle:(NSString *)title symbol:(NSString *)symbol tint:(UIColor *)tintColor backgroundColor:(UIColor *)backgroundColor;
- (UIScrollView *)horizontalScrollWithViews:(NSArray<UIView *> *)views height:(CGFloat)height spacing:(CGFloat)spacing;
- (UIButton *)filledButtonWithTitle:(NSString *)title symbol:(NSString *)symbol tint:(UIColor *)tintColor handler:(IHActionHandler)handler;
- (UIView *)progressBarWithProgress:(CGFloat)progress tint:(UIColor *)tintColor;
- (UIView *)metricCardWithValue:(NSString *)value title:(NSString *)title tint:(UIColor *)tintColor;
- (UIView *)listRowWithSymbol:(NSString *)symbol tint:(UIColor *)tintColor title:(NSString *)title subtitle:(NSString *)subtitle;
- (void)showMockAlertWithTitle:(NSString *)title message:(NSString *)message;

@end

@implementation IHubPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = IHColor(0xF5F7FB, 1.0);
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.backgroundColor = UIColor.clearColor;

    self.contentStack = IHStack(UILayoutConstraintAxisVertical, 24.0);
    self.contentStack.alignment = UIStackViewAlignmentFill;

    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentStack];

    UILayoutGuide *contentGuide = self.scrollView.contentLayoutGuide;
    UILayoutGuide *frameGuide = self.scrollView.frameLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentStack.topAnchor constraintEqualToAnchor:contentGuide.topAnchor constant:14.0],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:frameGuide.leadingAnchor constant:20.0],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:frameGuide.trailingAnchor constant:-20.0],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:contentGuide.bottomAnchor constant:-36.0],
    ]];
}

- (UIView *)sectionHeaderWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 6.0);
    [stack addArrangedSubview:IHLabel(title, IHRoundedFont(24.0, UIFontWeightBold), UIColor.labelColor, 1)];
    if (subtitle.length > 0) {
        [stack addArrangedSubview:IHLabel(subtitle, [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];
    }
    return stack;
}

- (UIView *)cardView {
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    IHApplyCardStyle(card);
    return card;
}

- (UIView *)pillViewWithTitle:(NSString *)title symbol:(NSString *)symbol tint:(UIColor *)tintColor backgroundColor:(UIColor *)backgroundColor {
    UIView *pill = [[UIView alloc] init];
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    pill.backgroundColor = backgroundColor;
    pill.layer.cornerRadius = 18.0;
    pill.layer.cornerCurve = kCACornerCurveContinuous;

    UIStackView *content = IHStack(UILayoutConstraintAxisHorizontal, 8.0);
    content.alignment = UIStackViewAlignmentCenter;
    [pill addSubview:content];

    if (symbol.length > 0) {
        UIImageView *icon = IHIconView(symbol, 12.0, tintColor);
        [icon.widthAnchor constraintEqualToConstant:14.0].active = YES;
        [icon.heightAnchor constraintEqualToConstant:14.0].active = YES;
        [content addArrangedSubview:icon];
    }

    [content addArrangedSubview:IHLabel(title, [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold], tintColor, 1)];

    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:12.0],
        [content.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-12.0],
        [content.topAnchor constraintEqualToAnchor:pill.topAnchor constant:9.0],
        [content.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-9.0],
    ]];

    return pill;
}

- (UIScrollView *)horizontalScrollWithViews:(NSArray<UIView *> *)views height:(CGFloat)height spacing:(CGFloat)spacing {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.clipsToBounds = NO;
    [scrollView.heightAnchor constraintEqualToConstant:height].active = YES;

    UIStackView *stack = IHStack(UILayoutConstraintAxisHorizontal, spacing);
    stack.alignment = UIStackViewAlignmentFill;

    [scrollView addSubview:stack];

    for (UIView *view in views) {
        [stack addArrangedSubview:view];
    }

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [stack.heightAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.heightAnchor],
    ]];

    return scrollView;
}

- (UIButton *)filledButtonWithTitle:(NSString *)title symbol:(NSString *)symbol tint:(UIColor *)tintColor handler:(IHActionHandler)handler {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;

    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.baseBackgroundColor = tintColor;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.image = [UIImage systemImageNamed:symbol];
    configuration.imagePadding = 8.0;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(12.0, 18.0, 12.0, 18.0);
    configuration.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey,id> * _Nonnull(NSDictionary<NSAttributedStringKey,id> * _Nonnull incoming) {
        NSMutableDictionary *attributes = [incoming mutableCopy];
        attributes[NSFontAttributeName] = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        return attributes;
    };
    button.configuration = configuration;

    if (handler != nil) {
        [button addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            handler();
        }] forControlEvents:UIControlEventTouchUpInside];
    }

    return button;
}

- (UIView *)progressBarWithProgress:(CGFloat)progress tint:(UIColor *)tintColor {
    UIView *track = [[UIView alloc] init];
    track.translatesAutoresizingMaskIntoConstraints = NO;
    track.backgroundColor = IHColor(0xE6EAF4, 1.0);
    track.layer.cornerRadius = 4.0;
    track.layer.cornerCurve = kCACornerCurveContinuous;
    [track.heightAnchor constraintEqualToConstant:8.0].active = YES;

    UIView *fill = [[UIView alloc] init];
    fill.translatesAutoresizingMaskIntoConstraints = NO;
    fill.backgroundColor = tintColor;
    fill.layer.cornerRadius = 4.0;
    fill.layer.cornerCurve = kCACornerCurveContinuous;
    [track addSubview:fill];

    [NSLayoutConstraint activateConstraints:@[
        [fill.leadingAnchor constraintEqualToAnchor:track.leadingAnchor],
        [fill.topAnchor constraintEqualToAnchor:track.topAnchor],
        [fill.bottomAnchor constraintEqualToAnchor:track.bottomAnchor],
        [fill.widthAnchor constraintEqualToAnchor:track.widthAnchor multiplier:MAX(MIN(progress, 1.0), 0.0)],
    ]];

    return track;
}

- (UIView *)metricCardWithValue:(NSString *)value title:(NSString *)title tint:(UIColor *)tintColor {
    UIView *card = [self cardView];
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.85];

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 4.0);
    [card addSubview:stack];
    [stack addArrangedSubview:IHLabel(value, IHRoundedFont(26.0, UIFontWeightBold), tintColor, 1)];
    [stack addArrangedSubview:IHLabel(title, [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium], UIColor.secondaryLabelColor, 0)];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

- (UIView *)listRowWithSymbol:(NSString *)symbol tint:(UIColor *)tintColor title:(NSString *)title subtitle:(NSString *)subtitle {
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *iconBackground = [[UIView alloc] init];
    iconBackground.translatesAutoresizingMaskIntoConstraints = NO;
    iconBackground.backgroundColor = [tintColor colorWithAlphaComponent:0.14];
    iconBackground.layer.cornerRadius = 18.0;
    iconBackground.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *icon = IHIconView(symbol, 15.0, tintColor);
    [iconBackground addSubview:icon];

    UIStackView *textStack = IHStack(UILayoutConstraintAxisVertical, 4.0);
    [textStack addArrangedSubview:IHLabel(title, [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold], UIColor.labelColor, 1)];
    [textStack addArrangedSubview:IHLabel(subtitle, [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];

    UIImageView *chevron = IHIconView(@"chevron.right", 13.0, UIColor.tertiaryLabelColor);

    UIStackView *rowStack = IHStack(UILayoutConstraintAxisHorizontal, 14.0);
    rowStack.alignment = UIStackViewAlignmentCenter;
    [rowStack addArrangedSubview:iconBackground];
    [rowStack addArrangedSubview:textStack];
    [rowStack addArrangedSubview:chevron];
    [row addSubview:rowStack];

    [iconBackground.widthAnchor constraintEqualToConstant:36.0].active = YES;
    [iconBackground.heightAnchor constraintEqualToConstant:36.0].active = YES;
    [icon.centerXAnchor constraintEqualToAnchor:iconBackground.centerXAnchor].active = YES;
    [icon.centerYAnchor constraintEqualToAnchor:iconBackground.centerYAnchor].active = YES;
    [icon.widthAnchor constraintEqualToConstant:18.0].active = YES;
    [icon.heightAnchor constraintEqualToConstant:18.0].active = YES;

    [NSLayoutConstraint activateConstraints:@[
        [rowStack.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [rowStack.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [rowStack.topAnchor constraintEqualToAnchor:row.topAnchor],
        [rowStack.bottomAnchor constraintEqualToAnchor:row.bottomAnchor],
    ]];

    return row;
}

- (void)showMockAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

@interface IHubHomeViewController : IHubPageViewController
@end

@interface IHubLearningViewController : IHubPageViewController
@end

@interface IHubCommunityViewController : IHubPageViewController
@end

@interface IHubProfileViewController : IHubPageViewController
@end

@implementation IHubHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";

    [self.contentStack addArrangedSubview:[self buildEditorialIntro]];
    [self.contentStack addArrangedSubview:[self buildHeroCard]];
    [self.contentStack addArrangedSubview:[self buildHeroHighlights]];
    [self.contentStack addArrangedSubview:[self buildSearchBar]];
    [self.contentStack addArrangedSubview:[self sectionHeaderWithTitle:@"探索方向" subtitle:@"从视频课、导师直播到项目实战，把学习路径做得更像一场精心编排的体验。"]];
    [self.contentStack addArrangedSubview:[self buildTopicScroller]];
    [self.contentStack addArrangedSubview:[self sectionHeaderWithTitle:@"编辑精选" subtitle:@"强内容先占据视线，剩下的交给清晰的层次、节奏和细节质感。"]];
    [self.contentStack addArrangedSubview:[self buildFeaturedCourses]];
    [self.contentStack addArrangedSubview:[self buildLiveClassCard]];
    [self.contentStack addArrangedSubview:[self buildCommunityHighlightCard]];
}

- (UIView *)buildEditorialIntro {
    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 12.0);
    [stack addArrangedSubview:[self pillViewWithTitle:@"IHub Learning · Spring 2026" symbol:@"sparkles" tint:IHColor(0x315CEB, 1.0) backgroundColor:IHColor(0xECF2FF, 1.0)]];

    UILabel *headline = IHLabel(@"把课程、社区和成长\n做成一场持续发生的体验", [UIFont systemFontOfSize:37.0 weight:UIFontWeightHeavy], UIColor.labelColor, 0);
    [stack addArrangedSubview:headline];
    [stack addArrangedSubview:IHLabel(@"首页不再只是一个课程列表，而是更像 App Store 式的内容舞台。先被吸引，再迅速进入学习。", [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];

    UIStackView *metrics = IHStack(UILayoutConstraintAxisHorizontal, 10.0);
    metrics.alignment = UIStackViewAlignmentCenter;
    [metrics addArrangedSubview:[self pillViewWithTitle:@"300+ 精品课" symbol:@"play.rectangle.fill" tint:IHColor(0x315CEB, 1.0) backgroundColor:IHColor(0xECF2FF, 1.0)]];
    [metrics addArrangedSubview:[self pillViewWithTitle:@"今晚 20:00 直播" symbol:@"video.fill" tint:IHColor(0xFF7A49, 1.0) backgroundColor:IHColor(0xFFF1EA, 1.0)]];
    [stack addArrangedSubview:[self horizontalScrollWithViews:@[metrics] height:42.0 spacing:0.0]];

    return stack;
}

- (UIView *)buildSearchBar {
    UIView *searchBar = [self cardView];
    searchBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.94];
    searchBar.layer.shadowColor = IHColor(0x1A2F8F, 0.08).CGColor;
    searchBar.layer.shadowOpacity = 1.0;
    searchBar.layer.shadowRadius = 18.0;
    searchBar.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    searchBar.layer.borderWidth = 1.0;
    searchBar.layer.borderColor = IHColor(0xE8EDF9, 1.0).CGColor;

    UIView *iconBackground = [[UIView alloc] init];
    iconBackground.translatesAutoresizingMaskIntoConstraints = NO;
    iconBackground.backgroundColor = IHColor(0xEDF2FF, 1.0);
    iconBackground.layer.cornerRadius = 18.0;
    iconBackground.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *icon = IHIconView(@"magnifyingglass", 15.0, IHColor(0x5272F2, 1.0));
    [iconBackground addSubview:icon];

    UILabel *placeholder = IHLabel(@"搜索课程、讲师、社区话题", [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold], UIColor.secondaryLabelColor, 1);

    UIView *askAIPill = [self pillViewWithTitle:@"问 AI" symbol:@"sparkles" tint:IHColor(0x315CEB, 1.0) backgroundColor:IHColor(0xECF2FF, 1.0)];

    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    filterButton.translatesAutoresizingMaskIntoConstraints = NO;
    filterButton.backgroundColor = IHColor(0x111D4A, 1.0);
    filterButton.layer.cornerRadius = 18.0;
    filterButton.layer.cornerCurve = kCACornerCurveContinuous;
    [filterButton addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [self showMockAlertWithTitle:@"搜索筛选" message:@"这里可以接课程分类、价格、难度、导师等筛选条件。"];
    }] forControlEvents:UIControlEventTouchUpInside];
    UIImageView *filterIcon = IHIconView(@"slider.horizontal.3", 14.0, UIColor.whiteColor);
    [filterButton addSubview:filterIcon];

    UIStackView *topRow = IHStack(UILayoutConstraintAxisHorizontal, 14.0);
    topRow.alignment = UIStackViewAlignmentCenter;
    [topRow addArrangedSubview:iconBackground];
    [topRow addArrangedSubview:placeholder];
    UIView *flex = [[UIView alloc] init];
    flex.translatesAutoresizingMaskIntoConstraints = NO;
    [topRow addArrangedSubview:flex];
    [topRow addArrangedSubview:askAIPill];
    [topRow addArrangedSubview:filterButton];

    UILabel *helper = IHLabel(@"试试：帮我找到适合零基础的 iOS 课程", [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium], UIColor.tertiaryLabelColor, 1);

    UIStackView *content = IHStack(UILayoutConstraintAxisVertical, 10.0);
    [content addArrangedSubview:topRow];
    [content addArrangedSubview:helper];
    [searchBar addSubview:content];

    [iconBackground.widthAnchor constraintEqualToConstant:36.0].active = YES;
    [iconBackground.heightAnchor constraintEqualToConstant:36.0].active = YES;
    [icon.centerXAnchor constraintEqualToAnchor:iconBackground.centerXAnchor].active = YES;
    [icon.centerYAnchor constraintEqualToAnchor:iconBackground.centerYAnchor].active = YES;
    [icon.widthAnchor constraintEqualToConstant:18.0].active = YES;
    [icon.heightAnchor constraintEqualToConstant:18.0].active = YES;

    [filterButton.widthAnchor constraintEqualToConstant:36.0].active = YES;
    [filterButton.heightAnchor constraintEqualToConstant:36.0].active = YES;
    [filterIcon.centerXAnchor constraintEqualToAnchor:filterButton.centerXAnchor].active = YES;
    [filterIcon.centerYAnchor constraintEqualToAnchor:filterButton.centerYAnchor].active = YES;
    [filterIcon.widthAnchor constraintEqualToConstant:18.0].active = YES;
    [filterIcon.heightAnchor constraintEqualToConstant:18.0].active = YES;
    [searchBar.heightAnchor constraintGreaterThanOrEqualToConstant:84.0].active = YES;

    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:searchBar.leadingAnchor constant:16.0],
        [content.trailingAnchor constraintEqualToAnchor:searchBar.trailingAnchor constant:-16.0],
        [content.topAnchor constraintEqualToAnchor:searchBar.topAnchor constant:15.0],
        [content.bottomAnchor constraintEqualToAnchor:searchBar.bottomAnchor constant:-15.0],
    ]];

    return searchBar;
}

- (UIView *)buildHeroCard {
    IHGradientView *hero = [[IHGradientView alloc] initWithColors:@[
        IHColor(0x0B1337, 1.0),
        IHColor(0x1A3DBD, 1.0),
        IHColor(0x4D8EFF, 1.0),
        IHColor(0x6DD3FF, 1.0)
    ] startPoint:CGPointMake(0.0, 0.0) endPoint:CGPointMake(1.0, 1.0)];
    hero.layer.shadowColor = IHColor(0x2449D8, 0.32).CGColor;
    hero.layer.shadowOpacity = 1.0;
    hero.layer.shadowRadius = 34.0;
    hero.layer.shadowOffset = CGSizeMake(0.0, 22.0);
    [hero.heightAnchor constraintEqualToConstant:392.0].active = YES;

    UIView *orbOne = [self heroOrbWithColor:[UIColor colorWithWhite:1.0 alpha:0.16] size:182.0];
    UIView *orbTwo = [self heroOrbWithColor:IHColor(0x9DE6FF, 0.18) size:138.0];
    UIView *orbThree = [self heroOrbWithColor:IHColor(0x5C88FF, 0.18) size:108.0];
    [hero addSubview:orbOne];
    [hero addSubview:orbTwo];
    [hero addSubview:orbThree];

    [NSLayoutConstraint activateConstraints:@[
        [orbOne.topAnchor constraintEqualToAnchor:hero.topAnchor constant:-54.0],
        [orbOne.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:48.0],
        [orbTwo.bottomAnchor constraintEqualToAnchor:hero.bottomAnchor constant:26.0],
        [orbTwo.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:-24.0],
        [orbThree.topAnchor constraintEqualToAnchor:hero.topAnchor constant:120.0],
        [orbThree.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-46.0],
    ]];

    UIStackView *content = IHStack(UILayoutConstraintAxisVertical, 18.0);
    [hero addSubview:content];

    UIView *labelPill = [self pillViewWithTitle:@"主视觉 · 今日必看" symbol:@"sparkles" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.18]];

    UIButton *bookmarkButton = [UIButton buttonWithType:UIButtonTypeSystem];
    bookmarkButton.translatesAutoresizingMaskIntoConstraints = NO;
    bookmarkButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.16];
    bookmarkButton.layer.cornerRadius = 20.0;
    bookmarkButton.layer.cornerCurve = kCACornerCurveContinuous;
    [bookmarkButton addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [self showMockAlertWithTitle:@"已加入收藏" message:@"课程已保存到“我的收藏”，后续可以接入真实收藏逻辑。"];
    }] forControlEvents:UIControlEventTouchUpInside];
    UIImageView *bookmarkIcon = IHIconView(@"bookmark.fill", 15.0, UIColor.whiteColor);
    [bookmarkButton addSubview:bookmarkIcon];

    UIView *topFiller = [[UIView alloc] init];
    topFiller.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *topRow = IHStack(UILayoutConstraintAxisHorizontal, 12.0);
    topRow.alignment = UIStackViewAlignmentCenter;
    [topRow addArrangedSubview:labelPill];
    [topRow addArrangedSubview:topFiller];
    [topRow addArrangedSubview:bookmarkButton];

    [bookmarkButton.widthAnchor constraintEqualToConstant:40.0].active = YES;
    [bookmarkButton.heightAnchor constraintEqualToConstant:40.0].active = YES;
    [bookmarkIcon.centerXAnchor constraintEqualToAnchor:bookmarkButton.centerXAnchor].active = YES;
    [bookmarkIcon.centerYAnchor constraintEqualToAnchor:bookmarkButton.centerYAnchor].active = YES;
    [bookmarkIcon.widthAnchor constraintEqualToConstant:18.0].active = YES;
    [bookmarkIcon.heightAnchor constraintEqualToConstant:18.0].active = YES;

    [content addArrangedSubview:topRow];
    [content addArrangedSubview:IHLabel(@"今晚，把下一次跃迁\n学得更具体一点", [UIFont systemFontOfSize:38.0 weight:UIFontWeightHeavy], UIColor.whiteColor, 0)];
    [content addArrangedSubview:IHLabel(@"把视频课、导师直播、作品互评和学习伙伴连接成一个更有张力的首页。先被打动，再自然进入学习状态。", [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium], [UIColor colorWithWhite:1.0 alpha:0.84], 0)];

    UIStackView *metaRow = IHStack(UILayoutConstraintAxisHorizontal, 10.0);
    metaRow.alignment = UIStackViewAlignmentCenter;
    [metaRow addArrangedSubview:[self pillViewWithTitle:@"12h 40m 视频" symbol:@"play.rectangle.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.16]]];
    [metaRow addArrangedSubview:[self pillViewWithTitle:@"126 人预约直播" symbol:@"person.2.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.16]]];
    [metaRow addArrangedSubview:[self pillViewWithTitle:@"社区共学中" symbol:@"bubble.left.and.bubble.right.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.16]]];
    [content addArrangedSubview:[self horizontalScrollWithViews:@[metaRow] height:40.0 spacing:0.0]];

    __weak typeof(self) weakSelf = self;
    UIButton *continueButton = [self filledButtonWithTitle:@"继续观看" symbol:@"play.fill" tint:IHColor(0x121B43, 1.0) handler:^{
        [weakSelf showMockAlertWithTitle:@"播放课程" message:@"这里可以接入课程详情页、视频播放器和学习进度同步。"];
    }];

    UIView *bottomGlass = [[UIView alloc] init];
    bottomGlass.translatesAutoresizingMaskIntoConstraints = NO;
    bottomGlass.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.14];
    bottomGlass.layer.cornerRadius = 22.0;
    bottomGlass.layer.cornerCurve = kCACornerCurveContinuous;

    UIStackView *glassLayout = IHStack(UILayoutConstraintAxisHorizontal, 14.0);
    glassLayout.alignment = UIStackViewAlignmentCenter;
    [bottomGlass addSubview:glassLayout];

    UIStackView *glassLeft = IHStack(UILayoutConstraintAxisVertical, 12.0);
    [glassLeft addArrangedSubview:[self pillViewWithTitle:@"今晚重点" symbol:@"bolt.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.14]]];
    [glassLeft addArrangedSubview:IHLabel(@"从 0 到 1 打造 AI 产品", [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold], UIColor.whiteColor, 2)];
    [glassLeft addArrangedSubview:IHLabel(@"已学习 2h 18m · 完成度 68% · 还剩 3 个项目练习", [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium], [UIColor colorWithWhite:1.0 alpha:0.84], 0)];
    [glassLeft addArrangedSubview:[self progressBarWithProgress:0.68 tint:UIColor.whiteColor]];
    [glassLeft addArrangedSubview:continueButton];

    UIView *spotlightPanel = [[UIView alloc] init];
    spotlightPanel.translatesAutoresizingMaskIntoConstraints = NO;
    spotlightPanel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.14];
    spotlightPanel.layer.cornerRadius = 22.0;
    spotlightPanel.layer.cornerCurve = kCACornerCurveContinuous;
    [spotlightPanel.widthAnchor constraintEqualToConstant:128.0].active = YES;

    UIStackView *spotlightStack = IHStack(UILayoutConstraintAxisVertical, 8.0);
    [spotlightPanel addSubview:spotlightStack];
    [spotlightStack addArrangedSubview:IHLabel(@"01", [UIFont systemFontOfSize:34.0 weight:UIFontWeightHeavy], UIColor.whiteColor, 1)];
    [spotlightStack addArrangedSubview:IHLabel(@"本周焦点", [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold], [UIColor colorWithWhite:1.0 alpha:0.76], 1)];
    [spotlightStack addArrangedSubview:IHLabel(@"留存设计", [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold], UIColor.whiteColor, 1)];
    [spotlightStack addArrangedSubview:[self pillViewWithTitle:@"Live" symbol:@"waveform" tint:IHColor(0x111C47, 1.0) backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.94]]];

    [glassLayout addArrangedSubview:glassLeft];
    [glassLayout addArrangedSubview:spotlightPanel];
    [content addArrangedSubview:bottomGlass];

    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:24.0],
        [content.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-24.0],
        [content.topAnchor constraintEqualToAnchor:hero.topAnchor constant:24.0],
        [content.bottomAnchor constraintEqualToAnchor:hero.bottomAnchor constant:-24.0],

        [glassLayout.leadingAnchor constraintEqualToAnchor:bottomGlass.leadingAnchor constant:16.0],
        [glassLayout.trailingAnchor constraintEqualToAnchor:bottomGlass.trailingAnchor constant:-16.0],
        [glassLayout.topAnchor constraintEqualToAnchor:bottomGlass.topAnchor constant:16.0],
        [glassLayout.bottomAnchor constraintEqualToAnchor:bottomGlass.bottomAnchor constant:-16.0],

        [spotlightStack.leadingAnchor constraintEqualToAnchor:spotlightPanel.leadingAnchor constant:14.0],
        [spotlightStack.trailingAnchor constraintEqualToAnchor:spotlightPanel.trailingAnchor constant:-14.0],
        [spotlightStack.topAnchor constraintEqualToAnchor:spotlightPanel.topAnchor constant:16.0],
        [spotlightStack.bottomAnchor constraintEqualToAnchor:spotlightPanel.bottomAnchor constant:-16.0],
    ]];

    return hero;
}

- (UIView *)buildHeroHighlights {
    NSArray<UIView *> *cards = @[
        [self secondaryHeroCardWithEyebrow:@"7 天速学计划" title:@"一周内完成一个真实作品" subtitle:@"每天 20 分钟，把课程、任务和打卡节奏穿在一起。" symbol:@"flame.fill" colors:@[IHColor(0x4E240A, 1.0), IHColor(0xFF7F3E, 1.0), IHColor(0xFFD08D, 1.0)]],
        [self secondaryHeroCardWithEyebrow:@"1v1 作品集诊所" title:@"作品集诊所本周开放预约" subtitle:@"导师会针对首页视觉、信息层级和交互体验给出逐条建议。" symbol:@"person.crop.circle.badge.checkmark" colors:@[IHColor(0x0F2D2A, 1.0), IHColor(0x0E8F7F, 1.0), IHColor(0x84E9D8, 1.0)]],
        [self secondaryHeroCardWithEyebrow:@"社区热议" title:@"社区最热正在讨论留存设计" subtitle:@"从教育产品的社区氛围到学习反馈机制，大家都在认真拆。" symbol:@"bubble.left.and.bubble.right.fill" colors:@[IHColor(0x24124A, 1.0), IHColor(0x7042FF, 1.0), IHColor(0xFFA4D8, 1.0)]],
    ];
    return [self horizontalScrollWithViews:cards height:178.0 spacing:16.0];
}

- (UIView *)secondaryHeroCardWithEyebrow:(NSString *)eyebrow title:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol colors:(NSArray<UIColor *> *)colors {
    IHGradientView *card = [[IHGradientView alloc] initWithColors:colors startPoint:CGPointMake(0.0, 0.0) endPoint:CGPointMake(1.0, 1.0)];
    [card.widthAnchor constraintEqualToConstant:282.0].active = YES;
    card.layer.cornerRadius = 28.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *icon = IHIconView(symbol, 36.0, [UIColor colorWithWhite:1.0 alpha:0.92]);
    [card addSubview:icon];
    [icon.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0].active = YES;
    [icon.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0].active = YES;
    [icon.widthAnchor constraintEqualToConstant:42.0].active = YES;
    [icon.heightAnchor constraintEqualToConstant:42.0].active = YES;

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 10.0);
    [stack addArrangedSubview:[self pillViewWithTitle:eyebrow symbol:@"sparkles" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.16]]];
    [stack addArrangedSubview:IHLabel(title, [UIFont systemFontOfSize:26.0 weight:UIFontWeightHeavy], UIColor.whiteColor, 0)];
    [stack addArrangedSubview:IHLabel(subtitle, [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium], [UIColor colorWithWhite:1.0 alpha:0.84], 0)];
    [card addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

- (UIView *)heroOrbWithColor:(UIColor *)color size:(CGFloat)size {
    UIView *orb = [[UIView alloc] init];
    orb.translatesAutoresizingMaskIntoConstraints = NO;
    orb.backgroundColor = color;
    orb.layer.cornerRadius = size / 2.0;
    orb.layer.cornerCurve = kCACornerCurveContinuous;
    [orb.widthAnchor constraintEqualToConstant:size].active = YES;
    [orb.heightAnchor constraintEqualToConstant:size].active = YES;
    return orb;
}

- (UIView *)buildTopicScroller {
    NSArray<UIView *> *items = @[
        [self pillViewWithTitle:@"iOS 开发" symbol:@"swift" tint:IHColor(0x2558E2, 1.0) backgroundColor:IHColor(0xEAF1FF, 1.0)],
        [self pillViewWithTitle:@"AI 产品" symbol:@"sparkles" tint:IHColor(0x6A4CFF, 1.0) backgroundColor:IHColor(0xF1ECFF, 1.0)],
        [self pillViewWithTitle:@"设计系统" symbol:@"square.grid.2x2.fill" tint:IHColor(0x00937A, 1.0) backgroundColor:IHColor(0xE8FBF4, 1.0)],
        [self pillViewWithTitle:@"增长运营" symbol:@"chart.line.uptrend.xyaxis" tint:IHColor(0xD65B23, 1.0) backgroundColor:IHColor(0xFFF1E8, 1.0)],
        [self pillViewWithTitle:@"数据分析" symbol:@"chart.bar.fill" tint:IHColor(0xB34FC3, 1.0) backgroundColor:IHColor(0xFBEFFD, 1.0)],
    ];
    return [self horizontalScrollWithViews:items height:42.0 spacing:12.0];
}

- (UIView *)buildFeaturedCourses {
    NSArray<UIView *> *courses = @[
        [self featuredCourseCardWithTitle:@"SwiftUI 动效实验室" mentor:@"主讲 · Yuki Han" summary:@"用真实 App 拆解滚动、转场、手势和细节动效。" symbol:@"wand.and.stars.inverse" badge:@"Best Seller" colors:@[IHColor(0x101C4C, 1.0), IHColor(0x375DEB, 1.0), IHColor(0x84D3FF, 1.0)] accent:IHColor(0x375DEB, 1.0)],
        [self featuredCourseCardWithTitle:@"产品经理的 AI 工作流" mentor:@"主讲 · Anita Xu" summary:@"从需求洞察、原型验证到指标复盘，做一套完整 AI PM 流程。" symbol:@"brain.head.profile" badge:@"New" colors:@[IHColor(0x2B1145, 1.0), IHColor(0x6A3CFF, 1.0), IHColor(0xFF7FD1, 1.0)] accent:IHColor(0x7A49FF, 1.0)],
        [self featuredCourseCardWithTitle:@"设计审美与视觉系统" mentor:@"主讲 · Leah Lin" summary:@"系统讲清 Apple 式界面层次、留白、动线与质感。" symbol:@"paintpalette.fill" badge:@"Editor Pick" colors:@[IHColor(0x113234, 1.0), IHColor(0x149B90, 1.0), IHColor(0xD0FFF4, 1.0)] accent:IHColor(0x129585, 1.0)],
    ];

    return [self horizontalScrollWithViews:courses height:274.0 spacing:18.0];
}

- (UIView *)featuredCourseCardWithTitle:(NSString *)title mentor:(NSString *)mentor summary:(NSString *)summary symbol:(NSString *)symbol badge:(NSString *)badge colors:(NSArray<UIColor *> *)colors accent:(UIColor *)accentColor {
    UIView *card = [self cardView];
    [card.widthAnchor constraintEqualToConstant:276.0].active = YES;

    IHGradientView *thumbnail = [[IHGradientView alloc] initWithColors:colors startPoint:CGPointMake(0.0, 0.0) endPoint:CGPointMake(1.0, 1.0)];
    thumbnail.layer.cornerRadius = 24.0;
    thumbnail.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *symbolView = IHIconView(symbol, 46.0, [UIColor colorWithWhite:1.0 alpha:0.95]);
    [thumbnail addSubview:symbolView];
    [symbolView.trailingAnchor constraintEqualToAnchor:thumbnail.trailingAnchor constant:-20.0].active = YES;
    [symbolView.bottomAnchor constraintEqualToAnchor:thumbnail.bottomAnchor constant:-18.0].active = YES;
    [symbolView.widthAnchor constraintEqualToConstant:54.0].active = YES;
    [symbolView.heightAnchor constraintEqualToConstant:54.0].active = YES;

    UIView *badgeView = [self pillViewWithTitle:badge symbol:@"star.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.18]];
    [thumbnail addSubview:badgeView];
    [badgeView.leadingAnchor constraintEqualToAnchor:thumbnail.leadingAnchor constant:14.0].active = YES;
    [badgeView.topAnchor constraintEqualToAnchor:thumbnail.topAnchor constant:14.0].active = YES;

    UIStackView *content = IHStack(UILayoutConstraintAxisVertical, 14.0);
    [card addSubview:thumbnail];
    [card addSubview:content];

    [content addArrangedSubview:IHLabel(title, IHRoundedFont(21.0, UIFontWeightBold), UIColor.labelColor, 2)];
    [content addArrangedSubview:IHLabel(mentor, [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold], UIColor.secondaryLabelColor, 1)];
    [content addArrangedSubview:IHLabel(summary, [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];

    UIStackView *footer = IHStack(UILayoutConstraintAxisHorizontal, 12.0);
    footer.alignment = UIStackViewAlignmentCenter;
    [footer addArrangedSubview:[self pillViewWithTitle:@"24 讲" symbol:@"play.circle.fill" tint:accentColor backgroundColor:[accentColor colorWithAlphaComponent:0.12]]];
    [footer addArrangedSubview:[self pillViewWithTitle:@"4.9 分" symbol:@"heart.fill" tint:IHColor(0xFF6F61, 1.0) backgroundColor:IHColor(0xFFF0ED, 1.0)]];
    [content addArrangedSubview:footer];

    [NSLayoutConstraint activateConstraints:@[
        [thumbnail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14.0],
        [thumbnail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14.0],
        [thumbnail.topAnchor constraintEqualToAnchor:card.topAnchor constant:14.0],
        [thumbnail.heightAnchor constraintEqualToConstant:126.0],

        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],
        [content.topAnchor constraintEqualToAnchor:thumbnail.bottomAnchor constant:16.0],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

- (UIView *)buildLiveClassCard {
    UIView *card = [self cardView];
    card.backgroundColor = IHColor(0x101A3D, 1.0);

    UIStackView *content = IHStack(UILayoutConstraintAxisVertical, 16.0);
    [card addSubview:content];

    [content addArrangedSubview:[self pillViewWithTitle:@"今晚直播 · 20:00" symbol:@"video.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.14]]];
    [content addArrangedSubview:IHLabel(@"和导师一起做一次真实项目复盘", IHRoundedFont(26.0, UIFontWeightBold), UIColor.whiteColor, 0)];
    [content addArrangedSubview:IHLabel(@"主题聚焦「在线教育 App 的留存设计」，会拆课程页、社区氛围和学习提醒机制。", [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], [UIColor colorWithWhite:1.0 alpha:0.78], 0)];

    UIStackView *stats = IHStack(UILayoutConstraintAxisHorizontal, 10.0);
    stats.alignment = UIStackViewAlignmentCenter;
    [stats addArrangedSubview:[self pillViewWithTitle:@"126 人已预约" symbol:@"person.2.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.14]]];
    [stats addArrangedSubview:[self pillViewWithTitle:@"含回放" symbol:@"arrow.triangle.2.circlepath.circle.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.14]]];
    [content addArrangedSubview:stats];

    __weak typeof(self) weakSelf = self;
    [content addArrangedSubview:[self filledButtonWithTitle:@"预约提醒" symbol:@"bell.fill" tint:IHColor(0x4A74FF, 1.0) handler:^{
        [weakSelf showMockAlertWithTitle:@"已预约直播" message:@"可以继续接入日历提醒、直播间入口和开播推送。"];
    }]];

    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20.0],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20.0],
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:22.0],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22.0],
    ]];

    return card;
}

- (UIView *)buildCommunityHighlightCard {
    UIView *card = [self cardView];

    UILabel *title = IHLabel(@"学习搭子社区", IHRoundedFont(23.0, UIFontWeightBold), UIColor.labelColor, 1);
    UILabel *subtitle = IHLabel(@"把看课变成一场有人陪伴的长期成长。可以打卡、提问、晒作品，也能参加作品互评。", [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0);

    UIStackView *avatars = IHStack(UILayoutConstraintAxisHorizontal, -10.0);
    avatars.alignment = UIStackViewAlignmentCenter;
    [avatars addArrangedSubview:[self circleAvatarWithText:@"A" background:IHColor(0x5B7CFA, 1.0)]];
    [avatars addArrangedSubview:[self circleAvatarWithText:@"M" background:IHColor(0x15AA91, 1.0)]];
    [avatars addArrangedSubview:[self circleAvatarWithText:@"Y" background:IHColor(0xFF8F53, 1.0)]];
    [avatars addArrangedSubview:[self circleAvatarWithText:@"Q" background:IHColor(0xA55AF3, 1.0)]];

    UIStackView *row = IHStack(UILayoutConstraintAxisHorizontal, 16.0);
    row.alignment = UIStackViewAlignmentCenter;

    UIStackView *left = IHStack(UILayoutConstraintAxisVertical, 10.0);
    [left addArrangedSubview:title];
    [left addArrangedSubview:subtitle];

    UIView *metrics = [[UIView alloc] init];
    metrics.translatesAutoresizingMaskIntoConstraints = NO;
    metrics.backgroundColor = IHColor(0xF5F8FF, 1.0);
    metrics.layer.cornerRadius = 22.0;
    metrics.layer.cornerCurve = kCACornerCurveContinuous;

    UIStackView *metricStack = IHStack(UILayoutConstraintAxisVertical, 10.0);
    [metrics addSubview:metricStack];
    [metricStack addArrangedSubview:avatars];
    [metricStack addArrangedSubview:IHLabel(@"本周新增 248 条互动", [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold], UIColor.labelColor, 1)];
    [metricStack addArrangedSubview:IHLabel(@"最热门：作品求点评、SwiftUI、AI 工作流", [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];

    [row addArrangedSubview:left];
    [row addArrangedSubview:metrics];
    [metrics.widthAnchor constraintEqualToConstant:176.0].active = YES;

    [card addSubview:row];

    __weak typeof(self) weakSelf = self;
    UIButton *communityButton = [self filledButtonWithTitle:@"进入社区" symbol:@"bubble.left.and.bubble.right.fill" tint:IHColor(0x111C47, 1.0) handler:^{
        [weakSelf showMockAlertWithTitle:@"社区入口" message:@"下一步可以补帖子详情、评论区、发帖编辑器和通知中心。"];
    }];
    [card addSubview:communityButton];

    [NSLayoutConstraint activateConstraints:@[
        [row.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [row.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [row.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],

        [communityButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [communityButton.topAnchor constraintEqualToAnchor:row.bottomAnchor constant:18.0],
        [communityButton.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],

        [metricStack.leadingAnchor constraintEqualToAnchor:metrics.leadingAnchor constant:14.0],
        [metricStack.trailingAnchor constraintEqualToAnchor:metrics.trailingAnchor constant:-14.0],
        [metricStack.topAnchor constraintEqualToAnchor:metrics.topAnchor constant:14.0],
        [metricStack.bottomAnchor constraintEqualToAnchor:metrics.bottomAnchor constant:-14.0],
    ]];

    return card;
}

- (UIView *)circleAvatarWithText:(NSString *)text background:(UIColor *)backgroundColor {
    UIView *avatar = [[UIView alloc] init];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    avatar.backgroundColor = backgroundColor;
    avatar.layer.cornerRadius = 18.0;
    avatar.layer.cornerCurve = kCACornerCurveContinuous;
    [avatar.widthAnchor constraintEqualToConstant:36.0].active = YES;
    [avatar.heightAnchor constraintEqualToConstant:36.0].active = YES;

    UILabel *label = IHLabel(text, IHRoundedFont(16.0, UIFontWeightBold), UIColor.whiteColor, 1);
    [avatar addSubview:label];
    [label.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor].active = YES;
    [label.centerYAnchor constraintEqualToAnchor:avatar.centerYAnchor].active = YES;

    return avatar;
}

@end

@implementation IHubLearningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"学习";

    [self.contentStack addArrangedSubview:[self buildProgressOverview]];
    [self.contentStack addArrangedSubview:[self sectionHeaderWithTitle:@"继续学习" subtitle:@"把最近在看的课程、剩余时长和完成度整合到一个地方。"]];
    [self.contentStack addArrangedSubview:[self buildContinueLearningSection]];
    [self.contentStack addArrangedSubview:[self sectionHeaderWithTitle:@"本周路径" subtitle:@"视频、练习和输出任务组合成一个更容易坚持的节奏。"]];
    [self.contentStack addArrangedSubview:[self buildRoadmapCard]];
    [self.contentStack addArrangedSubview:[self buildStudyRoomCard]];
}

- (UIView *)buildProgressOverview {
    UIView *card = [self cardView];
    card.backgroundColor = IHColor(0xF8FAFF, 1.0);

    UIView *circle = [[UIView alloc] init];
    circle.translatesAutoresizingMaskIntoConstraints = NO;
    circle.backgroundColor = IHColor(0x1F57EA, 1.0);
    circle.layer.cornerRadius = 54.0;
    circle.layer.cornerCurve = kCACornerCurveContinuous;

    UILabel *percent = IHLabel(@"68%", IHRoundedFont(34.0, UIFontWeightBold), UIColor.whiteColor, 1);
    UILabel *caption = IHLabel(@"本周完成", [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold], [UIColor colorWithWhite:1.0 alpha:0.82], 1);
    UIStackView *circleStack = IHStack(UILayoutConstraintAxisVertical, 4.0);
    circleStack.alignment = UIStackViewAlignmentCenter;
    [circleStack addArrangedSubview:percent];
    [circleStack addArrangedSubview:caption];
    [circle addSubview:circleStack];

    [circle.widthAnchor constraintEqualToConstant:108.0].active = YES;
    [circle.heightAnchor constraintEqualToConstant:108.0].active = YES;
    [circleStack.centerXAnchor constraintEqualToAnchor:circle.centerXAnchor].active = YES;
    [circleStack.centerYAnchor constraintEqualToAnchor:circle.centerYAnchor].active = YES;

    UIStackView *details = IHStack(UILayoutConstraintAxisVertical, 14.0);
    [details addArrangedSubview:IHLabel(@"你的学习节奏很好", IHRoundedFont(26.0, UIFontWeightBold), UIColor.labelColor, 0)];
    [details addArrangedSubview:IHLabel(@"距离本周目标还差 2 个视频章节和 1 次作业提交。", [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];

    UIStackView *barGroup = IHStack(UILayoutConstraintAxisVertical, 10.0);
    [barGroup addArrangedSubview:[self metricRowWithTitle:@"视频学习" value:@"8/10 节" progress:0.8 tint:IHColor(0x315CEB, 1.0)]];
    [barGroup addArrangedSubview:[self metricRowWithTitle:@"笔记整理" value:@"3/4 次" progress:0.75 tint:IHColor(0x17A288, 1.0)]];
    [barGroup addArrangedSubview:[self metricRowWithTitle:@"社区互动" value:@"5/6 次" progress:0.83 tint:IHColor(0xFF7A49, 1.0)]];
    [details addArrangedSubview:barGroup];

    UIStackView *layout = IHStack(UILayoutConstraintAxisHorizontal, 18.0);
    layout.alignment = UIStackViewAlignmentCenter;
    [layout addArrangedSubview:circle];
    [layout addArrangedSubview:details];
    [card addSubview:layout];

    [NSLayoutConstraint activateConstraints:@[
        [layout.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [layout.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [layout.topAnchor constraintEqualToAnchor:card.topAnchor constant:20.0],
        [layout.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20.0],
    ]];

    return card;
}

- (UIView *)metricRowWithTitle:(NSString *)title value:(NSString *)value progress:(CGFloat)progress tint:(UIColor *)tintColor {
    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 8.0);

    UIStackView *labelRow = IHStack(UILayoutConstraintAxisHorizontal, 12.0);
    [labelRow addArrangedSubview:IHLabel(title, [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold], UIColor.labelColor, 1)];
    UIView *flex = [[UIView alloc] init];
    flex.translatesAutoresizingMaskIntoConstraints = NO;
    [labelRow addArrangedSubview:flex];
    [labelRow addArrangedSubview:IHLabel(value, [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold], UIColor.secondaryLabelColor, 1)];

    [stack addArrangedSubview:labelRow];
    [stack addArrangedSubview:[self progressBarWithProgress:progress tint:tintColor]];
    return stack;
}

- (UIView *)buildContinueLearningSection {
    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 16.0);
    [stack addArrangedSubview:[self resumeCardWithTitle:@"在线教育 App 体验拆解" meta:@"第 12 节 · 还剩 18 分钟" symbol:@"iphone.gen3" colors:@[IHColor(0x18234F, 1.0), IHColor(0x3B61F5, 1.0)] progress:0.72]];
    [stack addArrangedSubview:[self resumeCardWithTitle:@"SwiftUI 手势与滚动进阶" meta:@"第 7 节 · 还剩 11 分钟" symbol:@"hand.tap.fill" colors:@[IHColor(0x2B133C, 1.0), IHColor(0x9A49FD, 1.0)] progress:0.46]];
    [stack addArrangedSubview:[self resumeCardWithTitle:@"AI PM 需求分析工作坊" meta:@"第 3 节 · 还剩 22 分钟" symbol:@"brain.head.profile" colors:@[IHColor(0x103535, 1.0), IHColor(0x11A692, 1.0)] progress:0.28]];
    return stack;
}

- (UIView *)resumeCardWithTitle:(NSString *)title meta:(NSString *)meta symbol:(NSString *)symbol colors:(NSArray<UIColor *> *)colors progress:(CGFloat)progress {
    UIView *card = [self cardView];

    IHGradientView *thumb = [[IHGradientView alloc] initWithColors:colors startPoint:CGPointMake(0.0, 0.0) endPoint:CGPointMake(1.0, 1.0)];
    thumb.layer.cornerRadius = 22.0;
    thumb.layer.cornerCurve = kCACornerCurveContinuous;
    [thumb.widthAnchor constraintEqualToConstant:92.0].active = YES;
    [thumb.heightAnchor constraintEqualToConstant:92.0].active = YES;
    UIImageView *icon = IHIconView(symbol, 32.0, UIColor.whiteColor);
    [thumb addSubview:icon];
    [icon.centerXAnchor constraintEqualToAnchor:thumb.centerXAnchor].active = YES;
    [icon.centerYAnchor constraintEqualToAnchor:thumb.centerYAnchor].active = YES;
    [icon.widthAnchor constraintEqualToConstant:34.0].active = YES;
    [icon.heightAnchor constraintEqualToConstant:34.0].active = YES;

    UIStackView *text = IHStack(UILayoutConstraintAxisVertical, 10.0);
    [text addArrangedSubview:IHLabel(title, IHRoundedFont(19.0, UIFontWeightBold), UIColor.labelColor, 2)];
    [text addArrangedSubview:IHLabel(meta, [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium], UIColor.secondaryLabelColor, 1)];
    [text addArrangedSubview:[self progressBarWithProgress:progress tint:IHColor(0x315CEB, 1.0)]];

    UIStackView *layout = IHStack(UILayoutConstraintAxisHorizontal, 16.0);
    layout.alignment = UIStackViewAlignmentCenter;
    [layout addArrangedSubview:thumb];
    [layout addArrangedSubview:text];
    [card addSubview:layout];

    [NSLayoutConstraint activateConstraints:@[
        [layout.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
        [layout.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],
        [layout.topAnchor constraintEqualToAnchor:card.topAnchor constant:16.0],
        [layout.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16.0],
    ]];

    return card;
}

- (UIView *)buildRoadmapCard {
    UIView *card = [self cardView];

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 18.0);
    [card addSubview:stack];

    [stack addArrangedSubview:[self pillViewWithTitle:@"学习路径 · Week 03" symbol:@"point.3.connected.trianglepath.dotted" tint:IHColor(0x355DEF, 1.0) backgroundColor:IHColor(0xECF2FF, 1.0)]];
    [stack addArrangedSubview:[self roadmapItemWithStatus:@"已完成" title:@"看完课程《课程主页的层次设计》" subtitle:@"你已经完成笔记整理，建议把重点同步到收藏夹。" tint:IHColor(0x17A288, 1.0)]];
    [stack addArrangedSubview:[self roadmapItemWithStatus:@"进行中" title:@"上传你的课程封面视觉作业" subtitle:@"在社区发帖后，可自动邀请导师和同学进行点评。" tint:IHColor(0x315CEB, 1.0)]];
    [stack addArrangedSubview:[self roadmapItemWithStatus:@"待开始" title:@"参加周四直播 · 作品复盘" subtitle:@"直播结束后会自动把回放添加到继续学习列表。" tint:IHColor(0xFF8C4A, 1.0)]];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

- (UIView *)roadmapItemWithStatus:(NSString *)status title:(NSString *)title subtitle:(NSString *)subtitle tint:(UIColor *)tintColor {
    UIStackView *row = IHStack(UILayoutConstraintAxisHorizontal, 14.0);
    row.alignment = UIStackViewAlignmentTop;

    UIView *dot = [[UIView alloc] init];
    dot.translatesAutoresizingMaskIntoConstraints = NO;
    dot.backgroundColor = tintColor;
    dot.layer.cornerRadius = 8.0;
    dot.layer.cornerCurve = kCACornerCurveContinuous;
    [dot.widthAnchor constraintEqualToConstant:16.0].active = YES;
    [dot.heightAnchor constraintEqualToConstant:16.0].active = YES;

    UIStackView *text = IHStack(UILayoutConstraintAxisVertical, 6.0);
    [text addArrangedSubview:[self pillViewWithTitle:status symbol:@"checkmark.circle.fill" tint:tintColor backgroundColor:[tintColor colorWithAlphaComponent:0.12]]];
    [text addArrangedSubview:IHLabel(title, [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold], UIColor.labelColor, 0)];
    [text addArrangedSubview:IHLabel(subtitle, [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];

    [row addArrangedSubview:dot];
    [row addArrangedSubview:text];
    return row;
}

- (UIView *)buildStudyRoomCard {
    UIView *card = [self cardView];
    card.backgroundColor = IHColor(0x0E1A42, 1.0);

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 14.0);
    [card addSubview:stack];

    [stack addArrangedSubview:IHLabel(@"离线学习空间", IHRoundedFont(25.0, UIFontWeightBold), UIColor.whiteColor, 1)];
    [stack addArrangedSubview:IHLabel(@"已经缓存 6 节课程视频、12 条课堂笔记和 3 份作业模板。通勤时也能继续学习。", [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], [UIColor colorWithWhite:1.0 alpha:0.8], 0)];

    UIStackView *metrics = IHStack(UILayoutConstraintAxisHorizontal, 12.0);
    metrics.distribution = UIStackViewDistributionFillEqually;
    [metrics addArrangedSubview:[self metricCardWithValue:@"6" title:@"缓存视频" tint:IHColor(0x84D3FF, 1.0)]];
    [metrics addArrangedSubview:[self metricCardWithValue:@"12" title:@"课堂笔记" tint:IHColor(0x7CF5DA, 1.0)]];
    [metrics addArrangedSubview:[self metricCardWithValue:@"3" title:@"作业模板" tint:IHColor(0xFFD27C, 1.0)]];
    [stack addArrangedSubview:metrics];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

@end

@implementation IHubCommunityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"社区";

    [self.contentStack addArrangedSubview:[self buildFeaturedLounge]];
    [self.contentStack addArrangedSubview:[self sectionHeaderWithTitle:@"话题广场" subtitle:@"课程学习之外，把提问、互评和交流都放进来。"]];
    [self.contentStack addArrangedSubview:[self buildTopicScroller]];
    [self.contentStack addArrangedSubview:[self sectionHeaderWithTitle:@"热门讨论" subtitle:@"下面的内容全部是 mock 数据，但结构已经可以承载真实社区信息。"]];
    [self.contentStack addArrangedSubview:[self buildPostList]];
    [self.contentStack addArrangedSubview:[self buildEventCard]];
}

- (UIView *)buildFeaturedLounge {
    IHGradientView *card = [[IHGradientView alloc] initWithColors:@[
        IHColor(0x221047, 1.0),
        IHColor(0x5638F6, 1.0),
        IHColor(0xFF7CD2, 1.0)
    ] startPoint:CGPointMake(0.0, 0.0) endPoint:CGPointMake(1.0, 1.0)];
    card.layer.cornerRadius = 32.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.masksToBounds = YES;
    card.layer.shadowColor = IHColor(0x6A38F5, 0.26).CGColor;
    card.layer.shadowOpacity = 1.0;
    card.layer.shadowRadius = 26.0;
    card.layer.shadowOffset = CGSizeMake(0.0, 14.0);

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 16.0);
    [card addSubview:stack];

    [stack addArrangedSubview:[self pillViewWithTitle:@"讨论室 · 进行中" symbol:@"waveform" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.16]]];
    [stack addArrangedSubview:IHLabel(@"今晚 20:00 作品复盘 Room", IHRoundedFont(30.0, UIFontWeightBold), UIColor.whiteColor, 0)];
    [stack addArrangedSubview:IHLabel(@"大家正在围绕“教育产品如何做好学习成就感”进行讨论，导师会现场挑选 3 个作业做深度点评。", [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], [UIColor colorWithWhite:1.0 alpha:0.84], 0)];

    UIStackView *stats = IHStack(UILayoutConstraintAxisHorizontal, 10.0);
    [stats addArrangedSubview:[self pillViewWithTitle:@"124 人在线" symbol:@"person.3.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.16]]];
    [stats addArrangedSubview:[self pillViewWithTitle:@"可申请上麦" symbol:@"mic.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.16]]];
    [stack addArrangedSubview:stats];

    __weak typeof(self) weakSelf = self;
    [stack addArrangedSubview:[self filledButtonWithTitle:@"进入讨论室" symbol:@"bubble.left.and.bubble.right.fill" tint:IHColor(0x11173E, 1.0) handler:^{
        [weakSelf showMockAlertWithTitle:@"进入讨论室" message:@"可以继续补语音房、举手申请、主持人管理和聊天消息流。"];
    }]];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:22.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22.0],
    ]];

    return card;
}

- (UIView *)buildTopicScroller {
    NSArray<UIView *> *items = @[
        [self pillViewWithTitle:@"作品求点评" symbol:@"sparkles.rectangle.stack.fill" tint:IHColor(0x315CEB, 1.0) backgroundColor:IHColor(0xECF2FF, 1.0)],
        [self pillViewWithTitle:@"AI 工具流" symbol:@"brain" tint:IHColor(0x7B49FF, 1.0) backgroundColor:IHColor(0xF3ECFF, 1.0)],
        [self pillViewWithTitle:@"SwiftUI" symbol:@"swift" tint:IHColor(0x14A38D, 1.0) backgroundColor:IHColor(0xEAFBF7, 1.0)],
        [self pillViewWithTitle:@"求职内推" symbol:@"briefcase.fill" tint:IHColor(0xFF884A, 1.0) backgroundColor:IHColor(0xFFF2E8, 1.0)],
        [self pillViewWithTitle:@"学习打卡" symbol:@"flame.fill" tint:IHColor(0xD84C4C, 1.0) backgroundColor:IHColor(0xFFF0F0, 1.0)],
    ];
    return [self horizontalScrollWithViews:items height:42.0 spacing:12.0];
}

- (UIView *)buildPostList {
    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 16.0);
    [stack addArrangedSubview:[self postCardWithAuthor:@"Luna" role:@"UI 学员" title:@"把课程里的订阅页重做了一版，欢迎拍砖" body:@"我把原来偏功能化的页面改成更强调层次感和会员价值的结构，想听听大家对信息优先级的建议。" tags:@[@"iOS", @"设计审美"] tint:IHColor(0x315CEB, 1.0) likes:@"86" replies:@"24"]];
    [stack addArrangedSubview:[self postCardWithAuthor:@"Mason" role:@"产品教练" title:@"做在线教育产品时，如何避免社区区变成灌水区？" body:@"我的经验是把发帖意图设计清楚，比如求点评、晒作业、发问题、分享资源，每一种都给出模板和激励。" tags:@[@"产品策略", @"社区运营"] tint:IHColor(0x7B49FF, 1.0) likes:@"114" replies:@"31"]];
    [stack addArrangedSubview:[self postCardWithAuthor:@"Qiqi" role:@"iOS 开发" title:@"谁能推荐一下适合课程首页的转场动画？" body:@"我在做卡片跳详情页，想要介于 Apple Music 和 App Store 之间的感觉，不想太花哨。" tags:@[@"SwiftUI", @"动效"] tint:IHColor(0x14A38D, 1.0) likes:@"59" replies:@"17"]];
    return stack;
}

- (UIView *)postCardWithAuthor:(NSString *)author role:(NSString *)role title:(NSString *)title body:(NSString *)body tags:(NSArray<NSString *> *)tags tint:(UIColor *)tintColor likes:(NSString *)likes replies:(NSString *)replies {
    UIView *card = [self cardView];

    UIView *avatar = [[UIView alloc] init];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    avatar.backgroundColor = tintColor;
    avatar.layer.cornerRadius = 22.0;
    avatar.layer.cornerCurve = kCACornerCurveContinuous;
    [avatar.widthAnchor constraintEqualToConstant:44.0].active = YES;
    [avatar.heightAnchor constraintEqualToConstant:44.0].active = YES;

    UILabel *letter = IHLabel([[author substringToIndex:1] uppercaseString], IHRoundedFont(20.0, UIFontWeightBold), UIColor.whiteColor, 1);
    [avatar addSubview:letter];
    [letter.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor].active = YES;
    [letter.centerYAnchor constraintEqualToAnchor:avatar.centerYAnchor].active = YES;

    UIStackView *userText = IHStack(UILayoutConstraintAxisVertical, 4.0);
    [userText addArrangedSubview:IHLabel(author, [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold], UIColor.labelColor, 1)];
    [userText addArrangedSubview:[self pillViewWithTitle:role symbol:@"person.fill.checkmark" tint:tintColor backgroundColor:[tintColor colorWithAlphaComponent:0.12]]];

    UIView *headFlex = [[UIView alloc] init];
    headFlex.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageView *more = IHIconView(@"ellipsis", 16.0, UIColor.tertiaryLabelColor);

    UIStackView *header = IHStack(UILayoutConstraintAxisHorizontal, 12.0);
    header.alignment = UIStackViewAlignmentCenter;
    [header addArrangedSubview:avatar];
    [header addArrangedSubview:userText];
    [header addArrangedSubview:headFlex];
    [header addArrangedSubview:more];

    UIStackView *content = IHStack(UILayoutConstraintAxisVertical, 14.0);
    [content addArrangedSubview:header];
    [content addArrangedSubview:IHLabel(title, IHRoundedFont(22.0, UIFontWeightBold), UIColor.labelColor, 0)];
    [content addArrangedSubview:IHLabel(body, [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];

    NSMutableArray<UIView *> *tagViews = [NSMutableArray array];
    for (NSString *tag in tags) {
        [tagViews addObject:[self pillViewWithTitle:tag symbol:@"number" tint:tintColor backgroundColor:[tintColor colorWithAlphaComponent:0.12]]];
    }
    [content addArrangedSubview:[self horizontalScrollWithViews:tagViews height:38.0 spacing:10.0]];

    UIStackView *stats = IHStack(UILayoutConstraintAxisHorizontal, 12.0);
    [stats addArrangedSubview:[self pillViewWithTitle:[NSString stringWithFormat:@"%@ 赞", likes] symbol:@"heart.fill" tint:IHColor(0xFF6F61, 1.0) backgroundColor:IHColor(0xFFF0ED, 1.0)]];
    [stats addArrangedSubview:[self pillViewWithTitle:[NSString stringWithFormat:@"%@ 回复", replies] symbol:@"bubble.left.fill" tint:IHColor(0x315CEB, 1.0) backgroundColor:IHColor(0xECF2FF, 1.0)]];
    [content addArrangedSubview:stats];

    [card addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

- (UIView *)buildEventCard {
    UIView *card = [self cardView];
    card.backgroundColor = IHColor(0xF7F9FF, 1.0);

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 16.0);
    [card addSubview:stack];

    [stack addArrangedSubview:IHLabel(@"周末线下活动", IHRoundedFont(24.0, UIFontWeightBold), UIColor.labelColor, 1)];
    [stack addArrangedSubview:IHLabel(@"上海 · 设计与产品学习者共创日。上午做作品集分享，下午做教育类产品头脑风暴。", [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], UIColor.secondaryLabelColor, 0)];

    UIStackView *chips = IHStack(UILayoutConstraintAxisHorizontal, 10.0);
    [chips addArrangedSubview:[self pillViewWithTitle:@"3 月 20 日" symbol:@"calendar" tint:IHColor(0x315CEB, 1.0) backgroundColor:IHColor(0xECF2FF, 1.0)]];
    [chips addArrangedSubview:[self pillViewWithTitle:@"线下 Meetup" symbol:@"mappin.and.ellipse" tint:IHColor(0x15AA91, 1.0) backgroundColor:IHColor(0xEAFBF7, 1.0)]];
    [stack addArrangedSubview:chips];

    __weak typeof(self) weakSelf = self;
    [stack addArrangedSubview:[self filledButtonWithTitle:@"我要报名" symbol:@"ticket.fill" tint:IHColor(0x111C47, 1.0) handler:^{
        [weakSelf showMockAlertWithTitle:@"活动报名" message:@"可以继续增加活动详情页、报名表单和二维码签到。"];
    }]];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

@end

@implementation IHubProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的";

    [self.contentStack addArrangedSubview:[self buildProfileHero]];
    [self.contentStack addArrangedSubview:[self buildStatsStrip]];
    [self.contentStack addArrangedSubview:[self sectionHeaderWithTitle:@"成就与收藏" subtitle:@"课程证书、收藏清单和常用工具都集中到这里。"]];
    [self.contentStack addArrangedSubview:[self buildAchievementsCard]];
    [self.contentStack addArrangedSubview:[self buildCollectionCard]];
    [self.contentStack addArrangedSubview:[self buildSettingsCard]];
}

- (UIView *)buildProfileHero {
    IHGradientView *hero = [[IHGradientView alloc] initWithColors:@[
        IHColor(0x111B44, 1.0),
        IHColor(0x2449D8, 1.0),
        IHColor(0x7DD5FF, 1.0)
    ] startPoint:CGPointMake(0.0, 0.0) endPoint:CGPointMake(1.0, 1.0)];
    [hero.heightAnchor constraintEqualToConstant:228.0].active = YES;

    UIView *avatar = [[UIView alloc] init];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    avatar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    avatar.layer.cornerRadius = 36.0;
    avatar.layer.cornerCurve = kCACornerCurveContinuous;
    [avatar.widthAnchor constraintEqualToConstant:72.0].active = YES;
    [avatar.heightAnchor constraintEqualToConstant:72.0].active = YES;
    UILabel *avatarLabel = IHLabel(@"R", IHRoundedFont(30.0, UIFontWeightBold), UIColor.whiteColor, 1);
    [avatar addSubview:avatarLabel];
    [avatarLabel.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor].active = YES;
    [avatarLabel.centerYAnchor constraintEqualToAnchor:avatar.centerYAnchor].active = YES;

    UIStackView *text = IHStack(UILayoutConstraintAxisVertical, 8.0);
    [text addArrangedSubview:IHLabel(@"Ryan", IHRoundedFont(30.0, UIFontWeightBold), UIColor.whiteColor, 1)];
    [text addArrangedSubview:IHLabel(@"Pro 会员 · 连续学习 9 天 · 已完成 3 门课程", [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium], [UIColor colorWithWhite:1.0 alpha:0.82], 0)];

    __weak typeof(self) weakSelf = self;
    UIButton *editButton = [self filledButtonWithTitle:@"编辑目标" symbol:@"slider.horizontal.3" tint:IHColor(0x101935, 1.0) handler:^{
        [weakSelf showMockAlertWithTitle:@"个人目标" message:@"这里可以接入学习目标、昵称头像编辑和会员套餐管理。"];
    }];

    UIStackView *top = IHStack(UILayoutConstraintAxisHorizontal, 16.0);
    top.alignment = UIStackViewAlignmentCenter;
    [top addArrangedSubview:avatar];
    [top addArrangedSubview:text];

    UIStackView *content = IHStack(UILayoutConstraintAxisVertical, 18.0);
    [content addArrangedSubview:top];
    [content addArrangedSubview:[self pillViewWithTitle:@"下一个徽章：连续学习 14 天" symbol:@"flame.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.16]]];
    [content addArrangedSubview:editButton];
    [hero addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:22.0],
        [content.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-22.0],
        [content.topAnchor constraintEqualToAnchor:hero.topAnchor constant:22.0],
        [content.bottomAnchor constraintEqualToAnchor:hero.bottomAnchor constant:-22.0],
    ]];

    return hero;
}

- (UIView *)buildStatsStrip {
    UIStackView *stack = IHStack(UILayoutConstraintAxisHorizontal, 12.0);
    stack.distribution = UIStackViewDistributionFillEqually;
    [stack addArrangedSubview:[self metricCardWithValue:@"48h" title:@"总学习时长" tint:IHColor(0x315CEB, 1.0)]];
    [stack addArrangedSubview:[self metricCardWithValue:@"9" title:@"连续打卡" tint:IHColor(0x15AA91, 1.0)]];
    [stack addArrangedSubview:[self metricCardWithValue:@"3" title:@"课程证书" tint:IHColor(0xFF8C4A, 1.0)]];
    return stack;
}

- (UIView *)buildAchievementsCard {
    UIView *card = [self cardView];

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 16.0);
    [card addSubview:stack];

    [stack addArrangedSubview:[self listRowWithSymbol:@"medal.fill" tint:IHColor(0x315CEB, 1.0) title:@"优秀学员证书" subtitle:@"已完成《AI 产品训练营》，证书支持导出与分享。"]];
    [stack addArrangedSubview:[self listRowWithSymbol:@"sparkles.tv.fill" tint:IHColor(0x7B49FF, 1.0) title:@"精选作业展示" subtitle:@"有 2 个作业被社区编辑推荐到首页。"]];
    [stack addArrangedSubview:[self listRowWithSymbol:@"person.2.fill" tint:IHColor(0x15AA91, 1.0) title:@"导师答疑权益" subtitle:@"本月还剩 3 次一对一作业点评资格。"]];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

- (UIView *)buildCollectionCard {
    UIView *card = [self cardView];
    card.backgroundColor = IHColor(0xF8FAFF, 1.0);

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 16.0);
    [card addSubview:stack];

    [stack addArrangedSubview:IHLabel(@"我的收藏", IHRoundedFont(24.0, UIFontWeightBold), UIColor.labelColor, 1)];
    [stack addArrangedSubview:[self listRowWithSymbol:@"bookmark.fill" tint:IHColor(0x315CEB, 1.0) title:@"产品思维训练营" subtitle:@"最近收藏 · 方便稍后继续观看和复盘。"]];
    [stack addArrangedSubview:[self listRowWithSymbol:@"square.stack.3d.up.fill" tint:IHColor(0x15AA91, 1.0) title:@"社区精华合集" subtitle:@"高质量帖子、导师点评和精选资源已归档。"]];
    [stack addArrangedSubview:[self listRowWithSymbol:@"tray.full.fill" tint:IHColor(0xFF8C4A, 1.0) title:@"离线资料夹" subtitle:@"可快速查看缓存视频、讲义和作业模板。"]];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

- (UIView *)buildSettingsCard {
    UIView *card = [self cardView];
    card.backgroundColor = IHColor(0x101A3D, 1.0);

    UIStackView *stack = IHStack(UILayoutConstraintAxisVertical, 16.0);
    [card addSubview:stack];

    [stack addArrangedSubview:IHLabel(@"账号服务", IHRoundedFont(24.0, UIFontWeightBold), UIColor.whiteColor, 1)];
    [stack addArrangedSubview:IHLabel(@"通知提醒、下载管理、问题反馈等配套服务可以继续在这里扩展。", [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular], [UIColor colorWithWhite:1.0 alpha:0.78], 0)];
    [stack addArrangedSubview:[self pillViewWithTitle:@"学习提醒已开启" symbol:@"bell.fill" tint:UIColor.whiteColor backgroundColor:[UIColor colorWithWhite:1.0 alpha:0.14]]];

    UIStackView *buttons = IHStack(UILayoutConstraintAxisHorizontal, 12.0);
    buttons.distribution = UIStackViewDistributionFillEqually;

    __weak typeof(self) weakSelf = self;
    UIButton *feedbackButton = [self filledButtonWithTitle:@"意见反馈" symbol:@"text.bubble.fill" tint:IHColor(0x2E57EA, 1.0) handler:^{
        [weakSelf showMockAlertWithTitle:@"意见反馈" message:@"可以补反馈表单、客服会话和版本更新日志。"];
    }];
    UIButton *downloadButton = [self filledButtonWithTitle:@"下载管理" symbol:@"arrow.down.circle.fill" tint:IHColor(0x15AA91, 1.0) handler:^{
        [weakSelf showMockAlertWithTitle:@"下载管理" message:@"可以接入真实离线缓存、清理空间和仅 Wi‑Fi 下载。"];
    }];
    [buttons addArrangedSubview:feedbackButton];
    [buttons addArrangedSubview:downloadButton];
    [stack addArrangedSubview:buttons];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];

    return card;
}

@end

@interface ViewController ()

@property (nonatomic, strong) UITabBarController *embeddedTabBarController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = IHColor(0xF5F7FB, 1.0);
    [self configureGlobalAppearance];
    [self embedMainExperienceIfNeeded];
}

- (void)configureGlobalAppearance {
    UINavigationBarAppearance *navigationAppearance = [[UINavigationBarAppearance alloc] init];
    [navigationAppearance configureWithOpaqueBackground];
    navigationAppearance.backgroundColor = IHColor(0xF5F7FB, 1.0);
    navigationAppearance.shadowColor = UIColor.clearColor;
    navigationAppearance.titleTextAttributes = @{
        NSFontAttributeName: IHRoundedFont(18.0, UIFontWeightBold),
        NSForegroundColorAttributeName: UIColor.labelColor
    };
    navigationAppearance.largeTitleTextAttributes = @{
        NSFontAttributeName: IHRoundedFont(34.0, UIFontWeightBold),
        NSForegroundColorAttributeName: UIColor.labelColor
    };

    [UINavigationBar appearance].standardAppearance = navigationAppearance;
    [UINavigationBar appearance].scrollEdgeAppearance = navigationAppearance;
    [UINavigationBar appearance].compactAppearance = navigationAppearance;
    [UINavigationBar appearance].tintColor = IHColor(0x1B2B67, 1.0);

    UITabBarAppearance *tabAppearance = [[UITabBarAppearance alloc] init];
    [tabAppearance configureWithDefaultBackground];
    tabAppearance.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.94];
    tabAppearance.shadowColor = UIColor.clearColor;

    UIColor *selectedColor = IHColor(0x2449D8, 1.0);
    UIColor *normalColor = UIColor.secondaryLabelColor;

    UITabBarItemAppearance *itemAppearance = tabAppearance.stackedLayoutAppearance;
    itemAppearance.normal.iconColor = normalColor;
    itemAppearance.normal.titleTextAttributes = @{
        NSForegroundColorAttributeName: normalColor,
        NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium]
    };
    itemAppearance.selected.iconColor = selectedColor;
    itemAppearance.selected.titleTextAttributes = @{
        NSForegroundColorAttributeName: selectedColor,
        NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold]
    };

    [UITabBar appearance].standardAppearance = tabAppearance;
    if (@available(iOS 15.0, *)) {
        [UITabBar appearance].scrollEdgeAppearance = tabAppearance;
    }
}

- (void)embedMainExperienceIfNeeded {
    if (self.embeddedTabBarController != nil) {
        return;
    }

    self.embeddedTabBarController = [[UITabBarController alloc] init];
    self.embeddedTabBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.embeddedTabBarController.view.backgroundColor = IHColor(0xF5F7FB, 1.0);

    self.embeddedTabBarController.viewControllers = @[
        [self wrappedControllerFor:[IHubHomeViewController new] title:@"首页" symbol:@"house.fill"],
        [self wrappedControllerFor:[IHubLearningViewController new] title:@"学习" symbol:@"play.rectangle.fill"],
        [self wrappedControllerFor:[IHubCommunityViewController new] title:@"社区" symbol:@"bubble.left.and.bubble.right.fill"],
        [self wrappedControllerFor:[IHubProfileViewController new] title:@"我的" symbol:@"person.crop.circle.fill"],
    ];
    self.embeddedTabBarController.selectedIndex = [self preferredLaunchTabIndex];

    [self addChildViewController:self.embeddedTabBarController];
    [self.view addSubview:self.embeddedTabBarController.view];

    [NSLayoutConstraint activateConstraints:@[
        [self.embeddedTabBarController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.embeddedTabBarController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.embeddedTabBarController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.embeddedTabBarController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self.embeddedTabBarController didMoveToParentViewController:self];
}

- (NSUInteger)preferredLaunchTabIndex {
    NSString *tabName = NSProcessInfo.processInfo.environment[@"IHUB_INITIAL_TAB"];
    if (tabName.length == 0) {
        return 0;
    }

    NSDictionary<NSString *, NSNumber *> *mapping = @{
        @"home": @0,
        @"learning": @1,
        @"community": @2,
        @"profile": @3,
    };
    NSNumber *index = mapping[tabName.lowercaseString];
    return index != nil ? index.unsignedIntegerValue : 0;
}

- (UINavigationController *)wrappedControllerFor:(UIViewController *)controller title:(NSString *)title symbol:(NSString *)symbol {
    controller.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:[UIImage systemImageNamed:symbol] selectedImage:[UIImage systemImageNamed:symbol]];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    navigationController.navigationBar.prefersLargeTitles = YES;
    return navigationController;
}

@end
