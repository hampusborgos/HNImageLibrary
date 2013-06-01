HNImageLibrary
==============

An simple image library that stores UIImages in a persistent way with caching.

This allows you to put away your images (thumbnails, previews) somewhere where you
don't really care where they are and they will be retrievable at any time.

This is not a cache, it will store images on disk forever if you do not remove them.
If you want a cache check out [JMImageCache](https://github.com/jakemarsh/JMImageCache).

Usage
=============
Put an image in the library:

    [[HNImageLibrary libraryWithName:@"MyLibrary"] setImage:img forKey:@"Awesome"];

Retrieve an image from the same library:

    [[HNImageLibrary libraryWithName:@"MyLibrary"] imageForKey:@"Awesome"];

That's all there is to it! The header file is well-commented so if you have any
questions look in there.
