import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'content_width.dart';

/// The title row of a main screen, as slivers for a [CustomScrollView].
///
/// The title and [actions] sit in the same centred column as the page
/// content (see [ContentWidth]), so they line up on wide browser windows,
/// and the row grows with the text size instead of clipping the title.
/// A zero-height pinned bar keeps content from scrolling under the status
/// bar.
class PageAppBar extends StatelessWidget {
  const PageAppBar({required this.title, this.actions = const [], super.key});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverMainAxisGroup(
      slivers: [
        const SliverAppBar(
          pinned: true,
          toolbarHeight: 0,
          automaticallyImplyLeading: false,
        ),
        SliverToBoxAdapter(
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
