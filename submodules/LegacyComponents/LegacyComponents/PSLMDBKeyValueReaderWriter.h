#import "lmdb.h"
#import "PSKeyValueReader.h"
#import "PSKeyValueWriter.h"

@class PSLMDBTable;

@interface PSLMDBKeyValueReaderWriter : NSObject <PSKeyValueReader, PSKeyValueWriter>

- (instancetype)initWithTable:(PSLMDBTable *)table transaction:(MDB_txn *)transaction;

@end
