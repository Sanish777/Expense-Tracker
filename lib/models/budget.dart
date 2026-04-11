import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  double monthlyLimit;

  @HiveField(1)
  double dailyLimit;

  Budget({
    required this.monthlyLimit,
    required this.dailyLimit,
  });
}
