// ignore_for_file: unused_element, no_wildcard_variable_uses

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/utils/log.dart';

class CommonNetImage extends StatefulWidget {
  const CommonNetImage({
    super.key,
    this.height,
    this.width,
    this.compressionRatio = 1,
    this.fit = BoxFit.contain,
    required this.url,
    this.errorWidgetBuilder,
    this.placeholder,
    this.alignment = Alignment.center,
    this.enableSlideOutPage = false,
    this.mode = ExtendedImageMode.none,
    this.imageCacheName,
    this.initGestureConfigHandler,
    this.loadStateChanged,
    this.gaplessPlayback = true,
    this.imageBuilder,
  });

  final String url;
  final double? height;
  final double? width;
  final double compressionRatio;
  final BoxFit? fit;
  final LoadingErrorWidgetBuilder? errorWidgetBuilder;
  final PlaceholderWidgetBuilder? placeholder;
  final AlignmentGeometry alignment;
  final bool enableSlideOutPage;
  final bool gaplessPlayback;
  final ExtendedImageMode mode;
  final String? imageCacheName;
  final InitGestureConfigHandler? initGestureConfigHandler;
  final LoadStateChanged? loadStateChanged;
  final ImageWidgetBuilder? imageBuilder;

  @override
  State<CommonNetImage> createState() => _CommonNetImageState();
}

class _CommonNetImageState extends State<CommonNetImage> {
  // CancellationToken? _cancelToken;

  // @override
  // void initState() {
  //   _cancelToken = CancellationToken();
  //   super.initState();
  // }

  // @override
  // void dispose() {
  //   // 快速滑动的过程中释放资源：作用不大
  //   _cancelToken?.cancel('dispose');
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double? width = widget.width ?? constraints.maxWidth;
        double? height = widget.height ?? constraints.maxHeight;
        // 置空进行自适应父空间尺寸
        if (width == double.infinity) {
          width = null;
        }
        if (height == double.infinity) {
          height = null;
        }

        return _DefaultExtendedImage.network(
          widget.url,
          fit: widget.fit ?? BoxFit.cover,
          height: height,
          width: width,
          // 重新渲染的过程中是否展示上一张图片
          gaplessPlayback: widget.gaplessPlayback,
          // 加上这两个属性，在使用 hero 会导致图片重复加载？？？
          // hero 动画效果很差
          // clearMemoryCacheWhenDispose: true,
          // cancelToken: _cancelToken,
          compressionRatio: widget.compressionRatio,
          enableSlideOutPage: widget.enableSlideOutPage,
          mode: widget.mode,
          imageCacheName: widget.imageCacheName,
          initGestureConfigHandler: widget.initGestureConfigHandler,
          loadStateChanged: widget.loadStateChanged,
          imageBuilder: widget.imageBuilder,
          errorWidget: (e, __) =>
              widget.errorWidgetBuilder?.call(e, __) ??
              _buildDefaultErrorWidget(context, height),
          placeholder: (c) =>
              widget.placeholder?.call(c) ??
              Container(
                alignment: Alignment.center,
                child: const CupertinoActivityIndicator(),
              ),
        );
      },
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context, double? height) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
          if (height != null && height > 80) ...[
            const SizedBox(height: 8),
            Text(
              'load failed',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 14 / 10,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

typedef PlaceholderWidgetBuilder = Widget? Function(BuildContext context);
typedef ImageWidgetBuilder =
    Widget Function(BuildContext context, ImageProvider imageProvider);
typedef ProgressIndicatorBuilder =
    Widget Function(BuildContext context, ImageChunkEvent progress);

typedef LoadingErrorWidgetBuilder =
    Widget? Function(BuildContext context, dynamic error);

class _DefaultExtendedImage extends StatelessWidget {
  final bool enableSlideOutPage;

  final InitGestureConfigHandler? initGestureConfigHandler;

  final ExtendedImageMode mode;

  final ImageProvider image;

  final double? width;

  final double? height;

  final BoxConstraints? constraints;

  final BoxFit? fit;

  final bool gaplessPlayback;

  final PlaceholderWidgetBuilder? placeholder;

  final LoadingErrorWidgetBuilder? errorWidget;

  final ImageWidgetBuilder? imageBuilder;

  final LoadStateChanged? loadStateChanged;

  _DefaultExtendedImage.network(
    String url, {
    this.width,
    this.height,
    this.fit,
    this.gaplessPlayback = false,
    this.loadStateChanged,

    this.mode = ExtendedImageMode.none,

    this.initGestureConfigHandler,
    this.enableSlideOutPage = false,
    BoxConstraints? constraints,
    CancellationToken? cancelToken,
    int retries = 3,
    Duration? timeLimit,
    Map<String, String>? headers,
    bool cache = true,
    double scale = 1.0,
    Duration timeRetry = const Duration(milliseconds: 100),

    int? cacheWidth,
    int? cacheHeight,
    String? cacheKey,
    bool printError = true,
    double? compressionRatio,
    int? maxBytes,
    bool cacheRawData = false,
    String? imageCacheName,
    Duration? cacheMaxAge,
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
  }) : assert(cacheWidth == null || cacheWidth > 0),
       assert(cacheHeight == null || cacheHeight > 0),
       image = ExtendedResizeImage.resizeIfNeeded(
         provider: ExtendedNetworkImageSSLProvider(
           url,
           scale: scale,
           headers: headers,
           cache: cache,
           cancelToken: cancelToken,
           retries: retries,
           timeRetry: timeRetry,
           timeLimit: timeLimit,
           cacheKey: cacheKey,
           printError: printError,
           cacheRawData: cacheRawData,
           imageCacheName: imageCacheName,
           cacheMaxAge: cacheMaxAge,
         ),
         compressionRatio: compressionRatio,
         maxBytes: maxBytes,
         cacheWidth: cacheWidth,
         cacheHeight: cacheHeight,
         cacheRawData: cacheRawData,
         imageCacheName: imageCacheName,
       ),
       assert(constraints == null || constraints.debugAssertIsValid()),
       constraints = (width != null || height != null)
           ? constraints?.tighten(width: width, height: height) ??
                 BoxConstraints.tightFor(width: width, height: height)
           : constraints,
       assert(cacheWidth == null || cacheWidth > 0),
       assert(cacheHeight == null || cacheHeight > 0);

  @override
  Widget build(BuildContext context) {
    return ExtendedImage(
      image: image,
      width: width,
      height: height,
      alignment: Alignment.center,
      clearMemoryCacheIfFailed: true,
      clearMemoryCacheWhenDispose: false,
      clipBehavior: Clip.antiAlias,
      constraints: constraints,
      enableLoadState: true,
      enableSlideOutPage: enableSlideOutPage,
      filterQuality: FilterQuality.low,
      fit: fit,
      gaplessPlayback: gaplessPlayback,
      handleLoadingProgress: false,
      isAntiAlias: true,
      repeat: ImageRepeat.noRepeat,
      layoutInsets: EdgeInsets.zero,
      initGestureConfigHandler: initGestureConfigHandler,
      loadStateChanged:
          loadStateChanged ??
          (ExtendedImageState state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                if (placeholder != null) {
                  return placeholder!(context);
                } else {
                  return null;
                }
              case LoadState.completed:
                if (imageBuilder != null) {
                  return imageBuilder!(context, state.imageProvider);
                }
                return null;
              case LoadState.failed:
                if (errorWidget != null) {
                  return errorWidget!(context, state.lastException);
                } else {
                  return null;
                }
            }
          },
      matchTextDirection: false,
      mode: mode,
    );
  }
}

class ExtendedNetworkImageSSLProvider
    extends ImageProvider<ExtendedNetworkImageProvider>
    with ExtendedImageProvider<ExtendedNetworkImageProvider>
    implements ExtendedNetworkImageProvider {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments must not be null.
  ExtendedNetworkImageSSLProvider(
    this.url, {
    this.scale = 1.0,
    this.headers,
    this.cache = false,
    this.retries = 3,
    this.timeLimit,
    this.timeRetry = const Duration(milliseconds: 100),
    this.cacheKey,
    this.printError = true,
    this.cacheRawData = false,
    this.cancelToken,
    this.imageCacheName,
    this.cacheMaxAge,
  });

  /// The name of [ImageCache], you can define custom [ImageCache] to store this provider.
  @override
  final String? imageCacheName;

  /// Whether cache raw data if you need to get raw data directly.
  /// For example, we need raw image data to edit,
  /// but [ui.Image.toByteData()] is very slow. So we cache the image
  /// data here.
  @override
  final bool cacheRawData;

  /// The time limit to request image
  @override
  final Duration? timeLimit;

  /// The time to retry to request
  @override
  final int retries;

  /// The time duration to retry to request
  @override
  final Duration timeRetry;

  /// Whether cache image to local
  @override
  final bool cache;

  /// The URL from which the image will be fetched.
  @override
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  @override
  final double scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  @override
  final Map<String, String>? headers;

  /// The token to cancel network request
  @override
  final CancellationToken? cancelToken;

  /// Custom cache key
  @override
  final String? cacheKey;

  /// print error
  @override
  final bool printError;

  /// The max duration to cahce image.
  /// After this time the cache is expired and the image is reloaded.
  @override
  final Duration? cacheMaxAge;

  @override
  ImageStreamCompleter loadImage(
    ExtendedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      scale: key.scale,
      chunkEvents: chunkEvents.stream,
      debugLabel: key.url,
      informationCollector: () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<ExtendedNetworkImageProvider>('Image key', key),
        ];
      },
    );
  }

  @override
  Future<ExtendedNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<ExtendedNetworkImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(
    ExtendedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);
    final String md5Key = cacheKey ?? keyToMd5(key.url);
    ui.Codec? result;
    if (cache) {
      try {
        final Uint8List? data = await _loadCache(key, chunkEvents, md5Key);
        if (data != null) {
          result = await instantiateImageCodec(data, decode);
        }
      } catch (e) {
        if (printError) {
          logger.e({'image_url': url, 'error': e});
        }
      }
    }

    if (result == null) {
      try {
        final Uint8List? data = await _loadNetwork(key, chunkEvents);
        if (data != null) {
          result = await instantiateImageCodec(data, decode);
        }
      } catch (e) {
        if (printError) {
          logger.e({'image_url': url, 'error': e});
        }
      }
    }

    //Failed to load
    if (result == null) {
      //result = await ui.instantiateImageCodec(kTransparentImage);
      return Future<ui.Codec>.error(StateError('Failed to load $url.'));
    }

    return result;
  }

  /// Get the image from cache folder.
  Future<Uint8List?> _loadCache(
    ExtendedNetworkImageProvider key,
    StreamController<ImageChunkEvent>? chunkEvents,
    String md5Key,
  ) async {
    final Directory cacheImagesDirectory = Directory(
      join((await getTemporaryDirectory()).path, cacheImageFolderName),
    );
    Uint8List? data;
    // exist, try to find cache image file
    if (cacheImagesDirectory.existsSync()) {
      final File cacheFlie = File(join(cacheImagesDirectory.path, md5Key));
      if (cacheFlie.existsSync()) {
        if (key.cacheMaxAge != null) {
          final DateTime now = DateTime.now();
          final FileStat fs = cacheFlie.statSync();
          if (now.subtract(key.cacheMaxAge!).isAfter(fs.changed)) {
            cacheFlie.deleteSync(recursive: true);
          } else {
            data = await cacheFlie.readAsBytes();
          }
        } else {
          data = await cacheFlie.readAsBytes();
        }
      }
    }
    // create folder
    else {
      await cacheImagesDirectory.create();
    }
    // load from network
    if (data == null) {
      data = await _loadNetwork(key, chunkEvents);
      if (data != null) {
        // cache image file
        await File(join(cacheImagesDirectory.path, md5Key)).writeAsBytes(data);
      }
    }

    return data;
  }

  /// Get the image from network.
  Future<Uint8List?> _loadNetwork(
    ExtendedNetworkImageProvider key,
    StreamController<ImageChunkEvent>? chunkEvents,
  ) async {
    try {
      final Uri resolved = Uri.base.resolve(key.url);
      final HttpClientResponse? response = await _tryGetResponse(resolved);
      if (response == null || response.statusCode != HttpStatus.ok) {
        if (response != null) {
          // The network may be only temporarily unavailable, or the file will be
          // added on the server later. Avoid having future calls to resolve
          // fail to check the network again.
          await response.drain<List<int>>(<int>[]);
        }
        return null;
      }

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: chunkEvents != null
            ? (int cumulative, int? total) {
                chunkEvents.add(
                  ImageChunkEvent(
                    cumulativeBytesLoaded: cumulative,
                    expectedTotalBytes: total,
                  ),
                );
              }
            : null,
      );
      if (bytes.lengthInBytes == 0) {
        return Future<Uint8List>.error(
          StateError('NetworkImage is an empty file: $resolved'),
        );
      }

      return bytes;
    } catch (e) {
      if (printError) {
        logger.e(e);
      }
    } finally {
      await chunkEvents?.close();
    }
    return null;
  }

  Future<HttpClientResponse> _getResponse(Uri resolved) async {
    final HttpClientRequest request = await httpClient.getUrl(resolved);
    headers?.forEach((String name, String value) {
      request.headers.add(name, value);
    });
    request.headers.add('Authorization', 'Bearer ${ApiService.authorization}');
    final HttpClientResponse response = await request.close();
    if (timeLimit != null) {
      response.timeout(timeLimit!);
    }
    return response;
  }

  // Http get with cancel, delay try again
  Future<HttpClientResponse?> _tryGetResponse(Uri resolved) async {
    cancelToken?.throwIfCancellationRequested();
    return await RetryHelper.tryRun<HttpClientResponse>(
      () {
        return CancellationTokenSource.register(
          cancelToken,
          _getResponse(resolved),
        );
      },
      cancelToken: cancelToken,
      timeRetry: timeRetry,
      retries: retries,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ExtendedNetworkImageProvider &&
        url == other.url &&
        scale == other.scale &&
        cacheRawData == other.cacheRawData &&
        timeLimit == other.timeLimit &&
        cancelToken == other.cancelToken &&
        timeRetry == other.timeRetry &&
        cache == other.cache &&
        cacheKey == other.cacheKey &&
        //headers == other.headers &&
        retries == other.retries &&
        imageCacheName == other.imageCacheName &&
        cacheMaxAge == other.cacheMaxAge;
  }

  @override
  int get hashCode => Object.hash(
    url,
    scale,
    cacheRawData,
    timeLimit,
    cancelToken,
    timeRetry,
    cache,
    cacheKey,
    //headers,
    retries,
    imageCacheName,
    cacheMaxAge,
  );

  @override
  String toString() =>
      '$ExtendedNetworkImageSSLProvider("$url", scale: $scale)';

  @override
  /// Get network image data from cached
  Future<Uint8List?> getNetworkImageData({
    StreamController<ImageChunkEvent>? chunkEvents,
  }) async {
    final String uId = cacheKey ?? keyToMd5(url);

    if (cache) {
      return await _loadCache(this, chunkEvents, uId);
    }

    return await _loadNetwork(this, chunkEvents);
  }

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) =>
        kDebugMode)
    ..autoUncompress = false;

  static HttpClient get httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  @override
  WebHtmlElementStrategy get webHtmlElementStrategy =>
      WebHtmlElementStrategy.never;
}
