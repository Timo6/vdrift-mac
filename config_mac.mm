#import <Cocoa/Cocoa.h>

char* get_mac_data_dir()
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *optionsPath = @"/settings/options.config";
    NSString *optionsPathLong = @"/data/settings/options.config";
    
    NSString *basePath = [[bundle bundlePath] stringByDeletingLastPathComponent];
    NSString *resourcePath = [bundle resourcePath];
    NSString *lastPath = [values valueForKey:@"LastPath"];
    NSString *choosenPath = [values valueForKey:@"ChoosenPath"];
    NSString *path;
    
    if ([fileManager fileExistsAtPath:[lastPath stringByAppendingPathComponent:optionsPath]])
    {
        path = lastPath;
    }
    else if ([fileManager fileExistsAtPath:[basePath stringByAppendingPathComponent:optionsPathLong]])
    {
        path = [[basePath stringByAppendingString:@"/data"] stringByResolvingSymlinksInPath];
        [values setValue:path forKey:@"LastPath"];
    }
    else if ([fileManager fileExistsAtPath:[resourcePath stringByAppendingPathComponent:optionsPathLong]])
    {
        path = [[resourcePath stringByAppendingString:@"/data"] stringByResolvingSymlinksInPath];
        [values setValue:path forKey:@"LastPath"];
    }
    else if ([fileManager fileExistsAtPath:[choosenPath stringByAppendingPathComponent:optionsPath]])
    {
        path = choosenPath;
        [values setValue:path forKey:@"LastPath"];
    }
    else
    {
        NSApplication *myApplication = [NSApplication sharedApplication];
        
        NSAlert *firstAlert = [NSAlert alertWithMessageText: @"Can't find data"
                                              defaultButton: @"Choose"
                                            alternateButton: @"Quit"
                                                otherButton: nil
                                  informativeTextWithFormat: @"Please choose the data folder."];
        
        if ([firstAlert runModal] == NSAlertDefaultReturn)
        {
            NSOpenPanel *findData = [NSOpenPanel openPanel];
            [findData setAllowsMultipleSelection:NO];
            [findData setCanChooseDirectories:YES];
            [findData setCanChooseFiles:NO];
            [findData setResolvesAliases:YES];
            
            if ([findData runModal] == NSFileHandlingPanelOKButton)
            {
                path = [[[findData URLs] objectAtIndex:0] path];
                [values setValue:path forKey:@"ChoosenPath"];
                [values setValue:path forKey:@"LastPath"];
                
                if (![fileManager fileExistsAtPath:[path stringByAppendingPathComponent:optionsPath]])
                {
                    NSAlert *secondAlert = [NSAlert alertWithMessageText: @"Can't find data"
                                                           defaultButton: @"Quit"
                                                         alternateButton: nil
                                                             otherButton: nil
                                               informativeTextWithFormat: @"Please check the folder you choose contains the data."];
                    [secondAlert runModal];
                    
                    [pool release];
                    exit(1);
                }
            }
            else
            {
                [pool release];
                exit(1);
            }
        }
        else
        {
            [pool release];
            exit(1);
        }
    }
    
    if ([path canBeConvertedToEncoding:NSUTF8StringEncoding])
    {
        int len = [path lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        char* cpath = (char*) malloc(len + 2);
        
        [path getCString:cpath maxLength:len + 1 encoding:NSUTF8StringEncoding];
        cpath[len] = '\0';
        
        [pool release];
        
        return cpath;
    }
    else
    {
        NSApplication *myApplication = [NSApplication sharedApplication];
        
        NSAlert *saneAlert = [NSAlert alertWithMessageText: @"Can't find data"
                                             defaultButton: @"Quit"
                                           alternateButton: nil
                                               otherButton: nil
                                 informativeTextWithFormat: @"Please move the data to a sane location on your computer, without weird characters in it's path!"];
        
        [saneAlert runModal];
        
        [pool release];
        exit(1);
    }
}
