#import <Cocoa/Cocoa.h>

char* get_mac_data_dir()
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
    
    NSString    *basePath = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
    NSString    *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString    *path;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[resourcePath stringByAppendingString:@"/data/settings/options.config"]])
    {
        path = [resourcePath stringByAppendingString:@"/data"];
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:[basePath stringByAppendingString:@"/data/settings/options.config"]])
    {
        path = [basePath stringByAppendingString:@"/data"];
    }
    else
    {
        NSApplication   *myApplication;
        myApplication = [NSApplication sharedApplication];
        
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
            [findData setCanCreateDirectories:NO];
            [findData setResolvesAliases:NO];
            [findData setDirectory:basePath];
            [findData setTitle:@"Choose Data Folder"];
            
            if ([findData runModal] == NSFileHandlingPanelOKButton)
            {
                path = [[findData filenames] objectAtIndex:0];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingString:@"/settings/options.config"]])
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
    
    CFStringRef resolvedPath = nil;
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, true);
    
    if (url != NULL)
    {
        FSRef fsRef;
        
        if (CFURLGetFSRef(url, &fsRef))
        {
            Boolean isFolder, isAlias;
            OSErr oserr = FSResolveAliasFile (&fsRef, true, &isFolder, &isAlias);
            
            if(oserr != noErr)
            {
                NSLog(@"FSResolveAliasFile failed: status = %d", oserr);
            }
            else
            {
                if(isAlias)
                {
                    CFURLRef resolved_url = CFURLCreateFromFSRef(NULL, &fsRef);
                    
                    if (resolved_url != NULL)
                    {
                        resolvedPath = CFURLCopyFileSystemPath(resolved_url, kCFURLPOSIXPathStyle);
                        CFRelease(resolved_url);
                    }
                }
            }
        }
        else // Failed to convert URL to a file or directory object.
        {
            NSApplication *myApplication;
            myApplication = [NSApplication sharedApplication];
            
            NSAlert *theAlert = [NSAlert alertWithMessageText: @"Can't find data"
                                                defaultButton: @"Quit"
                                              alternateButton: nil
                                                  otherButton: nil
                                    informativeTextWithFormat: @"Please make sure a folder named \"data\" is in:\n - the same folder as VDrift.app; or\n - VDrift.app/Contents/Resources"];
            [theAlert runModal];
            
            [pool release];
            exit(1);
        }
    }
    
    if(resolvedPath != nil)
    {
        path = [NSString stringWithString:(NSString *)resolvedPath];
        CFRelease(resolvedPath);
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
        NSApplication *myApplication;
        myApplication = [NSApplication sharedApplication];
        
        NSAlert *theAlert = [NSAlert alertWithMessageText: @"Can't find data"
                                            defaultButton: @"Quit"
                                          alternateButton: nil
                                              otherButton: nil
                                informativeTextWithFormat: @"Please move VDrift to a sane location on your computer, without weird characters in it's path!"];
        
        [theAlert runModal];
        
        [pool release];
        exit(1);
    }
}
