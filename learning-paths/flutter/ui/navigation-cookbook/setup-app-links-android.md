Deep linking is a mechanism for launching an app with a URI. 
URI contains scheme, host, and path, and opens the app to a specific screen.
An app link is a type of deep link that uses `http` or `https` and is exclusive to Android devices => Setting up app links requires one to own a web domain.
Consider using [Firebase Hosting](https://firebase.google.com/docs/hosting) or [GitHub Pages](https://pages.github.com/) as a temporary solution.

- [Step-by-step tutorial](https://docs.flutter.dev/cookbook/navigation/set-up-app-links)
- Complete code example - [deeplink_cookbook - Android](https://github.com/flutter/codelabs/tree/main/deeplink_cookbook/android)