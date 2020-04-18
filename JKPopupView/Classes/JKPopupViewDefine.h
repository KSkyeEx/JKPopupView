//
//  JKPopupViewDefine.h
//  Pods
//
//  Created by weij on 2020/4/18.
//

#ifndef JKPopupViewDefine_h
#define JKPopupViewDefine_h

/*！
 * 强弱引用转换，用于解决代码块（block）与强引用self之间的循环引用问题
 */
#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) @autoreleasepool{} __weak __typeof__(object) weak##_##object = object
#else
#define weakify(object) @autoreleasepool{} __block __typeof__(object) block##_##object = object
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) @try{} @finally{} {} __weak __typeof__(object) weak##_##object = object
#else
#define weakify(object) @try{} @finally{} {} __block __typeof__(object) block##_##object = object
#endif
#endif
#endif

/*！
 * 强弱引用转换，用于解决代码块（block）与强引用对象之间的循环引用问题
 */
#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) @autoreleasepool{} __typeof__(object) object = weak##_##object
#else
#define strongify(object) @autoreleasepool{} __typeof__(object) object = block##_##object
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) @try{} @finally{} __typeof__(object) object = weak##_##object
#else
#define strongify(object) @try{} @finally{} __typeof__(object) object = block##_##object
#endif
#endif
#endif

#endif /* JKPopupViewDefine_h */
