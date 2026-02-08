import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/base/data_wrapper.dart';
import '../../common/extensions/unix_extension.dart';
import '../../common/extensions/url_extension.dart';
import '../../common/utils/byte_util.dart';
import '../../common/utils/date_time_util.dart';
import '../../common/widgets/bottom_sheet.dart';
import '../../const/network_inspector_value.dart';
import '../../domain/entities/http_activity.dart';
import '../../domain/entities/http_request.dart';
import '../controllers/activity_filter_provider.dart';
import '../controllers/activity_provider.dart';
import '../widgets/container_label.dart';
import '../widgets/filter_bottom_sheet_content.dart';

/// A page that show list of logged HTTP Activities, for navigating to this
/// page use regular Navigator.push
/// ```dart
///  Navigator.push(
///   context,
///   MaterialPageRoute<void>(
///     builder: (context) => ActivityPage(),
///   ),
/// );
/// ```
class ActivityPage extends StatelessWidget {
  static const String routeName = '/http-activity';

  ActivityPage({super.key});

  final _byteUtil = ByteUtil();
  final _dateTimeUtil = DateTimeUtil();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivityProvider>(
      create: (context) =>
          ActivityProvider(
            context: context,
          ),
      builder: (context, child) =>
          Scaffold(
            appBar: AppBar(
              title: const Text('Http Activities'),
              actions: [
                IconButton(
                  onPressed: () {
                    onTapFilterIcon(context);
                  },
                  icon: const Icon(
                    Icons.filter_list_alt,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final provider = context.read<ActivityProvider>();
                    provider.deleteActivities();
                  },
                  icon: const Icon(
                    Icons.delete,
                  ),
                ),
              ],
            ),
            body: buildBody(context),
          ),
    );
  }

  Widget buildBody(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          final result = provider.fetchedActivity;
          switch (provider.fetchedActivity.status) {
            case Status.loading:
              return loadingWidget(context);
            case Status.success:
              return successBody(
                context,
                result.data,
              );
            case Status.error:
              return errorMessage(context, result.message);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget successBody(BuildContext context,
      List<HttpActivity>? data,) {
    return Visibility(
      visible: data?.isNotEmpty ?? false,
      replacement: emptyBody(context),
      child: activityList(context, data),
    );
  }

  Widget emptyBody(BuildContext context) {
    return Center(
      child: Text(
        'There is no log, try to fetch something !',
        style: Theme
            .of(context)
            .textTheme
            .bodyLarge,
      ),
    );
  }

  Widget errorMessage(BuildContext context, error) {
    return Center(
      child: Text(
        'Log has error $error',
        style: Theme
            .of(context)
            .textTheme
            .bodyLarge,
      ),
    );
  }

  Widget loadingWidget(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget idleWidget(BuildContext context) {
    return Center(
      child: Text(
        'Please wait',
        style: Theme
            .of(context)
            .textTheme
            .bodyLarge,
      ),
    );
  }

  Widget activityList(BuildContext context,
      List<HttpActivity>? data,) {
    return ListView.separated(
      itemCount: data?.length ?? 0,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) =>
          activityTile(
            context,
            data![index],
            index,
          ),
    );
  }

  Widget activityTile(BuildContext context,
      HttpActivity activity,
      int index,) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        context.read<ActivityProvider>().goToDetailActivity(activity);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// LEFT COLUMN
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// METHOD
                  Text(
                    activity.request?.method ?? '-',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  /// STATUS CODE
                  ContainerLabel(
                    text: '${activity.response?.responseStatusCode ?? 'N/A'}',
                    color: NetworkInspectorValue.containerColor(
                      activity.response?.responseStatusCode ?? 0,
                    ),
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 6),

                  /// TIME
                  Text(
                    _dateTimeUtil.milliSecondDifference(
                      activity.request?.createdAt,
                      activity.response?.createdAt,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// RIGHT COLUMN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// DATE | SIZE
                  Text(
                    '${activity.request?.createdAt?.convertToYmdHms ?? '-'}'
                        ' | '
                        '${_byteUtil.totalTransferSize(
                      activity.request?.requestSize,
                      activity.response?.responseSize,
                      false,
                    )}',
                    style: theme.textTheme.bodySmall,
                  ),

                  const SizedBox(height: 6),

                  /// FULL URL
                  Text(
                    activity.request?.fullUrl ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onTapFilterIcon(BuildContext context) {
    final activityProvider = context.read<ActivityProvider>();

    // Всегда показываем все доступные фильтры
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Создаем локальный провайдер фильтров
        final filterProvider = ActivityFilterProvider();

        // Восстанавливаем выбранные фильтры, если они есть
        if (activityProvider.filterProvider != null) {
          _restoreFilters(activityProvider.filterProvider!, filterProvider);
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return BottomSheetTemplate(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilterBottomSheetContent(
                  // Показываем ВСЕ доступные фильтры
                  responseStatusCodes: activityProvider.allStatusCodes,
                  baseUrls: activityProvider.allBaseUrls,
                  paths: activityProvider.allPaths,
                  methods: activityProvider.allMethods,
                  onTapApplyFilter: (statusCodes,
                      baseUrls,
                      paths,
                      methods,) {
                    // Сохраняем выбранные фильтры
                    activityProvider.filterProvider = filterProvider;

                    Navigator.pop(context);
                    activityProvider.filterHttpActivities(
                      statusCodes: statusCodes,
                      baseUrls: baseUrls,
                      paths: paths,
                      methods: methods,
                    );
                  },
                  provider: filterProvider,
                ),
              ),
            );
          },
        );
      },
    );
  }

// Вспомогательный метод для восстановления фильтров
  void _restoreFilters(ActivityFilterProvider source,
      ActivityFilterProvider target) {
    // Копируем выбранные статус коды
    for (final code in source.selectedStatusCodes) {
      target.selectedStatusCodes.add(code);
    }

    // Копируем выбранные базовые URL
    for (final url in source.selectedBaseUrls) {
      target.selectedBaseUrls.add(url);
    }

    // Копируем выбранные пути
    for (final path in source.selectedPaths) {
      target.selectedPaths.add(path);
    }

    // Копируем выбранные методы
    for (final method in source.selectedMethods) {
      target.selectedMethods.add(method);
    }
  }
}