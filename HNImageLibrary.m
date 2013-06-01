//
//  HNImageLibrary.m
//  An intelligent image store
//
//  Created by Hampus Nilsson on 6/1/13.
//  Copyright (c) 2013 hjnilsson. All rights reserved.
//

#import "HNImageLibrary.h"

NSMutableDictionary *_imageLibraries;

@implementation HNImageLibrary
{
    NSOperationQueue *_opQueue;
    
    // Images are stored here while they are writing to disk
    // This is to prevent imageForKey from returning nil in case of low memory
    // Which would happen in the below scenario:
    //   1. Call is made to setImage:forKey:, writing begins
    //   2. App runs low on memory and image is removed from _cache
    //   3. imageForKey: is called before write finishes, returning nil
    //   4. write finishes, imageForKey: now returns non-nil again
    NSMutableDictionary *_transparentStorage;
}

+ (void)initialize
{
    _imageLibraries = [NSMutableDictionary new];
}

- (id)initWithName:(NSString *)name defaultLossless:(BOOL)lossless
{
    self = [super init];
    if (self) {
        NSAssert(name.length > 0, @"Must pass a proper name to a HNImageLibrary");
        
        _defaultLossless = lossless;
        _jpegQuality = 8;
        _name = name;
        _cache = [NSCache new];
        _opQueue = [NSOperationQueue new];
        _transparentStorage = [NSMutableDictionary new];
        
        // Create the image directory
        [[NSFileManager defaultManager] createDirectoryAtPath:self.libraryPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    return self;
}

- (id)initWithName:(NSString *)name
{
    return [self initWithName:name defaultLossless:NO];
}

+ (HNImageLibrary *)defaultLibrary
{
	static HNImageLibrary *_sharedCache = nil;
	static dispatch_once_t onceToken;
    
	dispatch_once(&onceToken, ^{
		_sharedCache = [HNImageLibrary libraryWithName:HNImageLibraryDefaultName];
	});
    
	return _sharedCache;
}

+ (HNImageLibrary *)libraryWithName:(NSString *)name
{
    HNImageLibrary *library;
    
    // TODO: This acquires a mutex on every call, which is not ideal if we're fetching a lot of images
    @synchronized([HNImageLibrary class]) {
        library = _imageLibraries[name];
        if (library == nil) {
            library = [[HNImageLibrary alloc] initWithName:name];
            _imageLibraries[name] = library;
        }
    }
    
	return library;
}

- (NSString *)libraryPath
{
    NSString *path = NSHomeDirectory();
    path = [path stringByAppendingPathComponent:@"Library/HNImageLibrary/"];
    path = [path stringByAppendingPathComponent:self.name];
    return path;
}

- (NSString *)pathForKey:(NSString *)key
{
    return [self.libraryPath stringByAppendingPathComponent:key];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key lossless:(BOOL)lossless completion:(void (^)(UIImage *))completionHandler error:(void (^)(UIImage *, NSError *))errorHandler
{
    NSAssert(key != nil, @"Pass a non-null key please.");
    NSAssert(image != nil, @"Pass a non-null image please.");
    
    // Store in transparent storage so it remains in memory 'til completely written
    @synchronized(self) {
        [_transparentStorage setObject:image forKey:key];
    }
    
    // Store in cache for quick retrieval
    [self.cache setObject:image forKey:key];
    
    // Store these aside so they are thread-safe
    NSString *path = [self pathForKey:key];
    CGFloat jpegQuality = self.jpegQuality;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
            NSData *imageData = nil;
            if (lossless)
                imageData = UIImagePNGRepresentation(image);
            else
                imageData = UIImageJPEGRepresentation(image, jpegQuality);
            
            // Use atomic operation so imageForKey: won't try to access a transparent file
            BOOL success = [imageData writeToFile:path atomically:YES];
            
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(self) {
                        [_transparentStorage removeObjectForKey:key];
                    }
                    if(completionHandler)
                        completionHandler(image);
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(self) {
                        [_transparentStorage removeObjectForKey:key];
                    }
                    // TODO: Return a useful error here
                    if (errorHandler)
                        errorHandler(image, nil);
                });
            }
        }];
        
        [_opQueue addOperation:op];
    });
    
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key completion:(void (^)(UIImage *))completionHandler error:(void (^)(UIImage *, NSError *))errorHandler
{
    return [self setImage:image forKey:key lossless:self.defaultLossless completion:completionHandler error:errorHandler];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key lossless:(BOOL)lossless
{
    return [self setImage:image forKey:key lossless:lossless completion:nil error:nil];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key
{
    return [self setImage:image forKey:key lossless:self.defaultLossless completion:nil error:nil];
}

- (UIImage *)imageForKey:(NSString *)key
{
    NSAssert(key != nil, @"Pass a non-null key please.");
    
    UIImage *img = [self.cache objectForKey:key];
    if (img)
        return img;
    
    // Check the write storage
    img = [_transparentStorage objectForKey:key];
    if (img)
        return img;
    
    // So load it from disk & put it in cache
    img = [[UIImage alloc] initWithContentsOfFile:[self pathForKey:key]];
    if (img)
        [self.cache setObject:img forKey:key];
    
    return img;
}

- (void)removeImageForKey:(NSString *)key
{
    NSAssert(key != nil, @"Pass a non-null key please.");
    
    // Purge it from cache
    [self.cache removeObjectForKey:key];
    
    //
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:key] error:&error];
    if (error) {
        NSLog(@"HNImageLibrary - Could not delete image for key '%@' in library '%@'", key, self.name);
    }
}

- (void)removeAllImages
{
    // TODO:
}

@end
