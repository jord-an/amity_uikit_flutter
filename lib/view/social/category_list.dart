import 'package:amity_sdk/amity_sdk.dart';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodel/category_viewmodel.dart';

// ignore: must_be_immutable
class CategoryList extends StatefulWidget {
  AmityCommunity community;
  TextEditingController categoryTextController;

  CategoryList(this.community, this.categoryTextController, {super.key});
  @override
  CategoryListState createState() => CategoryListState();
}

class CategoryListState extends State<CategoryList> {
  // AmityCommunity community = AmityCommunity();

  // void buildCategoryIds() {
  //   for (var category
  //       in Provider.of<CategoryVM>(context, listen: false).getCategories()) {
  //     Provider.of<CategoryVM>(context, listen: false)
  //         .addCategoryId(category.categoryId!);
  //   }

  //   if (community.categoryIds != null) {
  //     Provider.of<CategoryVM>(context, listen: false)
  //         .setSelectedCategory(community.categoryIds![0]);
  //     // log("checking community category ids ${community.categoryIds}");
  //     // for (var id in community.categoryIds!) {
  //     //   if (categoryIds.contains(id)) {
  //     //     log("category id has a match ${id}");
  //     //     selectedCategoryIds.add(id);
  //     //   }
  //     // }
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // community = widget.community;
    Future.delayed(Duration.zero, () {
      Provider.of<CategoryVM>(context, listen: false)
          .setCommunity(widget.community);
      Provider.of<CategoryVM>(context, listen: false).initCategoryList(
          Provider.of<CategoryVM>(context, listen: false)
              .getCommunity()
              .categoryIds!);
    });
  }

  int getLength() {
    int length =
        Provider.of<CategoryVM>(context, listen: false).getCategories().length;
    return length;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        AppBar().preferredSize.height;

    final theme = Theme.of(context);
    return Consumer<CategoryVM>(builder: (context, vm, _) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  height: bHeight,
                  color: Colors.grey[200],
                  child: FadedSlideAnimation(
                    beginOffset: const Offset(0, 0.3),
                    endOffset: const Offset(0, 0),
                    slideCurve: Curves.linearToEaseOut,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: const Icon(Icons.chevron_left,
                                color: Colors.black, size: 35),
                          ),
                        ),
                        getLength() < 1
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: theme.primaryColor),
                              )
                            : Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  // shrinkWrap: true,
                                  itemCount: getLength(),
                                  itemBuilder: (context, index) {
                                    return CategoryWidget(
                                      category: Provider.of<CategoryVM>(context,
                                              listen: false)
                                          .getCategories()[index],
                                      theme: theme,
                                      textController:
                                          widget.categoryTextController,
                                      community: Provider.of<CategoryVM>(
                                              context,
                                              listen: false)
                                          .getCommunity(),
                                      index: index,
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class CategoryWidget extends StatelessWidget {
  const CategoryWidget(
      {Key? key,
      required this.textController,
      required this.category,
      required this.theme,
      required this.community,
      required this.index})
      : super(key: key);

  final AmityCommunityCategory category;
  final ThemeData theme;
  final AmityCommunity community;
  final int index;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ListTile(
          contentPadding: const EdgeInsets.all(0),
          onTap: () {
            Provider.of<CategoryVM>(context, listen: false).setSelectedCategory(
                Provider.of<CategoryVM>(context, listen: false)
                    .getCategoryIds()[index]);
            textController.text =
                Provider.of<CategoryVM>(context, listen: false)
                    .getSelectedCommunityName(
                        Provider.of<CategoryVM>(context, listen: false)
                            .getCategoryIds()[index]);
          },
          leading: FadeAnimation(
            child: (category.avatar?.fileUrl != null)
                ? CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: (NetworkImage(category.avatar!.fileUrl)))
                : const CircleAvatar(
                    backgroundImage:
                        AssetImage("assets/images/user_placeholder.png")),
          ),
          title: Text(
            category.name ?? "Category",
            style: theme.textTheme.bodyText1!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          trailing: Provider.of<CategoryVM>(context, listen: true)
                  .checkIfSelected(
                      Provider.of<CategoryVM>(context, listen: false)
                          .getCategories()[index]
                          .categoryId!)
              ? Icon(
                  Icons.check_rounded,
                  color: theme.primaryColor,
                )
              : null,
        ),
      ),
    );
  }
}