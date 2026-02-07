#import <Foundation/Foundation.h>

@interface YTNotesStorage : NSObject
+ (NSURL *)notesDirectoryURLEnsuringExists;
+ (NSString *)sanitizedBaseNameFromTitle:(NSString *)title;
+ (NSURL *)uniqueNoteFileURLForBaseName:(NSString *)baseName excludingFileName:(NSString *)excludedFileName;
+ (NSArray<NSURL *> *)sortedNoteFileURLs;
+ (NSString *)displayTitleForFileURL:(NSURL *)fileURL;
+ (NSDate *)modificationDateForFileURL:(NSURL *)fileURL;
@end
