//
//  NSRegExNamedCaptureGroup.m
//  NSRegExNamedCaptureGroup
//
//  Created by Tong G. on 16/06/2017.
//
//

#import "NSRegEx+NamedCaptureGroup.h"
#import "NSRegExNamedCaptureGroup/NSRegExNamedCaptureGroup-Swift.h"

static void* _CaptureGroupsDictAssociatedKey;
static void _swizzle( Class srcClass, SEL srcSelector, Class dstClass, SEL dstSelector );

@implementation NSTextCheckingResult ( NSRegExNamedCaptureGroup )

- ( NSRange ) rangeWithGroupName: ( nullable NSString* )groupName {
  if ( !groupName )
    return [ self rangeAtIndex: 0 ];

  NSDictionary* captureGroupsDict = objc_getAssociatedObject( self, &_CaptureGroupsDictAssociatedKey );
  NSValue* rangeWrapper = captureGroupsDict[ groupName ];
  return rangeWrapper ? rangeWrapper.rangeValue : NSMakeRange( NSNotFound, 0 );
  }

@end

@implementation NSRegularExpression ( NSRegExNamedCaptureGroup )

- ( NSArray<NSTextCheckingResult*>* ) 
_swizzling_matchesInString: ( NSString* )text
                   options: ( NSMatchingOptions )options
                     range: ( NSRange )range {
  NSArray* checkingResults = [ self _swizzling_matchesInString: text options: options range: range ];

  for ( NSTextCheckingResult* result in checkingResults ) {
    NSDictionary* captureGroupsDict = [ self rangesOfNamedCaptureGroupsInMatch: result error: nil ];
    objc_setAssociatedObject( result, &_CaptureGroupsDictAssociatedKey, captureGroupsDict, OBJC_ASSOCIATION_RETAIN );
    }

  return checkingResults;
  }

typedef void (^NSRegExEnumerationBlock)(
    NSTextCheckingResult* result
  , NSMatchingFlags flags
  , BOOL* stop
  );

- ( void )
_swizzling_enumerateMatchesInString: ( NSString* )string
                            options: ( NSMatchingOptions )options
                              range: ( NSRange )range 
                         usingBlock: ( NSRegExEnumerationBlock )block {
  NSLog( @"Woody" );
  NSRegExEnumerationBlock ourBlock =
    ^( NSTextCheckingResult* result, NSMatchingFlags flags, BOOL* stop ) {
      NSDictionary* captureGroupsDict = [ self rangesOfNamedCaptureGroupsInMatch: result error: nil ];
      objc_setAssociatedObject( result, &_CaptureGroupsDictAssociatedKey, captureGroupsDict, OBJC_ASSOCIATION_RETAIN );

      if ( block )
        block( result, flags, stop );
      };

  [ self _swizzling_enumerateMatchesInString: string
                                     options: options
                                       range: range
                                  usingBlock: ourBlock ];
  }

+ ( void ) load {
  // _swizzle(
  //     [ NSRegularExpression class ], @selector( matchesInString:options:range: )
  //   , [ NSRegularExpression class ], @selector( _swizzling_matchesInString:options:range: )
  //   );

  _swizzle(
      [ NSRegularExpression class ], @selector( enumerateMatchesInString:options:range:usingBlock: )
    , [ NSRegularExpression class ], @selector( _swizzling_enumerateMatchesInString:options:range:usingBlock: )
    );
  }

- ( NSDictionary<NSString*, NSNumber*>* ) indicesOfNamedCaptureGroupsWithError: ( NSError** )error {
  NSMutableDictionary* groupNames = [ NSMutableDictionary dictionary ];

  [ [ self _textCheckingResultsOfNamedCaptureGroups_objcAndReturnError: error ]
    enumerateKeysAndObjectsUsingBlock:
      ^( NSString* subexpr, _ObjCGroupNamesSearchResult* result, BOOL* stopToken ) {
      groupNames[ subexpr ] = @( result._index + 1 );
      } ];

  return groupNames;
  }

- ( NSDictionary<NSString*, NSValue*>* ) rangesOfNamedCaptureGroupsInMatch: ( NSTextCheckingResult* )match error: ( NSError** )error {
  NSMutableDictionary* groupNames = [ NSMutableDictionary dictionary ];

  [ [ self _textCheckingResultsOfNamedCaptureGroups_objcAndReturnError: error ]
    enumerateKeysAndObjectsUsingBlock:
      ^( NSString* subexpr, _ObjCGroupNamesSearchResult* result, BOOL* stopToken ) {
      groupNames[ subexpr ] = [ NSValue valueWithRange: [ match rangeAtIndex: result._index + 1 ] ];
      } ];

  return groupNames;
  }
@end

void _swizzle( Class srcClass, SEL srcSelector, Class dstClass, SEL dstSelector ) {
  Method srcMethod = class_getInstanceMethod( srcClass, srcSelector );
  IMP srcImp = method_getImplementation( srcMethod );

  Method dstMethod = class_getInstanceMethod( dstClass, dstSelector );
  IMP dstImp = method_getImplementation( dstMethod );

  method_setImplementation( srcMethod, dstImp );
  method_setImplementation( dstMethod, srcImp );  
  }
