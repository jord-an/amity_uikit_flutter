import 'dart:developer';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/viewmodel/amity_viewmodel.dart';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../../components/custom_user_avatar.dart';

import '../../components/accept_dialog.dart';
import '../../components/select_post_dialog.dart';
import '../../constans/app_string.dart';
import '../../constans/app_text_style.dart';
import '../../viewmodel/community_feed_viewmodel.dart';
import '../../viewmodel/community_view_model.dart';
import '../../viewmodel/community_viewmodel.dart';
import '../../viewmodel/configuration_viewmodel.dart';
import '../../viewmodel/edit_post_viewmodel.dart';
import '../../viewmodel/feed_viewmodel.dart';
import '../../viewmodel/post_viewmodel.dart';
import '../../viewmodel/user_feed_viewmodel.dart';
import '../user/user_profile.dart';
import '../post_detail/comments.dart';
import 'community_feed.dart';
import 'edit_post_screen.dart';
import 'post_content_widget.dart';

class GlobalFeedScreen extends StatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  GlobalFeedScreenState createState() => GlobalFeedScreenState();
}

class GlobalFeedScreenState extends State<GlobalFeedScreen> {
  final selectPostDialog = SelectPostDialog();
  @override
  void dispose() {
    selectPostDialog.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    onRefresh();
  }

  Future<void> onRefresh() async {
    context.read<CommunityVM>().initAmityMyCommunityList();
    await Provider.of<FeedVM>(context, listen: false).initAmityGlobalfeed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<FeedVM>(builder: (context, vm, _) {
      return RefreshIndicator(
        color: Provider.of<AmityUIConfiguration>(context).primaryColor,
        onRefresh: () async {
          await onRefresh();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (vm.getAmityPosts().isEmpty && !vm.isLoading)
              Consumer<AmityVM>(builder: (context, vm, _) {
                String msg = "Welcome\n Go to the Explore page";
                String? displayName = vm.currentamityUser?.displayName;
                if (displayName != null && displayName.isNotEmpty) {
                  msg = "Welcome, $displayName! \n Go to the Explore page";
                }
                return GestureDetector(
                  onTap: () {
                    context.read<CommunityViewModel>().selectTab(1);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          msg,
                          style: AppTextStyle.header1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            if (vm.getAmityPosts().isNotEmpty)
              Column(
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.grey[200],
                      child: FadedSlideAnimation(
                        beginOffset: const Offset(0, 0.3),
                        endOffset: const Offset(0, 0),
                        slideCurve: Curves.linearToEaseOut,
                        child: ListView.builder(
                          // shrinkWrap: true,
                          controller: vm.scrollcontroller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: vm.getAmityPosts().length,
                          itemBuilder: (context, index) {
                            return StreamBuilder<AmityPost>(
                                key: Key(vm.getAmityPosts()[index].postId!),
                                stream: vm.getAmityPosts()[index].listen.stream,
                                initialData: vm.getAmityPosts()[index],
                                builder: (context, snapshot) {
                                  return PostWidget(
                                    post: snapshot.data!,
                                    theme: theme,
                                    postIndex: index,
                                    isFromFeed: true,
                                  );
                                });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Positioned(
              right: 15,
              bottom: 15,
              child: GestureDetector(
                onTap: () async {
                  selectPostDialog.open(context: context);
                },
                child: ClipOval(
                  child: Container(
                    width: 50,
                    height: 50,
                    color: context
                        .watch<AmityUIConfiguration>()
                        .buttonConfig
                        .backgroundColor,
                    child: Icon(
                      Icons.add,
                      color: context
                          .watch<AmityUIConfiguration>()
                          .buttonConfig
                          .textColor,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class PostWidget extends StatefulWidget {
  const PostWidget({
    Key? key,
    required this.post,
    required this.theme,
    required this.postIndex,
    this.isFromFeed = false,
    this.isCommunity,
    this.onDeleteAction,
  }) : super(key: key);
  final bool? isCommunity;
  final AmityPost post;
  final ThemeData theme;
  final int postIndex;
  final bool isFromFeed;
  final ValueChanged? onDeleteAction;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget>
// with AutomaticKeepAliveClientMixin
{
  double iconSize = 20;
  double feedReactionCountSize = 14;
  final deleteDialog = AcceptDialog();

  @override
  void dispose() {
    deleteDialog.close();
    super.dispose();
  }

  Future<void> onRefresh() async {
    if (mounted) {
      context.read<CommunityVM>().initAmityMyCommunityList();
      await Provider.of<FeedVM>(context, listen: false).initAmityGlobalfeed();
    }
  }

  Future<int> checkIsFollowing() async {
    AmityMyFollowInfo myFollowInfo = await AmityCoreClient.newUserRepository()
        .relationship()
        .getMyFollowInfo();
    return myFollowInfo.followingCount ?? -1;
  }

  Future<void> navigatorToCommentScreen() async {
    await showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => CommentScreen(
        amityPost: widget.post,
      ),
    );
    if (mounted) {
      Provider.of<FeedVM>(context, listen: false).updatePost(widget.post);
    }
  }

  Future<void> navigatorToUser() async {
    int beforeFollowing = -1;
    try {
      beforeFollowing = await checkIsFollowing();
    } catch (_) {}
    if (mounted) {
      await showDialog(
        context: context,
        useSafeArea: false,
        builder: (context) => ChangeNotifierProvider(
          create: (context) => UserFeedVM(),
          child: UserProfileScreen(
            amityUser: widget.post.postedUser!,
          ),
        ),
      );
      if (widget.post.postedUser!.userId !=
          AmityCoreClient.getCurrentUser().userId) {
        if (beforeFollowing != -1) {
          int afterFollowing = await checkIsFollowing();
          if(afterFollowing != -1){
            if(afterFollowing != beforeFollowing){
              onRefresh();
            }
          }
        }
      }
    }
  }

  Future<void> navigatorToCommunity() async {
    final community = (widget.post.target as CommunityTarget).targetCommunity!;
    await showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => ChangeNotifierProvider(
        create: (context) => CommuFeedVM(),
        child: CommunityScreen(
          isFromFeed: true,
          community: community,
        ),
      ),
    );
    if (mounted) {
      final result = await Provider.of<CommunityVM>(context, listen: false)
          .getAmityCommunity(community.channelId!);
      if (!(result.isJoined ?? false)) {
        onRefresh();
      }
    }
  }

  Future<void> onDeletePost() async {
    if (widget.isCommunity == null || widget.isCommunity == false) {
      await Provider.of<FeedVM>(context, listen: false)
          .deletePost(widget.post, widget.postIndex);
    } else {
      await Provider.of<CommuFeedVM>(context, listen: false)
          .deletePost(widget.post, widget.postIndex);
    }
    if (widget.onDeleteAction != null) {
      widget.onDeleteAction!(1);
    }
  }

  Widget postWidgets() {
    List<Widget> widgets = [];
    if (widget.post.data != null) {
      widgets.add(AmityPostWidget([widget.post], false, false));
    }
    final childrenPosts = widget.post.children;
    if (childrenPosts != null && childrenPosts.isNotEmpty) {
      widgets.add(AmityPostWidget(childrenPosts, true, true));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget postOptions(BuildContext context) {
    bool isPostOwner =
        widget.post.postedUserId == AmityCoreClient.getCurrentUser().userId;
    List<String> postOwnerMenu = ['Edit Post', 'Delete Post'];

    final isFlaggedByMe = widget.post.isFlaggedByMe;
    return PopupMenuButton(
      onSelected: (value) async {
        switch (value) {
          case 'Report Post':
          case 'Unreport Post':
            log("isflag by me $isFlaggedByMe");
            if (isFlaggedByMe) {
              Provider.of<PostVM>(context, listen: false)
                  .unflagPost(widget.post);
            } else {
              Provider.of<PostVM>(context, listen: false).flagPost(widget.post);
            }

            break;
          case 'Edit Post':
            await showDialog(
              context: context,
              useSafeArea: false,
              builder: (context) => ChangeNotifierProvider<EditPostVM>(
                create: (context) => EditPostVM(),
                child: EditPostScreen(post: widget.post),
              ),
            );
            onRefresh();
            break;
          case 'Delete Post':
            setState(() => deleteDialog.open(
              context: context,
              title: 'Delete Post',
              message: AppString.messageConfrimDelete,
              acceptText: AppString.deleteButton,
              acceptButtonConfig:
                  context.read<AmityUIConfiguration>().deleteButtonConfig,
              onPressedCancel: () {
                deleteDialog.close();
              },
              onPressedAccept: () {
                onDeletePost();
                deleteDialog.close();
              },
            ));
            break;
          default:
        }
      },
      child: const Icon(
        Icons.more_horiz_rounded,
        size: 24,
        color: Colors.grey,
      ),
      itemBuilder: (context) {
        return List.generate(isPostOwner ? 2 : 1, (index) {
          return PopupMenuItem(
            value: isPostOwner
                ? postOwnerMenu[index]
                : isFlaggedByMe
                    ? 'Unreport Post'
                    : 'Report Post',
            child: Text(
              isPostOwner
                  ? postOwnerMenu[index]
                  : isFlaggedByMe
                      ? 'Unreport Post'
                      : 'Report Post',
            ),
          );
        });
      },
    );
  }

  // @override
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          navigatorToCommentScreen();
        },
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(2),
                    leading: FadeAnimation(
                      child: GestureDetector(
                        onTap: () async {
                          navigatorToUser();
                        },
                        child: getAvatarImage(
                          widget.post.postedUser!.userId !=
                                  AmityCoreClient.getCurrentUser().userId
                              ? widget.post.postedUser?.avatarUrl
                              : Provider.of<AmityVM>(context)
                                          .currentamityUser !=
                                      null
                                  ? Provider.of<AmityVM>(context)
                                      .currentamityUser!
                                      .avatarUrl
                                  : null,
                        ),
                      ),
                    ),
                    title: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            navigatorToUser();
                          },
                          child: Text(
                            widget.post.postedUser!.userId !=
                                    AmityCoreClient.getCurrentUser().userId
                                ? widget.post.postedUser?.displayName ??
                                    "Display name"
                                : Provider.of<AmityVM>(context)
                                        .currentamityUser
                                        ?.displayName ??
                                    "",
                            style: widget.theme.textTheme.bodyLarge!.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        // TODO: Need community role in user object
                        // if (widget.post.postedUser != null &&
                        //     widget.post.postedUser!.roles!
                        //         .contains("community-moderator"))
                        //   Image.asset(
                        //     "assets/Icons/moderator.png",
                        //     package: 'amity_uikit_beta_service',
                        //     width: 15,
                        //     height: 15,
                        //   ),
                        widget.post.targetType ==
                                    AmityPostTargetType.COMMUNITY &&
                                widget.isFromFeed
                            ? const Icon(
                                Icons.arrow_right_rounded,
                                color: Colors.black,
                              )
                            : Container(),
                        widget.post.targetType ==
                                    AmityPostTargetType.COMMUNITY &&
                                widget.isFromFeed
                            ? GestureDetector(
                                onTap: () async {
                                  navigatorToCommunity();
                                },
                                child: Text(
                                  (widget.post.target as CommunityTarget)
                                          .targetCommunity!
                                          .displayName ??
                                      "Community name",
                                  style: widget.theme.textTheme.bodyLarge!
                                      .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : Container()
                      ],
                    ),
                    subtitle: Text(
                      DateFormat.yMMMMEEEEd().format(widget.post.createdAt!),
                      style: widget.theme.textTheme.bodyLarge!
                          .copyWith(color: Colors.grey, fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Image.asset(
                        //   'assets/Icons/ic_share.png',
                        //   scale: 3,
                        // ),
                        // SizedBox(width: iconSize.feedIconSize),
                        // Icon(
                        //   Icons.bookmark_border,
                        //   size: iconSize.feedIconSize,
                        //   color: ApplicationColors.grey,
                        // ),
                        // SizedBox(width: iconSize.feedIconSize),
                        postOptions(context),
                      ],
                    ),
                  ),
                  postWidgets(),
                  Padding(
                      padding: const EdgeInsets.only(
                          top: 10, bottom: 10, left: 9, right: 9),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(builder: (context) {
                            return widget.post.reactionCount! > 0
                                ? Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundColor:
                                            Provider.of<AmityUIConfiguration>(
                                                    context)
                                                .primaryColor,
                                        child: const Icon(
                                          Icons.thumb_up,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(widget.post.reactionCount.toString(),
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: feedReactionCountSize,
                                              letterSpacing: 1))
                                    ],
                                  )
                                : const SizedBox(
                                    width: 0,
                                  );
                          }),
                          Builder(builder: (context) {
                            // any logic needed...
                            if (widget.post.commentCount! > 1) {
                              return Text(
                                '${widget.post.commentCount} comments',
                                style: AppTextStyle.mainStyle.copyWith(
                                    color: Colors.grey,
                                    fontSize: feedReactionCountSize,
                                    letterSpacing: 0.5),
                              );
                            } else if (widget.post.commentCount! == 0) {
                              return const SizedBox(
                                width: 0,
                              );
                            } else {
                              return Text(
                                '${widget.post.commentCount} comment',
                                style: AppTextStyle.mainStyle.copyWith(
                                    color: Colors.grey,
                                    fontSize: feedReactionCountSize,
                                    letterSpacing: 0.5),
                              );
                            }
                          })
                        ],
                      )),
                  const Divider(
                    color: Colors.grey,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Row(
                      //   children: [
                      //     Icon(
                      //       Icons.remove_red_eye,
                      //       size: iconSize.feedIconSize,
                      //       color: ApplicationColors.grey,
                      //     ),
                      //     SizedBox(width: 8.5),
                      //     Text(
                      //       S.of(context).onepointtwok,
                      //       style: TextStyle(
                      //           color: ApplicationColors.grey,
                      //           fontSize: 12,
                      //           letterSpacing: 1),
                      //     ),
                      //   ],
                      // ),
                      // Row(
                      //   children: [
                      //     FaIcon(
                      //       Icons.repeat_rounded,
                      //       color: ApplicationColors.grey,
                      //       size: iconSize.feedIconSize,
                      //     ),
                      //     SizedBox(width: 8.5),
                      //     Text(
                      //       '287',
                      //       style: TextStyle(
                      //           color: ApplicationColors.grey,
                      //           fontSize: 12,
                      //           letterSpacing: 0.5),
                      //     ),
                      //   ],
                      // ),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            widget.post.myReactions!.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      HapticFeedback.heavyImpact();
                                      Provider.of<PostVM>(context,
                                              listen: false)
                                          .removePostReaction(widget.post);
                                    },
                                    child: Container(
                                      color: Colors.white,
                                      height: 40,
                                      width: MediaQuery.of(context).size.width *
                                          0.45,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.thumb_up,
                                            color: Provider.of<
                                                        AmityUIConfiguration>(
                                                    context)
                                                .primaryColor,
                                            size: iconSize,
                                          ),
                                          Text(
                                            ' Like',
                                            style: AppTextStyle.mainStyle.copyWith(
                                                color: Provider.of<
                                                            AmityUIConfiguration>(
                                                        context)
                                                    .primaryColor,
                                                fontSize: feedReactionCountSize,
                                                letterSpacing: 1),
                                          ),
                                        ],
                                      ),
                                    ))
                                : GestureDetector(
                                    onTap: () {
                                      HapticFeedback.heavyImpact();
                                      Provider.of<PostVM>(context,
                                              listen: false)
                                          .addPostReaction(widget.post);
                                    },
                                    child: Container(
                                      color: Colors.white,
                                      width: MediaQuery.of(context).size.width *
                                          0.45,
                                      height: 40,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.thumb_up_alt_outlined,
                                            color: Colors.grey,
                                            size: iconSize,
                                          ),
                                          Text(
                                            ' Like',
                                            style: AppTextStyle.mainStyle
                                                .copyWith(
                                                    color: Colors.grey,
                                                    fontSize:
                                                        feedReactionCountSize,
                                                    letterSpacing: 1),
                                          ),
                                        ],
                                      ),
                                    )),
                          ],
                        ),
                      ),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            navigatorToCommentScreen();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.grey,
                                size: iconSize,
                              ),
                              const SizedBox(width: 5.5),
                              Text(
                                'Comment',
                                style: AppTextStyle.mainStyle.copyWith(
                                    color: Colors.grey,
                                    fontSize: feedReactionCountSize,
                                    letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Divider(),
                  // CommentComponent(
                  //     key: Key(widget.post.postId!),
                  //     postId: widget.post.postId!,
                  //     theme: widget.theme)
                ],
              ),
            ),
          ),
        ));
  }

  // @override
  // bool get wantKeepAlive {
  //   final childrenPosts = widget.post.children;
  //   if (childrenPosts != null && childrenPosts.isNotEmpty) {
  //     if (childrenPosts[0].data is VideoData) {
  //       log("keep ${childrenPosts[0].parentPostId} alive");
  //       return true;
  //     } else {
  //       return true;
  //     }
  //   } else {
  //     return false;
  //   }
  // }
}
