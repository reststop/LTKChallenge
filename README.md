#  LTK Challenge


## Requirements

- Build a feed of full-width images that are consumed from a production API.
 
        - All of our images are in an aspect ratio that supports an edge-to-edge (full-width) UI. So, no worries there.
 
        - The feed should support pagination.

- When a user taps on one of the full-width images, then a detail view should be pushed onto the view stack. The detail view should contain product images, the hero image, and the profile picture.

        - All of this information is returned from the API. To relate the different models together (ltk, product, and profile), take a look at the JSON that is returned. There are top-level lists for each of these. The ltk has a list of associated product_idsand an associated profile_id.

- When a user taps on one of the product images, then the associated
`products.hyperlink` should resolve in a WebView (either in safari or in the app itself).

- To power the above requirements, you’ll consume the following public API:
https://api-gateway.rewardstyle.com/api/ltk/v2/ltks/?featured=true&limit=20


## Libraries, git submodules

When cloning this repository use the terminal command:

```
git clone --recursive https://github.com/reststop/LTKChallenge
```

That should also clone the Alamofire and AlamofireImage submodules
and put things into the correct places for Xcode on your machine.



### Alamofire
- AF Networking for Swift 5.x

### AlamofireImage
- Image caching and retrieval integrated with Alamofire


## Language
- Swift 5


## BuildTools
- Xcode Version 13.2.1 (13C100)


## Implementation

The main view controller is encapsulated in a Navigation Controller
in order to gain some navigation control, and to stage the Back and Next
buttons which are used for pagination.  The constant LTKData.itemCount
can be modified to set an appropriate number of entries for each page.

The screens were designed for the iPhone 13 Pro Max, but some attempt was
made to see that it runs on a real device, an iPhone SE without too much
of an issue with the Detail screen being unable to see the profile image.
It is in a scroll view with bounce enabled so the user can drag the
screen up to view the entire profile picture, which is otherwise cut
off near the bottom of the screen.  (Some improvement culd be made to
make the scroll easier or smoother, but not enough time for this effort).

A placeholder image is used when there is network congestion, and there
is certainly a difference running on the simulator vs. a device on 4G.

Opening a webURL for the product hyperlink was made synchronous for
use with a WKWebView, but it is not clear that any speed difference
would be seen with an asynchronous machanism.


## Timing and implementation concerns and decisions

I did take longer than 3 hours, but the main code was written in that
time, with the storyboards 99% complete.  The remaining time was spent
fighting with getting the storyboard items to do what I wanted, rather
than what they wanted to do themselves.  I wasted time attempting to
use a UIPageViewController, and ripped it out and started over with the
Navigation Controller after seeing that others on StackOverflow and the
Apple forums were having the same issues with black screens, with no
answer in sight.  I was also seeing issues with loading images, so I
implemented a cheap alternative to the Alamofire Image cache to do A/B
testing of two implementations of grabbing and caching images from
the network.

## Discussion

I look forward to discussing my implementation.




