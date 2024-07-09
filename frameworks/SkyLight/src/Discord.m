/*

[2022-05-23 01:06:53.079] [103939] (quartz_video_source_mac.mm:187): Screen capture ending due to an internal error.

/Users/amy/Library/Application Support/discord/0.0.266/modules/discord_voice/discord_voice.node
discord::media::QuartzVideoSourceImpl::SampleHandler - unhappy
discord::media::CreateQuartzVideoSource - checks __isPlatformVersionAtLeast 10.14.0
discord::voice::Connection::SetDesktopSource - fallback if CreateQuartzVideoSource returns null
__isPlatformVersionAtLeast - uses _availability_version_check

*/

BOOL enableDiscordHack;
dispatch_once_t enableDiscordHackOnce;

BOOL _availability_version_check(int,int*);
BOOL fake_avc(int count,int* versions)
{
	dispatch_once(&enableDiscordHackOnce,^()
	{
		enableDiscordHack=[process containsString:@"/Discord.app/Contents/"];
		if(enableDiscordHack)
		{
			trace(@"Discord screenshare hack: enabled");
		}
	});
	
	if(enableDiscordHack&&count==1)
	{
		int major=(versions[1]>>16)&0xffff;
		int minor=(versions[1]>>8)&0xff;
		int subminor=versions[1]&0xff;
		
		if(major>10||minor>13)
		{
			trace(@"Discord screenshare hack: lying about %d.%d.%d",major,minor,subminor);
			return false;
		}
	}
	
	return _availability_version_check(count,versions);
}

DYLD_INTERPOSE(fake_avc,_availability_version_check)