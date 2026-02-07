#import "YTNotesListViewController.h"
#import "YTNotesStorage.h"
#import "YTNoteEditorViewController.h"

@interface YTNotesListViewController ()
@property (nonatomic, copy) NSArray<NSURL *> *noteFileURLs;
@end

@implementation YTNotesListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Notes";
    self.noteFileURLs = @[];
    self.tableView.tableFooterView = [UIView new];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewNote)];
    [self reloadNotes];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadNotes];
}

- (void)reloadNotes {
    self.noteFileURLs = [YTNotesStorage sortedNoteFileURLs];
    [self.tableView reloadData];
}

- (void)createNewNote {
    YTNoteEditorViewController *editor = [[YTNoteEditorViewController alloc] initWithNoteFileURL:nil];
    [self.navigationController pushViewController:editor animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.noteFileURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoteCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NoteCell"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSURL *fileURL = self.noteFileURLs[indexPath.row];
    cell.textLabel.text = [YTNotesStorage displayTitleForFileURL:fileURL];

    NSDate *modifiedDate = [YTNotesStorage modificationDateForFileURL:fileURL];
    if (modifiedDate) {
        static NSDateFormatter *formatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            formatter = [NSDateFormatter new];
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
        });
        cell.detailTextLabel.text = [formatter stringFromDate:modifiedDate];
    } else {
        cell.detailTextLabel.text = @"";
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YTNoteEditorViewController *editor = [[YTNoteEditorViewController alloc] initWithNoteFileURL:self.noteFileURLs[indexPath.row]];
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;

    NSURL *fileURL = self.noteFileURLs[indexPath.row];
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    [self reloadNotes];
}

@end
