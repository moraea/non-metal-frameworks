// might as well take advantage of loading in every graphical process!

const NSString* PLUGIN_PATH=@"/Library/Application Support/SkyLightPlugins";

// using NSFileManager in early boot causes a hang

NSArray<NSString*>* listFolderEarlyBoot(NSString* path)
{
	DIR* folder=opendir(path.UTF8String);
	if(!folder)
	{
		return nil;
	}
	
	NSMutableArray<NSString*>* files=NSMutableArray.alloc.init;
	while(true)
	{
		struct dirent* file=readdir(folder);
		if(!file)
		{
			break;
		}
		
		NSString* name=[NSString stringWithUTF8String:file->d_name];
		[files addObject:name];
	}
	
	closedir(folder);
	
	return files.autorelease;
}


BOOL pluginLoggingValue;
dispatch_once_t pluginLoggingOnce;
BOOL pluginLogging()
{
	dispatch_once(&pluginLoggingOnce,^()
	{
		pluginLoggingValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_PluginLogging"];
	});
	
	return pluginLoggingValue;
}

void pluginsSetup()
{
	NSArray<NSString*>* files=listFolderEarlyBoot((NSString*)PLUGIN_PATH);
	if(!files)
	{
		return;
	}
	
	for(NSString* file in files)
	{
		if(![file.pathExtension isEqualToString:@"txt"])
		{
			continue;
		}
		
		NSString* infoPath=[PLUGIN_PATH stringByAppendingPathComponent:file];
		NSString* infoString=[NSString stringWithContentsOfFile:infoPath encoding:NSUTF8StringEncoding error:nil];
		if(!infoString)
		{
			continue;
		}
		
		NSArray<NSString*>* infoLines=[infoString componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
		if(![infoLines containsObject:@"*"]&&![infoLines containsObject:process])
		{
			continue;
		}
		
		NSString* dylibName=[file.stringByDeletingPathExtension stringByAppendingPathExtension:@"dylib"];
		NSString* dylibPath=[PLUGIN_PATH stringByAppendingPathComponent:dylibName];
		void* handle=dlopen(dylibPath.UTF8String,RTLD_NOW);
		
		// logging in early boot causes a hang
		
		if(!earlyBoot)
		{
			if(pluginLogging()){
				if(handle)
				{
					trace(@"plugin: loaded %@",dylibName);
				}
				else
				{
					trace(@"plugin: %s",dlerror());
				}
			}
		}
		
		void (*entry)()=dlsym(handle,"SkyLightPluginEntry");
		if(entry)
		{
			if(!earlyBoot)
			{
				trace(@"plugin: found initializer %p",entry);
			}
			
			entry();
		}
	}
}