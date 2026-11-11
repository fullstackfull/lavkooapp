import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/chat/domain/models/message_body.dart';
import 'package:syriapharmacy/features/chat/domain/models/message_model.dart';
import 'package:syriapharmacy/features/chat/widgets/custom_image_pick_bottom_sheet.dart';
import 'package:syriapharmacy/helper/date_converter.dart';
import 'package:syriapharmacy/helper/image_size_checker.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/chat/controllers/chat_controller.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/common/basewidget/no_internet_screen_widget.dart';
import 'package:syriapharmacy/common/basewidget/paginated_list_view_widget.dart';
import 'package:syriapharmacy/features/chat/widgets/chat_shimmer_widget.dart';
import 'package:syriapharmacy/features/chat/widgets/message_bubble_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as foundation;

class ChatScreen extends StatefulWidget {
  final int? id;
  final String? name;
  final bool isDelivery;
  final String? image;
  final String? phone;
  final bool isShopOnVacation;
  final bool isShopTemporaryClosed;
  final int? userType;
  const ChatScreen({
    super.key,
    this.id,
    required this.name,
    this.isDelivery = false,
    this.image,
    this.phone,
    this.userType,
    this.isShopOnVacation = false,
    this.isShopTemporaryClosed = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  bool emojiPicker = false;
  bool isClosed = false;
  bool _isTyping = false;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

  void clickedOnClose() {
    setState(() {
      isClosed = true;
    });
  }

  @override
  void initState() {
    loadDaa();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendButtonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );
    _controller.addListener(() {
      final typing = _controller.text.isNotEmpty;
      if (typing != _isTyping) {
        setState(() => _isTyping = typing);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _sendButtonController.dispose();
    _controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadDaa() async {
    await Provider.of<ChatController>(context, listen: false)
        .getMessageList(context, widget.id, 1, userType: widget.userType);
  }

  bool _isMediaExist(ChatController chatController) {
    return (chatController.pickedMediaStored?.isNotEmpty ?? false) ||
        (chatController.pickedFiles?.isNotEmpty ?? false);
  }

  bool _isMsgValid(ChatController chatController) {
    bool isImageMsgValid =
        (chatController.pickedMediaStored?.isNotEmpty ?? false) &&
            !chatController.pickedFIleCrossMaxLength;
    bool isFileMsgValid = (chatController.pickedFiles?.isNotEmpty ?? false) &&
        !chatController.pickedFIleCrossMaxLength;
    bool isTextMsgValid =
        _controller.text.isNotEmpty && !chatController.pickedFIleCrossMaxLength;
    return (isImageMsgValid || isFileMsgValid || isTextMsgValid) &&
        !chatController.pickedFIleCrossMaxLimit &&
        !chatController.isLoading;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeController>(context).darkTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1117) : const Color(0xFFF0F4F8),
      appBar: _buildAppBar(isDark, primaryColor),
      body: Stack(
        children: [
          // Background subtle pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _ChatBgPainter(isDark: isDark, color: primaryColor),
            ),
          ),

          Consumer<ChatController>(
            builder: (context, chatController, child) => Column(
              children: [
                // Vacation / closed banner
                if (widget.isShopOnVacation &&
                    !isClosed &&
                    !widget.isShopTemporaryClosed)
                  _buildBanner(
                    context,
                    getTranslated("shop_close_message", context) ?? '',
                    const Color(0xFFFFF3CD),
                    const Color(0xFFE6A817),
                    Icons.beach_access_rounded,
                  ),

                if (!isClosed && widget.isShopTemporaryClosed)
                  _buildBanner(
                    context,
                    getTranslated("shop_available_message", context) ?? '',
                    const Color(0xFFFFE8E8),
                    const Color(0xFFE53935),
                    Icons.access_time_rounded,
                  ),

                // Message list
                chatController.messageModel != null
                    ? (chatController.messageModel!.message != null &&
                            chatController.messageModel!.message!.isNotEmpty)
                        ? Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              reverse: true,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault,
                                    vertical: Dimensions.paddingSizeSmall),
                                child: PaginatedListView(
                                  reverse: true,
                                  scrollController: scrollController,
                                  onPaginate: (int? offset) =>
                                      chatController.getMessageList(
                                          context, widget.id, offset ?? 1,
                                          reload: false),
                                  totalSize:
                                      chatController.messageModel?.totalSize,
                                  offset: chatController.messageModel?.offset,
                                  limit: chatController.messageModel?.limit,
                                  itemView: ListView.builder(
                                    itemCount: chatController
                                        .messageModel?.message?.length,
                                    padding: EdgeInsets.zero,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    reverse: true,
                                    itemBuilder: (context, index) {
                                      return Column(
                                        crossAxisAlignment: chatController
                                                    .messageModel
                                                    ?.message?[index]
                                                    .sentByCustomer ??
                                                false
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_willShowDate(
                                                  index,
                                                  chatController
                                                      .messageModel) !=
                                              null)
                                            _DateSeparator(
                                              label: DateConverter
                                                  .dateStringMonthYear(
                                                DateTime.tryParse(chatController
                                                    .messageModel!
                                                    .message![index]
                                                    .createdAt!),
                                              ),
                                            ),
                                          MessageBubbleWidget(
                                            message: chatController
                                                .messageModel!.message![index],
                                            previous: (index != 0)
                                                ? chatController.messageModel!
                                                    .message![index - 1]
                                                : null,
                                            next: index ==
                                                    (chatController
                                                            .messageModel!
                                                            .message!
                                                            .length -
                                                        1)
                                                ? null
                                                : chatController.messageModel!
                                                    .message![index + 1],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const Expanded(
                            child: NoInternetOrDataScreenWidget(
                                isNoInternet: false))
                    : const Expanded(child: ChatShimmerWidget()),

                // Sending indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: chatController.isSending
                      ? _SendingIndicator(primaryColor: primaryColor)
                      : const SizedBox.shrink(),
                ),

                // Media previews & input area
                _buildInputArea(context, chatController, isDark, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color primaryColor) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1D2E), const Color(0xFF252836)]
                : [primaryColor, primaryColor.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Back button
                Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(CupertinoIcons.back,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar with online ring
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.6), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: SizedBox(
                          height: 42,
                          width: 42,
                          child:
                              (widget.image != null && widget.image!.isNotEmpty)
                                  ? CustomImageWidget(image: widget.image!)
                                  : Image.asset(Images.placeholder,
                                      height: 42, width: 42, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Online',
                            style: textRegular.copyWith(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // Call button (delivery only)
                if (widget.isDelivery)
                  Material(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _launchUrl("tel:${widget.phone}"),
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Image.asset(Images.callIcon,
                            color: Colors.white, height: 20, width: 20),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(
    BuildContext context,
    String message,
    Color bgColor,
    Color iconColor,
    IconData icon,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: iconColor.withOpacity(0.9),
              ),
            ),
          ),
          InkWell(
            onTap: clickedOnClose,
            borderRadius: BorderRadius.circular(20),
            child: Icon(Icons.close_rounded, size: 20, color: iconColor),
          )
        ],
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    ChatController chatController,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // Image previews
          if (chatController.pickedMediaStored?.isNotEmpty ?? false)
            _buildImagePreviews(chatController, isDark, primaryColor),

          // File previews
          if ((chatController.pickedFiles?.isNotEmpty ?? false) &&
              chatController.isLoading == false)
            _buildFilePreviews(chatController, isDark),

          // Error messages
          if (chatController.pickedFIleCrossMaxLimit ||
              chatController.pickedFIleCrossMaxLength ||
              chatController.singleFIleCrossMaxLimit)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeExtraSmall),
              child: Text(
                "${chatController.pickedFIleCrossMaxLength ? "• ${getTranslated('can_not_select_more_than', context)!} ${AppConstants.maxLimitOfTotalFileSent.floor()} files " : ""}"
                "${chatController.pickedFIleCrossMaxLimit ? "• ${getTranslated('total_images_size_can_not_be_more_than', context)!} ${AppConstants.maxLimitOfFileSentINConversation.floor()} MB" : ""}"
                "${chatController.singleFIleCrossMaxLimit ? "• ${getTranslated('single_file_size_can_not_be_more_than', context)!} ${AppConstants.maxSizeOfASingleFile.floor()} MB" : ""}",
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),

          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Opacity(
              opacity:
                  ((chatController.isSending || chatController.isLoading) ||
                          widget.isShopTemporaryClosed)
                      ? 0.5
                      : 1,
              child: AbsorbPointer(
                absorbing:
                    ((chatController.isSending || chatController.isLoading) ||
                        widget.isShopTemporaryClosed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Emoji + attachment buttons
                    _buildActionButton(
                      isDark: isDark,
                      primaryColor: primaryColor,
                      icon: Icons.emoji_emotions_outlined,
                      onTap: () {
                        setState(() {
                          emojiPicker = !emojiPicker;
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                      },
                    ),
                    const SizedBox(width: 6),

                    // Text field
                    Expanded(
                      child: Container(
                        constraints:
                            const BoxConstraints(minHeight: 48, maxHeight: 120),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252836)
                              : const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: emojiPicker
                                ? primaryColor.withOpacity(0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onTap: () {
                                  setState(() => emojiPicker = false);
                                },
                                onSubmitted: (_) =>
                                    _sendMessage(chatController),
                                style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF222324),
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText:
                                      getTranslated('send_a_message', context),
                                  hintStyle: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade500,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            // Attachment icon inside field
                            _buildInlineButton(
                              icon: Icons.attach_file_rounded,
                              color: primaryColor,
                              onTap: () => showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) =>
                                    CustomImagePickBottomSheet(chatController),
                              ),
                            ),
                            _buildInlineButton(
                              icon: Icons.insert_drive_file_outlined,
                              color: primaryColor,
                              onTap: () => chatController.pickOtherFile(false),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send button
                    ScaleTransition(
                      scale: _sendButtonScale,
                      child: GestureDetector(
                        onTapDown: (_) => _sendButtonController.forward(),
                        onTapUp: (_) {
                          _sendButtonController.reverse();
                          _sendMessage(chatController);
                        },
                        onTapCancel: () => _sendButtonController.reverse(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isTyping || _isMediaExist(chatController)
                                  ? [
                                      primaryColor,
                                      primaryColor.withOpacity(0.75)
                                    ]
                                  : [
                                      Colors.grey.shade400,
                                      Colors.grey.shade300
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (_isTyping || _isMediaExist(chatController))
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Emoji picker
          if (emojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onBackspacePressed: () {},
                textEditingController: _controller,
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor:
                        isDark ? const Color(0xFF1A1D2E) : Colors.white,
                    emojiSizeMax: 28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.2
                            : 1.0),
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor:
                        isDark ? const Color(0xFF1A1D2E) : Colors.white,
                    indicatorColor: primaryColor,
                    iconColorSelected: primaryColor,
                    iconColor: Colors.grey,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor:
                        isDark ? const Color(0xFF1A1D2E) : Colors.white,
                    buttonColor: primaryColor,
                    buttonIconColor: Colors.white,
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor:
                        isDark ? const Color(0xFF1A1D2E) : Colors.white,
                    buttonIconColor: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required bool isDark,
    required Color primaryColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? const Color(0xFF252836) : primaryColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: primaryColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildInlineButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Icon(icon, color: color.withOpacity(0.7), size: 20),
      ),
    );
  }

  Widget _buildImagePreviews(
      ChatController chatController, bool isDark, Color primaryColor) {
    return Container(
      height: (chatController.pickedFIleCrossMaxLimit ||
              chatController.pickedFIleCrossMaxLength ||
              chatController.singleFIleCrossMaxLimit)
          ? 110
          : 96,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: chatController.pickedMediaStored!.length,
        itemBuilder: (context, index) {
          if (kDebugMode) {
            print(
                '--------path: ${chatController.pickedMediaStored?[index].thumbnailPath}');
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 80,
                    width: chatController.pickedMediaStored?[index].isVideo ??
                            false
                        ? 120
                        : 80,
                    child:
                        chatController.pickedMediaStored?[index].isSvg ?? false
                            ? SvgPicture.file(
                                File(chatController.pickedMediaStored![index]
                                        .thumbnailPath ??
                                    ''),
                                fit: BoxFit.cover)
                            : Image.file(
                                File(chatController.pickedMediaStored![index]
                                        .thumbnailPath ??
                                    ''),
                                fit: BoxFit.cover),
                  ),
                ),
                if (chatController.pickedMediaStored?[index].isVideo ?? false)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: InkWell(
                        onTap: () {
                          RouterHelper.getMediaViewerScreenRoute(
                            clickedIndex: index,
                            localMedia:
                                chatController.getXFileFromMediaFileModel(
                                    chatController.pickedMediaStored ?? []),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_arrow,
                              color: primaryColor, size: 24),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () =>
                        chatController.pickMultipleMedia(true, index: index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilePreviews(ChatController chatController, bool isDark) {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: chatController.pickedFiles?.length ?? 0,
        itemBuilder: (context, index) {
          String fileSize =
              ImageValidationHelper.getFileSizeFromPlatformFileToString(
                  chatController.pickedFiles![index]);
          return Container(
            width: 170,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(Images.fileIcon, height: 22, width: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        chatController.pickedFiles![index].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall),
                      ),
                      Text(
                        fileSize,
                        style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => chatController.pickOtherFile(true, index: index),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _sendMessage(ChatController chatController) {
    if (!_isMsgValid(chatController)) {
      chatController.pickedFIleCrossMaxLength
          ? showCustomSnackBarWidget(
              getTranslated('can_not_select_more_than_5_files', context),
              context,
              snackBarType: SnackBarType.warning)
          : showCustomSnackBarWidget(
              getTranslated('write_somethings', context), context,
              snackBarType: SnackBarType.warning);
    } else {
      MessageBody messageBody =
          MessageBody(id: widget.id, message: _controller.text);
      chatController
          .sendMessage(messageBody, userType: widget.userType)
          .then((value) {
        _controller.clear();
      });
    }
  }

  String? _willShowDate(int index, MessageModel? messageModel) {
    if (messageModel?.message == null) return null;
    final Message currentMessage = messageModel!.message![index];
    final nextMessage = index < ((messageModel.message?.length ?? 0) - 1)
        ? messageModel.message![index + 1]
        : null;
    DateTime? currentMessageDate = currentMessage.createdAt == null
        ? null
        : DateTime.tryParse(currentMessage.createdAt!);
    DateTime? nextMessageDate = nextMessage?.createdAt == null
        ? null
        : DateTime.tryParse(nextMessage!.createdAt!);
    bool isFirst = index == ((messageModel.message?.length ?? 0) - 1);
    if (isFirst || (nextMessageDate?.day != currentMessageDate?.day)) {
      return DateConverter.dateStringMonthYear(currentMessageDate);
    }
    return null;
  }
}

// ─── Date Separator ───────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context).darkTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                )
              ],
            ),
            child: Text(
              label,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sending Indicator ────────────────────────────────────────────────────────

class _SendingIndicator extends StatefulWidget {
  final Color primaryColor;
  const _SendingIndicator({required this.primaryColor});

  @override
  State<_SendingIndicator> createState() => _SendingIndicatorState();
}

class _SendingIndicatorState extends State<_SendingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            getTranslated('sending', context) ?? 'Sending',
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: widget.primaryColor.withOpacity(0.75),
            ),
          ),
          const SizedBox(width: 6),
          _DotsIndicator(color: widget.primaryColor, controller: _controller),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final Color color;
  final AnimationController controller;
  const _DotsIndicator({required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          children: List.generate(3, (i) {
            final double delay = i / 3;
            final double value =
                ((controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final double opacity = (value < 0.5) ? value * 2 : 2 - value * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color.withOpacity(opacity.clamp(0.2, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Background Painter ───────────────────────────────────────────────────────

class _ChatBgPainter extends CustomPainter {
  final bool isDark;
  final Color color;
  _ChatBgPainter({required this.isDark, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? color.withOpacity(0.03) : color.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    // Draw subtle circles in corners
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.85), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 100, paint);
  }

  @override
  bool shouldRepaint(_ChatBgPainter oldDelegate) => false;
}

Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw 'Could not launch $url';
  }
}
