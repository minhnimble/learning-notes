# Definition

Create an intermediary between two incompatible class interfaces, allowing one to work with the other. Think of the adapter class as a wrapper around an object of another class.

# Example code

```dart
class Post {
  final String title;
  final String content;

  const Post(this.title, this.content);
}

// Mock Data
class SiteApi1 {
  String getSite1Posts() {
    return '[{"headline": "Title1", "text": "Sample text..."}]';
  }
}

class SiteApi2 {
  String getSite2Posts() {
    return '[{"header": "Title1", "body": "Sample text..."}]';
  }
}

// We start by creating an interface
abstract class IPostsAPI {
  List<Post> getPosts();
}

// Implement the interface `IPostsAPI` for Adapter
import 'dart:convert';

class Site1Adapter implements IPostsAPI {
  final api = SiteApi1();

  List<Post>getPosts() {
    final rawPosts = jsonDecode(api.getSite1Posts()) as List;

    return rawPosts.map((post) =>
        Post(post['headline'], post['text'])).toList();
  }
}

class Site2Adapter implements IPostsAPI {
  final api = SiteApi2();

  List<Post>getPosts() {
    final rawPosts = jsonDecode(api.getSite2Posts()) as List;

    return rawPosts.map((post) =>
        Post(post['header'], post['body'])).toList();
  }
}

// Use the same posts data
final IPostsAPI api1 = Site1Adapter();
final IPostsAPI api2 = Site2Adapter();

final List<Post> posts = api1.getPosts() + api2.getPosts();
```