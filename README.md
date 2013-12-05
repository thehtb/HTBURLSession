= HTBURLSession - A drop-in equivalent replacement for NSURLSession with better blocks support

Behaviour should be identical to NSURLSession as all actual work is forwarded to an NSURLSession
instance internally. The only difference is that completion blocks and delegate callbacks are not
mutually exclusive (which they are with NSURLSession).

The only NSURLSession method not supported is `sharedSession` which is a bad idea IMO anyway.

== For the love of Cocoa, why?

I like NSURLSession. It makes easy things easy and hard things possible, which is good, but a great
api should also not behave in unexpected ways. Unfortunately NSURLSession has a few unexpected
behaviours. The first one that tripped me up is that as soon as you use the convenient `completionHandler`
blocks, you no longer get delegate callbacks for those tasks. Why? I have no idea. It is documented,
but I found it unexpected and akward. The completionHandler blocks are not direct replacements for
the delegate methods and so are basically useless.

An obvious workaround could be implemented with a category, but
another unexpected thing about NSURLSession is it's class hierarchy seems to be pretend (compare
the docs with what `isKindOfClass` returns for an NSURLSessionDownloadTask in the real world...).
NSURLSession also cannot be transparently subclassed because, amongst other issues, it's class methods
do not return instancetype.

But I still like the NSURLSession api, it strikes the balance between being simple and powerful very
elegantly.

So I decided to wrap NSURLSession in a near-transparent drop-in wrapper that calls both delegate
methods and completionHandler blocks.

== Y U no CocoPod?

This is too early to even reasonably be called version 0.0.1.

== Caveats

This is a very early release. The only thing I'm using it for in any meaningful way is simple
data tasks and download tasks, YMMV.

Please submit bug reports and pull requests.

== TODO

I plan to also expand block support very simply, by adding further convenience methods with
additional progress completion callback blocks, eliminating the need for a delegate in simple
cases.
