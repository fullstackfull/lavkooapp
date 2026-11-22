import 'package:flutter/foundation.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';

/// A customer moving from one storefront to another, as everything that has to react to it is told.
class StorefrontChange {
  const StorefrontChange({
    required this.previous,
    required this.current,
    required this.signedIn,
  });

  final StorefrontCountry previous;
  final StorefrontCountry current;

  /// Whether a customer is signed in, for the lists that only a signed-in customer has: a guest asking for them is refused, and a refusal
  /// signs the guest out.
  final bool signedIn;
}

/// Something that holds what a storefront decides: its lists of products, its banners, its cart.
abstract interface class StorefrontChangeListener {
  /// Called once, after the app's requests have started to ask for [StorefrontChange.current].
  ///
  /// Whatever is held for [StorefrontChange.previous] must be dropped before the first `await`, and the screens told, so the customer
  /// never sees the storefront they left: every listener is called one after another, and the drops of all of them have happened before
  /// the first reload gets an answer. What is on screen is then loaded again, for the storefront the customer is on now.
  Future<void> onStorefrontChanged(StorefrontChange change);
}

/// What happens when the customer chooses another storefront, in one place, the way a language change does it for the language: the
/// answers cached for the storefront they left are cleared, in the HTTP cache and in the local database, and everything that holds data
/// of that storefront is told to drop it and load again.
///
/// It is not what makes the change. The storefront chooser saves the choice and rebuilds the request headers first; this runs after, so
/// every reload asks for the storefront the customer is on.
class StorefrontChangeNotifier {
  StorefrontChangeNotifier({
    required this.clearHttpCache,
    required this.clearLocalCache,
    required this.isSignedIn,
    this.enabled = StorefrontConfig.enabled,
  });

  /// Forgets the HTTP cache's answers for a storefront, in memory and on disk.
  final void Function(String storefrontCode) clearHttpCache;

  /// Deletes the local database's rows for a storefront.
  final Future<void> Function(String storefrontCode) clearLocalCache;

  final bool Function() isSignedIn;

  /// While storefronts are off nothing changes and nothing here runs. It defaults to the build flag and is a parameter so both settings
  /// can be tested in one run.
  final bool enabled;

  final List<StorefrontChangeListener> _listeners =
      <StorefrontChangeListener>[];

  @visibleForTesting
  int get listenerCount => _listeners.length;

  void register(StorefrontChangeListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void unregister(StorefrontChangeListener listener) {
    _listeners.remove(listener);
  }

  /// Clears what [previous] cached and tells every listener. It completes when they have all loaded again, and never throws: a listener
  /// that cannot reload leaves its own lists empty and the others are not held up by it.
  Future<void> storefrontChanged({
    required StorefrontCountry previous,
    required StorefrontCountry current,
  }) async {
    if (!enabled || previous.code == current.code) {
      return;
    }

    final StorefrontChange change = StorefrontChange(
      previous: previous,
      current: current,
      signedIn: isSignedIn(),
    );

    // Every call below runs up to its first await at once, in this loop: the drops of all the listeners come before any reload's answer.
    await Future.wait(<Future<void>>[
      _clearHttp(previous.code),
      _clearLocal(previous.code),
      for (final StorefrontChangeListener listener
          in List<StorefrontChangeListener>.of(_listeners))
        _tell(listener, change),
    ]);
  }

  Future<void> _clearHttp(String storefrontCode) async {
    try {
      clearHttpCache(storefrontCode);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[storefront] http cache not cleared: ${error.runtimeType}');
      }
    }
  }

  Future<void> _clearLocal(String storefrontCode) async {
    try {
      await clearLocalCache(storefrontCode);
    } catch (error) {
      // The rows of a storefront the customer left are only unreachable, never wrong, so failing to delete them costs nothing but space.
      if (kDebugMode) {
        debugPrint(
            '[storefront] local cache not cleared: ${error.runtimeType}');
      }
    }
  }

  Future<void> _tell(
    StorefrontChangeListener listener,
    StorefrontChange change,
  ) async {
    try {
      await listener.onStorefrontChanged(change);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[storefront] a listener failed: ${error.runtimeType}');
      }
    }
  }
}

/// For a controller that holds what a storefront decides. It joins the notifier when it is built and leaves it when it is disposed, so
/// the notifier never holds a controller that is gone. A controller built without a notifier, as the tests of most controllers do, is
/// simply not told.
mixin StorefrontChangeAware on ChangeNotifier
    implements StorefrontChangeListener {
  StorefrontChangeNotifier? _storefrontChangeNotifier;

  /// Call it once, from the constructor.
  void followStorefrontChanges(StorefrontChangeNotifier? notifier) {
    _storefrontChangeNotifier = notifier;
    notifier?.register(this);
  }

  @override
  void dispose() {
    _storefrontChangeNotifier?.unregister(this);
    super.dispose();
  }
}
