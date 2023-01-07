// since we are swapping Defenestrator implementations rapidly
// it may help to have a standard interface for them
// both for Main and things like CABL that may depend on Defenestrator

// all future Defenestrator*.m MUST implement these!

@protocol DefenestratorWrapper

@property(assign) int wid;
@property(assign) int sid;
@property(assign) CAContext* context;

@end

void defenestratorSetup();

NSObject<DefenestratorWrapper>* defenestratorGetWrapper(int);

// TODO: D1 compatibility, update other shims and remove
NSObject<DefenestratorWrapper>* wrapperForWindow(int wid)
{
	return defenestratorGetWrapper(wid);
}

typedef void (^DefenestratorBlock)(NSObject<DefenestratorWrapper>*);
void defenestratorRegisterOnce(dispatch_block_t);
void defenestratorRegisterCreation(DefenestratorBlock);
void defenestratorRegisterDestruction(DefenestratorBlock);
void defenestratorRegisterUpdate(DefenestratorBlock);