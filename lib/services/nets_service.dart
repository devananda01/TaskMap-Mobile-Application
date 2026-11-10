import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class NETSService {
  final String apiKey = '2YjDIGqCR4OMOBHDaZ3l';
  final String projectId = '4a77a4de-517c-48fd-92dd-3b90b6192085';

  // Generates a NETS QR payment request
  Future<Map<String, dynamic>> requestQR(double amount) async {
    try {
      final url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr/request',
      );

      final response = await post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
          'project-id': projectId,
        },
        body: jsonEncode({
          'txn_id': 'sandbox_nets|m|8ff8e5b6-d43e-4786-8ac5-7accf8c5bd9b',
          'amt_in_dollars': amount,
          'notify_mobile': 0,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'requestQR non-200: ${response.statusCode} ${response.body}',
        );
        return {};
      }

      final data = jsonDecode(response.body);
      final result = data is Map ? data['result'] : null;
      final resultData = result is Map ? result['data'] : null;

      if (resultData is! Map) {
        debugPrint('requestQR unexpected body: ${response.body}');
        return {};
      }

      return {
        'qrCode': resultData['qr_code'],
        'txnRef': resultData['txn_retrieval_ref'],
      };
    } catch (e) {
      debugPrint('requestQR error: $e');
      return {};
    }
  }

  // SSE stream for real-time payment updates
  Stream<String> webhookStream(String txnRef) async* {
    final client = Client();

    try {
      final url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets/webhook?txn_retrieval_ref=$txnRef',
      );

      final request = Request('GET', url)
        ..headers.addAll({
          'Accept': 'text/event-stream',
          'Connection': 'keep-alive',
          'api-key': apiKey,
          'project-id': projectId,
        });

      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          yield chunk;
        }
      }
    } finally {
      client.close();
    }
  }

  // Final payment status check
  Future<Map<String, dynamic>> checkPayment(String txnRef) async {
    try {
      final url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr/query',
      );

      final response = await post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
          'project-id': projectId,
        },
        body: jsonEncode({
          'txn_retrieval_ref': txnRef,
          'frontend_timeout_status': 1,
        }),
      );

      if (response.statusCode != 200) {
        return {};
      }

      final data = jsonDecode(response.body);
      final result = data is Map ? data['result'] : null;
      final resultData = result is Map ? result['data'] : null;

      if (resultData is! Map) {
        return {};
      }

      return {
        "response_code": resultData['response_code'],
        "message": resultData['message'],
      };
    } catch (e) {
      return {};
    }
  }
}
