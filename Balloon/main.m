//
//  main.m
//  Balloon
//
//  Created by Mark Madsen on 4/1/11.
//  Copyright 2011 AGiLE ANiMAL INC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
  return macruby_main("rb_main.rb", argc, argv);
}
