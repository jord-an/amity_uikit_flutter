import 'dart:developer';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../components/custom_user_avatar.dart';

import '../../viewmodel/community_Feed_viewmodel.dart';
import '../../viewmodel/edit_post_viewmodel.dart';
import '../../viewmodel/feed_viewmodel.dart';
import '../../viewmodel/post_viewmodel.dart';
import '../user/user_profile.dart';
import 'comments.dart';
import 'community_feed.dart';
import 'edit_post_screen.dart';
import 'post_content_widget.dart';

class GlobalFeedTabScreen extends StatefulWidget {
  const GlobalFeedTabScreen({super.key});

  @override
  GlobalFeedTabScreenState createState() => GlobalFeedTabScreenState();
}

class GlobalFeedTabScreenState extends State<GlobalFeedTabScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Provider.of<FeedVM>(context, listen: false).initAmityGlobalfeed();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        AppBar().preferredSize.height;

    final theme = Theme.of(context);
    return Consumer<FeedVM>(builder: (context, vm, _) {
      return RefreshIndicator(
        color: theme.primaryColor,
        onRefresh: () async {
          await vm.initAmityGlobalfeed();
        },
        child: vm.getAmityPosts().isEmpty
            ? SingleChildScrollView(
                controller: vm.scrollcontroller,
                child: Container(
                  color: Colors.grey[200],
                  height: bHeight,
                ),
              )
            : Column(
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
                                stream: vm.getAmityPosts()[index].listen,
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
      );
    });
  }
}

class PostWidget extends StatefulWidget {
  const PostWidget(
      {Key? key,
      required this.post,
      required this.theme,
      required this.postIndex,
      this.isFromFeed = false})
      : super(key: key);

  final AmityPost post;
  final ThemeData theme;
  final int postIndex;
  final bool isFromFeed;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget>
// with AutomaticKeepAliveClientMixin
{
  double iconSize = 20;
  double feedReactionCountSize = 14;

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
      onSelected: (value) {
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
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider<EditPostVM>(
                    create: (context) => EditPostVM(),
                    child: EditPostScreen(post: widget.post))));
            break;
          case 'Delete Post':
            Provider.of<FeedVM>(context, listen: false)
                .deletePost(widget.post, widget.postIndex);
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
              child: Text(isPostOwner
                  ? postOwnerMenu[index]
                  : isFlaggedByMe
                      ? 'Unreport Post'
                      : 'Report Post'));
        });
      },
    );
  }

  // @override
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CommentScreen(
                    amityPost: widget.post,
                  )));
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
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                        amityUser: widget.post.postedUser!,
                                      )));
                            },
                            child: getAvatarImage(
                                widget.post.postedUser?.avatarUrl))),
                    title: Wrap(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                      amityUser: widget.post.postedUser!,
                                    )));
                          },
                          child: Text(
                            widget.post.postedUser?.displayName ??
                                "Display name",
                            style: widget.theme.textTheme.bodyText1!.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
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
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) =>
                                          ChangeNotifierProvider(
                                            create: (context) => CommuFeedVM(),
                                            child: CommunityScreen(
                                              isFromFeed: true,
                                              community: (widget.post.target
                                                      as CommunityTarget)
                                                  .targetCommunity!,
                                            ),
                                          )));
                                },
                                child: Text(
                                  (widget.post.target as CommunityTarget)
                                          .targetCommunity!
                                          .displayName ??
                                      "Community name",
                                  style: widget.theme.textTheme.bodyText1!
                                      .copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                ),
                              )
                            : Container()
                      ],
                    ),
                    subtitle: Text(
                      " ${widget.post.createdAt?.toLocal().day}-${widget.post.createdAt?.toLocal().month}-${widget.post.createdAt?.toLocal().year}",
                      style: widget.theme.textTheme.bodyText1!
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
                                      const Image(
                                        image:
                                            AssetImage('assets/Icons/like.png'),
                                        height: 21,
                                        width: 21,
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
                                style: TextStyle(
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
                                style: TextStyle(
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
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 7, bottom: 7, left: 10, right: 10),
                    child: Row(
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              widget.post.myReactions!.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        HapticFeedback.heavyImpact();
                                        Provider.of<PostVM>(context,
                                                listen: false)
                                            .removePostReaction(widget.post);
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.thumb_up,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: iconSize,
                                          ),
                                          Text(
                                            ' Like',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: feedReactionCountSize,
                                                letterSpacing: 1),
                                          ),
                                        ],
                                      ))
                                  : GestureDetector(
                                      onTap: () {
                                        HapticFeedback.heavyImpact();
                                        Provider.of<PostVM>(context,
                                                listen: false)
                                            .addPostReaction(widget.post);
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.thumb_up_alt_outlined,
                                            color: Colors.grey,
                                            size: iconSize,
                                          ),
                                          Text(
                                            ' Like',
                                            style: TextStyle(
                                                color: Colors.grey[200],
                                                fontSize: feedReactionCountSize,
                                                letterSpacing: 1),
                                          ),
                                        ],
                                      )),
                              const SizedBox(width: 8.5),
                            ],
                          ),
                        ),

                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => CommentScreen(
                                        amityPost: widget.post,
                                      )));
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
                                  style: TextStyle(
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