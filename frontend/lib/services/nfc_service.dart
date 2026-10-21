import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

class NfcService {
  /// Kiểm tra thiết bị có hỗ trợ NFC và đã bật hay chưa
  Future<bool> isAvailable() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      return availability == NfcAvailability.enabled;
    } catch (e) {
      debugPrint('NFC isAvailable error: $e');
      return false;
    }
  }

  /// Bắt đầu phiên quét thẻ NFC
  Future<void> startSession({
    required void Function(String cardId) onDiscovered,
    required void Function(String errorMessage) onError,
  }) async {
    try {
      final available = await isAvailable();
      if (!available) {
        onError('Thiết bị không hỗ trợ NFC hoặc chưa bật tính năng NFC.');
        return;
      }

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            final cardId = _extractIdentifier(tag);
            if (cardId != null && cardId.isNotEmpty) {
              onDiscovered(cardId);
            } else {
              onError('Không trích xuất được mã thẻ NFC.');
            }
          } catch (e) {
            onError('Lỗi khi đọc thẻ NFC: $e');
          }
        },
      );
    } catch (e) {
      onError('Không thể khởi động NFC: $e');
    }
  }

  /// Dừng phiên quét thẻ NFC
  Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('NFC stopSession error: $e');
    }
  }

  /// Trích xuất mã UID hex từ thẻ NFC Android
  String? _extractIdentifier(NfcTag tag) {
    try {
      final androidTag = NfcTagAndroid.from(tag);
      if (androidTag != null && androidTag.id.isNotEmpty) {
        return androidTag.id
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join('');
      }
    } catch (e) {
      debugPrint('Error extracting Android NFC identifier: $e');
    }
    return null;
  }
}
