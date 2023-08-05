// hacks for Books features that require Metal
// TODO: generates an enormous amount of warnings

Class soft_NSWindow;
Class soft_NSColor;
Class soft_NSBitmapImageRep;
#define NSBackingStoreBuffered 2

void books_fake_start(NSObject* self, SEL sel) {
    dispatch_async(dispatch_get_main_queue(), ^() {
        CALayer* layer = [self configureLayer];
        layer.geometryFlipped = 1;
        CALayer* container = CALayer.alloc.init;
        [container addSublayer:layer];

        NSObject* window = [[soft_NSWindow alloc] initWithContentRect:layer.bounds styleMask:0 backing:NSBackingStoreBuffered defer:false];
        NSObject* view = [window contentView];
        [view setWantsLayer:true];
        [view setLayer:container];
        container.release;
        [window setOpaque:false];
        [window setBackgroundColor:[soft_NSColor clearColor]];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^() {
            int wid = [window windowNumber];
            NSArray* images = SLSHWCaptureWindowList(SLSMainConnectionID(), &wid, 1, 0);
            window.release;

            if (!images) {
                trace(@"Amy.BooksHack failed");
                return;
            }

            NSObject* image = [[soft_NSBitmapImageRep alloc] initWithCGImage:images[0]];
            image.autorelease;
            trace(@"Amy.BooksHack generated cover %@", image);

            [self completeWithImage:image];
        });
    });
}

void (*books_real_turnPages)(NSObject*, SEL, void*, BOOL);

void books_fake_turnPages(NSObject* self, SEL sel, void* rdx, BOOL animated) { books_real_turnPages(self, sel, rdx, false); }

void booksHackSetup() {
    if ([process isEqual:@"/System/Applications/Books.app/Contents/MacOS/Books"]) {
        soft_NSWindow = NSClassFromString(@"NSWindow");
        soft_NSColor = NSClassFromString(@"NSColor");
        soft_NSBitmapImageRep = NSClassFromString(@"NSBitmapImageRep");

        swizzleImp(@"_BCULayerRendererOperation", @"start", true, (IMP)books_fake_start, NULL);
        swizzleImp(@"BKFlowingBookViewController", @"turnPages:animated:", true, (IMP)books_fake_turnPages, (IMP*)&books_real_turnPages);
    }
}