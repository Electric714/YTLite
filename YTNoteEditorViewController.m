#import "YTNoteEditorViewController.h"
#import "YTNotesStorage.h"

@interface YTNoteEditorViewController () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSURL *noteFileURL;
@end

@implementation YTNoteEditorViewController

- (instancetype)initWithNoteFileURL:(NSURL *)noteFileURL {
    self = [super init];
    if (self) {
        _noteFileURL = noteFileURL;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareNote)],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveNow)]
    ];

    self.titleField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.titleField.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleField.borderStyle = UITextBorderStyleRoundedRect;
    self.titleField.placeholder = @"Title";
    self.titleField.delegate = self;
    [self.titleField addTarget:self action:@selector(scheduleAutoSave) forControlEvents:UIControlEventEditingChanged];

    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textView.delegate = self;

    [self.view addSubview:self.titleField];
    [self.view addSubview:self.textView];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleField.topAnchor constraintEqualToAnchor:guide.topAnchor constant:12.0],
        [self.titleField.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:12.0],
        [self.titleField.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-12.0],

        [self.textView.topAnchor constraintEqualToAnchor:self.titleField.bottomAnchor constant:8.0],
        [self.textView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:8.0],
        [self.textView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-8.0],
        [self.textView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-8.0]
    ]];

    [self loadNote];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveNow];
}

- (void)textViewDidChange:(UITextView *)textView {
    [self scheduleAutoSave];
}

- (void)scheduleAutoSave {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveNow) object:nil];
    [self performSelector:@selector(saveNow) withObject:nil afterDelay:1.0];
}

- (void)loadNote {
    self.navigationItem.title = @"Note";

    if (!self.noteFileURL) return;

    NSString *content = [NSString stringWithContentsOfURL:self.noteFileURL encoding:NSUTF8StringEncoding error:nil] ?: @"";
    self.textView.text = content;

    NSString *currentTitle = [[self.noteFileURL lastPathComponent] stringByDeletingPathExtension];
    self.titleField.text = currentTitle;
}

- (void)saveNow {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveNow) object:nil];

    NSString *baseName = [YTNotesStorage sanitizedBaseNameFromTitle:self.titleField.text];
    NSString *excluded = self.noteFileURL.lastPathComponent;
    NSURL *targetURL = [YTNotesStorage uniqueNoteFileURLForBaseName:baseName excludingFileName:excluded];

    NSError *writeError;
    BOOL success = [self.textView.text ?: @"" writeToURL:targetURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    if (!success) return;

    if (self.noteFileURL && ![self.noteFileURL isEqual:targetURL]) {
        [[NSFileManager defaultManager] removeItemAtURL:self.noteFileURL error:nil];
    }

    self.noteFileURL = targetURL;
    self.titleField.text = baseName;
}

- (void)shareNote {
    [self saveNow];
    if (!self.noteFileURL) return;

    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[self.noteFileURL] applicationActivities:nil];
    UIPopoverPresentationController *popover = activityController.popoverPresentationController;
    if (popover) {
        popover.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    }
    [self presentViewController:activityController animated:YES completion:nil];
}

@end
