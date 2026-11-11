import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syriapharmacy/data/model/image_full_url.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

import 'package:syriapharmacy/utill/images.dart';

import '../../../common/basewidget/custom_image_widget.dart';
import '../../../utill/dimensions.dart';

class ProductImageScreen extends StatefulWidget {
  final String? title;
  final List<ImageFullUrl>? imageList;
  const ProductImageScreen(
      {super.key, required this.title, required this.imageList});

  @override
  ProductImageScreenState createState() => ProductImageScreenState();
}

class ProductImageScreenState extends State<ProductImageScreen> {
  int? pageIndex;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    pageIndex = Provider.of<ProductDetailsController>(context, listen: false)
            .imageSliderIndex ??
        0;
    _pageController = PageController(initialPage: pageIndex ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        CustomAppBar(title: widget.title),
        Expanded(
          child: Stack(
            children: [
              PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  final path = widget.imageList![index].path;
                  final showNetworkImage =
                      path != null && path.trim().isNotEmpty;
                  return PhotoViewGalleryPageOptions(
                    imageProvider: showNetworkImage
                        ? CachedNetworkImageProvider(path)
                        : const AssetImage(Images.placeholder) as ImageProvider,
                    initialScale: PhotoViewComputedScale.contained,
                    heroAttributes:
                        PhotoViewHeroAttributes(tag: index.toString()),
                  );
                },
                backgroundDecoration:
                    BoxDecoration(color: Theme.of(context).highlightColor),
                itemCount: widget.imageList!.length,
                loadingBuilder: (context, event) => Center(
                    child: SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          value: event == null
                              ? 0
                              : event.cumulativeBytesLoaded /
                                  event.expectedTotalBytes!,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor),
                        ))),
                pageController: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    pageIndex = index;
                  });
                },
              ),
              pageIndex != 0
                  ? Positioned(
                      left: 5,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle),
                        child: InkWell(
                          onTap: () {
                            if (pageIndex! > 0) {
                              _pageController!.animateToPage(pageIndex! - 1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut);
                            }
                          },
                          child: Icon(Icons.chevron_left_outlined,
                              size: 40, color: Theme.of(context).cardColor),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              pageIndex != widget.imageList!.length - 1
                  ? Positioned(
                      right: 5,
                      top: 0,
                      bottom: 0,
                      child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle),
                          child: InkWell(
                              onTap: () {
                                if (pageIndex! < widget.imageList!.length) {
                                  _pageController!.animateToPage(pageIndex! + 1,
                                      duration:
                                          const Duration(milliseconds: 500),
                                      curve: Curves.easeInOut);
                                }
                              },
                              child: Icon(Icons.chevron_right_outlined,
                                  size: 40,
                                  color: Theme.of(context).cardColor))),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ]),
      // ============ إضافة جديدة: صف الـ Thumbnails ============
      bottomNavigationBar: Container(
        color: Theme.of(context).highlightColor, // نفس لون خلفية الـ Gallery
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.imageList!.length,
                itemBuilder: (context, index) {
                  final isSelected = index == pageIndex;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        pageIndex = index;
                      });
                      _pageController!.animateToPage(index,
                          duration: const Duration(microseconds: 50),
                          curve: Curves.ease);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          right: Dimensions.paddingSizeSmall),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: isSelected ? 2 : 0,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : const Color(0x00FFFFFF),
                            ),
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(
                                Dimensions.paddingSizeExtraSmall),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                Dimensions.paddingSizeExtraSmall),
                            child: CustomImageWidget(
                                height: 70,
                                width: 70,
                                image: '${widget.imageList![index].path}'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),    );
  }
}
