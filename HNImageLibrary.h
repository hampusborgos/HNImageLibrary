//
//  HNImageLibrary.h
//  An intelligent image store
//
//  Created by Hampus Nilsson on 6/1/13.
//  Copyright (c) 2013 hjnilsson. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const HNImageLibraryDefaultName = @"Default";

@interface HNImageLibrary : NSObject

/**
 * The cache used by the library to store images in memory
 * You can access this directly without any worries
 */
@property NSCache *cache;

/**
 * The name of the image library
 */
@property (nonatomic, readonly) NSString *name;

/**
 * The path to the directory where images are stored on disk
 */
@property (nonatomic, readonly) NSString *libraryPath;

/**
 * If yes, images will be saved as PNGs per default, otherwise JPEGs
 */
@property (nonatomic) BOOL defaultLossless;

/**
 * The compression quality passed to the jpeg writer for lossfull images
 */
@property (nonatomic) CGFloat jpegQuality;

/**
 * Creates a new image library
 * You should not create 2 image libraries with the same name, as they will clash
 * Images put into different libraries cannot be seen from the others, they are entirely separate
 * Don't name your custom library 'Default'
 * Lossless indicates if images are stored as jpegs or pngs, default is NO (jpegs).
 */
- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name defaultLossless:(BOOL)lossless;

/**
 * The default image library, the name of it is 'Default'
 */
+ (HNImageLibrary *)defaultLibrary;

/**
 * Thread-safe way to fetch a global library by name
 */
+ (HNImageLibrary *)libraryWithName:(NSString *)name;

/**
 * Puts an image into the library, it will be stored to disk asyncrounously
 * The completion / error handler, if passed, will be called once the image has been stored (the function returns immediately)
 * If lossless is true, the image will be stored in PNG format, otherwise JPEG
 */
- (void)setImage:(UIImage *)image forKey:(NSString *)key lossless:(BOOL)lossless completion:(void(^)(UIImage *image))completionHandler error:(void (^)(UIImage *, NSError *))errorHandler;
- (void)setImage:(UIImage *)image forKey:(NSString *)key completion:(void(^)(UIImage *image))completionHandler error:(void (^)(UIImage *, NSError *))errorHandler;
- (void)setImage:(UIImage *)image forKey:(NSString *)key lossless:(BOOL)lossless;
- (void)setImage:(UIImage *)image forKey:(NSString *)key;

/**
 * Returns the file system path for a specific cache key
 */
- (NSString *)pathForKey:(NSString *)key;

/**
 * Loads the specified image, either from cache or disk
 */
- (UIImage *)imageForKey:(NSString *)key;

/**
 * Remove the specified image from the cache and deletes it from disk
 */
- (void)removeImageForKey:(NSString *)key;

/**
 * Removes all images from the library, freeing up all disk space currently in use
 * This cancels all ongoing saves as well
 */
- (void)removeAllImages;

@end
