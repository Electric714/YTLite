#import "YTNotesStorage.h"

@implementation YTNotesStorage

+ (NSURL *)notesDirectoryURLEnsuringExists {
    // Notes are stored strictly in the app sandbox at Documents/YTLiteNotes.
    NSURL *documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *notesDirectory = [documentsDirectory URLByAppendingPathComponent:@"YTLiteNotes" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:notesDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    return notesDirectory;
}

+ (NSString *)sanitizedBaseNameFromTitle:(NSString *)title {
    NSString *trimmedTitle = [[title ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
    if (trimmedTitle.length == 0) trimmedTitle = @"Untitled";

    NSMutableString *sanitized = [NSMutableString stringWithCapacity:trimmedTitle.length];
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_ "];
    for (NSUInteger i = 0; i < trimmedTitle.length; i++) {
        unichar character = [trimmedTitle characterAtIndex:i];
        if ([allowed characterIsMember:character]) {
            [sanitized appendFormat:@"%C", character];
        } else {
            [sanitized appendString:@"_"];
        }
    }

    NSString *collapsed = [[sanitized componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@" "];
    NSString *result = [collapsed stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return result.length > 0 ? result : @"Untitled";
}

+ (NSURL *)uniqueNoteFileURLForBaseName:(NSString *)baseName excludingFileName:(NSString *)excludedFileName {
    NSURL *directoryURL = [self notesDirectoryURLEnsuringExists];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *candidateName = [baseName stringByAppendingPathExtension:@"txt"];
    NSURL *candidateURL = [directoryURL URLByAppendingPathComponent:candidateName];

    NSUInteger suffix = 1;
    while ([fileManager fileExistsAtPath:candidateURL.path] && ![candidateName isEqualToString:excludedFileName]) {
        candidateName = [[NSString stringWithFormat:@"%@ (%lu)", baseName, (unsigned long)suffix] stringByAppendingPathExtension:@"txt"];
        candidateURL = [directoryURL URLByAppendingPathComponent:candidateName];
        suffix++;
    }

    return candidateURL;
}

+ (NSArray<NSURL *> *)sortedNoteFileURLs {
    NSURL *directoryURL = [self notesDirectoryURLEnsuringExists];
    NSArray<NSURL *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL includingPropertiesForKeys:@[NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil] ?: @[];

    NSArray<NSURL *> *textFiles = [files filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *fileURL, NSDictionary *bindings) {
        return [[fileURL.pathExtension lowercaseString] isEqualToString:@"txt"];
    }]];

    return [textFiles sortedArrayUsingComparator:^NSComparisonResult(NSURL *left, NSURL *right) {
        NSDate *leftDate = [self modificationDateForFileURL:left] ?: [NSDate distantPast];
        NSDate *rightDate = [self modificationDateForFileURL:right] ?: [NSDate distantPast];
        return [rightDate compare:leftDate];
    }];
}

+ (NSString *)displayTitleForFileURL:(NSURL *)fileURL {
    NSString *contents = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil] ?: @"";
    NSString *firstLine = [[[contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (firstLine.length > 0) return firstLine;

    return [[fileURL lastPathComponent] stringByDeletingPathExtension];
}

+ (NSDate *)modificationDateForFileURL:(NSURL *)fileURL {
    return [fileURL resourceValuesForKeys:@[NSURLContentModificationDateKey] error:nil].contentModificationDate;
}

@end
