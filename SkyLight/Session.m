// logout

void SLSSessionSwitchToAuditSessionIDWithOptions(unsigned int edi_sessionID,NSDictionary* rsi_options)
{
	BOOL cube=[rsi_options[kSLSSessionSwitchTransitionTypeKey] isEqual:kSLSSessionSwitchTransitionTypeCube];
	SLSSetSessionSwitchCubeAnimation(cube);
	
	SLSSessionSwitchToAuditSessionID(edi_sessionID);
}
