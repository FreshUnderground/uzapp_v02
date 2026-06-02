import 'package:drift/drift.dart';
import '../local/uza_database.dart';

class MessageRepository {
  final UzaDatabase db;

  MessageRepository(this.db);

  /// Conversation thread id = sorted phones + optional shopId.
  String threadKey(String a, String b, {int? shopId}) {
    final phones = [a, b]..sort();
    return '${phones[0]}|${phones[1]}${shopId != null ? '|$shopId' : ''}';
  }

  Stream<List<ChatMessage>> watchThread({
    required String userPhone,
    required String otherPhone,
    int? shopId,
  }) {
    return (db.select(db.chatMessages)
          ..where((t) {
            final withOther =
                (t.senderPhone.equals(userPhone) &
                    t.receiverPhone.equals(otherPhone)) |
                (t.senderPhone.equals(otherPhone) &
                    t.receiverPhone.equals(userPhone));
            if (shopId != null) {
              return withOther & t.shopId.equals(shopId);
            }
            return withOther;
          })
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<List<ChatMessage>> watchInbox(String userPhone) {
    return (db.select(db.chatMessages)
          ..where(
            (t) =>
                t.senderPhone.equals(userPhone) |
                t.receiverPhone.equals(userPhone),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> sendMessage({
    required String senderPhone,
    required String receiverPhone,
    required String body,
    int? shopId,
    int? productId,
  }) {
    return db.into(db.chatMessages).insert(
          ChatMessagesCompanion.insert(
            senderPhone: senderPhone,
            receiverPhone: receiverPhone,
            body: body,
            shopId: Value(shopId),
            productId: Value(productId),
          ),
        );
  }

  Future<void> markThreadRead({
    required String userPhone,
    required String otherPhone,
    int? shopId,
  }) async {
    await (db.update(db.chatMessages)
          ..where(
            (t) {
              final base =
                  t.receiverPhone.equals(userPhone) &
                  t.senderPhone.equals(otherPhone) &
                  t.isRead.equals(false);
              if (shopId != null) {
                return base & t.shopId.equals(shopId);
              }
              return base;
            },
          ))
        .write(const ChatMessagesCompanion(isRead: Value(true)));
  }
}
