import 'package:antd_mobile/antd_mobile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:git_touch/graphql/__generated__/github.data.gql.dart';
import 'package:git_touch/graphql/__generated__/github.req.gql.dart';
import 'package:git_touch/models/auth.dart';
import 'package:git_touch/models/theme.dart';
import 'package:git_touch/scaffolds/refresh_stateful.dart';
import 'package:git_touch/utils/utils.dart';
import 'package:git_touch/widgets/action_button.dart';
import 'package:git_touch/widgets/action_entry.dart';
import 'package:git_touch/widgets/app_bar_title.dart';
import 'package:git_touch/widgets/contribution.dart';
import 'package:git_touch/widgets/entry_item.dart';
import 'package:git_touch/widgets/mutation_button.dart';
import 'package:git_touch/widgets/repository_item.dart';
import 'package:git_touch/widgets/text_with_at.dart';
import 'package:git_touch/widgets/user_header.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _Repos extends StatelessWidget {
  _Repos(final Iterable<GRepoParts> pinned, final Iterable<GRepoParts>? repos)
      : title =
            pinned.isNotEmpty ? 'pinned repositories' : 'popular repositories',
        repos = pinned.isNotEmpty ? pinned : repos;
  final String title;
  final Iterable<GRepoParts>? repos;

  @override
  Widget build(BuildContext context) {
    return AntList(
      header: Text(title),
      children: [
        for (final v in repos!)
          RepositoryItem.gh(
            owner: v.owner.login,
            avatarUrl: v.owner.avatarUrl,
            name: v.name,
            description: v.description,
            starCount: v.stargazers.totalCount,
            forkCount: v.forks.totalCount,
            primaryLanguageName: v.primaryLanguage?.name,
            primaryLanguageColor: v.primaryLanguage?.color,
            isPrivate: v.isPrivate,
            isFork: v.isFork,
          ),
      ],
    );
  }
}

class _User extends StatelessWidget {
  const _User(this.p, {this.isViewer = false, this.rightWidgets = const []});
  final GUserPartsFull p;
  final bool isViewer;
  final List<Widget> rightWidgets;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeModel>(context);
    final login = p.login;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UserHeader(
          avatarUrl: p.avatarUrl,
          name: p.name,
          login: p.login,
          createdAt: p.createdAt,
          bio: p.bio,
          isViewer: isViewer,
          rightWidgets: rightWidgets,
        ),
        CommonStyle.border,
        Row(children: [
          EntryItem(
            count: p.repositories.totalCount,
            text: AppLocalizations.of(context)!.repositories,
            url: '/github/$login?tab=repositories',
          ),
          EntryItem(
            count: p.starredRepositories.totalCount,
            text: AppLocalizations.of(context)!.stars,
            url: '/github/$login?tab=stars',
          ),
          EntryItem(
            count: p.followers.totalCount,
            text: AppLocalizations.of(context)!.followers,
            url: '/github/$login?tab=followers',
          ),
          EntryItem(
            count: p.following.totalCount,
            text: AppLocalizations.of(context)!.following,
            url: '/github/$login?tab=following',
          ),
        ]),
        CommonStyle.border,
        ContributionWidget(
          weeks: [
            for (final week
                in p.contributionsCollection.contributionCalendar.weeks)
              [
                //  https://github.com/git-touch/git-touch/issues/122
                for (final day in week.contributionDays)
                  ContributionDay(hexColor: day.color)
              ]
          ],
        ),
        CommonStyle.border,
        AntList(
          children: [
            AntListItem(
              prefix: const Icon(Octicons.rss),
              child: Text(AppLocalizations.of(context)!.events),
              onClick: () {
                context.push('/github/$login?tab=events');
              },
            ),
            AntListItem(
              prefix: const Icon(Octicons.book),
              child: Text(AppLocalizations.of(context)!.gists),
              onClick: () {
                context.push('/github/$login?tab=gists');
              },
            ),
            AntListItem(
              prefix: const Icon(Octicons.home),
              child: Text(AppLocalizations.of(context)!.organizations),
              onClick: () {
                context.push('/github/$login?tab=organizations');
              },
            ),
            if (isNotNullOrEmpty(p.company))
              AntListItem(
                prefix: const Icon(Octicons.organization),
                child: TextWithAt(
                  text: p.company!,
                  linkFactory: (text) => '/github/${text.substring(1)}',
                  style: TextStyle(
                      fontSize: 17, color: AntTheme.of(context).colorText),
                  oneLine: true,
                ),
              ),
            if (isNotNullOrEmpty(p.location))
              AntListItem(
                prefix: const Icon(Octicons.location),
                child: Text(p.location!),
                onClick: () {
                  launchStringUrl(
                      'https://www.google.com/maps/place/${p.location!.replaceAll(RegExp(r'\s+'), '')}');
                },
              ),
            if (isNotNullOrEmpty(p.email))
              AntListItem(
                prefix: const Icon(Octicons.mail),
                child: Text(p.email),
                onClick: () {
                  launchStringUrl('mailto:${p.email}');
                },
              ),
            if (isNotNullOrEmpty(p.websiteUrl))
              AntListItem(
                prefix: const Icon(Octicons.link),
                child: Text(p.websiteUrl!),
                onClick: () {
                  var url = p.websiteUrl!;
                  if (!url.startsWith('http')) {
                    url = 'http://$url';
                  }
                  launchStringUrl(url);
                },
              ),
          ],
        ),
        CommonStyle.verticalGap,
        _Repos(
          p.pinnedItems.nodes!.whereType<GRepoParts>(),
          p.repositories.nodes,
        ),
        CommonStyle.verticalGap,
      ],
    );
  }
}

class _Org extends StatelessWidget {
  const _Org(this.p);
  final GUserData_organization p;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UserHeader(
          avatarUrl: p.avatarUrl,
          name: p.name,
          login: p.login,
          createdAt: p.createdAt,
          bio: p.description,
        ),
        CommonStyle.border,
        Row(children: [
          EntryItem(
            count: p.pinnableItems.totalCount,
            text: AppLocalizations.of(context)!.repositories,
            url: '/github/${p.login}?tab=repositories',
          ),
          EntryItem(
            count: p.membersWithRole.totalCount,
            text: AppLocalizations.of(context)!.members,
            url: '/github/${p.login}?tab=people',
          ),
        ]),
        AntList(
          children: [
            AntListItem(
              prefix: const Icon(Octicons.rss),
              child: Text(AppLocalizations.of(context)!.events),
              onClick: () {
                context.push('/github/${p.login}?tab=events');
              },
            ),
            if (isNotNullOrEmpty(p.location))
              AntListItem(
                prefix: const Icon(Octicons.location),
                child: Text(p.location!),
                onClick: () {
                  launchStringUrl(
                      'https://www.google.com/maps/place/${p.location!.replaceAll(RegExp(r'\s+'), '')}');
                },
              ),
            if (isNotNullOrEmpty(p.email))
              AntListItem(
                prefix: const Icon(Octicons.mail),
                child: Text(p.email!),
                onClick: () {
                  launchStringUrl('mailto:${p.email!}');
                },
              ),
            if (isNotNullOrEmpty(p.websiteUrl))
              AntListItem(
                prefix: const Icon(Octicons.link),
                child: Text(p.websiteUrl!),
                onClick: () {
                  var url = p.websiteUrl!;
                  if (!url.startsWith('http')) {
                    url = 'http://$url';
                  }
                  launchStringUrl(url);
                },
              ),
          ],
        ),
        CommonStyle.verticalGap,
        _Repos(
          p.pinnedItems.nodes!.whereType<GRepoParts>(),
          p.pinnableItems.nodes!.whereType<GRepoParts>(),
        ),
        CommonStyle.verticalGap,
      ],
    );
  }
}

class GhViewerScreen extends StatelessWidget {
  const GhViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthModel>(context);
    return RefreshStatefulScaffold<GUserPartsFull?>(
      fetch: () async {
        final req = GViewerReq();
        final res = await auth.gqlClient.request(req).first;
        return res.data?.viewer;
      },
      title: AppBarTitle(AppLocalizations.of(context)!.me),
      action: const ActionEntry(
        iconData: Ionicons.cog,
        url: '/settings',
      ),
      bodyBuilder: (p, _) {
        if (p == null) return null;
        return _User(p, isViewer: true);
      },
    );
  }
}

class GhUserScreen extends StatelessWidget {
  const GhUserScreen(this.login, {super.key});
  final String login;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthModel>(context);
    return RefreshStatefulScaffold<GUserData?>(
      fetch: () async {
        final req = GUserReq((b) => b..vars.login = login);
        final res = await auth.gqlClient.request(req).first;
        return res.data;
      },
      title: AppBarTitle(login),
      actionBuilder: (payload, _) {
        final url = payload?.user?.url ?? payload?.organization?.url;
        if (url == null) return null;

        return ActionButton(
          title: 'User Actions',
          items: ActionItem.getUrlActions(url),
        );
      },
      bodyBuilder: (data, setData) {
        if (data?.user != null) {
          final p = data!.user!;
          return _User(
            p,
            rightWidgets: [
              if (p.viewerCanFollow)
                MutationButton(
                  active: p.viewerIsFollowing,
                  text: p.viewerIsFollowing
                      ? AppLocalizations.of(context)!.unfollow
                      : AppLocalizations.of(context)!.follow,
                  onTap: () async {
                    if (p.viewerIsFollowing) {
                      await auth.ghClient.users.unfollowUser(p.login);
                    } else {
                      await auth.ghClient.users.followUser(p.login);
                    }
                    setData(data.rebuild((b) {
                      b.user.viewerIsFollowing = !b.user.viewerIsFollowing!;
                    }));
                  },
                )
            ],
          );
        } else if (data?.organization != null) {
          return _Org(data!.organization!);
        }
        return null; // TODO: not found
      },
    );
  }
}
