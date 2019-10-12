//
//  SaveMachO.m
//  MachOView
//
//  Created by linweizhu on 2019/10/12.
//

#import "SaveMachO.h"
#import "MachOLayout.h"
#import "Document.h"
#import "DataController.h"
#import "ReadWrite.h"
#import "ArchiveLayout.h"

@implementation SaveMachO

+ (NSDictionary *)mixStringInfo {
    NSDictionary *dict = @{
        @"AAABBB":@"AAACCC",
    };
    return dict;
}

+ (void)mixStringAtLocation:(uint32_t)location
                     length:(uint32_t)length {
    MVDocument *doc = [NSDocumentController sharedDocumentController].currentDocument;
    if (doc) {
           for (NSString *key in [self mixStringInfo].allKeys) {
               const char *findStr = [key cStringUsingEncoding:NSASCIIStringEncoding];
               const char *replaceStr = [[self mixStringInfo][key] cStringUsingEncoding:NSASCIIStringEncoding];
               uint8_t temp[length];
               memcpy(temp, (uint8_t *)[doc.dataController.fileData bytes] + location, length);
               int needWriteBack = NO;
               for (uint64_t i = 0; i < length - strlen(findStr) && i < length; ++i) {
                   int found = 1;
                   for (size_t j = i; j-i < strlen(findStr); ++j) {
                       if (temp[j] != findStr[j-i]) {
                           found = 0;
                           break;
                       }
                   }
                   if (found) {
                       for (size_t j = i; j-i < strlen(replaceStr); ++j) {
                           temp[j] = replaceStr[j-i];
                       }
                       needWriteBack = YES;
                   }
               }
               if (needWriteBack) {
                   [doc.dataController.fileData replaceBytesInRange:NSMakeRange(location, length) withBytes:temp length:length];
               }
           }
       }
}

+ (void)mixStringTable {
    MVDocument *doc = [NSDocumentController sharedDocumentController].currentDocument;
    if (doc) {
        for (MachOLayout *layout in doc.dataController.layouts) {
            if ([layout isKindOfClass:[ArchiveLayout class]]) {
                ArchiveLayout *archiveLayout = (ArchiveLayout *)layout;
                if (layout.strTabLengh > 0) {
                    [self mixStringAtLocation:layout.strTabBegin length:layout.strTabLengh];
                }
                NSArray *machoLayoutArr = [archiveLayout getMachoLayoutArray];
                for (MachOLayout *machoLayout in machoLayoutArr) {
                    if ([machoLayout isKindOfClass:[MachOLayout class]] && machoLayout.strTabLengh > 0) {
                        [self mixStringAtLocation:machoLayout.strTabBegin length:machoLayout.strTabLengh];
                    }
                }
            }
            else if (layout.strTabLengh > 0) {
                [self mixStringAtLocation:layout.strTabBegin length:layout.strTabLengh];
            }
        }
    }
}

+ (void)mixCStringsNode {
    MVDocument *doc = [NSDocumentController sharedDocumentController].currentDocument;
       if (doc) {
           NSMutableArray<NSValue *> *rangeArr = [[NSMutableArray alloc] init];
           for (MachOLayout *layout in doc.dataController.layouts) {
               if ([layout isKindOfClass:[ArchiveLayout class]]) {
                   ArchiveLayout *archiveLayout = (ArchiveLayout *)layout;
                   NSArray *machoLayoutArr = [archiveLayout getMachoLayoutArray];
                   for (MachOLayout *machoLayout in machoLayoutArr) {
                       if ([machoLayout isKindOfClass:[MachOLayout class]]) {
                           NSArray<NSValue *> *arr = [machoLayout getCStringNodeRangeArray];
                           NSArray<NSValue *> *arr64 = [machoLayout getCString64NodeRangeArray];
                           if (arr.count > 0) {
                               [rangeArr addObjectsFromArray:arr];
                           }
                           if (arr64.count > 0) {
                               [rangeArr addObjectsFromArray:arr64];
                           }
                       }
                   }
               }
               else if ([layout isKindOfClass:[MachOLayout class]]) {
                   NSArray<NSValue *> *arr = [layout getCStringNodeRangeArray];
                   NSArray<NSValue *> *arr64 = [layout getCString64NodeRangeArray];
                   if (arr.count > 0) {
                       [rangeArr addObjectsFromArray:arr];
                   }
                   if (arr64.count > 0) {
                       [rangeArr addObjectsFromArray:arr64];
                   }
               }
           }
           if (rangeArr.count > 0) {
               for (NSValue *value in rangeArr) {
                   NSRange range = [value rangeValue];
                   [self mixStringAtLocation:range.location length:range.length];
               }
           }
       }
}

+ (void)save {
    [self mixStringTable];
    [self mixCStringsNode];
    MVDocument *doc = [NSDocumentController sharedDocumentController].currentDocument;
    [doc.dataController.fileData writeToFile:@"/Users/linweizhu/Desktop/DingDing/ShareKit_replace" atomically:YES];
}

@end
