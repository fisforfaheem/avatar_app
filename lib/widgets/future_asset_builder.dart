import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A builder that asynchronously loads an asset and provides its data to a child widget.
class FutureAssetBuilder extends StatefulWidget {
  /// A unique key identifying the asset to load (e.g., a URL or DB key).
  final String assetKey;

  /// The asynchronous function that takes the key and returns the asset's byte data.
  final Future<Uint8List?> Function(String key) loader;

  /// A builder function that receives the loaded data and returns the widget to display.
  final Widget Function(BuildContext context, Uint8List? data) builder;

  /// A widget to display while the asset is loading.
  final Widget? loadingWidget;

  /// A widget to display if an error occurs during loading.
  final Widget? errorWidget;

  const FutureAssetBuilder({
    super.key,
    required this.assetKey,
    required this.loader,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<FutureAssetBuilder> createState() => _FutureAssetBuilderState();
}

class _FutureAssetBuilderState extends State<FutureAssetBuilder> {
  late Future<Uint8List?> _assetFuture;

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  @override
  void didUpdateWidget(FutureAssetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the key changes, trigger a reload of the asset.
    if (widget.assetKey != oldWidget.assetKey) {
      _loadAsset();
    }
  }

  void _loadAsset() {
    _assetFuture = widget.loader(widget.assetKey);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _assetFuture,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
          case ConnectionState.active:
            return widget.loadingWidget ??
                const Center(child: CircularProgressIndicator());
          case ConnectionState.done:
            if (snapshot.hasError || snapshot.data == null) {
              return widget.errorWidget ??
                  const Center(child: Icon(Icons.broken_image));
            }
            // Pass the loaded data to the builder function.
            return widget.builder(context, snapshot.data);
          case ConnectionState.none:
            return widget.errorWidget ??
                const Center(child: Icon(Icons.error, color: Colors.red));
        }
      },
    );
  }
}
