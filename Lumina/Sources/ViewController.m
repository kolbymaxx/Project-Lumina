#import "ViewController.h"
#import "LogCapture.h"
#include "krw.h"

@interface ViewController ()
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UIButton *runButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) BOOL running;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Lumina";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationController.navigationBar.prefersLargeTitles = YES;

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.statusLabel.text = @"DS-K lab harness — not a jailbreak. Tap Run DS-K.";
    [self.view addSubview:self.statusLabel];

    self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.runButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.runButton setTitle:@"Run DS-K" forState:UIControlStateNormal];
    self.runButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.runButton addTarget:self
                       action:@selector(runTapped)
             forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.runButton];

    self.logView = [[UITextView alloc] init];
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logView.editable = NO;
    self.logView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    self.logView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.logView.text = @"Ready.\n";
    [self.view addSubview:self.logView];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.topAnchor constraintEqualToAnchor:g.topAnchor constant:12],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],

        [self.runButton.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:12],
        [self.runButton.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],

        [self.logView.topAnchor constraintEqualToAnchor:self.runButton.bottomAnchor constant:12],
        [self.logView.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:8],
        [self.logView.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-8],
        [self.logView.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-8],
    ]];
}

- (void)appendLog:(NSString *)line
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logView.text = [self.logView.text stringByAppendingFormat:@"%@\n", line];
        NSRange bottom = NSMakeRange(self.logView.text.length, 0);
        [self.logView scrollRangeToVisible:bottom];
    });
}

- (void)runTapped
{
    if (self.running) {
        return;
    }
    self.running = YES;
    self.runButton.enabled = NO;
    self.statusLabel.text = @"Running DS-K… (UI may freeze during race)";
    self.logView.text = @"";
    [self appendLog:@"=== Lumina DS-K session ==="];
    [self appendLog:[NSString stringWithFormat:@"krw.h codes: OK=%d NO_BACKEND=%d NOT_INIT=%d IO=%d NOT_LINKED=%d",
                     KRW_OK, KRW_ERR_NO_BACKEND, KRW_ERR_NOT_INIT, KRW_ERR_IO, KRW_ERR_NOT_LINKED]];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [[LogCapture shared] startRedirectingToFile];
        printf("[*] calling krw_init()\n");
        fflush(stdout);

        int rc = krw_init();
        uint64_t base = kbase();
        uint64_t slide = kslide();

        NSString *captured = [[LogCapture shared] drainFileContents];

        /* Optional read probe — only if init succeeded. Never invent expected bytes. */
        NSString *readNote = @"(skipped — init failed)";
        if (rc == KRW_OK && base != 0) {
            uint64_t magic = 0;
            int rr = kread(base, &magic, sizeof(magic));
            readNote = [NSString stringWithFormat:@"kread(kbase)=%d magic=%#llx", rr,
                                                  (unsigned long long)magic];
        }

        krw_deinit();

        dispatch_async(dispatch_get_main_queue(), ^{
            if (captured.length) {
                [self appendLog:captured];
            }
            [self appendLog:[NSString stringWithFormat:@"krw_init => %d", rc]];
            [self appendLog:[NSString stringWithFormat:@"kbase  => %#llx", (unsigned long long)base]];
            [self appendLog:[NSString stringWithFormat:@"kslide => %#llx", (unsigned long long)slide]];
            [self appendLog:readNote];
            [self appendLog:[self classifyResult:rc base:base]];
            [self appendLog:@"=== end (paste into docs/STATUS.md) ==="];

            if (rc == KRW_OK && base != 0) {
                self.statusLabel.text =
                    [NSString stringWithFormat:@"SUCCESS path? base=%#llx — verify magic / LAB_DSK",
                                               (unsigned long long)base];
            } else if (rc == KRW_ERR_NOT_LINKED) {
                self.statusLabel.text = @"NOT_LINKED — rebuild with third_party clone";
            } else {
                self.statusLabel.text =
                    [NSString stringWithFormat:@"Finished with krw_init=%d (see log / LAB_DSK codes)", rc];
            }
            self.running = NO;
            self.runButton.enabled = YES;
        });
    });
}

- (NSString *)classifyResult:(int)rc base:(uint64_t)base
{
    /* Human still assigns official LAB_DSK code; this is a hint only. */
    if (rc == KRW_ERR_NOT_LINKED) {
        return @"hint: FAIL_ENTRY/build — backend not linked";
    }
    if (rc == KRW_OK && base != 0) {
        return @"hint: candidate SUCCESS_KRW — confirm with LAB_DSK before claiming";
    }
    if (rc == KRW_ERR_IO) {
        return @"hint: FAIL_PATCHED or FAIL_OFFSETS or FAIL_ENTRY — inspect log/panic";
    }
    return @"hint: UNKNOWN — classify via docs/LAB_DSK.md";
}

@end
