import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../common/extensions/json_extension.dart';
import '../../common/utils/date_time_util.dart';
import '../../const/network_inspector_enum.dart';
import '../../const/network_inspector_value.dart';
import '../../domain/entities/http_activity.dart';
import '../../domain/entities/http_request.dart';
import '../controllers/activity_detail_provider.dart';

import '../../domain/entities/http_response.dart';
import '../widgets/content_container.dart';
import '../widgets/titled_label.dart';
import 'http_error_page.dart';
import 'http_request_page.dart';
import 'http_response_page.dart';

class ActivityDetailPage extends StatelessWidget {
  static const String routeName = '/http-activity-detail';

  final HttpActivity httpActivity;

  ActivityDetailPage({
    required this.httpActivity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivityDetailProvider>(
      create: (context) => ActivityDetailProvider(
        httpActivity: httpActivity,
        context: context,
      ),
      builder: (context, child) {
        final provider = context.read<ActivityDetailProvider>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Request Details'),
            actions: [
              IconButton(
                onPressed: () {
                  provider.buildJson(
                    provider.shareHttpActivity,
                    HttpActivityActionType.share,
                  );
                },
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- OVERVIEW ---
                  const SectionHeader(title: 'OVERVIEW'),
                  OverviewCard(httpActivity: httpActivity),

                  const SizedBox(height: 16),

                  // --- REQUEST HEADERS ---
                  const SectionHeader(title: 'REQUEST HEADERS'),
                  HeadersCard(headers: httpActivity.request?.requestHeader),

                  const SizedBox(height: 16),

                  // --- REQUEST BODY ---
                  const SectionHeader(title: 'REQUEST BODY'),
                  RequestBodyCard(
                    response: httpActivity.request,
                  ),

                  const SizedBox(height: 16),

                  // --- RESPONSE BODY ---
                  const SectionHeader(title: 'RESPONSE BODY'),
                  ResponseBodyCard(
                    response: httpActivity.response,
                  ),

                  const SizedBox(height: 16),

                  // --- RESPONSE HEADERS ---
                  const SectionHeader(title: 'RESPONSE HEADERS'),
                  HeadersCard(headers: httpActivity.response?.responseHeader),

                  const SizedBox(height: 16),

                  // --- DEVELOPER INFO ---
                  const SectionHeader(title: 'DEVELOPER INFO'),
                  DeveloperInfoCard(httpActivity: httpActivity),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class OverviewCard extends StatelessWidget {
  final HttpActivity httpActivity;
  final _dateTimeUtil = DateTimeUtil();

  OverviewCard({required this.httpActivity, super.key});

  @override
  Widget build(BuildContext context) {
    final request = httpActivity.request;
    final response = httpActivity.response;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(
              context,
              label: 'URL',
              value: request?.fullUrl ?? 'N/A',
              isClickable: true,
              onTap: () => _showDetailSheet(context, 'URL', request?.fullUrl ?? 'N/A'),
            ),
            const Divider(),
            _buildRow(
              context,
              label: 'Method',
              value: request?.method ?? 'N/A',
              isClickable: false,
            ),
            const Divider(),
            _buildRow(
              context,
              label: 'Response Code',
              value: response?.responseStatusCode?.toString() ?? 'N/A',
              isClickable: false,
            ),
            const Divider(),
            _buildRow(
              context,
              label: 'Response Size',
              value: '${response?.responseSize} bytes' ?? 'N/A',
              isClickable: false,
            ),
            const Divider(),
            _buildRow(
              context,
              label: 'Date',
              value: response?.createdAt?.toString() ?? 'N/A',
              isClickable: false,
            ),
            const Divider(),
            _buildRow(
              context,
              label: 'Duration',
              value: _dateTimeUtil.milliSecondDifference(
                request?.createdAt,
                response?.createdAt,
              ) ?? 'N/A',
              isClickable: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
      BuildContext context, {
        required String label,
        required String value,
        bool isClickable = false,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: isClickable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: isClickable
                  ? Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              )
                  : Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeadersCard extends StatelessWidget {
  final String? headers;
  const HeadersCard({this.headers, super.key});

  @override
  Widget build(BuildContext context) {
    final headerList = _parseHeaders(headers);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < headerList.length; i++)
              Column(
                children: [
                  _buildHeaderRow(context, headerList[i].key, headerList[i].value),
                  if (i < headerList.length - 1) const Divider(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<_HeaderItem> _parseHeaders(String? rawHeaders) {
    if (rawHeaders == null || rawHeaders.isEmpty) {
      return [];
    }

    try {
      final dynamic jsonParsed = json.decode(rawHeaders);
      if (jsonParsed is Map<String, dynamic>) {
        final headers = <_HeaderItem>[];
        jsonParsed.forEach((key, value) {
          String valueStr;
          if (value is List) {
            valueStr = value.map((e) => e.toString()).join(', ');
          } else {
            valueStr = value.toString();
          }
          headers.add(_HeaderItem(key, valueStr));
        });
        return headers;
      }
    } catch (e) {
      print('JSON parsing failed: $e');
    }

    final lines = rawHeaders.split('\n');
    final headers = <_HeaderItem>[];

    for (final line in lines) {
      final parts = line.split(':').map((e) => e.trim()).toList();
      if (parts.length >= 2) {
        final key = parts[0];
        final value = parts.sublist(1).join(':').trim();
        headers.add(_HeaderItem(key, value));
      }
    }

    return headers;
  }

  Widget _buildHeaderRow(BuildContext context, String key, String value) {
    return InkWell(
      onTap: () => _showDetailSheet(context, key, value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                key,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestBodyCard extends StatelessWidget {
  final HttpRequest? response;
  const RequestBodyCard({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showDetailSheet(context, 'Request Headers', response?.requestHeader ?? ''),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'View Request headers',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Divider(),
            InkWell(
              onTap: () => _showDetailSheet(context, 'Request Body', response?.requestBody ?? ''),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'View Request body',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResponseBodyCard extends StatelessWidget {
  final HttpResponse? response;
  const ResponseBodyCard({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showDetailSheet(context, 'Response Headers', response?.responseHeader ?? ''),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'View response headers',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Divider(),
            InkWell(
              onTap: () => _showDetailSheet(context, 'Response Body', response?.responseBody ?? ''),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'View response body',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeveloperInfoCard extends StatelessWidget {
  final HttpActivity httpActivity;
  const DeveloperInfoCard({required this.httpActivity, super.key});

  @override
  Widget build(BuildContext context) {
    final response = httpActivity.response;
    final request = httpActivity.request;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(
              context,
              label: 'Request time',
              value: request?.createdAt?.toString() ?? 'N/A',
            ),
            const Divider(),
            _buildRow(
              context,
              label: 'Response time',
              value: response?.createdAt?.toString() ?? 'N/A',
            ),
            const Divider(),
            InkWell(
              onTap: () => _showDetailSheet(context, 'cUrl', httpActivity.request?.cUrl ?? ''),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Export cURL request',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HeaderItem {
  final String key;
  final String value;
  _HeaderItem(this.key, this.value);
}

void _showDetailSheet(BuildContext context, String title, String content) {
  final provider = Provider.of<ActivityDetailProvider>(
    context,
    listen: false,
  );
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {

      return

        SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ContentContainer(
                title: title,
                content: content,
                onCopyTap: () {
                  provider.copyActivityData(
                    content.prettify,
                  );
                },
                onShareTap: () {
                  provider.shareActivityData(
                    'Content',
                    content.prettify,
                  );
                  Navigator.pop(context);
                },
              )
              ],
            ),
          ),
        );
    },
  );
}